;;; The Maru VM, written in a subset of Maru.

(define-form k/assert prog ())
(define-form debug    prog ())
(define-form gc/debug prog ())

;;
;; you can enable safety and debugging features here
;;
(define-form k/assert (test . args) `(or ,test (k/error ,@(or args (list "assertion failed")))))
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
;;; vm     - Virtual Machine, i.e. a universe capable of executing code.
;;;          It has its own set of laws that are accepted as axioms.
;;;
;;; host   - The Maru vm running the compiler.
;;;
;;; target - The target vm of the "level-shift" operation (e.g. x86 asm).
;;;
;;; kernel - It's the part of the semantic space that runs on the target.
;;;          e.g. k/apply vs. subr/apply (which uses k/apply in its
;;;          implementation).
;;;
;;; k/ prefix means that it's the kernel version of something that
;;;    also exist in the Maru semantic space.
;;;
;;; slave  - The Maru vm that is being bootstrapped and will
;;;          spring to life when the result of the level-shift
;;;          (the compilation) gets executed on the target.
;;;          Its name comes from the idea that, having a dynamic compiler,
;;;          the host could start up the slave vm under its full
;;;          supervision.
;;;
;;; oop    - Ordinary Object Pointer
;;;
;;; get, put, is
;;;        - These are the kernel "accessors" for Maru values.
;;;          They are also used as a namespace, e.g. get/long.
;;;
;;; subr/ prefix denotes the subr's, the primitive functions that will
;;;       be made visible to user code in the bootstrapped Maru
;;;       semantic space as part of the laws of the slave vm.
;;;
;;; *foo* is global
;;; +foo+ is a constant
;;; -foo- comes from the implicit lexical scope
;;; <foo> is a type
;;;
;;; size means bytes; if not, then it should be indicated.

;;;
;;; Implementation details:
;;;
;;;  - () is the false value, and is mapped to 0 in the target. Its type is the <undefined> type.
;;;

(define-form bytes-to-words (value)
  (if (long? value)
      (>> value 2)
    `(>> ,value 2)))

(define-form words-to-bytes (value)
  (if (long? value)
      (<< value 2)
    `(<< ,value 2)))

(define-form align-to-words (value)
  `(& -4 (+ 3 ,value)))

(define-form malloc-oops (wordcount)
  `(libc/malloc (words-to-bytes ,wordcount)))

(define-form copy-oops (from to wordcount)
  `(libc/memcpy ,to ,from (words-to-bytes ,wordcount)))

(define-form move-oops (from to wordcount)
  `(libc/memmove ,to ,from (words-to-bytes ,wordcount)))

(define-form size-of-structure (type)
  (structure-field-count (eval type)))

;; the header of heap objects
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

(define-function max (a b)
  (if (> a b) a b))

(define-externs
  abort exit
  malloc free memset memcpy memmove
  stdin stdout stderr printf fprintf sprintf
  strlen strcmp strdup strtoul getc ungetc putc
  fopen fdopen fclose fflush fscanf)

(define-constant libc/EOF -1)
(define-constant +done+ -4) ; NOTE: careful when introducing tagged immediates

(define-function die ()
  (libc/fprintf libc/stderr "\nDIE called, printing a backtrace to stdout and exiting with exit code 1...\n")
  (libc/flush-streams)
  (let ((i *backtrace-index*))
    (while (<= 0 (set i (- i 1)))
      (libc/printf "%3d: " i)
      (k/dumpln (k/array-at *backtrace-stack* i))
      (libc/flush-streams)))
  (libc/exit 1))

;; FATAL directly uses the libc printf (i.e. it cannot print maru objects), while
;; K/ERROR goes through the maru printing facility (i.e. must not be called with an .asciz).
(define-function fatal  (fmt)           (libc/fprintf libc/stderr fmt)           (libc/fprintf libc/stderr "\n") (die))
(define-function fatal1 (fmt arg)       (libc/fprintf libc/stderr fmt arg)       (libc/fprintf libc/stderr "\n") (die))
(define-function fatal2 (fmt arg1 arg2) (libc/fprintf libc/stderr fmt arg1 arg2) (libc/fprintf libc/stderr "\n") (die))

;; FIXME it would be nice for K/ERROR to be a function (or at least expand to a breakpoint'able function call),
;; but that would need the compiler to support variable nr of args, or literal lists
(define-form k/error args
  `(let ()
     (libc/printf "\nerror: ")
     ,@(map (lambda (arg)
              ;; string literals are turned into pointers to .asciz, therefore
              ;; we need to print them using libc/printf (or instantiate
              ;; them into Maru objects using new-<string>-from-cstring).
              (if (string? arg)
                  `(libc/printf ,arg)
                  `(k/print ,arg)))
            args)
     (libc/printf "\n")
     (die)))

;;;
;;; GC
;;;
(define gc/quantum              (* 50 1024))
(define gc/frequency            32768)

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

;; opaque objects are black boxes for the gc.
(define-function gc/new-object/opaque (type bytesize)
  (safety 1 (k/assert (not (= 0 type)) "gc/new-object/opaque: called with zero type"))
  (let* ((obj (gc/allocate-opaque bytesize))
         (header (header-of obj)))
    (set (<header>-type header) type)
    obj))

;; from the gc's pov objects are oop vectors
(define-function gc/new-object (type wordsize)
  (safety 1 (k/assert (not (= 0 type)) "gc/new-object: called with zero type"))
  (let* ((obj (gc/allocate (words-to-bytes wordsize)))
         (header (header-of obj)))
    (set (<header>-type header) type)
    obj))

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
                  (safety 4 (k/assert (= (gc/object-size obj) requested-size) "gc/allocate: was about to return with an object whose size in the header is not equal to the requested size"))
                  (safety 4 (k/assert (& (<header>-flags-used) (<header>-flags (header-of obj))) "gc/allocate: was about to return with an object whose USED flag is unset"))
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
              (safety 3 (and (= 0 (<header>-type ptr)) (fatal1 "gc/sweep: encountered an object with zero type %p" ptr)))
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
    (debug (libc/printf "GC: %d used, %d free, %d allocations\n" nused nfree gc/alloc-count))))

(define-function gc/mark-and-trace (obj)
  (and obj
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

;; NOTE: types are represented at runtime as integers (starting with 0 as <undefined>).
;;       the subr's here in eval.l encode/implement the behavior of the primitive types.
;; TODO get rid of these by using something like a symbol-macro that turns the references into literal integers.
(define-form bootstrap-type (type-name)
  `(define-constant ,type-name ,(eval type-name)))

(bootstrap-type <undefined>)
(bootstrap-type <long>)
(bootstrap-type <string>)
(bootstrap-type <symbol>)
(bootstrap-type <pair>)
(bootstrap-type <_array>)
(bootstrap-type <array>)
(bootstrap-type <expr>)
(bootstrap-type <form>)
(bootstrap-type <fixed>)
(bootstrap-type <subr>)
(bootstrap-type <module>)

;;;
;;; Some of the state of the Maru VM needs to be captured/known by the target VM.
;;;
;;; Only one of these is essential: *module*. The rest is just optimization or debug helpers.
;;;
(define *module* 0)

;; the well-known symbols that we need to reference (they will be initialized at start)
(define symbol/t                     0)
(define symbol/dot                   0)
(define symbol/set                   0)
(define symbol/quote                 0)
(define symbol/quasiquote            0)
(define symbol/unquote               0)
(define symbol/unquote_splicing      0)
(define symbol/*module*              0)

;; for optimization: we cache these definitions from the env
(define expanders               0)
(define encoders                0)
(define evaluators              0)
(define applicators             0)

(define fixed-subr/quote        0)
(define fixed-subr/lambda       0)
(define fixed-subr/let          0)

(define *backtrace-stack*     0)
(define *backtrace-index*     0)

(define-function new-<long> (bits)
  (let ((obj (gc/new-object/opaque <long> (words-to-bytes (size-of-structure <long>)))))
    (set (<long>-_bits obj) bits)
    obj))

(define-function new-<string>-of-length (len)
  (let ((str (gc/new-object <string> (size-of-structure <string>))))
    (gc/protect (str)
      (set (<string>-size  str) (new-<long> len))
      (set (<string>-_bits str) (gc/allocate-opaque (+ len 1))) ; +1 is for the terminal zero
      (safety 3 (set (<header>-type (header-of (<string>-_bits str))) -43))
      str)))

(define-function new-<string>-from-cstring (cstr)
  (let ((len (libc/strlen cstr)))
    (let ((obj (new-<string>-of-length len))) ; also deals with the cstring terminal zero
      (libc/memcpy (<string>-_bits obj) cstr len)
      obj)))

(define-function new-<symbol> (cstr)
  (let ((obj (gc/new-object/opaque <symbol> (words-to-bytes (size-of-structure <symbol>)))))
    (set (<symbol>-_bits obj) (libc/strdup cstr))
    obj))

(define-function new-<pair> (head tail)
  (let ((obj (gc/new-object <pair> (size-of-structure <pair>))))
    (set (<pair>-head obj) head)
    (set (<pair>-tail obj) tail)
    obj))

(define-function new-<array> (size)
  (let ((cap (or size 1))
        (arr (gc/new-object <array> (size-of-structure <array>))))
    (gc/protect (arr)
      (set (<array>-size arr)   (new-<long> size))
      (set (<array>-_array arr) (gc/new-object <_array> cap))
      arr)))

(define-function new-<expr> (defn env)
  (let ((obj (gc/new-object <expr> (size-of-structure <expr>))))
    (set (<expr>-defn obj) defn)
    (set (<expr>-env  obj) env )
    obj))

(define-function new-<form> (fn sym)
  (let ((obj (gc/new-object <form> (size-of-structure <form>))))
    (gc/protect (obj)
      (set (<form>-function obj) fn)
      (set (<form>-symbol   obj) fn)
      obj)))

(define-function new-<fixed> (fn)
  (let ((obj (gc/new-object <fixed> (size-of-structure <fixed>))))
    (gc/protect (obj)
      (set (<fixed>-function obj) fn)
      obj)))

(define-function new-<subr> (_imp _name)
  (let ((obj (gc/new-object/opaque <subr> (words-to-bytes (size-of-structure <subr>)))))
    (gc/protect (obj)
      (set (<subr>-_imp  obj) _imp )
      (set (<subr>-_name obj) _name)
      obj)))

(define-function new-<module> ()
  (let ((obj (gc/new-object <module> (words-to-bytes (size-of-structure <module>)))))
    (gc/protect (obj)
      ;; env is chained into the cdr of this cons. let's set up a dummy as the first assoc entry.
      ;; FIXME this is ugly, but for now it's compatible with the rest of the code.
      (let ((dummy (new-<pair> 0 0)))
        (gc/protect (dummy)
          (set (<module>-env obj) (new-<pair> dummy ()))))
      (set (<module>-symbols obj) ())
      obj)))

(define-form is (type arg)
  `(let ((__arg__ ,arg))
     (and __arg__
          (let ((header (header-of __arg__)))
            (safety 3 (or (valid-header-magic-marker? header) (fatal1 "is: encountered an untagged pointer: %p" __arg__)))
            (= ,type (<header>-type header))))))

(define-form get/type (arg)
  `(let ((__arg__ ,arg))
     (if __arg__
         (let ((header (header-of __arg__)))
           (safety 3 (or (valid-header-magic-marker? header) (fatal1 "get/type: encountered an untagged pointer: %p" __arg__)))
           (safety 1 (or (& (<header>-flags-used) (<header>-flags header)) (fatal1 "get/type: attempt to access dead object: %p" __arg__)))
           (<header>-type (header-of __arg__)))
       <undefined>)))

(define-function %type-check-failed (exp act)
  (fatal2 "type error: expected %d, got %d" exp act))

;; "one of the reasons for having all accesses to object fields go through get() and set() was to make it ridiculously easy to add read and write barriers"
(define-form get (type field object)
  `(let ((__obj__ ,object))
     (safety 2 (let ((t (get/type __obj__))) (or (= ,type t) (%type-check-failed ,type t))))
     (,(concat-symbol (concat-symbol type '-) field) __obj__)))

(define-form put (type field object value)
  `(let ((__obj__ ,object))
     (safety 2 (let ((t (get/type __obj__))) (or (= ,type t) (%type-check-failed ,type t))))
     (set (,(concat-symbol (concat-symbol type '-) field) __obj__) ,value)))

;; shorthands (and optimizations)
(define-form is/long  (obj)     `(is <long> ,obj))
(define-form get/long (obj)     (if (< safety-level 4)     `(oop-at ,obj ,(structure-field-index <long> '_bits))     `(get <long> _bits ,obj)))
(define-form get/head (obj)     (if (< safety-level 4)     `(oop-at ,obj ,(structure-field-index <pair> 'head))      `(get <pair> head ,obj)))
(define-form get/tail (obj)     (if (< safety-level 4)     `(oop-at ,obj ,(structure-field-index <pair> 'tail))      `(get <pair> tail ,obj)))
(define-form put/tail (obj val) (if (< safety-level 4) `(set-oop-at ,obj ,(structure-field-index <pair> 'tail) ,val) `(put <pair> tail ,obj ,val)))

(define-form get/string		(obj)		`(get <string> _bits ,obj))
(define-form get/symbol		(obj)		`(get <symbol> _bits ,obj))

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

(define-function intern* (cstr module)
  (safety 1 (k/assert (is <module> module) "intern called with not a module " module))
  (let ((len (libc/strlen cstr))
        (idx 0))
    (while (< idx len)
      (when (= ?: (string-at cstr idx))
        (let ((module-name (libc/malloc (+ 1 idx))))
          (libc/memcpy module-name cstr idx)
          (set (string-at module-name idx) 0)
          (let ((submod (k/assq (intern* module-name module) (<module>-env module))))
            (unless (and (is <pair> submod)
                         (is <module> (get/tail submod)))
              (fatal2 "intern: module '%s' not found while interning %s" module-name cstr))
            (libc/free module-name)
            (return (intern* (+ 1 (+ cstr idx)) (get/tail submod))))))
      (set idx (+ 1 idx))))
  (let ((syms (<module>-symbols module)))
    (while (is <pair> syms)
      (let ((sym (get/head syms)))
        (when (= 0 (libc/strcmp cstr (get <symbol> _bits sym)))
          (return sym)))
      (set syms (get/tail syms))))
  (let ((sym (new-<symbol> cstr)))
    (gc/protect (sym)
      (debug (libc/printf "interning %s into module {%p}\n" cstr module))
      (set (<module>-symbols module) (new-<pair> sym (<module>-symbols module)))
      sym)))

(define-function intern (cstr)
  (intern* cstr *module*))

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
                                              (k/error "illegal character escape"))
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
                                                  (k/error "illegal character escape"))))
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
                                                  (k/error "illegal character escape"))))
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
      (when (= libc/EOF c)
        (k/error "unterminated string literal"))
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
      (while (and (!= +done+ (set elt (k/read stream)))
                  (!= symbol/dot elt))
        (set elt (new-<pair> elt ()))
        (set tail (put/tail tail elt)))
      (and (= symbol/dot elt) (put/tail tail (k/read stream))))
    (let ((c (libc/getc stream)))
      (if (= delim c)
          (get/tail head)
        (fatal1 "missing closing '%c' delimiter while reading list" delim)))))

(define-function read_quote (prefix stream)
  (let ((qobj (k/read stream)))
    (when (= +done+ qobj)
      (k/error "EOF while reading quoted literal"))
    (gc/protect (qobj)
      (set qobj (new-<pair> qobj ()))
      (set qobj (new-<pair> prefix qobj))
      qobj)))

(define-function k/read (stream)
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
        ((= ?\( c)      (return (read_list ?\) stream)))        ((= ?\) c)      (return (let () (libc/ungetc c stream) +done+)))
        ((= ?\[ c)      (return (read_list ?\] stream)))        ((= ?\] c)      (return (let () (libc/ungetc c stream) +done+)))
        ((= ?\{ c)      (return (read_list ?\} stream)))        ((= ?\} c)      (return (let () (libc/ungetc c stream) +done+)))
        ((is_digit10 c) (return (read_number c stream)))
        ((= ?\; c)      (while (and (!= ?\n (set c (libc/getc stream)))
                                    (!= ?\r c)
                                    (!= libc/EOF c))))
        ((= ?\" c)      (return (read_string c stream)))
        ((= c libc/EOF) (return +done+)) ; TODO use feof and ferror to check whether it's an error, or a true libc/EOF
        (else           (fatal1 "illegal character: %c" c))))))

(define-function do_print (obj storing)
  (debug (libc/printf "{%p}" obj))
  (let ((type (get/type obj)))
    (cond
      ((= type <undefined>)     (libc/printf "nil"))
      ((= type <long>)          (libc/printf "%d" (get/long obj)))
      ((= type <string>)        (let ((bits (get/string obj)))
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
                                  (while (is <pair> obj)
                                    (do_print (get/head obj) storing)
                                    (and (is <pair> (set obj (get/tail obj)))
                                         (libc/printf " ")))
                                  (and obj
                                       (let ()
                                         (libc/printf " . ")
                                         (do_print obj storing)))
                                  (libc/printf ")")))
      ((= type <array>)         (let ((len (k/array-length obj)))
                                  (libc/printf "Array(")
                                  (for (i 0 len)
                                    (and i (libc/printf " "))
                                    (do_print (k/array-at obj i) storing))
                                  (libc/printf ")")))
      ((= type <expr>)          (let ()
                                  (libc/printf "Expr(")
                                  (do_print (k/car (get <expr> defn obj)) storing)
                                  (libc/printf ")")))
      ((= type <form>)          (let ()
                                  (libc/printf "Form(")
                                  (do_print (get <form> function obj) storing)
                                  (libc/printf ",")
                                  (do_print (get <form> symbol   obj) storing)
                                  (libc/printf ")")))
      ((= type <fixed>)         (let ()
                                  (libc/printf "Fixed(")
                                  (do_print (get <fixed> function obj) storing)
                                  (libc/printf ")")))
      ((= type <subr>)          (libc/printf "Subr(%s)" (get <subr> _name obj)))
      (else                     (libc/printf "<type:%d>" type)))))

(define-function k/print (obj) (do_print obj 0))        (define-function k/println (obj) (do_print obj 0) (libc/printf "\n"))
(define-function k/dump  (obj) (do_print obj 1))        (define-function k/dumpln  (obj) (do_print obj 1) (libc/printf "\n"))

;;; ----------------------------------------------------------------

(define-function k/define* (name value module)
  (safety 1 (k/assert (is <symbol> name)))
  (safety 1 (k/assert (is <module> module)))
  (let ((env (<module>-env module))
        (ass (new-<pair> name value)))
    (gc/protect (ass)
      (let ((ent (new-<pair> ass (get/tail env))))
        (put/tail env ent)
        ass))))

(define-function k/define (name value)
  (k/define* name value *module*))

(define-function k/assq (key list)
  (while (is <pair> list)
    (let ((head (get/head list)))
      (and (is <pair> head)
           (= key (get/head head))
           (return head)))
    (set list (get/tail list))))

(define-function k/car (list)   (and (is <pair> list) (get/head list)))
(define-function k/cdr (list)   (and (is <pair> list) (get/tail list)))

(define-function k/caar (list)  (k/car (k/car list)))
(define-function k/cadr (list)  (k/car (k/cdr list)))
(define-function k/cddr (list)  (k/cdr (k/cdr list)))

(define-function k/caddr (list) (k/car (k/cdr (k/cdr list))))

(define-function k/string-length (obj)  (get/long (get <string> size obj)))

(define-function k/array-length (obj)
  (safety 1 (or (is <array> obj) (fatal1 "k/array-length: called with object of type %d" (get/type obj))))
  (get/long (get <array> size obj)))

(define-function k/array-at (obj idx)
  (safety 1 (or (and (is <array> obj) (<= 0 idx)) (fatal2 "k/array-at: called with object of type %d, and index %d" (get/type obj) idx)))
  (and (is <array> obj)
       (let ((elements (get <array> _array obj))
             (size     (get/long (get <array> size obj))))
         (and (<= 0 idx)
              (< idx size)
              (oop-at elements idx)))))

(define-function k/set-array-at (obj idx val)
  (safety 1 (or (and (is <array> obj) (<= 0 idx)) (fatal2 "k/set-array-at: called with object of type %d, and index %d" (get/type obj) idx)))
  (and (is <array> obj)
       (let* ((elts (get <array> _array obj))
              (size (get/long (get <array> size obj)))
              (cap  (bytes-to-words (gc/object-size elts))))
         (and (<= 0 idx)
              (let ()
                (or (< idx cap)
                    (let ()
                      (while (not (< idx cap))
                        (set cap (* cap 2)))
                      (let ((new-elts (gc/new-object <_array> cap)))
                        (gc/protect (new-elts) ; note: it's not really necessary here, because we store it before any new allocation
                          (copy-oops elts new-elts size)
                          (set elts (put <array> _array obj new-elts))))))
                (unless (< idx size)
                  ;; record the largest ever written index + 1 (aka size) in the size slot
                  (put <array> size obj (new-<long> (+ 1 idx))))
                (set-oop-at elts idx val))))))

(define-function k/array-append (array val)
  (k/set-array-at array (k/array-length array) val))

(define-function k/array-insert (obj index value)
  (let ((len (k/array-length obj)))
    (k/array-append obj value)         ; ensure we have enough room
    (and (< index len)
         (let* ((elts (get <array> _array obj))
                (src (+ elts (words-to-bytes index))))
           (move-oops src
                      (+ src (words-to-bytes 1))
                      (- len index)))))
  (k/set-array-at obj index value))

(define-function k/concat-list (head tail)
  (if (is <pair> head)
      (let ()
        (set tail (k/concat-list (get/tail head) tail))
        (gc/protect (tail)
          (new-<pair> (get/head head) tail)))
    tail))

;;; ----------------------------------------------------------------

(define-function exlist (list env)
  (if (is <pair> list)
      (let ((head (k/expand (get/head list) env)))
        (gc/protect (head)
          (let ((tail (exlist (get/tail list) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    list))

(define-function k/expand (exp env)
  (if (is <pair> exp)
      (let ((head (k/expand (get/head exp) env)))
        (gc/push-root (address-of head))
        (when (is <symbol> head)
          (let ((val (k/cdr (k/assq head env))))
            (when (is <form> val)
              (set head (k/apply (get <form> function val) (get/tail exp) env))
              (set head (k/expand head env))
              (gc/pop-root (address-of head))
              (return head))))
        (let ((tail (get/tail exp)))
          (gc/push-root (address-of tail))
          (or (= head symbol/quote) (set tail (exlist tail env)))
          ;; convert set forms: (set (foo a b c) new-value) -> (set-foo a b c new-value)
          (and (= symbol/set head)
               (is <pair>   (k/car  tail))
               (is <symbol> (k/caar tail))
               (let ((buf (new_buffer)))
                 (buffer_append_all buf "set-")
                 (buffer_append_all buf (get <symbol> _bits (get/head (get/head tail))))
                 (set head (intern (buffer_contents buf)))
                 (set tail (k/concat-list (get/tail (get/head tail)) (get/tail tail)))))
          (set exp (new-<pair> head tail))
          (gc/pop-root (address-of tail))
          (gc/pop-root (address-of head))))
    (let ((fn (k/array-at (get/tail expanders) (get/type exp))))
      (and fn
           (let ((args (new-<pair> exp ())))
             (gc/protect (args)
               (set exp (k/apply fn args env)))))))
  exp)

(define-function enlist (list env)
  (if (is <pair> list)
      (let ((head (k/encode (get/head list) env)))
        (gc/protect (head)
          (let ((tail (enlist (get/tail list) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    list))

(define-function k/encode (exp env)
  (if (is <pair> exp)
      (let ((head (k/encode (get/head exp) env))
            (tail (get/tail exp)))
        (gc/protect (head tail)
          (when (is <symbol> head)
            (let ((val (k/cdr (k/assq head env))))
              (when (or (is <fixed> val)
                        (is <subr> val))
                (set head val))))
          (cond
            ((= head fixed-subr/let)    (let ((args (k/cadr exp))
                                              (tmp  ()))
                                          (gc/protect (env tmp)
                                            (while (is <pair> args)
                                              (let ((var (get/head args)))
                                                (and (is <pair> var) (set var (get/head var)))
                                                (set tmp (new-<pair> var ()))
                                                (set env (new-<pair> tmp env))
                                                (set args (get/tail args))))
                                            (set tail (enlist tail env)))))
            ((= head fixed-subr/lambda) (let ((args (k/cadr exp))
                                              (tmp  ()))
                                          (gc/protect (env tmp)
                                            (while (is <pair> args)
                                              (set tmp (new-<pair> (get/head args) ()))
                                              (set env (new-<pair> tmp env))
                                              (set args (get/tail args)))
                                            (and args
                                                 (let ()
                                                   (set tmp (new-<pair> args ()))
                                                   (set env (new-<pair> tmp env))))
                                            (set tail (enlist tail env)))))
            ((!= head fixed-subr/quote)     (set tail (enlist tail env))))
          (set exp (new-<pair> head tail))))
    (let ((fn (k/array-at (get/tail encoders) (get/type exp))))
      (debug (when fn
               (libc/printf "APPLY GOT ENCODER\n... ")
               (k/println fn)))
      (and fn
           (let ((args (new-<pair> env ())))
             (gc/protect (args)
               (set args (new-<pair> exp args))
               (debug (libc/printf "APPLY ENCODER\n... ")) (k/print fn) (libc/printf " ") (k/print args) (libc/printf " ") (k/println env)
               (set exp (k/apply fn args env)))))))
  exp)

(define-function k/eval (exp env)
  (let ((ev (k/array-at (get/tail evaluators) (get/type exp))))
    (and ev
         (let ((args (new-<pair> exp ())))
           (gc/protect (args)
             (k/set-array-at *backtrace-stack* *backtrace-index* exp)
             (set *backtrace-index* (+ *backtrace-index* 1))
             (set exp (k/apply ev args env))
             (set *backtrace-index* (- *backtrace-index* 1)))))
    exp))

(define-function k/apply (fun arguments env)
  (if (is <subr> fun)
      ((get <subr> _imp fun) arguments env)
    (let ((ap (k/array-at (get/tail applicators) (get/type fun))))
      (or ap (k/error "cannot apply: " fun))
      (let ((args arguments))
        (gc/protect (args)
          (set args (new-<pair> fun args))
          (k/apply ap args env))))))

;;;
;;; the subr's
;;;
(define-form define-subr (name-and-props . body)
  (unless (pair? name-and-props)
    (set name-and-props (list name-and-props)))
  (let ((name (car name-and-props))
        (arity (car (cdr name-and-props))))
    (assert (symbol? name))
    `(define-function ,name (-args- -env-)
       ,@(when arity
           `((safety 1 (,(concat-symbol 'arity (string->symbol (long->string arity)))
                         (new-<string>-from-cstring ,(symbol->string name))
                         -args-))))
       ,@body)))

(define-function arity0 (op args)
  (or (not args)
      (k/error "Operator '" op "' expected no arguments, got: " args)))

(define-function arity1 (op args)
  (or (and (is <pair> args)
           (= () (get/tail args)))
      (k/error "Operator '" op "' expected 1 argument, got: " args)))

(define-function arity2 (op args)
  (or (and (is <pair> args)
           (is <pair> (get/tail args))
           (= () (get/tail (get/tail args))))
      (k/error "Operator '" op "' expected 2 arguments, got: " args)))

(define-function arity3 (op args)
  (or (and (is <pair> args)
           (is <pair> (get/tail args))
           (is <pair> (get/tail (get/tail args)))
           (= () (get/tail (get/tail (get/tail args)))))
      (k/error "Operator '" op "' expected 3 arguments, got: " args)))

(define-subr (subr/define 2)
  (let ((sym (k/car -args-)))
    (or (is <symbol> sym)
        (k/error "non-symbol identifier in define: " sym))
    (let ((val (k/eval (k/cadr -args-) -env-)))
      (gc/protect (val)
        (k/define sym val)
        val))))

(define-subr subr/lambda
  (new-<expr> -args- -env-))

(define-subr subr/let
  (let ((env2     -env-)
        (tmp      ())
        (bindings (k/car -args-))
        (body     (k/cdr -args-)))
    (gc/protect (env2 tmp)
      (while (is <pair> bindings)
        (let ((binding (get/head bindings)))
          (or (is <pair> binding)
              (k/error "invalid binding form for IF: " binding))
          (let ((sym  (get/head binding))
                (prog (get/tail binding)))
            (or (is <symbol> sym)
                (k/error "invalid binding name for IF: " sym))
            (while (is <pair> prog)
              (set tmp (k/eval (get/head prog) -env-))
              (set prog (get/tail prog)))
            (set tmp  (new-<pair> sym tmp))
            (set env2 (new-<pair> tmp env2))))
        (set bindings (get/tail bindings)))
      (set tmp ())
      (while (is <pair> body)
        (set tmp (k/eval (get/head body) env2))
        (set body (get/tail body)))
     tmp)))

(define-subr (subr/set 2)
  (let ((var (k/assq (k/car -args-) -env-)))
    (or (is <pair> var)
        (k/error "undefined variable: (set "-args-")"))
    (let ((result (k/eval (k/cadr -args-) -env-)))
      (put/tail var result)
      result)))

(define-subr subr/while
  (let ((tst  (k/car -args-))
        (prog -args-))
    (while (k/eval tst -env-)
      (let ((body prog))
        (while (is <pair> (set body (k/cdr body)))
          (k/eval (get/head body) -env-))))))

(define-subr subr/if
  (if (k/eval (k/car -args-) -env-)
      (k/eval (k/cadr -args-) -env-)
    (let ((ans ()))
      (set -args- (k/cdr -args-))
      (while (is <pair> (set -args- (k/cdr -args-)))
        (set ans (k/eval (get/head -args-) -env-)))
      ans)))

(define-subr subr/or
  (let ((ans ()))
    (while (is <pair> -args-)
      (and (set ans (k/eval (get/head -args-) -env-))
           (return ans))
      (set -args- (get/tail -args-)))))

(define-subr subr/and
  (let ((ans symbol/t))
    (while (is <pair> -args-)
      (or (set ans (k/eval (get/head -args-) -env-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-subr (subr/quote 1)
  (k/car -args-))

(define-subr (subr/not 1)
  (if (k/car -args-) () symbol/t))

(define-subr subr/long/substract
  (safety 1 (or (and (k/car -args-) (not (k/cddr -args-))) (k/error "operator '-' expected 1 or 2 arguments, got: " -args-)))
  (let ((lhs (get/head -args-))
        (rhs (get/tail -args-)))
    (if (is <pair> rhs)
        (let ()
          (set rhs (get/head rhs))
          (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (- "lhs" "rhs")")))
          (new-<long> (- (get/long lhs) (get/long rhs))))
      (safety 1 (or (is/long lhs) (k/error "non-numeric argument: (- "lhs")")))
      (new-<long> (- (get/long lhs))))))

(define-form define-binary (op name)
  `(define-subr (,name 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string name)" "lhs" "rhs")")))
       (new-<long> (,op (get/long lhs) (get/long rhs))))))

(define-binary &  subr/bitand)
(define-binary |  subr/bitor)
(define-binary ^  subr/bitxor)
(define-binary +  subr/long/add)
(define-binary *  subr/long/multiply)
(define-binary /  subr/long/divide)
(define-binary << subr/long/shift-left)
(define-binary >> subr/long/shift-right)

(define-form define-relation (op name)
  `(define-subr (,name 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string name)" "lhs" "rhs")")))
       (and (,op (get/long lhs) (get/long rhs))
            symbol/t))))

(define-relation <  subr/relation/less)
(define-relation <= subr/relation/less-or-equal)
(define-relation >= subr/relation/greater-or-equal)
(define-relation >  subr/relation/greater)

(define-subr (subr/relation/equal 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (get/type lhs)))
    (cond
      ((= type <long>)          (and (is/long rhs) (= (get/long lhs) (get/long rhs)) symbol/t))
      ((= type <string>)        (and (is <string> rhs) (not (libc/strcmp (get/string lhs) (get/string rhs))) symbol/t))
      (else                     (and (= lhs rhs) symbol/t)))))

(define-subr (subr/relation/not-equal 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (get/type lhs)))
    (cond
      ((= type <long>)          (and (is/long rhs) (!= (get/long lhs) (get/long rhs)) symbol/t))
      ((= type <string>)        (and (is <string> rhs) (libc/strcmp (get/string lhs) (get/string rhs))) symbol/t)
      (else                     (and (!= lhs rhs) symbol/t)))))

(define-subr (subr/abort 0)
  (libc/flush-streams)
  (libc/abort))

(define-subr (subr/exit 1)
  (let ((arg (k/car -args-)))
    (or (is/long arg)
        (k/error "argument to subr_exit is not a <long>: " arg))
    (libc/flush-streams)
    (libc/exit (get/long arg))))

;; KLUDGE FIXME FILE* pointer is stuffed into a long. it won't necessarily work with tagged immediate longs.
(define-subr (subr/open 1)
  (let ((path (k/car -args-)))
    (or (is <string> path) (fatal "subr/open: non-string path argument"))
    (let ((stream (libc/fopen (get/string path) "rb")))
      (and stream (new-<long> stream)))))

(define-subr (subr/close 1)
  (let ((arg (k/car -args-)))
    (or (is <long> arg) (fatal "subr/close: non-integer argument"))
    (libc/fclose (get/long arg))
    arg))

(define-subr subr/dump
  (while (is <pair> -args-)
    (k/dump (get/head -args-))
    (set -args- (get/tail -args-))))

(define-subr subr/print
  (while (is <pair> -args-)
    (k/print (get/head -args-))
    (set -args- (get/tail -args-))))

(define-subr subr/warn
  (while (is <pair> -args-)
    (let* ((arg  (get/head -args-))
           (type (get/type arg)))
      (cond
        ((= type <string>) (libc/fprintf libc/stderr "%s" (get/string arg)))
        ((= type <symbol>) (libc/fprintf libc/stderr "%s" (get/symbol arg)))))
    (set -args- (get/tail -args-))))

(define-subr subr/apply-<expr>
  (let ((fun (k/car -args-)))
    ;; TODO signal an explicit error otherwise?
    (and (is <expr> fun)
         (let ()
           (let* ((arguments (k/cdr -args-))
                  (argl      arguments)
                  (defn      (get <expr> defn fun))
                  (formals   (k/car defn))
                  (tmp       ()))
             (set -env- (get <expr> env fun))
             (gc/protect (defn -env- tmp)
               (while (is <pair> formals)
                 (unless (is <pair> argl)
                   (k/error "too few arguments: ("fun" "arguments")"))
                 (set tmp     (new-<pair> (get/head formals) (get/head argl)))
                 (set -env-   (new-<pair> tmp -env-))
                 (set formals (get/tail formals))
                 (set argl    (get/tail argl)))
               (and (is <symbol> formals)
                    (let ()
                      (set tmp   (new-<pair> formals argl))
                      (set -env- (new-<pair> tmp -env-))
                      (set argl  ())))
               (when argl
                 (k/error "too many arguments: ("fun" "arguments")"))
               (set defn (get/tail defn))
               (while (is <pair> defn)
                 (set argl (k/eval (get/head defn) -env-))
                 (set defn (get/tail defn)))
               argl))))))

(define-subr (subr/apply-<fixed> 2)
  (let ((fun  (k/car -args-))
        (argl (k/cdr -args-)))
    (and (is <fixed> fun)
         (k/apply (get <fixed> function fun) argl -env-))))

(define-subr subr/apply
  (k/apply (k/car -args-) (k/cadr -args-) (or (k/caddr -args-) -env-)))

(define-subr (subr/eval-<symbol> 1)
  (let ((exp (k/car -args-))
        (val (k/assq exp -env-)))
    (or (is <pair> val)
        (k/error "eval-<symbol>: undefined variable: " exp))
    (get/tail val)))

(define-function evlist (obj env)
  (if (is <pair> obj)
      (let ((head (k/eval (get/head obj) env)))
        (gc/protect (head)
          (let ((tail (evlist (get/tail obj) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    obj))

(define-subr (subr/eval-<pair> 1)
  (let ((exp  (k/car -args-))
        (head (k/eval (k/car exp) -env-)))
    (gc/protect (head)
      (k/set-array-at *backtrace-stack* *backtrace-index* exp)
      (set *backtrace-index* (+ *backtrace-index* 1))
      (set head (if (is <fixed> head)
                    (k/apply (get <fixed> function head) (get/tail exp) -env-)
                  (let ((-args- (evlist (get/tail exp) -env-)))
                    (gc/protect (-args-)
                      (k/apply head -args- -env-)))))
      (set *backtrace-index* (- *backtrace-index* 1))
      head)))

(define-subr subr/eval
  (let ((x (k/car -args-))
        (e (or (k/cadr -args-) -env-)))
    (gc/protect (x)
      (set x (k/expand x e))
      (set x (k/encode x e))
      (k/eval x e))))

(define-subr subr/cons       (new-<pair> (k/car -args-) (k/cadr -args-)))
(define-subr (subr/string 1) (new-<string>-of-length (and (is/long (k/car -args-)) (get/long (get/head -args-)))))
(define-subr subr/array      (new-<array> (and (is/long (k/car -args-)) (get/long (get/head -args-)))))
(define-subr subr/form       (new-<form> (k/car -args-) (k/cadr -args-)))

(define-subr (subr/allocate 2)
  (let ((type (get/head -args-))
        (size (get/head (get/tail -args-))))
    (safety 1 (k/assert (is/long type) "allocate: invalid type "type))
    (safety 1 (k/assert (is/long size) "allocate: invalid size "size))
    (gc/new-object (get/long type) (get/long size))))

(define-subr (subr/type-of 1) (and -args- (new-<long> (get/type (k/car -args-)))))
(define-subr (subr/string? 1) (and (is <string> (k/car -args-)) symbol/t))
(define-subr (subr/symbol? 1) (and (is <symbol> (k/car -args-)) symbol/t))
(define-subr (subr/pair? 1)   (and (is <pair>   (k/car -args-)) symbol/t))
(define-subr (subr/array? 1)  (and (is <array>  (k/car -args-)) symbol/t))
(define-subr (subr/car 1)     (k/car (k/car -args-)))
(define-subr (subr/cdr 1)     (k/cdr (k/car -args-)))

(define-subr (subr/set-car 2)
  (let ((obj (k/car -args-)))
    (and (is <pair> obj)
         (put <pair> head obj (k/cadr -args-)))))

(define-subr (subr/set-cdr 2)
  (let ((obj (k/car -args-)))
    (and (is <pair> obj)
         (put <pair> tail obj (k/cadr -args-)))))

(define-subr (subr/oop-at 2)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 1 (k/assert (and obj (is/long idx))))
    (oop-at obj (get/long idx))))

(define-subr (subr/set-oop-at 3)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and obj (is/long idx))))
    (set-oop-at obj (get/long idx) val)))

(define-subr (subr/array-length 1)
  (new-<long> (k/array-length (k/car -args-))))

(define-subr (subr/array-at 2)
  (let ((arr (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 1 (k/assert (and (is <array> arr) (is/long idx))))
    (k/array-at arr (get/long idx))))

(define-subr (subr/set-array-at 3)
  (let ((arr (get/head -args-))
        (idx (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and (is <array> arr) (is/long idx))))
    (k/set-array-at arr (get/long idx) val)))

(define-subr (subr/string-length 1)
  (let ((arg (k/car -args-)))
    (safety 1 (k/assert (is <string> arg)))
    (get <string> size arg)))

(define-subr (subr/string-at 2)
  (let ((arr (get/head -args-))
        (arg (get/head (get/tail -args-))))
    (safety 1 (k/assert (and (is <string> arr) (is/long arg))))
    (let ((idx (get/long arg)))
      (and (<= 0 idx)
           (< idx (k/string-length arr))
           (new-<long> (string-at (get/string arr) idx))))))

(define-subr (subr/set-string-at 3)
  (let ((arr (get/head -args-))
        (arg (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and (is <string> arr) (is/long val))))
    (let ((idx (get/long arg)))
      (and (<= 0 idx)
           (< idx (k/string-length arr))
           ;; TODO don't just silently ignore wrong indexes?
           (let ()
             (set-string-at (get/string arr) idx (get/long val))
             val)))))

(define-subr (subr/string->symbol 1)
  (let ((arg (k/car -args-)))
    (if (is <symbol> arg)
        arg
      (and (is <string> arg)
           (intern (get/string arg))))))

(define-subr (subr/symbol->string 1)
  (let ((arg (k/car -args-)))
    (if (is <string> arg)
        arg
      (and (is <symbol> arg)
           (new-<string>-from-cstring (get <symbol> _bits arg))))))

(define-subr (subr/long->string 1)
  (let ((arg (k/car -args-)))
    (if (is <string> arg)
        arg
      (and (is/long arg)
           (let ((buf (libc/malloc 32)))
             (libc/sprintf buf "%ld" (get/long arg))
             (let ((result (new-<string>-from-cstring buf)))
               (libc/free buf)
               result))))))

(define-subr (subr/current-module 0)
  *module*)

(define-function k/set-current-module (module)
  (debug (libc/printf "k/set-current-module {%p}\n" module))
  (set *module* module)
  (capture-well-known-vm-values))

(define-subr (subr/set-current-module 1)
  (let ((module (k/car -args-)))
    (safety 1 (k/assert (is <module> module) "set-current-module: called with not a <module>: "module))
    (k/set-current-module module))
  ())

(define-subr (subr/create-module 0)
  (let ((module (new-<module>)))
    (populate-module-with-primitives module)
    module))

(define-subr (subr/eval-in-module 2)
  (let ((new-module (k/car -args-))
        (form (k/cadr -args-))
        (previous-module *module*))
    (safety 1 (k/assert (is <module> new-module) "eval-in-module: called with not a <module>: "new-module))
    (debug (libc/printf "eval-in-module: form ") (k/println form))
    (k/set-current-module new-module)
    (let ((env (<module>-env new-module))
          (result form))
      (gc/protect (result)
        (set result (k/expand result env))
        (set result (k/encode result env))
        (set result (k/eval result env))
        (k/set-current-module previous-module)
        (debug (libc/printf "eval-in-module is about to return ") (k/println result))
        result))))

;;; ----------------------------------------------------------------

(define *arg/verbose* 0)

(define-function repl_stream (stream)
  (let ((value 0))
    (libc/fscanf stream "#!%*[^\012\015]")
    (while (!= +done+ (set value (k/read stream)))
      (gc/protect (value)
        (and (> *arg/verbose* 0) (libc/printf ";;; ") (k/dumpln value))
        (set value (k/expand value (<module>-env *module*)))  (and (> *arg/verbose* 2) (libc/printf "expd--> ") (k/dumpln value))
        (set value (k/encode value (<module>-env *module*)))  (and (> *arg/verbose* 2) (libc/printf "encd--> ") (k/dumpln value))
        (set value (k/eval   value (<module>-env *module*)))  (and (> *arg/verbose* 1) (libc/printf "eval--> ") (k/dumpln value))
        ))))

(define-function instantiate-subr (name imp module)
  (let ((tmp (new-<subr> imp name)))
    (gc/protect (tmp)
      (k/define* (intern* name module) tmp module))))

(define-function instantiate-fixed-subr (name imp module)
  (let ((tmp (new-<subr> imp name)))
    (gc/protect (tmp)
      (set tmp (new-<fixed> tmp))
      (k/define* (intern* name module) tmp module))))

(define-function libc/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

(define-function lookup-env-entry/current-module (name)
  (lookup-env-entry (intern* name *module*) *module*))

(define-function lookup-env-entry (name module)
  (safety 2 (k/assert (is <symbol> name)))
  (safety 2 (k/assert (is <module> module)))
  (or (k/assq name (<module>-env module))
      (k/error "LOOKUP-ENV-ENTRY failed for '"name"' in module "module)))

(define-function populate-module-with-primitives (module)
  (safety 1 (k/assert (is <module> module) "populate-module-with-primitives: called with not a <module>: "module))
  ;; the predefined primitives of the language
  (let ((tmp)
        (symbol/*expanders*   (intern* "*expanders*"   module))
        (symbol/*encoders*    (intern* "*encoders*"    module))
        (symbol/*evaluators*  (intern* "*evaluators*"  module))
        (symbol/*applicators* (intern* "*applicators*" module)))
    (gc/protect (tmp)
      (set tmp (new-<array> 0)) (k/define* symbol/*expanders*   tmp module)
      (set tmp (new-<array> 0)) (k/define* symbol/*encoders*    tmp module)
      (set tmp (new-<array> 0)) (k/define* symbol/*evaluators*  tmp module)
      (set tmp (new-<array> 0)) (k/define* symbol/*applicators* tmp module)

      (set tmp (new-<subr> subr/eval-<symbol> "eval-<symbol>")) (k/set-array-at (get/tail (lookup-env-entry symbol/*evaluators*  module)) <symbol> tmp)
      (set tmp (new-<subr> subr/eval-<pair>   "eval-<pair>"  )) (k/set-array-at (get/tail (lookup-env-entry symbol/*evaluators*  module)) <pair>   tmp)
      (set tmp (new-<subr> subr/apply-<fixed> "apply-<fixed>")) (k/set-array-at (get/tail (lookup-env-entry symbol/*applicators* module)) <fixed>  tmp)
      (set tmp (new-<subr> subr/apply-<expr>  "apply-<expr>" )) (k/set-array-at (get/tail (lookup-env-entry symbol/*applicators* module)) <expr>   tmp)))

  (instantiate-fixed-subr "define"           subr/define module)
  (instantiate-fixed-subr "lambda"           subr/lambda module)
  (instantiate-fixed-subr "let"              subr/let    module)
  (instantiate-fixed-subr "set"              subr/set    module)
  (instantiate-fixed-subr "while"            subr/while  module)
  (instantiate-fixed-subr "if"               subr/if     module)
  (instantiate-fixed-subr "or"               subr/or     module)
  (instantiate-fixed-subr "and"              subr/and    module)
  (instantiate-fixed-subr "quote"            subr/quote  module)

  (instantiate-subr  "not"                   subr/not                module)
  (instantiate-subr  "&"                     subr/bitand             module)
  (instantiate-subr  "|"                     subr/bitor              module)
  (instantiate-subr  "^"                     subr/bitxor             module)
  (instantiate-subr  "+"                     subr/long/add           module)
  (instantiate-subr  "-"                     subr/long/substract     module)
  (instantiate-subr  "*"                     subr/long/multiply      module)
  (instantiate-subr  "/"                     subr/long/divide        module)
  (instantiate-subr  "<<"                    subr/long/shift-left    module)
  (instantiate-subr  ">>"                    subr/long/shift-right   module)
  (instantiate-subr  "<"                     subr/relation/less      module)
  (instantiate-subr  "<="                    subr/relation/less-or-equal module)
  (instantiate-subr  "!="                    subr/relation/not-equal module)
  (instantiate-subr  "="                     subr/relation/equal     module)
  (instantiate-subr  ">="                    subr/relation/greater-or-equal module)
  (instantiate-subr  ">"                     subr/relation/greater   module)
  (instantiate-subr  "abort"                 subr/abort              module)
  (instantiate-subr  "exit"                  subr/exit               module)
  (instantiate-subr  "dump"                  subr/dump               module)
  (instantiate-subr  "print"                 subr/print              module)
  (instantiate-subr  "warn"                  subr/warn               module)
  (instantiate-subr  "apply"                 subr/apply              module)
  (instantiate-subr  "eval"                  subr/eval               module)
  (instantiate-subr  "cons"                  subr/cons               module)
  (instantiate-subr  "string"                subr/string             module)
  (instantiate-subr  "array"                 subr/array              module)
  (instantiate-subr  "form"                  subr/form               module)
  (instantiate-subr  "open"                  subr/open               module)
  (instantiate-subr  "close"                 subr/close              module)
  (instantiate-subr  "allocate"              subr/allocate           module)
  (instantiate-subr  "type-of"               subr/type-of            module)
  (instantiate-subr  "string?"               subr/string?            module)
  (instantiate-subr  "symbol?"               subr/symbol?            module)
  (instantiate-subr  "pair?"                 subr/pair?              module)
  (instantiate-subr  "array?"                subr/array?             module)
  (instantiate-subr  "car"                   subr/car                module)
  (instantiate-subr  "set-car"               subr/set-car            module)
  (instantiate-subr  "cdr"                   subr/cdr                module)
  (instantiate-subr  "set-cdr"               subr/set-cdr            module)
  (instantiate-subr  "oop-at"                subr/oop-at             module)
  (instantiate-subr  "set-oop-at"            subr/set-oop-at         module)
  (instantiate-subr  "array-length"          subr/array-length       module)
  (instantiate-subr  "array-at"              subr/array-at           module)
  (instantiate-subr  "set-array-at"          subr/set-array-at       module)
  (instantiate-subr  "string-length"         subr/string-length      module)
  (instantiate-subr  "string-at"             subr/string-at          module)
  (instantiate-subr  "set-string-at"         subr/set-string-at      module)
  (instantiate-subr  "string->symbol"        subr/string->symbol     module)
  (instantiate-subr  "symbol->string"        subr/symbol->string     module)
  (instantiate-subr  "long->string"          subr/long->string       module)
  (instantiate-subr  "current-module"        subr/current-module     module)
  (instantiate-subr  "set-current-module"    subr/set-current-module module)
  (instantiate-subr  "create-module"         subr/create-module      module)
  (instantiate-subr  "eval-in-module"        subr/eval-in-module     module)
  )

(define-function capture-well-known-vm-values ()
  ;; let's cache some values from *module* to speed up their access in tight loops
  (set symbol/t                      (intern* "t"                *module*))
  (set symbol/dot                    (intern* "."                *module*))
  (set symbol/set                    (intern* "set"              *module*))
  (set symbol/quote                  (intern* "quote"            *module*))
  (set symbol/quasiquote             (intern* "quasiquote"       *module*))
  (set symbol/unquote                (intern* "unquote"          *module*))
  (set symbol/unquote_splicing       (intern* "unquote-splicing" *module*))
  (set symbol/*module*               (intern* "*module*"         *module*))

  (set expanders         (lookup-env-entry/current-module "*expanders*"))
  (set encoders          (lookup-env-entry/current-module "*encoders*"))
  (set evaluators        (lookup-env-entry/current-module "*evaluators*"))
  (set applicators       (lookup-env-entry/current-module "*applicators*"))

  (set fixed-subr/quote  (k/cdr (lookup-env-entry/current-module "quote")))
  (set fixed-subr/lambda (k/cdr (lookup-env-entry/current-module "lambda")))
  (set fixed-subr/let    (k/cdr (lookup-env-entry/current-module "let"))))

(define-function main (argc argv)
  ;; we need to dereference them once
  (set libc/stdin  (oop-at libc/stdin 0))
  (set libc/stdout (oop-at libc/stdout 0))
  (set libc/stderr (oop-at libc/stderr 0))

  (gc/initialise)

  (safety 4 (set gc/frequency 1))

  (debug (libc/printf "gc initialized\n"))

  (set *module* (new-<module>))          (gc/push-root (address-of *module*))

  (debug (libc/printf "*module* initialized\n"))

  (set *backtrace-stack* (new-<array> 32))     (gc/push-root (address-of *backtrace-stack*))

  (debug (libc/printf "populating *module*\n"))

  (populate-module-with-primitives *module*)
  (capture-well-known-vm-values)

  (debug (libc/printf "start processing argv\n"))

  (let ((i 1))
    (while (< i argc)
      (let ((arg (oop-at argv i)))
        (cond
          ((not (libc/strcmp arg "-v"))
           (set *arg/verbose* (+ 1 *arg/verbose*)))
          ((not (libc/strcmp arg "-c"))
           (unless (> argc 0)
             (fatal "-c requires an argument"))
           (set i (+ i 1))
           (let* ((cstr (oop-at argv i))
                  (sym (intern cstr))
                  (form (new-<pair> sym ())))
             (k/eval form (<module>-env *module*))))
          (else
           (let ((stream (libc/fopen arg "r")))
             (or stream (fatal1 "no such file: %s" arg))
             (repl_stream stream)
             (libc/fclose stream)))))
      (set i (+ i 1))))
  (libc/flush-streams)
  (and (> *arg/verbose* 0)
       (let ()
         (gc/collect)
         (libc/printf "GC: %d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)))

  (libc/fprintf libc/stderr "%d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)
  (libc/flush-streams)
  0)

(compile-end)
