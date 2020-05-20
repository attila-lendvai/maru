;;; The Maru VM, written in a subset of Maru.

(define-form s/assert prog ())
(define-form debug    prog ())
(define-form gc/debug prog ())

;;
;; you can enable safety and debugging features here
;;
(define-form s/assert (test . args) `(or ,test (s/error ,@(or args (list "assertion failed")))))
;(define-form debug    prog `(let () ,@prog))
;(define-form gc/debug prog `(let () ,@prog))

;; This variable controls the amount of safety features compiled
;; into the runtime, at the cost of execution speed.
(define safety-level 3)

(define-form safety (level . prog)
  (when (<= level safety-level)
    `(let () ,@prog)))

;;;
;;; Naming convention in this file:
;;;
;;; vm     - Virtual Machine, i.e. a universe with its set of rules
;;;          accepted as axioms.
;;;
;;; host   - the Maru virtual machine (VM) running the compiler.
;;;
;;; target - the target VM of the "level-shift" operation (e.g. x86 asm).
;;;
;;; slave  - the Maru VM that is being bootstrapped and will
;;;          spring to life when the result of the level-shift
;;;          (compilation) gets executed in the target VM.
;;;          'slave' comes from the idea that, having a dynamic compiler,
;;;          the host could start up the slave VM under its full
;;;          supervision.
;;;
;;; oop    - Ordinary Object Pointer
;;;
;;; s/ prefix means that it's the slave version of something that
;;;    also exist in the host Maru (i.e. we need to differentiate
;;;    between the host and the slave versions). ideally, it should
;;;    be done with packages/modules, and automated tests against leaks.
;;;
;;; subr/ prefix is used for the Maru <subr>'s that will
;;;       be made visible to user code in the slave VM.
;;;
;;; size means bytes; if not, then it should be indicated.

;;;
;;; Implementation details:
;;;
;;;  - () is the false value, and is mapped to 0 in the target. Its type is <undefined>.
;;;

(define-form gc/protect (vars . prog)
  (let ((make-protectors
         (lambda (vars)
           (map (lambda (v) `(gc/push-root (address-of ,v)))
                vars)))
        (make-unprotectors
         (lambda (vars)
           (let ((result ()))
             (while (pair? vars)
               (set result (cons `(gc/pop-root (address-of ,(car vars))) result))
               (set vars (cdr vars)))
             result))))
    `(let ()
       ,@(make-protectors vars)
       (let ((__answer__ ,@prog))
         ,@(make-unprotectors vars)
         __answer__))))

(define-form define-externs args
  `(let ()
     ,@(map (lambda (libc-name)
              (let ((maru-name (concat-symbol 'libc/ libc-name)))
                `(define ,maru-name (extern ',libc-name))))
            args)))

(define-form bytes-to-words (value)
  `(>> ,value 2)) ; 32bit

(define-form words-to-bytes (value)
  `(<< ,value 2)) ; 32bit

(define-form align-to-words (value)
  `(& -4 (+ 3 ,value))) ; 32bit

(define-form malloc-oops (wordcount)
  `(libc/malloc (words-to-bytes ,wordcount)))

(define-form copy-oops (from to wordcount)
  `(libc/memcpy ,to ,from (words-to-bytes ,wordcount)))

;; FIXME structure-field-count: it's a leakage from the host to the slave
;; strategy: load the next boot.l into a clear env with only the primitives, then load eval.l, and compile from this clear env
(define-form size-of-structure (type)
  (structure-field-count (eval type)))

(eval `(define-structure <header> (,@(when (<= 3 safety-level) (list 'magic-marker)) size flags next type)))

(define-form size-of-<header> ()
  (words-to-bytes (size-of-structure <header>)))

(define-form header-of (arg)
  `(- ,arg ,(size-of-<header>)))

(let ((marker 233495534)) ; 0xDEADBEE, it's just an easy to recognize token without any meaning
  (define-form valid-header-magic-marker? (header)
    `(= (<header>-magic-marker ,header) ,marker))

  (define-form initialize-header-magic-marker (header)
    `(set (<header>-magic-marker ,header) ,marker)))

(define-form <header>-flags-used   ()     1)
(define-form <header>-flags-opaque ()     2)
(define-form <header>-flags-mark   ()     4)

(define-form <header>-flags-used+opaque () (+ (<header>-flags-used) (<header>-flags-opaque)))

;;;
;;;
;;; Actual artifacts that are meant to be level-shifted into the target
;;;
;;;
(compile-begin)

(define-externs
  abort exit
  malloc free memset memcpy
  stdout stderr printf fprintf sprintf
  strlen strcmp strdup strtoul getc ungetc putc
  fopen fdopen fclose fflush fscanf)

(define gc/quantum              65504)
(define gc/frequency            65536)

(define gc/objects-live         0)
(define gc/bytes-used           0)
(define gc/bytes-free           0)

(define gc/roots                0)
(define gc/root-count           0)
(define gc/root-max             0)

(define gc/memory-base          0)
(define gc/memory-last          0)
(define gc/alloc-count          0)
(define gc/collection-count     0)

(define-function max (a b)      (if (> a b) a b))

(define trace_stack     0)
(define trace_depth     0)

(define-form get_long (obj)     `(oop-at ,obj 0))

(define-form get_head (obj)     `(oop-at ,obj 0))
(define-form get_tail (obj)     `(oop-at ,obj 1))
(define-form set_tail (obj val) `(set-oop-at ,obj 1 ,val))

(define-function die ()
  (libc/fprintf libc/stderr "\nDIE called, printing a backtrace to stdout and exiting with exit code 1...\n")
  (libc/flush-streams)
  (let ((i trace_depth))
    (while (<= 0 (set i (- i 1)))
      (libc/printf "%3d: " i)
      (s/dumpln (s/array-at trace_stack i))
      (libc/flush-streams)))
  (libc/exit 1))

;; FATAL directly uses the libc printf (i.e. it cannot print maru objects), while
;; S/ERROR goes through the maru printing facility (i.e. must not be called with an .asciz).
(define-function fatal  (fmt)           (libc/fprintf libc/stderr fmt)           (libc/fprintf libc/stderr "\n") (die))
(define-function fatal1 (fmt arg)       (libc/fprintf libc/stderr fmt arg)       (libc/fprintf libc/stderr "\n") (die))
(define-function fatal2 (fmt arg1 arg2) (libc/fprintf libc/stderr fmt arg1 arg2) (libc/fprintf libc/stderr "\n") (die))

;; FIXME it would be nice for S/ERROR to be a function (or at least expand to a breakpoint'able function call),
;; but that would need the compiler to support variable nr of args, or literal lists
(define-form s/error args
  `(let ()
     (libc/printf "\nerror: ")
     ,@(map (lambda (arg)
              ;; string literals are turned into pointers to .asciz, therefore
              ;; we need to print them using libc/printf (or instantiate
              ;; them into Maru objects using new-<string>-from-cstring).
              (if (string? arg)
                  `(libc/printf ,arg)
                  `(s/print ,arg)))
            args)
     (libc/printf "\n")
     (die)))

(define-function gc/acquire-new-heap-space (size)
  (let ((ptr (libc/malloc size)))
    (or ptr (fatal "out of memory"))
    (set (<header>-size  ptr) (- size (size-of-<header>)))
    (set (<header>-flags ptr) 0)
    (set (<header>-next  ptr) ptr)
    (gc/debug (libc/printf "heap growth %p size %d %d/%d\n" ptr size gc/alloc-count gc/frequency))
    ptr))

(define-function gc/initialise ()
  (let ((ptr (gc/acquire-new-heap-space gc/quantum)))
    (set gc/memory-base ptr)
    (set gc/memory-last ptr)))

(define-function gc/push-root (ptr)
  (gc/debug (libc/printf "gc/push-root %d at %p\n" gc/root-count ptr))
  (when (= gc/root-count gc/root-max)
    (let ((new-roots (malloc-oops (set gc/root-max (max 32 (* 2 gc/root-max))))))
      (copy-oops gc/roots new-roots gc/root-count)
      (and gc/roots (libc/free gc/roots))
      (set gc/roots new-roots)))
  (set-oop-at gc/roots gc/root-count ptr)
  (set gc/root-count (+ 1 gc/root-count)))

(define-function gc/pop-root (ptr)
  (gc/debug (libc/printf "gc/pop-root %d at %p\n" gc/root-count ptr))
  (or gc/root-count (fatal "root table underflow"))
  (set gc/root-count (- gc/root-count 1))
  (or (= ptr (oop-at gc/roots gc/root-count))
      (fatal "non-lifo root")))

(define-function gc/grow-heap (size)
  (let ((new-block (gc/acquire-new-heap-space size)))
    (set (<header>-next new-block) (<header>-next gc/memory-last))
    (set (<header>-next gc/memory-last) new-block)))

(define-function gc/object-size (obj)
  (<header>-size (header-of obj)))

(define-function gc/allocate-opaque (size)
  (let ((obj (gc/allocate size)))
    (set (<header>-flags (header-of obj)) (<header>-flags-used+opaque))
    obj))

(define-function gc/allocate (requested-size)
  (gc/debug (libc/printf "gc/allocate %d\n" requested-size))
  (set requested-size (align-to-words requested-size))
  (and (= gc/alloc-count gc/frequency)
       (gc/collect))
  (let* ((first (<header>-next gc/memory-last))
         (chunk first)
         (total-size (+ requested-size (size-of-<header>))))
    (while 1
      (while
        (let ()
          (gc/debug (libc/printf "alloc? %d %p %p [%p] %d >= %d %d\n" (<header>-flags chunk) chunk (<header>-next chunk) first (<header>-size chunk) requested-size (<= requested-size (<header>-size chunk))))
          (when (= 0 (<header>-flags chunk))
            (let ((chunk-size (<header>-size chunk)))
              (while (and (= 0 (<header>-flags (<header>-next chunk)))
                          (= (<header>-next chunk) (+ chunk (+ (size-of-<header>) chunk-size))))
                (let ((next (<header>-next chunk)))
                  (set (<header>-next chunk) (<header>-next next))
                  (set chunk-size (set (<header>-size chunk) (+ chunk-size (+ (size-of-<header>) (<header>-size next)))))
                  (and (= next gc/memory-last) (set gc/memory-last chunk))))
              (when (or (< total-size chunk-size) ; we'll split this chunk
                        (= requested-size chunk-size)) ; we'll use the entire chunk
                (gc/debug (libc/printf "chunk-size %d\n" chunk-size))
                (when (> chunk-size total-size)
                  (let ((split (+ chunk total-size)))
                    (gc/debug (libc/printf "split %d: %p + %d -> %p + %d\n" chunk-size chunk requested-size split (- chunk-size total-size)))
                    (set (<header>-size  split) (- chunk-size total-size))
                    (set (<header>-flags split) 0)
                    (set (<header>-next  split) (<header>-next chunk))
                    (set (<header>-size  chunk) requested-size)
                    (set (<header>-next  chunk) split)
                    (set chunk-size requested-size)))
                (set (<header>-flags chunk) (<header>-flags-used))
                (set gc/memory-last chunk)
                (gc/debug (libc/printf "alloc chunk %p\n" chunk))
                (let ((obj (+ chunk (size-of-<header>))))
                  (libc/memset obj 0 chunk-size)
                  (set gc/alloc-count (+ gc/alloc-count 1))
                  (safety 4 (s/assert (= (gc/object-size obj) requested-size) "gc/allocate: was about to return with an object whose size in the header is not equal to the requested size"))
                  (safety 4 (s/assert (& (<header>-flags-used) (<header>-flags (header-of obj))) "gc/allocate: was about to return with an object whose USED flag is unset"))
                  (safety 3 (initialize-header-magic-marker (header-of obj)))
                  (safety 3 (set (<header>-type (header-of obj)) -42))
                  (gc/debug (libc/printf "gc/allocate: returning with %p (%p), size %d\n" (header-of obj) obj (gc/object-size obj)))
                  (return obj)))))
          (!= first (set chunk (<header>-next chunk)))))
      (gc/grow-heap (max (+ (size-of-<header>) requested-size) gc/quantum)))))

(define-function gc/sweep ()
  (gc/debug (libc/printf "sweep\n"))
  (let ((ptr gc/memory-base)
        (nobjs 0)
        (nused 0)
        (nfree 0))
    (while ptr
      (gc/debug (libc/printf "sweep? %d %p + %d\n" (<header>-flags ptr) ptr (<header>-size ptr)))
      (let ((flags (<header>-flags ptr)))
        (if (& flags (<header>-flags-mark))
            (let ()
              (safety 2 (or (not (= 0 (<header>-type ptr))) (fatal1 "gc/sweep: object with zero type %p" ptr)))
              (set nused (+ nused (<header>-size ptr)))
              (set nobjs (+ nobjs 1))
              (set (<header>-flags ptr) (^ flags (<header>-flags-mark))))
          (gc/debug (libc/printf "collect %p size %d\n" ptr (<header>-size ptr)))
          (set nfree (+ nfree (<header>-size ptr)))
          (set (<header>-flags ptr) 0)))
      (and (= gc/memory-base (set ptr (<header>-next ptr)))
           (set ptr 0)))
    (set gc/objects-live nobjs)
    (set gc/bytes-used nused)
    (set gc/bytes-free nfree)
    (debug (libc/printf "GC: %d used, %d free, %d allocations\n" nused nfree gc/alloc-count))
    ;;(and (< nfree nused) (gc/grow-heap gc/quantum))
    ))

(define-function gc/mark-and-trace (obj)
  (and obj
       (not (& 1 obj)) ; TODO ??? is that supposed to be the used flag of the header?
       (let* ((header (header-of obj))
              (flags  (<header>-flags header)))
         (gc/debug (libc/printf "mark and trace %p flags %d size %d type %d\n" header flags (<header>-size header) (<header>-type header)))
         (safety 3 (or (valid-header-magic-marker? header)  (fatal1 "gc/mark-and-trace: encountered an untagged pointer: %p" obj)))
         (safety 1 (or (& (<header>-flags-used) flags)      (fatal1 "gc/mark-and-trace: attempt to mark dead object %p" header)))
         (or (& flags (<header>-flags-mark))
             (let ()
               (set (<header>-flags header) (| flags (<header>-flags-mark)))
               (or (& flags (<header>-flags-opaque))
                   (let ((index (bytes-to-words (<header>-size header))))
                     (gc/debug (libc/printf "mark %p wordsize %d type %d\n" header index (<header>-type header)))
                     (safety 2 (or (not (= 0 (<header>-type header))) (fatal1 "gc/mark-and-trace: object with zero type %p" header)))
                     (while index
                       (set index (- index 1))
                       (gc/debug (libc/printf "@%d %p\n" index (header-of (oop-at obj index))))
                       (gc/mark-and-trace (oop-at obj index))))))))))

(define-function gc/collect ()
  (gc/debug
    (or (& 1023 (set gc/collection-count (+ gc/collection-count 1)))
        (libc/fprintf libc/stderr "%d collections\n" gc/collection-count 1)))
  (let ((i 0))
    (while (< i gc/root-count)
      (gc/debug (let ((root (oop-at gc/roots i))) (libc/printf "mark gc root %d : %p -> %p\n" i root (header-of (oop-at root 0)))))
      (gc/mark-and-trace (oop-at (oop-at gc/roots i) 0))
      (set i (+ 1 i))))
  (gc/sweep)
  (set gc/alloc-count 0))

;;; ----------------------------------------------------------------

(define EOF     -1)

;; NOTE: the subr's in eval.l assume a certain layout for the built-in types.
;;   what actually happens is encoded in eval.l, and the define-structure forms
;;   for the built-in types in boot.l merely fill in some missing parts. types
;;   are represented internally as successive integers.
;;   corollary: the two files must agree, both in the order and in the field layout.
;; NOTE: the following type names will shadow the ones from the host VM.
;;   strictly speaking, they should be prefixed with s/.
(define <undefined>      0)
(define <long>           1)
(define <string>         2)
(define <symbol>         3)
(define <pair>           4)
(define <_array>         5)
(define <array>          6)
(define <expr>           7)
(define <form>           8)
(define <fixed>          9)
(define <subr>          10)

(define symbols                 0)

;; these point to the respective assoc entries in the env
(define globals                 0) ; environments are an alist of (name . value)
(define expanders               0)
(define encoders                0)
(define evaluators              0)
(define applicators             0)

;; the well-known symbols that we need to reference (they will be initialized at start)
(define symbol/t                     0)
(define symbol/dot                   0)
(define symbol/set                   0)
(define symbol/lambda                0)
(define symbol/let                   0)
(define symbol/quote                 0)
(define symbol/quasiquote            0)
(define symbol/unquote               0)
(define symbol/unquote_splicing      0)

(define fixed-subr/quote        0)
(define fixed-subr/lambda       0)
(define fixed-subr/let          0)

(define opt_verbose             0)

(define-function new-object/opaque (type bytesize)
  (safety 1 (s/assert (not (= 0 type)) "new-object/opaque was called with zero type"))
  (let* ((obj (gc/allocate-opaque bytesize))
         (header (header-of obj)))
    (set (<header>-type header) type)
    obj))

(define-function new-object (type wordsize)
  (safety 1 (s/assert (not (= 0 type)) "new-object was called with zero type"))
  (let* ((obj (gc/allocate (words-to-bytes wordsize)))
         (header (header-of obj)))
    (set (<header>-type header) type)
    obj))

(define-function new-<long> (bits)
  (let ((obj (new-object/opaque <long> (words-to-bytes (size-of-structure <long>)))))
    (set (<long>-_bits obj) bits)
    obj))

(define-function new-<string>-of-length (len)
  (let ((str (new-object <string> (size-of-structure <string>))))
    (gc/protect (str)
      (set (<string>-size  str) (new-<long> len))
      (set (<string>-_bits str) (gc/allocate-opaque (+ len 1)))
      (safety 3 (set (<header>-type (header-of (<string>-_bits str))) -43))
      str)))

(define-function new-<string>-from-cstring (cstr)
  (let ((len (libc/strlen cstr)))
    (let ((obj (new-<string>-of-length len)))
      (libc/memcpy (<string>-_bits obj) cstr len)
      obj)))

(define-function new-<symbol> (cstr)
  (let ((obj (new-object/opaque <symbol> (words-to-bytes (size-of-structure <symbol>)))))
    (set (<symbol>-_bits obj) (libc/strdup cstr))
    obj))

(define-function new-<pair> (head tail)
  (let ((obj (new-object <pair> (size-of-structure <pair>))))
    (set (<pair>-head obj) head)
    (set (<pair>-tail obj) tail)
    obj))

(define-function new-<array> (size)
  (let ((arr (new-object <array> (size-of-structure <array>))))
    (gc/protect (arr)
      (set (<array>-_array arr) (new-object <_array> size))
      arr)))

(define-function new-<expr> (defn env)
  (let ((obj (new-object <expr> (size-of-structure <expr>))))
    (set (<expr>-defn obj) defn)
    (set (<expr>-env  obj) env )
    obj))

(define-function new-<form> (fn)
  (let ((obj (new-object <form> (size-of-structure <form>))))
    (gc/protect (obj)
      (set (<form>-function obj) fn)
      obj)))

(define-function new-<fixed> (fn)
  (let ((obj (new-object <fixed> (size-of-structure <fixed>))))
    (gc/protect (obj)
      (set (<fixed>-function obj) fn)
      obj)))

(define-function new-<subr> (_imp _name)
  (let ((obj (new-object/opaque <subr> (words-to-bytes (size-of-structure <subr>)))))
    (gc/protect (obj)
      (set (<subr>-_imp  obj) _imp )
      (set (<subr>-_name obj) _name)
      obj)))

(define-form is (type arg)
  `(let ((__arg__ ,arg))
     (and __arg__
          (not (& 1 __arg__))           ; TODO ???
          (let ((header (header-of __arg__)))
            (safety 3 (or (valid-header-magic-marker? header) (fatal1 "IS: encountered an untagged pointer: %p" __arg__)))
            (= ,type (<header>-type header))))))

(define-form s/type-of (arg)
  `(let ((__arg__ ,arg))
     (if __arg__
         (let ((header (header-of __arg__)))
           (safety 3 (or (valid-header-magic-marker? header) (fatal1 "S/TYPE-OF: encountered an untagged pointer: %p" __arg__)))
           (safety 1 (or (& (<header>-flags-used) (<header>-flags header)) (fatal1 "S/TYPE-OF: attempt to access dead object: %p" __arg__)))
           (<header>-type (header-of __arg__)))
       <undefined>)))

(define-function %type-check-failed (exp act)
  (fatal2 "type error: expected %d, got %d" exp act))

(define-form get (type field object)
  `(let ((__obj__ ,object))
     (safety 2 (let ((t (s/type-of __obj__))) (or (= ,type t) (%type-check-failed ,type t))))
     (,(concat-symbol (concat-symbol type '-) field) __obj__)))

(define-form put (type field object value)
  `(let ((__obj__ ,object))
     (safety 2 (let ((t (s/type-of __obj__))) (or (= ,type t) (%type-check-failed ,type t))))
     (set (,(concat-symbol (concat-symbol type '-) field) __obj__) ,value)))

(define-function is_blank (c)   (or      ( = ?   c)                     ; sp
                                         ( = ?\t c)                     ; ht
                                         ( = ?\n c)                     ; nl
                                         ( = ?\v c)                     ; vt
                                         ( = ?\f c)                     ; ff
                                         ( = ?\r c)))                   ; cr

(define-function is_digit10 (c)     (and (<= ?0  c) (<= c ?9)))         ; 0 1 2 3 4 5 6 7 8 9

(define-function is_digit16 (c) (or (and (<= ?0  c) (<= c ?9))          ; 0 1 2 3 4 5 6 7 8 9
                                    (and (<= ?a  c) (<= c ?f))          ; a b c d e f
                                    (and (<= ?A  c) (<= c ?F))))        ; A B C D E F

(define-function is_alpha (c)   (or (and (<= ?a  c) (<= c ?z))          ; a b c d e f g h i j k l m n o p q r s t u v w x y z
                                    (and (<= ?A  c) (<= c ?Z))))        ; A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

(define-function is_letter (c)  (or      ( = ?!  c)                     ; !
                                    (and (<= ?#  c) (<= c ?&))          ; # $ % &
                                    (and (<= ?*  c) (<= c ?/))          ; * + , - . /
                                         ( = ?:  c)                     ; :
                                    (and (<= ?<  c) (<= c ?Z))          ; < = > ?  @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                                         ( = ?\\ c)                     ; \
                                         ( = ?^  c)                     ; ^
                                         ( = ?_  c)                     ; _
                                    (and (<= ?a  c) (<= c ?z))          ; a b c d e f g h i j k l m n o p q r s t u v w x y z
                                         ( = ?|  c)                     ; |
                                         ( = ?~  c)))                   ; ~

(define-structure <buffer> (contents size position))

(define-function new_buffer ()
  (let ((buf (libc/malloc (words-to-bytes (size-of-structure <buffer>)))))
    (set (<buffer>-contents buf) (libc/malloc 32))
    (set (<buffer>-size     buf) 32)
    (set (<buffer>-position buf) 0)
    buf))

(define-function buffer_delete (buf)
  (libc/free (<buffer>-contents buf))
  (libc/free buf))

(define-function buffer_grow (buf)
  (let* ((size     (<buffer>-size buf))
         (contents (libc/malloc (* 2 size))))
    (libc/memcpy contents (<buffer>-contents buf) size)
    (libc/free (<buffer>-contents buf))
    (set (<buffer>-contents buf) contents)
    (set (<buffer>-size buf) (* 2 size))))

(define-function buffer_append (buf c)
  (and (= (<buffer>-position buf) (<buffer>-size buf))
       (buffer_grow buf))
  (let ((posn (<buffer>-position buf)))
    (set-string-at (<buffer>-contents buf) posn c)
    (set (<buffer>-position buf) (+ 1 posn))))

(define-function buffer_append_all (buf s)
  (let ((i 0)
        (c 0))
    (while (set c (string-at s i))
      (buffer_append buf c)
      (set i (+ 1 i)))))

(define-function buffer_contents (buf)
  (buffer_append buf 0)
  (set (<buffer>-position buf) (- (<buffer>-position buf) 1))
  (<buffer>-contents buf))

(define-function intern (cstr)
  (let ((list symbols))
    (while (is <pair> list)
      (let ((sym (get_head list)))
        (or (libc/strcmp cstr (get <symbol> _bits sym))
            (return sym)))
      (set list (get_tail list))))
  (let ((sym (new-<symbol> cstr)))
    (gc/protect (sym)
      (set symbols (new-<pair> sym symbols))
      sym)))

(define-function is_octal (c)           (and (<= ?0 c) (<= c ?7)))

(define-function is_hexadecimal (c)     (or (and (<= ?0 c) (<= c ?9))
                                            (and (<= ?a c) (<= c ?f))
                                            (and (<= ?A c) (<= c ?F))))

(define-function digit_value (c)
  (cond
    ((and (<= ?0 c) (<= c ?9))  (- c ?0))
    ((and (<= ?a c) (<= c ?z))  (- c (- ?a 10)))
    ((and (<= ?A c) (<= c ?Z))  (- c (- ?A 10)))
    (else                       (fatal1 "illegal digit in character escape: %c" c))))

(define-function read_char (c stream)
  (if (= ?\\ c)
      (let ()
        (set c (libc/getc stream))
        (cond
          ((= c ?a)                     ?\a)
          ((= c ?b)                     ?\b)
          ((= c ?f)                     ?\f)
          ((= c ?n)                     ?\n)
          ((= c ?r)                     ?\r)
          ((= c ?t)                     ?\t)
          ((= c ?v)                     ?\v)
          ((= c ?u)                     (let ((a (libc/getc stream))
                                              (b (libc/getc stream))
                                              (c (libc/getc stream))
                                              (d (libc/getc stream)))
                                          (or (and (is_hexadecimal a)
                                                   (is_hexadecimal b)
                                                   (is_hexadecimal c)
                                                   (is_hexadecimal d))
                                              (s/error "illegal character escape"))
                                          (+ (<< (digit_value a) 24)
                                             (+ (<< (digit_value b) 16)
                                                (+ (<< (digit_value c)  8)
                                                   (digit_value d))))))
          ((= c ?x)                     (let ((x 0))
                                          (if (is_hexadecimal (set c (libc/getc stream)))
                                              (let ()
                                                (set x (digit_value c))
                                                (if (is_hexadecimal (set c (libc/getc stream)))
                                                    (let ()
                                                      (set x (+ (* x 16) (digit_value c)))
                                                      (set c (libc/getc stream)))
                                                  (s/error "illegal character escape"))))
                                          (libc/ungetc c stream)
                                          x))
          ((and (<= ?0 c) (<= c ?7))    (let ((x (digit_value c)))
                                          (if (is_octal (set c (libc/getc stream)))
                                              (let ()
                                                (set x (+ (* x 8) (digit_value c)))
                                                (if (is_octal (set c (libc/getc stream)))
                                                    (let ()
                                                      (set x (+ (* x 8) (digit_value c)))
                                                      (set c (libc/getc stream)))
                                                  (s/error "illegal character escape"))))
                                          (libc/ungetc c stream)
                                          x))
          (else                 (if (or (is_alpha c) (is_digit10 c))
                                    (fatal1 "illegal character escape: \\%c" c)
                                  c))))
    c))

(define-function read_number (c stream)
  (let ((buf (new_buffer))
        (neg (= ?- c)))
    (or neg (buffer_append buf c))
    (while (is_digit10 (set c (libc/getc stream))) (buffer_append buf c))
    (and (= ?x c) (= 1 (<buffer>-position buf))
         (let ()
           (buffer_append buf c)
           (while (is_digit16 (set c (libc/getc stream))) (buffer_append buf c))))
    (libc/ungetc c stream)
    (buffer_append buf 0)
    (let ((result (libc/strtoul (<buffer>-contents buf) 0 0)))
      (buffer_delete buf)
      (new-<long> (if neg (- result) result)))))

(define-function read_symbol (c stream)
  (let ((buf (new_buffer)))
    (while (or (is_letter c) (is_digit10 c))
      (buffer_append buf c)
      (set c (libc/getc stream)))
    (libc/ungetc c stream)
    (buffer_append buf 0)
    (let ((result (intern (<buffer>-contents buf))))
      (buffer_delete buf)
      result)))

(define-function read_string (c stream)
  (let ((buf (new_buffer)))
    (while (!= ?\" (set c (libc/getc stream)))
      (set c (read_char c stream))
      (when (= EOF c)
        (s/error "unterminated string literal"))
      (buffer_append buf c))
    (buffer_append buf 0)
    (let ((result (new-<string>-from-cstring (<buffer>-contents buf))))
      (buffer_delete buf)
      result)))

(define-function read_list (delim stream)
  (let* ((head (new-<pair> () ()))
         (tail head)
         (elt  ()))
    (gc/protect (head elt)
      (while (and (!= EOF (set elt (s/read stream))) (!= symbol/dot elt))
        (set elt (new-<pair> elt ()))
        (set tail (set_tail tail elt)))
      (and (= symbol/dot elt) (set_tail tail (s/read stream))))
    (let ((c (libc/getc stream)))
      (if (= delim c)
          (get_tail head)
        (fatal1 "missing closing '%c' delimiter while reading list" delim)))))

(define-function read_quote (prefix stream)
  (let ((qobj (s/read stream)))
    (when (= EOF qobj)
      (s/error "EOF while reading quoted literal"))
    (gc/protect (qobj)
      (set qobj (new-<pair> qobj ()))
      (set qobj (new-<pair> prefix qobj))
      qobj)))

(define-function s/read (stream)
  (while 1
    (let ((c (libc/getc stream)))
      (cond
        ((is_blank c)   ())
        ((= ?? c)       (return (new-<long> (read_char (libc/getc stream) stream))))
        ((= ?- c)       (return (if (is_digit10 (libc/ungetc (libc/getc stream) stream))
                                    (read_number c stream)
                                    (read_symbol c stream))))
        ((= ?\' c)      (return (read_quote symbol/quote stream)))
        ((= ?\` c)      (return (read_quote symbol/quasiquote stream)))
        ((= ?\, c)      (return (let ((d (libc/getc stream)))
                                  (if (= ?@ d)
                                      (read_quote symbol/unquote_splicing stream)
                                    (libc/ungetc d stream)
                                    (read_quote symbol/unquote stream)))))
        ((is_letter c)  (return (read_symbol c stream)))
        ((= ?\( c)      (return (read_list ?\) stream)))        ((= ?\) c)      (return (let () (libc/ungetc c stream) EOF)))
        ((= ?\[ c)      (return (read_list ?\] stream)))        ((= ?\] c)      (return (let () (libc/ungetc c stream) EOF)))
        ((= ?\{ c)      (return (read_list ?\} stream)))        ((= ?\} c)      (return (let () (libc/ungetc c stream) EOF)))
        ((is_digit10 c) (return (read_number c stream)))
        ((= ?\; c)      (while (and (!= ?\n (set c (libc/getc stream)))
                                    (!= ?\r c)
                                    (!= EOF c))))
        ((= ?\" c)      (return (read_string c stream)))
        ((< c 0)        (return EOF))
        (else           (fatal1 "illegal character: %c" c))))))

(define-function do_print (obj storing)
  (debug (libc/printf "{%p}" obj))
  (let ((type (s/type-of obj)))
    (cond
      ((= type <undefined>)     (libc/printf "nil"))
      ((= type <long>)          (libc/printf "%d" (get <long> _bits obj)))
      ((= type <string>)        (let ((bits (get <string> _bits obj)))
                                  (if (not storing)
                                      (libc/printf "%s" bits)
                                    (let ((i 0)
                                          (c 0))
                                      (libc/printf "\"")
                                      (while (set c (string-at bits i))
                                        (if (and (<= 32 c) (<= c 126))
                                            (cond
                                              ((= c ?\")        (libc/printf "\\\""))
                                              ((= c ?\\)        (libc/printf "\\\\"))
                                              (else             (libc/printf "%c" c)))
                                          (libc/printf "\\%03o" c))
                                        (set i (+ 1 i)))
                                      (libc/printf "\"")))))
      ((= type <symbol>)        (libc/printf "%s" (get <symbol> _bits obj)))
      ((= type <pair>)          (let ()
                                  (libc/printf "(")
                                  (while (and (is <pair> obj) (!= (get_tail globals) obj))
                                    (do_print (get_head obj) storing)
                                    (and (is <pair> (set obj (get_tail obj))) (libc/printf " ")))
                                  (if (= (get_tail globals) obj)
                                      (libc/printf "<globals>")
                                    (and obj
                                         (let ()
                                           (libc/printf " . ")
                                           (do_print obj storing))))
                                  (libc/printf ")")))
      ((= type <array>)         (let ((len (s/array-length obj)))
                                  (libc/printf "Array(")
                                  (for (i 0 len)
                                    (and i (libc/printf " "))
                                    (do_print (s/array-at obj i) storing))
                                  (libc/printf ")")))
      ((= type <expr>)          (let ()
                                  (libc/printf "Expr(")
                                  (do_print (s/car (get <expr> defn obj)) storing)
                                  (libc/printf ")")))
      ((= type <form>)          (let ()
                                  (libc/printf "Form(")
                                  (do_print (get <form> function obj) storing)
                                  (libc/printf ")")))
      ((= type <fixed>)         (let ()
                                  (libc/printf "Fixed(")
                                  (do_print (get <fixed> function obj) storing)
                                  (libc/printf ")")))
      ((= type <subr>)          (libc/printf "Subr(%s)" (get <subr> _name obj)))
      (else                     (libc/printf "<type:%d>" type)))))

(define-function s/print (obj) (do_print obj 0))        (define-function s/println (obj) (do_print obj 0) (libc/printf "\n"))
(define-function s/dump  (obj) (do_print obj 1))        (define-function s/dumpln  (obj) (do_print obj 1) (libc/printf "\n"))

;;; ----------------------------------------------------------------

(define-function s/define (name value env)
  (let ((ass (new-<pair> name value)))
    (gc/protect (ass)
      (let ((ent (new-<pair> ass (get_tail env))))
        (set_tail env ent)
        ass))))

(define-function s/assq (key list)
  (while (is <pair> list)
    (let ((head (get_head list)))
      (and (is <pair> head)
           (= key (get_head head))
           (return head)))
    (set list (get_tail list))))

(define-function s/car (list)   (and (is <pair> list) (get_head list)))
(define-function s/cdr (list)   (and (is <pair> list) (get_tail list)))

(define-function s/caar (list)  (s/car (s/car list)))
(define-function s/cadr (list)  (s/car (s/cdr list)))
(define-function s/cddr (list)  (s/cdr (s/cdr list)))

(define-function s/caddr (list) (s/car (s/cdr (s/cdr list))))

(define-function s/string-length (obj)  (get_long (get <string> size obj)))

(define-function s/array-length (obj)
  (safety 1 (or (is <array> obj) (fatal1 "s/array-length: called with object of type %d" (s/type-of obj))))
  (and (is <array> obj)
       (let ((_arr (get <array> _array obj)))
         (let ((wordsize (bytes-to-words (gc/object-size _arr))))
           wordsize))))

(define-function s/array-at (obj idx)
  (safety 1 (or (and (is <array> obj) (<= 0 idx)) (fatal2 "s/array-at: called with object of type %d, and index %d" (s/type-of obj) idx)))
  (and (is <array> obj)
       (let* ((elts (get <array> _array obj))
              (wordsize (bytes-to-words (gc/object-size elts))))
         (and (<= 0 idx) (< idx wordsize)
              (oop-at elts idx)))))

(define-function s/set-array-at (obj idx val)
  (safety 1 (or (and (is <array> obj) (<= 0 idx)) (fatal2 "s/set-array-at: called with object of type %d, and index %d" (s/type-of obj) idx)))
  (and (is <array> obj)
       (let* ((elts (get <array> _array obj))
              (wordsize (bytes-to-words (gc/object-size elts))))
         (and (<= 0 idx)
              (let ()
                (or (< idx wordsize)
                    (let* ((newsize (max (+ idx 1) (* wordsize 2)))
                           (oops  (new-object <_array> newsize)))
                      (copy-oops elts oops wordsize)
                      (set elts (put <array> _array obj oops))))
                (set-oop-at elts idx val))))))

(define-function s/concat-list (head tail)
  (if (is <pair> head)
      (let ()
        (set tail (s/concat-list (get_tail head) tail))
        (gc/protect (tail)
          (new-<pair> (get_head head) tail)))
    tail))

;;; ----------------------------------------------------------------

(define-function exlist (list env)
  (if (is <pair> list)
      (let ((head (s/expand (get_head list) env)))
        (gc/protect (head)
          (let ((tail (exlist (get_tail list) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    list))

(define-function s/expand (exp env)
  (if (is <pair> exp)
      (let ((head (s/expand (get_head exp) env)))
        (gc/push-root (address-of head))
        (if (is <symbol> head)
            (let ((val (s/cdr (s/assq head env))))
              (if (is <form> val)
                  (let ()
                    (set head (s/apply (get <form> function val) (get_tail exp) env))
                    (set head (s/expand head env))
                    (gc/pop-root (address-of head))
                    (return head)))))
        (let ((tail (get_tail exp)))
          (gc/push-root (address-of tail))
          (or (= head symbol/quote) (set tail (exlist tail env)))
          (and (= symbol/set head)
               (is <pair>   (s/car  tail))
               (is <symbol> (s/caar tail))
               (let ((buf (new_buffer)))
                 (buffer_append_all buf "set-")
                 (buffer_append_all buf (get <symbol> _bits (get_head (get_head tail))))
                 (set head (intern (buffer_contents buf)))
                 (set tail (s/concat-list (get_tail (get_head tail)) (get_tail tail)))))
          (set exp (new-<pair> head tail))
          (gc/pop-root (address-of tail))
          (gc/pop-root (address-of head))))
    (let ((fn (s/array-at (get_tail expanders) (s/type-of exp))))
      (and fn
           (let ((args (new-<pair> exp ())))
             (gc/protect (args)
               (set exp (s/apply fn args env)))))))
  exp)

(define-function enlist (list env)
  (if (is <pair> list)
      (let ((head (s/encode (get_head list) env)))
        (gc/protect (head)
          (let ((tail (enlist (get_tail list) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    list))

(define-function s/encode (exp env)
  (if (is <pair> exp)
      (let ((head (s/encode (get_head exp) env))
            (tail (get_tail exp)))
        (gc/protect (head tail)
          (if (is <symbol> head)
              (let ((val (s/cdr (s/assq head env))))
                (and (or (is <fixed> val) (is <subr> val))
                     (set head val))))
          (cond
            ((= head fixed-subr/let)    (let ((args (s/cadr exp))
                                              (tmp  ()))
                                          (gc/protect (env tmp)
                                            (while (is <pair> args)
                                              (let ((var (get_head args)))
                                                (and (is <pair> var) (set var (get_head var)))
                                                (set tmp (new-<pair> var ()))
                                                (set env (new-<pair> tmp env))
                                                (set args (get_tail args))))
                                            (set tail (enlist tail env)))))
            ((= head fixed-subr/lambda) (let ((args (s/cadr exp))
                                              (tmp  ()))
                                          (gc/protect (env tmp)
                                            (while (is <pair> args)
                                              (set tmp (new-<pair> (get_head args) ()))
                                              (set env (new-<pair> tmp env))
                                              (set args (get_tail args)))
                                            (and args
                                                 (let ()
                                                   (set tmp (new-<pair> args ()))
                                                   (set env (new-<pair> tmp env))))
                                            (set tail (enlist tail env)))))
            ((!= head fixed-subr/quote)     (set tail (enlist tail env))))
          (set exp (new-<pair> head tail))))
    (let ((fn (s/array-at (get_tail encoders) (s/type-of exp))))
      (debug (when fn
               (libc/printf "APPLY GOT ENCODER\n... ")
               (s/println fn)))
      (and fn
           (let ((args (new-<pair> env ())))
             (gc/protect (args)
               (set args (new-<pair> exp args))
               (libc/printf "APPLY ENCODER\n... ") (s/print fn) (libc/printf " ") (s/print args) (libc/printf " ") (s/println env)
               (set exp (s/apply fn args env)))))))
  exp)

(define-function s/eval (exp env)
  (let ((ev (s/array-at (get_tail evaluators) (s/type-of exp))))
    (and ev
         (let ((args (new-<pair> exp ())))
           (gc/protect (args)
             (s/set-array-at trace_stack trace_depth exp)
             (set trace_depth (+ trace_depth 1))
             (set exp (s/apply ev args env))
             (set trace_depth (- trace_depth 1)))))
    exp))

(define-function s/apply (fun arguments env)
  (if (is <subr> fun)
      ((get <subr> _imp fun) arguments env)
    (let ((ap (s/array-at (get_tail applicators) (s/type-of fun))))
      (or ap (s/error "cannot apply: " fun))
      (let ((args arguments))
        (gc/protect (args)
          (set args (new-<pair> fun args))
          (s/apply ap args env))))))

;;;
;;; the subr's
;;;
(define-form define-subr (name-and-props . body)
  (unless (pair? name-and-props)
    (set name-and-props (list name-and-props)))
  (let ((name (car name-and-props))
        (arity (car (cdr name-and-props))))
    (assert (symbol? name))
    `(define-function ,(concat-symbol 'subr/ (string->symbol name)) (args env)
       ,@(when arity
           `((safety 1 (,(concat-symbol 'arity (string->symbol (long->string arity)))
                        (new-<string>-from-cstring ,(symbol->string name))
                        args))))
       ,@body)))

(define-function arity0 (op args)
  (or (not args)
      (s/error "Operator '" op "' expected no arguments, got: " args)))

(define-function arity1 (op args)
  (or (and (is <pair> args)
           (= () (get_tail args)))
      (s/error "Operator '" op "' expected 1 argument, got: " args)))

(define-function arity2 (op args)
  (or (and (is <pair> args)
           (is <pair> (get_tail args))
           (= () (get_tail (get_tail args))))
      (s/error "Operator '" op "' expected 2 arguments, got: " args)))

(define-function arity3 (op args)
  (or (and (is <pair> args)
           (is <pair> (get_tail args))
           (is <pair> (get_tail (get_tail args)))
           (= () (get_tail (get_tail (get_tail args)))))
      (s/error "Operator '" op "' expected 3 arguments, got: " args)))

(define-subr (define 2)
  (let ((sym (s/car args)))
    (or (is <symbol> sym)
        (s/error "non-symbol identifier in define: " sym))
    (let ((val (s/eval (s/cadr args) env)))
      (gc/protect (val)
        (s/define sym val (get_tail globals))
        val))))

(define-subr lambda
  (new-<expr> args env))

(define-subr let
  (let ((env2     env)
        (tmp      ())
        (bindings (s/car args))
        (body     (s/cdr args)))
    (gc/protect (env2 tmp)
      (while (is <pair> bindings)
        (let ((binding (get_head bindings)))
          (or (is <pair> binding)
              (s/error "invalid binding form for IF: " binding))
          (let ((sym  (get_head binding))
                (prog (get_tail binding)))
            (or (is <symbol> sym)
                (s/error "invalid binding name for IF: " sym))
            (while (is <pair> prog)
              (set tmp (s/eval (get_head prog) env))
              (set prog (get_tail prog)))
            (set tmp  (new-<pair> sym tmp))
            (set env2 (new-<pair> tmp env2))))
        (set bindings (get_tail bindings)))
      (set tmp ())
      (while (is <pair> body)
        (set tmp (s/eval (get_head body) env2))
        (set body (get_tail body)))
     tmp)))

(define-subr (set 2)
  (let ((var (s/assq (s/car args) env)))
    (or (is <pair> var)
        (s/error "undefined variable: (set "args")"))
    (set_tail var (s/eval (s/cadr args) env))))

(define-subr while
  (let ((tst  (s/car args))
        (prog args))
    (while (s/eval tst env)
      (let ((body prog))
        (while (is <pair> (set body (s/cdr body)))
          (s/eval (get_head body) env))))))

(define-subr if
  (if (s/eval (s/car args) env)
      (s/eval (s/cadr args) env)
    (let ((ans ()))
      (set args (s/cdr args))
      (while (is <pair> (set args (s/cdr args)))
        (set ans (s/eval (get_head args) env)))
      ans)))

(define-subr or
  (let ((ans ()))
    (while (is <pair> args)
      (and (set ans (s/eval (get_head args) env))
           (return ans))
      (set args (get_tail args)))))

(define-subr and
  (let ((ans symbol/t))
    (while (is <pair> args)
      (or (set ans (s/eval (get_head args) env))
          (return ()))
      (set args (get_tail args)))
    ans))

(define-subr (quote 1)
  (s/car args))

(define-subr (not 1)
  (if (s/car args) () symbol/t))

(define-subr long/substract
  (safety 1 (or (and (s/car args) (not (s/cddr args))) (s/error "operator '-' expected 1 or 2 arguments, got: " args)))
  (let ((lhs (get_head args))
        (rhs (get_tail args)))
    (if (is <pair> rhs)
        (let ()
          (set rhs (get_head rhs))
          (safety 1 (or (and (is <long> lhs) (is <long> rhs)) (s/error "non-numeric argument: (- "lhs" "rhs")")))
          (new-<long> (- (get_long lhs) (get_long rhs))))
      (safety 1 (or (is <long> lhs) (s/error "non-numeric argument: (- "lhs")")))
      (new-<long> (- (get_long lhs))))))

(define-form define-binary (op name)
  `(define-subr (,name 2)
     (let ((lhs (get_head args))
           (rhs (get_head (get_tail args))))
       (safety 1 (or (and (is <long> lhs) (is <long> rhs)) (s/error "non-numeric argument: (",(symbol->string name)" "lhs" "rhs")")))
       (new-<long> (,op (get_long lhs) (get_long rhs))))))

(define-binary &  bitand)
(define-binary |  bitor)
(define-binary ^  bitxor)
(define-binary +  long/add)
(define-binary *  long/multiply)
(define-binary /  long/divide)
(define-binary << long/shift-left)
(define-binary >> long/shift-right)

(define-form define-relation (op name)
  `(define-subr (,name 2)
     (let ((lhs (get_head args))
           (rhs (get_head (get_tail args))))
       (safety 1 (or (and (is <long> lhs) (is <long> rhs)) (s/error "non-numeric argument: (",(symbol->string name)" "lhs" "rhs")")))
       (and (,op (get_long lhs) (get_long rhs))
            symbol/t))))

(define-relation <  relation/less)
(define-relation <= relation/less-or-equal)
(define-relation >  relation/greater)

(define-subr (relation/equal 2)
  (let* ((lhs  (get_head args))
         (rhs  (get_head (get_tail args)))
         (type (s/type-of lhs)))
    (cond
      ((= type <long>)          (and (is <long> rhs) (= (get_long lhs) (get_long rhs)) symbol/t))
      ((= type <string>)        (and (is <string> rhs) (not (libc/strcmp (get <string> _bits lhs) (get <string> _bits rhs))) symbol/t))
      (else                     (and (= lhs rhs) symbol/t)))))

(define-subr (relation/not-equal 2)
  (let* ((lhs  (get_head args))
         (rhs  (get_head (get_tail args)))
         (type (s/type-of lhs)))
    (cond
      ((= type <long>)          (and (is <long> rhs) (!= (get_long lhs) (get_long rhs)) symbol/t))
      ((= type <string>)        (and (is <string> rhs) (libc/strcmp (get <string> _bits lhs) (get <string> _bits rhs))) symbol/t)
      (else                     (and (!= lhs rhs) symbol/t)))))

(define-subr (abort 0)
  (libc/flush-streams)
  (libc/abort))

(define-subr (exit 1)
  (let ((arg (s/car args)))
    (or (is <long> arg)
        (s/error "argument to subr_exit is not a <long>: " arg))
    (libc/flush-streams)
    (libc/exit (get_long arg))))

(define-subr dump
  (while (is <pair> args)
    (s/dump (get_head args))
    (set args (get_tail args))))

(define-subr print
  (while (is <pair> args)
    (s/print (get_head args))
    (set args (get_tail args))))

(define-subr warn
  (while (is <pair> args)
    (let* ((arg  (get_head args))
           (type (s/type-of arg)))
      (cond
        ((= type <string>) (libc/fprintf libc/stderr "%s" (get <string> _bits arg)))
        ((= type <symbol>) (libc/fprintf libc/stderr "%s" (get <symbol> _bits arg)))))
    (set args (get_tail args))))

(define-subr apply-<expr>
  (let ((fun (s/car args)))
    ;; TODO signal an explicit error otherwise?
    (and (is <expr> fun)
         (let ()
           (let* ((arguments (s/cdr args))
                  (argl      arguments)
                  (defn      (get <expr> defn fun))
                  (formals   (s/car defn))
                  (tmp       ()))
             (set env (get <expr> env fun))
             (gc/protect (defn env tmp)
               (while (is <pair> formals)
                 (unless (is <pair> argl)
                   (s/error "too few arguments: ("fun" "arguments")"))
                 (set tmp     (new-<pair> (get_head formals) (get_head argl)))
                 (set env     (new-<pair> tmp env))
                 (set formals (get_tail formals))
                 (set argl    (get_tail argl)))
               (and (is <symbol> formals)
                    (let ()
                      (set tmp (new-<pair> formals argl))
                      (set env (new-<pair> tmp env))
                      (set argl ())))
               (when argl
                 (s/error "too many arguments: ("fun" "arguments")"))
               (set defn (get_tail defn))
               (while (is <pair> defn)
                 (set argl (s/eval (get_head defn) env))
                 (set defn (get_tail defn)))
               argl))))))

(define-subr (apply-<fixed> 2)
  (let ((fun  (s/car args))
        (argl (s/cdr args)))
    (and (is <fixed> fun)
         (s/apply (get <fixed> function fun) argl env))))

(define-subr apply
  (s/apply (s/car args) (s/cadr args) (or (s/caddr args) env)))

(define-subr (eval-<symbol> 1)
  (let ((exp (s/car args))
        (val (s/assq exp env)))
    (or (is <pair> val)
        (s/error "eval-<symbol>: undefined variable: " exp))
    (get_tail val)))

(define-function evlist (obj env)
  (if (is <pair> obj)
      (let ((head (s/eval (get_head obj) env)))
        (gc/protect (head)
          (let ((tail (evlist (get_tail obj) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    obj))

(define-subr (eval-<pair> 1)
  (let ((exp  (s/car args))
        (head (s/eval (s/car exp) env)))
    (gc/protect (head)
      (s/set-array-at trace_stack trace_depth exp)
      (set trace_depth (+ trace_depth 1))
      (set head (if (is <fixed> head)
                    (s/apply (get <fixed> function head) (get_tail exp) env)
                  (let ((args (evlist (get_tail exp) env)))
                    (gc/protect (args)
                      (s/apply head args env)))))
      (set trace_depth (- trace_depth 1))
      head)))

(define-subr eval
  (let ((x (s/car args))
        (e (or (s/cadr args) env)))
    (gc/protect (x)
      (set x (s/expand x e))
      (set x (s/encode x e))
      (s/eval x e))))

(define-subr (cons 2)   (new-<pair> (s/car args) (s/cadr args)))
(define-subr (string 1) (new-<string>-of-length (and (is <long> (s/car args)) (get_long (get_head args)))))
(define-subr array      (new-<array> (and (is <long> (s/car args)) (get_long (get_head args)))))
(define-subr (form 1)   (new-<form> (s/car args)))

(define-subr (allocate 2)
  (let ((type (get_head args))
        (size (get_head (get_tail args))))
    (safety 1 (s/assert (and (is <long> type) (is <long> size))))
    (new-object (get_long type) (get_long size))))

(define-subr (type-of 1) (and args (new-<long> (s/type-of (s/car args)))))
(define-subr (string? 1) (and (is <string> (s/car args)) symbol/t))
(define-subr (symbol? 1) (and (is <symbol> (s/car args)) symbol/t))
(define-subr (pair? 1)   (and (is <pair>   (s/car args)) symbol/t))
(define-subr (array? 1)  (and (is <array>  (s/car args)) symbol/t))
(define-subr (car 1)     (s/car (s/car args)))
(define-subr (cdr 1)     (s/cdr (s/car args)))

(define-subr (oop-at 2)
  (let ((obj (get_head args))
        (idx (get_head (get_tail args))))
    (safety 1 (s/assert (and obj (is <long> idx))))
    (oop-at obj (get_long idx))))

(define-subr (set-oop-at 3)
  (let ((obj (get_head args))
        (idx (get_head (get_tail args)))
        (val (get_head (get_tail (get_tail args)))))
    (safety 1 (s/assert (and obj (is <long> idx))))
    (set-oop-at obj (get_long idx) val)))

(define-subr (array-length 1)
  (new-<long> (s/array-length (s/car args))))

(define-subr (array-at 2)
  (let ((arr (get_head args))
        (idx (get_head (get_tail args))))
    (safety 1 (s/assert (and (is <array> arr) (is <long> idx))))
    (s/array-at arr (get_long idx))))

(define-subr (set-array-at 3)
  (let ((arr (get_head args))
        (idx (get_head (get_tail args)))
        (val (get_head (get_tail (get_tail args)))))
    (safety 1 (s/assert (and (is <array> arr) (is <long> idx))))
    (s/set-array-at arr (get_long idx) val)))

(define-subr (string-length 1)
  (let ((arg (s/car args)))
    (safety 1 (s/assert (is <string> arg)))
    (get <string> size arg)))

(define-subr (string-at 2)
  (let ((arr (get_head args))
        (arg (get_head (get_tail args))))
    (safety 1 (s/assert (and (is <string> arr) (is <long> arg))))
    (let ((idx (get_long arg)))
      (and (<= 0 idx)
           (< idx (s/string-length arr))
           (new-<long> (string-at (get <string> _bits arr) idx))))))

(define-subr (set-string-at 3)
  (let ((arr (get_head args))
        (arg (get_head (get_tail args)))
        (val (get_head (get_tail (get_tail args)))))
    (safety 1 (s/assert (and (is <string> arr) (is <long> val))))
    (let ((idx (get_long arg)))
      (and (<= 0 idx)
           (< idx (s/string-length arr))
           ;; TODO don't just silently ignore wrong indexes?
           (let ()
             (set-string-at (get <string> _bits arr) idx (get_long val))
             val)))))

(define-subr (string->symbol 1)
  (let ((arg (s/car args)))
    (if (is <symbol> arg)
        arg
      (and (is <string> arg)
           (intern (get <string> _bits arg))))))

(define-subr (symbol->string 1)
  (let ((arg (s/car args)))
    (if (is <string> arg)
        arg
      (and (is <symbol> arg)
           (new-<string>-from-cstring (get <symbol> _bits arg))))))

(define-subr (long->string 1)
  (let ((arg (s/car args)))
    (if (is <string> arg)
        arg
      (and (is <long> arg)
           (let ((buf (libc/malloc 32)))
             (libc/sprintf buf "%ld" (get_long arg))
             (let ((result (new-<string>-from-cstring buf)))
               (libc/free buf)
               result))))))

(define-subr current-environment
  env)

;;; ----------------------------------------------------------------

(define-function repl_stream (stream)
  (let ((value 0))
    (libc/fscanf stream "#!%*[^\012\015]")
    (while (!= EOF (set value (s/read stream)))
      (gc/protect (value)
        (and (> opt_verbose 0) (libc/printf ";;; ") (s/dumpln value))
        (set value (s/expand value (get_tail globals)))    (and (> opt_verbose 2) (libc/printf "expd--> ") (s/dumpln value))
        (set value (s/encode value (get_tail globals)))    (and (> opt_verbose 2) (libc/printf "encd--> ") (s/dumpln value))
        (set value (s/eval   value (get_tail globals)))    (and (> opt_verbose 1) (libc/printf "eval--> ") (s/dumpln value))
        ))))

(define-function instantiate-subr (name imp)
  (let ((tmp (new-<subr> imp name)))
    (gc/protect (tmp)
      (s/define (intern name) tmp (get_tail globals)))))

(define-function instantiate-fixed-subr (name imp)
  (let ((tmp (new-<subr> imp name)))
    (gc/protect (tmp)
      (set tmp (new-<fixed> tmp))
      (s/define (intern name) tmp (get_tail globals)))))

(define-function libc/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

(define-function main (argc argv)
  ;; we need to dereference them once
  (set libc/stdout (oop-at libc/stdout 0))
  (set libc/stderr (oop-at libc/stderr 0))

  (gc/initialise)

  (safety 4 (set gc/frequency 1))

  (gc/push-root (address-of symbols))
  (gc/push-root (address-of globals))

  (set symbol/t                      (intern "t"))
  (set symbol/dot                    (intern "."))
  (set symbol/set                    (intern "set"))
  (set symbol/lambda                 (intern "lambda"))
  (set symbol/let                    (intern "let"))
  (set symbol/quote                  (intern "quote"))
  (set symbol/quasiquote             (intern "quasiquote"))
  (set symbol/unquote                (intern "unquote"))
  (set symbol/unquote_splicing       (intern "unquote-splicing"))

  (set globals (new-<pair> (intern "*globals*") 0))
  (set_tail globals (new-<pair> globals 0))
  (let ((tmp))
    (gc/protect (tmp)
      (set tmp (new-<array> 0))  (set expanders   (s/define (intern "*expanders*"  ) tmp (get_tail globals)))
      (set tmp (new-<array> 0))  (set encoders    (s/define (intern "*encoders*"   ) tmp (get_tail globals)))
      (set tmp (new-<array> 0))  (set evaluators  (s/define (intern "*evaluators*" ) tmp (get_tail globals)))
      (set tmp (new-<array> 0))  (set applicators (s/define (intern "*applicators*") tmp (get_tail globals)))

      (set tmp (new-<subr> subr/eval-<symbol> "eval-<symbol>")) (s/set-array-at (get_tail evaluators)  <symbol> tmp)
      (set tmp (new-<subr> subr/eval-<pair>   "eval-<pair>"  )) (s/set-array-at (get_tail evaluators)  <pair>   tmp)
      (set tmp (new-<subr> subr/apply-<fixed> "apply-<fixed>")) (s/set-array-at (get_tail applicators) <fixed>  tmp)
      (set tmp (new-<subr> subr/apply-<expr>  "apply-<expr>" )) (s/set-array-at (get_tail applicators) <expr>   tmp)))

  (instantiate-fixed-subr "define"           subr/define)
  (instantiate-fixed-subr "lambda"           subr/lambda)
  (instantiate-fixed-subr "let"              subr/let)
  (instantiate-fixed-subr "set"              subr/set)
  (instantiate-fixed-subr "while"            subr/while)
  (instantiate-fixed-subr "if"               subr/if)
  (instantiate-fixed-subr "or"               subr/or)
  (instantiate-fixed-subr "and"              subr/and)
  (instantiate-fixed-subr "quote"            subr/quote)

  (instantiate-subr  "not"                   subr/not)
  (instantiate-subr  "&"                     subr/bitand)
  (instantiate-subr  "|"                     subr/bitor)
  (instantiate-subr  "^"                     subr/bitxor)
  (instantiate-subr  "+"                     subr/long/add)
  (instantiate-subr  "-"                     subr/long/substract)
  (instantiate-subr  "*"                     subr/long/multiply)
  (instantiate-subr  "/"                     subr/long/divide)
  (instantiate-subr  "<<"                    subr/long/shift-left)
  (instantiate-subr  ">>"                    subr/long/shift-right)
  (instantiate-subr  "<"                     subr/relation/less)
  (instantiate-subr  "<="                    subr/relation/less-or-equal)
  (instantiate-subr  "!="                    subr/relation/not-equal)
  (instantiate-subr  "="                     subr/relation/equal)
  (instantiate-subr  ">"                     subr/relation/greater)
  (instantiate-subr  "abort"                 subr/abort)
  (instantiate-subr  "exit"                  subr/exit)
  (instantiate-subr  "dump"                  subr/dump)
  (instantiate-subr  "print"                 subr/print)
  (instantiate-subr  "warn"                  subr/warn)
  (instantiate-subr  "apply"                 subr/apply)
  (instantiate-subr  "eval"                  subr/eval)
  (instantiate-subr  "cons"                  subr/cons)
  (instantiate-subr  "string"                subr/string)
  (instantiate-subr  "array"                 subr/array)
  (instantiate-subr  "form"                  subr/form)
  (instantiate-subr  "allocate"              subr/allocate)
  (instantiate-subr  "type-of"               subr/type-of)
  (instantiate-subr  "string?"               subr/string?)
  (instantiate-subr  "symbol?"               subr/symbol?)
  (instantiate-subr  "pair?"                 subr/pair?)
  (instantiate-subr  "array?"                subr/array?)
  (instantiate-subr  "car"                   subr/car)
  (instantiate-subr  "cdr"                   subr/cdr)
  (instantiate-subr  "oop-at"                subr/oop-at)
  (instantiate-subr  "set-oop-at"            subr/set-oop-at)
  (instantiate-subr  "array-length"          subr/array-length)
  (instantiate-subr  "array-at"              subr/array-at)
  (instantiate-subr  "set-array-at"          subr/set-array-at)
  (instantiate-subr  "string-length"         subr/string-length)
  (instantiate-subr  "string-at"             subr/string-at)
  (instantiate-subr  "set-string-at"         subr/set-string-at)
  (instantiate-subr  "string->symbol"        subr/string->symbol)
  (instantiate-subr  "symbol->string"        subr/symbol->string)
  (instantiate-subr  "long->string"          subr/long->string)
  (instantiate-subr  "current-environment"   subr/current-environment)

  (set fixed-subr/quote  (s/cdr (s/assq symbol/quote  (get_tail globals))))
  (set fixed-subr/lambda (s/cdr (s/assq symbol/lambda (get_tail globals))))
  (set fixed-subr/let    (s/cdr (s/assq symbol/let    (get_tail globals))))

  (set trace_stack (new-<array> 32))                            (gc/push-root (address-of trace_stack))

  (while (set argc (- argc 1))
    (set argv (+ argv 4))
    (let ((arg (oop-at argv 0)))
      (cond
        ((not (libc/strcmp arg "-v"))   (set opt_verbose (+ 1 opt_verbose)))
        (else                           (let ((stream (libc/fopen (oop-at argv 0) "r")))
                                          (or stream (fatal1 "no such file: %s" (oop-at argv 0)))
                                          (repl_stream stream)
                                          (libc/fclose stream))))))
  (libc/flush-streams)
  (and (> opt_verbose 0)
       (let ()
         (gc/collect)
         (libc/printf "GC: %d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)))

  (libc/fprintf libc/stderr "%d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)
  (libc/flush-streams)
  0)

(compile-end)
