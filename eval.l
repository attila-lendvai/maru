;;; The maru VM, written in itself

(define-form safe     prog ())
(define-form k/assert prog ())
(define-form debug    prog ())
(define-form gc/debug prog ())

;;
;; you can enable safety and debugging features here
;;
(define-form k/assert (test . args) `(or ,test (k/error ,@(or args (list "assertion failed")))))
(define-form safe     prog `(let () ,@prog))
;(define-form debug    prog `(let () ,@prog))
;(define-form gc/debug prog `(let () ,@prog))

;;;
;;; Naming convention
;;;
;;; k/ prefix means that it's some "level-shifted" code that is
;;;    compiled into the target and "messes with the bits at runtime".
;;;
;;; subr/ prefix means that it's the body of a maru <subr>, often
;;;       just wrapping a k/ primitive, together with some safety checks.

(define-structure <header> (size flags next type))
(define-structure <buffer> (contents size position))

(define-function make-gc-protectors (vars)
  (map (lambda (v) `(gc/push-root (address-of ,v)))
       vars))

(define-function make-gc-unprotectors (vars)
  (let ((result ()))
    (while (pair? vars)
      (set result (cons `(gc/pop-root (address-of ,(car vars))) result))
      (set vars (cdr vars)))
    result))

(define-form gc-protect (vars . prog)
  `(let ()
     ,@(make-gc-protectors vars)
     (let ((__answer__ ,@prog))
       ,@(make-gc-unprotectors vars)
       __answer__)))

(define-function make-gc-let* (inits prog)
  (if (pair? inits)
      `((let (,(car inits)) (gc-protect (,(caar inits)) ,@(make-gc-let* (cdr inits) prog))))
    prog))

(define-form gc-let* (inits . prog) (car (make-gc-let* inits prog)))

(define-form define-externs args
  `(let ()
     ,@(map (lambda (libc-name)
              (let ((maru-name (concat-symbol 'libc/ libc-name)))
                `(define ,maru-name (extern ',libc-name))))
            args)))

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

(define-form size-of-structure (type)   (* 4 (array-at %structure-sizes (eval type))))

(define-form <header>-flags-used ()     1)
(define-form <header>-flags-atom ()     2)
(define-form <header>-flags-mark ()     4)

(define-form <header>-flags-used+atom ()        (+ (<header>-flags-used) (<header>-flags-atom)))

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
      (k/dumpln (k/array-at trace_stack i))
      (libc/flush-streams)))
  (libc/exit 1))

;; FATAL directly uses the libc printf (i.e. more resilient, and can properly print char type), while
;; K/ERROR goes through our own printing facility (i.e. can print maru objects).
(define-function fatal  (fmt)           (libc/fprintf libc/stderr fmt)           (libc/fprintf libc/stderr "\n") (die))
(define-function fatal1 (fmt arg)       (libc/fprintf libc/stderr fmt arg)       (libc/fprintf libc/stderr "\n") (die))
(define-function fatal2 (fmt arg1 arg2) (libc/fprintf libc/stderr fmt arg1 arg2) (libc/fprintf libc/stderr "\n") (die))

;; FIXME it would be nice for K/ERROR to be a function (or at least expand to a breakpoint'able function call),
;; but that would need the compiler to support variable nr of args, or literal lists
(define-form k/error args
  (let ((stream 'libc/stderr))
    ;; KLUDGE if it's only strings, then print to stderr. to clean up this mess, the PRINT API needs support for setting the output stream.
    (list-do arg args
      (unless (string? arg)
        (set stream 'libc/stdout)))
    `(let ()
       (libc/fprintf ,stream "\nerror: ")
       ,@(map (lambda (arg)
                (if (string? arg)
                    `(libc/fprintf ,stream ,arg)
                  `(k/print ,arg)))
              args)
       (libc/fprintf ,stream "\n")
       (die))))

(define-function new_memory_block (size)
  (let ((ptr (libc/malloc size)))
    (or ptr (fatal "out of memory"))
    (set (<header>-size  ptr) (- size (size-of-structure <header>)))
    (set (<header>-flags ptr) 0)
    (set (<header>-next  ptr) ptr)
    (debug (libc/printf "BRK %p %d %d/%d\n" ptr size gc/alloc-count gc/frequency))
    ptr))

(define-function gc/initialise ()
  (let ((ptr (new_memory_block gc/quantum)))
    (set gc/memory-base ptr)
    (set gc/memory-last ptr)))

(define-function gc/push-root (ptr)
  (and (= gc/root-count gc/root-max)
       (let* ((roots (libc/malloc (* 4 (set gc/root-max (max 32 (* 2 gc/root-max)))))))
         (libc/memcpy roots gc/roots (* 4 gc/root-count))
         (and gc/roots (libc/free gc/roots))
         (set gc/roots roots)))
  (set-oop-at gc/roots gc/root-count ptr)
  (debug (libc/printf "gc add root %d at %p\n" gc/root-count ptr))
  (set gc/root-count (+ 1 gc/root-count)))

(define-function gc/pop-root (ptr)
  (or gc/root-count (fatal "root table underflow"))
  (set gc/root-count (- gc/root-count 1))
  (debug (libc/printf "gc del root %d at %p %s\n" gc/root-count ptr))
  (or (= ptr (oop-at gc/roots gc/root-count))
      (fatal "non-lifo root")))

(define-function gc/grow-memory (size)
  (let ((brk (new_memory_block size)))
    (set (<header>-next brk) (<header>-next gc/memory-last))
    (set (<header>-next gc/memory-last) brk)))

(define-function gc/size (obj)  (<header>-size (- obj (size-of-structure <header>))))

(define-function gc/malloc-atomic (size)
  (let* ((obj (gc/malloc size)))
    (set (<header>-flags (- obj (size-of-structure <header>))) (<header>-flags-used+atom))
    obj))

(define-function gc/malloc (size)
  (set size (& -4 (+ 3 size)))
  (and (= gc/alloc-count gc/frequency) (gc/collect))
  (let* ((first (<header>-next gc/memory-last))
         (chunk first)
         (ssize (+ size (size-of-structure <header>))))
    (while 1
      (while
        (let ()
          (debug (libc/printf "alloc? %d %p %p [%p] %d >= %d %d\n" (<header>-flags chunk) chunk (<header>-next chunk) first (<header>-size chunk) size (<= size (<header>-size chunk))))
          (if (= 0 (<header>-flags chunk))
              (let ((csize (<header>-size chunk)))
                (while (and (= 0 (<header>-flags (<header>-next chunk)))
                            (= (<header>-next chunk) (+ chunk (+ (size-of-structure <header>) csize))))
                  (let ((next (<header>-next chunk)))
                    (set (<header>-next chunk) (<header>-next next))
                    (set csize (set (<header>-size chunk) (+ csize (+ (size-of-structure <header>) (<header>-size next)))))
                    (and (= next gc/memory-last) (set gc/memory-last chunk))))
                (if (or (< ssize csize) (= size csize))
                    (let ()
                      (debug (libc/printf "csize %d\n" csize))
                      (and (> csize ssize)
                           (let ((split (+ chunk ssize)))
                             (debug (libc/printf "split %d: %p + %d -> %p + %d\n" csize chunk size split (- csize (+ size (size-of-structure <header>)))))
                             (set (<header>-size  split) (- csize (+ size (size-of-structure <header>))))
                             (set (<header>-flags split) 0)
                             (set (<header>-next  split) (<header>-next chunk))
                             (set (<header>-size  chunk) size)
                             (set (<header>-next  chunk) split)
                             (set csize size)))
                      (set (<header>-flags chunk) (<header>-flags-used))
                      (set gc/memory-last chunk)
                      (debug (libc/printf "alloc chunk %p\n" chunk))
                      (let ((obj (+ chunk (size-of-structure <header>))))
                        (libc/memset obj 0 csize)
                        (set gc/alloc-count (+ gc/alloc-count 1))
                        (return obj))))))
          (!= first (set chunk (<header>-next chunk)))))
      (gc/grow-memory (max (+ (size-of-structure <header>) size) gc/quantum)))))

(define-function gc/sweep ()
  (debug (libc/printf "sweep\n"))
  (let ((ptr gc/memory-base)
        (nobjs 0)
        (nused 0)
        (nfree 0))
    (while ptr
      (debug (libc/printf "sweep? %d %p + %d\n" (<header>-flags ptr) ptr (<header>-size ptr)))
      (let ((flags (<header>-flags ptr)))
        (if (& flags (<header>-flags-mark))
            (let ()
              (set nused (+ nused (<header>-size ptr)))
              (set nobjs (+ nobjs 1))
              (set (<header>-flags ptr) (^ flags (<header>-flags-mark))))
          (debug (libc/printf "collect %p %d\n" ptr (<header>-size ptr)))
          (set nfree (+ nfree (<header>-size ptr)))
          (set (<header>-flags ptr) 0)))
      (and (= gc/memory-base (set ptr (<header>-next ptr)))
           (set ptr 0)))
    (set gc/objects-live nobjs)
    (set gc/bytes-used nused)
    (set gc/bytes-free nfree)
    (debug (libc/printf "GC: %d used, %d free, %d allocations\n" nused nfree gc/alloc-count))
    ;;(and (< nfree nused) (gc/grow-memory gc/quantum))
    ))

(define-function gc/mark-and-trace (obj)
  (and obj
       (not (& 1 obj))
       (let* ((ptr   (- obj (size-of-structure <header>)))
              (flags (<header>-flags ptr)))
         (debug (libc/printf "mark and trace %p flags %d\n" obj flags))
         (safe (or (& (<header>-flags-used) flags) (fatal1 "attempt to mark dead object %p" ptr)))
         (or (& flags (<header>-flags-mark))
             (let ()
               (set (<header>-flags ptr) (| flags (<header>-flags-mark)))
               (or (& flags (<header>-flags-atom))
                   (let ((size (>> (<header>-size ptr) 2)))
                     (debug (libc/printf "mark %p %d type %d\n" ptr size (<header>-type ptr)))
                     (while size
                       (set size (- size 1))
                       (debug (libc/printf "@%d %p\n" size (oop-at obj size)))
                       (gc/mark-and-trace (oop-at obj size))))))))))

(define-function gc/collect ()
  (gc/debug
    (or (& 1023 (set gc/collection-count (+ gc/collection-count 1)))
        (libc/fprintf libc/stderr "%d collections\n" gc/collection-count 1)))
  (let ((i 0))
    (while (< i gc/root-count)
      (debug (let ((ptr (oop-at gc/roots i))) (libc/printf "mark gc root %d : %p -> %p\n" i ptr (oop-at ptr 0))))
      (gc/mark-and-trace (oop-at (oop-at gc/roots i) 0))
      (set i (+ 1 i))))
  (gc/sweep)
  (set gc/alloc-count 0))

;;; ----------------------------------------------------------------

(define EOF     -1)

;; NOTE: the subr's in eval.l assume a certain layout for the built-in types.
;; what actually happens is encoded in eval.l, and the define-structure forms
;; for the built-in types in boot.l merely fill in some missing parts. types
;; are represented internally as successive integers.
;; corollary: the two files must agree, both in the order and in the field layout.
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
(define globals                 0)
(define expanders               0)
(define encoders                0)
(define evaluators              0)
(define applicators             0)
(define s_t                     0)
(define s_dot                   0)
(define s_set                   0)
(define s_lambda                0)
(define s_let                   0)
(define s_quote                 0)
(define s_quasiquote            0)
(define s_unquote               0)
(define s_unquote_splicing      0)
(define s_expanders             0)
(define s_encoders              0)
(define s_evaluators            0)
(define s_applicators           0)
(define f_set                   0)
(define f_quote                 0)
(define f_lambda                0)
(define f_let                   0)

(define opt_verbose             0)

(define-function new-bits (type size)
  (let ((obj (gc/malloc-atomic size)))
    (set (oop-at obj -1) type)
    obj))

(define-function new-oops (type size)
  (let ((obj (gc/malloc size)))
    (set (oop-at obj -1) type)
    obj))

(define-function new-<long> (bits)
  (let ((obj (new-bits <long> (size-of-structure <long>))))
    (set (<long>-_bits obj) bits)
    obj))

(define-function _new-<string> (len)
  (let ((str (new-oops <string> (size-of-structure <string>))))
    (gc-protect (str)
      (set (<string>-size  str) (new-<long> len))
      (set (<string>-_bits str) (gc/malloc-atomic (+ len 1)))
      str)))

(define-function new-<string> (cstr)
  (let ((len (libc/strlen cstr)))
    (let ((obj (_new-<string> len)))
      (libc/memcpy (<string>-_bits obj) cstr len)
      obj)))

(define-function new-<symbol> (cstr)
  (let ((obj (new-bits <symbol> (size-of-structure <symbol>))))
    (set (<symbol>-_bits obj) (libc/strdup cstr))
    obj))

(define-function new-<pair> (head tail)
  (let ((obj (new-oops <pair> (size-of-structure <pair>))))
    (set (<pair>-head obj) head)
    (set (<pair>-tail obj) tail)
    obj))

(define-function new-<array> (size)
  (let ((arr (new-oops <array> (size-of-structure <array>))))
    (gc-protect (arr)
      (set (<array>-_array arr) (new-oops <_array> (* 4 size)))
      arr)))

(define-function new-<expr> (defn env)
  (let ((obj (new-oops <expr> (size-of-structure <expr>))))
    (set (<expr>-defn obj) defn)
    (set (<expr>-env  obj) env )
    obj))

(define-function new-<form> (fn)
  (let ((obj (new-oops <form> (size-of-structure <form>))))
    (gc-protect (obj)
      (set (<form>-function obj) fn)
      obj)))

(define-function new-<fixed> (fn)
  (let ((obj (new-oops <fixed> (size-of-structure <fixed>))))
    (gc-protect (obj)
      (set (<fixed>-function obj) fn)
      obj)))

(define-function new-<subr> (_imp _name)
  (let ((obj (new-bits <subr> (size-of-structure <subr>))))
    (gc-protect (obj)
      (set (<subr>-_imp  obj) _imp )
      (set (<subr>-_name obj) _name)
      obj)))

(define-form is (type arg)
  `(let ((__arg__ ,arg))
     (and __arg__
          (not (& 1 __arg__))
          (= ,type (oop-at __arg__ -1)))))

(define-form k/type-of (arg)
  `(let ((__arg__ ,arg))
     (safe (and __arg__ (or (& (<header>-flags-used) (<header>-flags (- __arg__ (size-of-structure <header>)))) (fatal1 "attempt to access dead object %p type %d" __arg__))))
     (if __arg__
         (oop-at __arg__ -1)
       <undefined>)))

(define-function type_check_fail (exp act)
  (fatal2 "illegal type: expected %d got %d" exp act))

(define-form get (type field object)
  `(let ((__obj__ ,object))
     (safe (let ((t (k/type-of __obj__))) (or (= ,type t) (type_check_fail ,type t))))
     (,(concat-symbol (concat-symbol type '-) field) __obj__)))

(define-form put (type field object value)
  `(let ((__obj__ ,object))
     (safe (let ((t (k/type-of __obj__))) (or (= ,type t) (type_check_fail ,type t))))
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

(define-function new_buffer ()
  (let ((buf (libc/malloc (size-of-structure <buffer>))))
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
    (gc-protect (sym)
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
      (when (= EOF c)
        (k/error "unterminated string literal"))
      (buffer_append buf c))
    (buffer_append buf 0)
    (let ((result (new-<string> (<buffer>-contents buf))))
      (buffer_delete buf)
      result)))

(define-function read_list (delim stream)
  (let* ((head (new-<pair> () ()))
         (tail head)
         (elt  ()))
    (gc-protect (head elt)
      (while (and (!= EOF (set elt (k/read stream))) (!= s_dot elt))
        (set elt (new-<pair> elt ()))
        (set tail (set_tail tail elt)))
      (and (= s_dot elt) (set_tail tail (k/read stream))))
    (let ((c (libc/getc stream)))
      (if (= delim c)
          (get_tail head)
        (fatal1 "missing closing '%c' delimiter while reading list" delim)))))

(define-function read_quote (prefix stream)
  (let ((qobj (k/read stream)))
    (when (= EOF qobj)
      (k/error "EOF while reading quoted literal"))
    (gc-protect (qobj)
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
        ((= ?\' c)      (return (read_quote s_quote stream)))
        ((= ?\` c)      (return (read_quote s_quasiquote stream)))
        ((= ?\, c)      (return (let ((d (libc/getc stream)))
                                  (if (= ?@ d)
                                      (read_quote s_unquote_splicing stream)
                                    (libc/ungetc d stream)
                                    (read_quote s_unquote stream)))))
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
  (let ((type (k/type-of obj)))
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
                                  (while (and (is <pair> obj) (!= globals obj))
                                    (do_print (get_head obj) storing)
                                    (and (is <pair> (set obj (get_tail obj))) (libc/printf " ")))
                                  (if (= globals obj)
                                      (libc/printf "<globals>")
                                    (and obj
                                         (let ()
                                           (libc/printf " . ")
                                           (do_print obj storing))))
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

(define-function k/define (name value env)
  (let ((ass (new-<pair> name value)))
    (gc-protect (ass)
      (let ((ent (new-<pair> ass (get_tail env))))
        (set_tail env ent)
        ass))))

(define-function k/assq (key list)
  (while (is <pair> list)
    (let ((head (get_head list)))
      (and (is <pair> head)
           (= key (get_head head))
           (return head)))
    (set list (get_tail list))))

(define-function k/car (list)   (and (is <pair> list) (get_head list)))
(define-function k/cdr (list)   (and (is <pair> list) (get_tail list)))

(define-function k/caar (list)  (k/car (k/car list)))
(define-function k/cadr (list)  (k/car (k/cdr list)))
(define-function k/cddr (list)  (k/cdr (k/cdr list)))

(define-function k/caddr (list) (k/car (k/cdr (k/cdr list))))

(define-function k/string-length (obj)  (get_long (get <string> size obj)))

(define-function k/array-length (obj)
  (safe (or (is <array> obj) (fatal1 "k/array-length: called with object of type %d" (k/type-of obj))))
  (and (is <array> obj)
       (let ((_arr (get <array> _array obj)))
         (let ((sz (/ (gc/size _arr) 4)))
           sz))))

(define-function k/array-at (obj idx)
  (safe (or (and (is <array> obj) (<= 0 idx)) (fatal2 "k/array-at: called with object of type %d, and index %d" (k/type-of obj) idx)))
  (and (is <array> obj)
       (let* ((elts (get <array> _array obj))
              (size (/ (gc/size elts) 4)))
         (and (<= 0 idx) (< idx size)
              (oop-at elts idx)))))

(define-function k/set-array-at (obj idx val)
  (safe (or (and (is <array> obj) (<= 0 idx)) (fatal2 "k/set-array-at: called with object of type %d, and index %d" (k/type-of obj) idx)))
  (and (is <array> obj)
       (let* ((elts (get <array> _array obj))
              (size (/ (gc/size elts) 4)))
         (and (<= 0 idx)
              (let ()
                (or (< idx size)
                    (let* ((nsize (max (+ idx 1) (* size 2)))
                           (oops  (new-oops <_array> (* 4 nsize))))
                      (libc/memcpy oops elts (* size 4))
                      (set elts (put <array> _array obj oops))))
                (set-oop-at elts idx val))))))

(define-function k/concat-list (head tail)
  (if (is <pair> head)
      (let ()
        (set tail (k/concat-list (get_tail head) tail))
        (gc-protect (tail)
          (new-<pair> (get_head head) tail)))
    tail))

;;; ----------------------------------------------------------------

(define-function exlist (list env)
  (if (is <pair> list)
      (let ((head (k/expand (get_head list) env)))
        (gc-protect (head)
          (let ((tail (exlist (get_tail list) env)))
            (gc-protect (tail)
              (new-<pair> head tail)))))
    list))

(define-function k/expand (exp env)
  (if (is <pair> exp)
      (let ((head (k/expand (get_head exp) env)))
        (gc/push-root (address-of head))
        (if (is <symbol> head)
            (let ((val (k/cdr (k/assq head env))))
              (if (is <form> val)
                  (let ()
                    (set head (k/apply (get <form> function val) (get_tail exp) env))
                    (set head (k/expand head env))
                    (gc/pop-root (address-of head))
                    (return head)))))
        (let ((tail (get_tail exp)))
          (gc/push-root (address-of tail))
          (or (= head s_quote) (set tail (exlist tail env)))
          (and (= s_set head)
               (is <pair>   (k/car  tail))
               (is <symbol> (k/caar tail))
               (let ((buf (new_buffer)))
                 (buffer_append_all buf "set-")
                 (buffer_append_all buf (get <symbol> _bits (get_head (get_head tail))))
                 (set head (intern (buffer_contents buf)))
                 (set tail (k/concat-list (get_tail (get_head tail)) (get_tail tail)))))
          (set exp (new-<pair> head tail))
          (gc/pop-root (address-of tail))
          (gc/pop-root (address-of head))))
    (let ((fn (k/array-at (get_tail expanders) (k/type-of exp))))
      (and fn
           (let ((args (new-<pair> exp ())))
             (gc-protect (args)
               (set exp (k/apply fn args env)))))))
  exp)

(define-function enlist (list env)
  (if (is <pair> list)
      (let ((head (k/encode (get_head list) env)))
        (gc-protect (head)
          (let ((tail (enlist (get_tail list) env)))
            (gc-protect (tail)
              (new-<pair> head tail)))))
    list))

(define-function k/encode (exp env)
  (if (is <pair> exp)
      (let ((head (k/encode (get_head exp) env))
            (tail (get_tail exp)))
        (gc-protect (head tail)
          (if (is <symbol> head)
              (let ((val (k/cdr (k/assq head env))))
                (and (or (is <fixed> val) (is <subr> val))
                     (set head val))))
          (cond
            ((= head f_let)             (let ((args (k/cadr exp))
                                              (tmp  ()))
                                          (gc-protect (env tmp)
                                            (while (is <pair> args)
                                              (let ((var (get_head args)))
                                                (and (is <pair> var) (set var (get_head var)))
                                                (set tmp (new-<pair> var ()))
                                                (set env (new-<pair> tmp env))
                                                (set args (get_tail args))))
                                            (set tail (enlist tail env)))))
            ((= head f_lambda)          (let ((args (k/cadr exp))
                                              (tmp  ()))
                                          (gc-protect (env tmp)
                                            (while (is <pair> args)
                                              (set tmp (new-<pair> (get_head args) ()))
                                              (set env (new-<pair> tmp env))
                                              (set args (get_tail args)))
                                            (and args
                                                 (let ()
                                                   (set tmp (new-<pair> args ()))
                                                   (set env (new-<pair> tmp env))))
                                            (set tail (enlist tail env)))))
            ((!= head f_quote)          (set tail (enlist tail env))))
          (set exp (new-<pair> head tail))))
    (let ((fn (k/array-at (get_tail encoders) (k/type-of exp))))
      (and fn (let () (libc/printf "APPLY GOT ENCODER\n... " (k/println fn) 1)))
      (and fn
           (let ((args (new-<pair> env ())))
             (gc-protect (args)
               (set args (new-<pair> exp args))
               (libc/printf "APPLY ENCODER\n... ") (k/print fn) (libc/printf " ") (k/print args) (libc/printf " ") (k/println env)
               (set exp (k/apply fn args env)))))))
  exp)

(define-function k/eval (exp env)
  (let ((ev (k/array-at (get_tail evaluators) (k/type-of exp))))
    (and ev
         (let ((args (new-<pair> exp ())))
           (gc-protect (args)
             (k/set-array-at trace_stack trace_depth exp)
             (set trace_depth (+ trace_depth 1))
             (set exp (k/apply ev args env))
             (set trace_depth (- trace_depth 1)))))
    exp))

(define-function k/apply (fun arguments env)
  (if (is <subr> fun)
      ((get <subr> _imp fun) arguments env)
    (let ((ap (k/array-at (get_tail applicators) (k/type-of fun))))
      (or ap (k/error "cannot apply: " fun))
      (let ((args arguments))
        (gc-protect (args)
          (set args (new-<pair> fun args))
          (k/apply ap args env))))))

;;;
;;; the subr's
;;;

(define-form define-subr (name . body)
  `(define-function ,(concat-symbol 'subr/ (string->symbol name)) (args env)
     ,@body))

(define-subr define
  (let ((sym (k/car args)))
    (or (is <symbol> sym)
        (k/error "non-symbol identifier in define: " sym))
    (let ((val (k/eval (k/cadr args) env)))
      (gc-protect (val)
                  (k/define sym val globals)
                  val))))

(define-subr lambda
  (new-<expr> args env))

(define-subr let
  (let ((env2     env)
        (tmp      ())
        (bindings (k/car args))
        (body     (k/cdr args)))
    (gc-protect (env2 tmp)
      (while (is <pair> bindings)
        (let ((binding (get_head bindings)))
          (or (is <pair> binding)
              (k/error "invalid binding form for IF: " binding))
          (let ((sym  (get_head binding))
                (prog (get_tail binding)))
            (or (is <symbol> sym)
                (k/error "invalid binding name for IF: " sym))
            (while (is <pair> prog)
              (set tmp (k/eval (get_head prog) env))
              (set prog (get_tail prog)))
            (set tmp  (new-<pair> sym tmp))
            (set env2 (new-<pair> tmp env2))))
        (set bindings (get_tail bindings)))
      (set tmp ())
      (while (is <pair> body)
        (set tmp (k/eval (get_head body) env2))
        (set body (get_tail body)))
     tmp)))

(define-subr set
  (let ((var (k/assq (k/car args) env)))
    (or (is <pair> var)
        (k/error "undefined variable: (set "args")"))
    (set_tail var (k/eval (k/cadr args) env))))

(define-subr while
  (let ((tst  (k/car args))
        (prog args))
    (while (k/eval tst env)
      (let ((body prog))
        (while (is <pair> (set body (k/cdr body)))
          (k/eval (get_head body) env))))))

(define-subr if
  (if (k/eval (k/car args) env)
      (k/eval (k/cadr args) env)
    (let ((ans ()))
      (set args (k/cdr args))
      (while (is <pair> (set args (k/cdr args)))
        (set ans (k/eval (get_head args) env)))
      ans)))

(define-subr or
  (let ((ans ()))
    (while (is <pair> args)
      (and (set ans (k/eval (get_head args) env))
           (return ans))
      (set args (get_tail args)))))

(define-subr and
  (let ((ans s_t))
    (while (is <pair> args)
      (or (set ans (k/eval (get_head args) env))
          (return ()))
      (set args (get_tail args)))
    ans))

(define-function arity1 (op args)
  (safe (or (and (is <pair> args)
                 (= () (get_tail args)))
            (k/error "Operator '" op "' expected 1 argument, got: " args))))

(define-function arity2 (op args)
  (safe (or (and (is <pair> args)
                 (is <pair> (get_tail args))
                 (= () (get_tail (get_tail args))))
            (k/error "Operator '" op "' expected 2 arguments, got: " args))))

(define-function arity3 (op args)
  (safe (or (and (is <pair> args)
                 (is <pair> (get_tail args))
                 (is <pair> (get_tail (get_tail args)))
                 (= () (get_tail (get_tail (get_tail args)))))
            (k/error "Operator '" op "' expected 3 arguments, got: " args))))

(define-subr quote
  (arity1 "quote" args)
  (k/car args))

(define-subr not
  (arity1 "not" args)
  (if (k/car args) () s_t))

(define-subr sub
  (safe (or (and (k/car args) (not (k/cddr args))) (k/error "operator '-' expected 1 or 2 arguments, got: " args)))
  (let ((lhs (get_head args))
        (rhs (get_tail args)))
    (if (is <pair> rhs)
        (let ()
          (set rhs (get_head rhs))
          (safe (or (and (is <long> lhs) (is <long> rhs)) (k/error "non-numeric argument: (- "lhs" "rhs")")))
          (new-<long> (- (get_long lhs) (get_long rhs))))
      (safe (or (is <long> lhs) (k/error "non-numeric argument: (- "lhs")")))
      (new-<long> (- (get_long lhs))))))

(define-form define-binary (op name)
  `(define-subr ,name
     (arity2 ,name args)
     (let ((lhs (get_head args))
           (rhs (get_head (get_tail args))))
       (safe (or (and (is <long> lhs) (is <long> rhs)) (k/error "non-numeric argument: (",name" "lhs" "rhs")")))
       (new-<long> (,op (get_long lhs) (get_long rhs))))))

(define-binary &  "bitand")
(define-binary |  "bitor")
(define-binary ^  "bitxor")
(define-binary +  "add")
(define-binary *  "mul")
(define-binary /  "div")
(define-binary << "shl")
(define-binary >> "shr")

(define-form define-relation (op name)
  `(define-subr ,name
     (arity2 ,name args)
     (let ((lhs (get_head args))
           (rhs (get_head (get_tail args))))
       (safe (or (and (is <long> lhs) (is <long> rhs)) (k/error "non-numeric argument: (",name" "lhs" "rhs")")))
       (and (,op (get_long lhs) (get_long rhs))
            s_t))))

(define-relation <  "lt")
(define-relation <= "le")
(define-relation >  "gt")

(define-subr eq
  (arity2 "=" args)
  (let* ((lhs  (get_head args))
         (rhs  (get_head (get_tail args)))
         (type (k/type-of lhs)))
    (cond
      ((= type <long>)          (and (is <long> rhs) (= (get_long lhs) (get_long rhs)) s_t))
      ((= type <string>)        (and (is <string> rhs) (not (libc/strcmp (get <string> _bits lhs) (get <string> _bits rhs))) s_t))
      (else                     (and (= lhs rhs) s_t)))))

(define-subr ne
  (arity2 "!=" args)
  (let* ((lhs  (get_head args))
         (rhs  (get_head (get_tail args)))
         (type (k/type-of lhs)))
    (cond
      ((= type <long>)          (and (is <long> rhs) (!= (get_long lhs) (get_long rhs)) s_t))
      ((= type <string>)        (and (is <string> rhs) (libc/strcmp (get <string> _bits lhs) (get <string> _bits rhs))) s_t)
      (else                     (and (!= lhs rhs) s_t)))))

(define-subr abort
  (libc/flush-streams)
  (libc/abort))

(define-subr exit
  (let ((arg (k/car args)))
    (or (is <long> arg)
        (k/error "argument to subr_exit is not a <long>: " arg))
    (libc/flush-streams)
    (libc/exit (get_long arg))))

(define-subr dump
  (while (is <pair> args)
    (k/dump (get_head args))
    (set args (get_tail args))))

(define-subr print
  (while (is <pair> args)
    (k/print (get_head args))
    (set args (get_tail args))))

(define-subr warn
  (while (is <pair> args)
    (let* ((arg  (get_head args))
           (type (k/type-of arg)))
      (cond
        ((= type <string>) (libc/fprintf libc/stderr "%s" (get <string> _bits arg)))
        ((= type <symbol>) (libc/fprintf libc/stderr "%s" (get <symbol> _bits arg)))))
    (set args (get_tail args))))

(define-subr apply-expr
  (let ((fun (k/car args)))
    ;; TODO signal an explicit error otherwise?
    (and (is <expr> fun)
         (let ()
           (let* ((arguments (k/cdr args))
                  (argl      arguments)
                  (defn      (get <expr> defn fun))
                  (formals   (k/car defn))
                  (tmp       ()))
             (set env (get <expr> env fun))
             (gc-protect (defn env tmp)
               (while (is <pair> formals)
                 (unless (is <pair> argl)
                   (k/error "too few arguments: ("fun" "arguments")"))
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
                 (k/error "too many arguments: ("fun" "arguments")"))
               (set defn (get_tail defn))
               (while (is <pair> defn)
                 (set argl (k/eval (get_head defn) env))
                 (set defn (get_tail defn)))
               argl))))))

(define-subr apply-fixed
  (let ((fun  (k/car args))
        (argl (k/cdr args)))
    (and (is <fixed> fun)
         (k/apply (get <fixed> function fun) argl env))))

(define-subr apply
  (k/apply (k/car args) (k/cadr args) (or (k/caddr args) env)))

(define-subr eval-symbol
  (let ((exp (k/car args))
        (val (k/assq exp env)))
    (or (is <pair> val)
        (k/error "subr_eval_symbol: undefined variable: " exp))
    (get_tail val)))

(define-function evlist (obj env)
  (if (is <pair> obj)
      (let ((head (k/eval (get_head obj) env)))
        (gc-protect (head)
          (let ((tail (evlist (get_tail obj) env)))
            (gc-protect (tail)
              (new-<pair> head tail)))))
    obj))

(define-subr eval-pair
  (let ((exp  (k/car args))
        (head (k/eval (k/car exp) env)))
    (gc-protect (head)
      (k/set-array-at trace_stack trace_depth exp)
      (set trace_depth (+ trace_depth 1))
      (set head (if (is <fixed> head)
                    (k/apply (get <fixed> function head) (get_tail exp) env)
                  (let ((args (evlist (get_tail exp) env)))
                    (gc-protect (args)
                      (k/apply head args env)))))
      (set trace_depth (- trace_depth 1))
      head)))

(define-subr eval
  (let ((x (k/car args))
        (e (or (k/cadr args) env)))
    (gc-protect (x)
      (set x (k/expand x e))
      (set x (k/encode x e))
      (k/eval x e))))

(define-subr cons      (new-<pair> (k/car args) (k/cadr args)))
(define-subr string    (_new-<string> (and (is <long> (k/car args)) (get_long (get_head args)))))
(define-subr array     (new-<array> (and (is <long> (k/car args)) (get_long (get_head args)))))
(define-subr form      (new-<form> (k/car args)))

(define-subr allocate
  (arity2 "allocate" args)
  (let ((type (get_head args))
        (size (get_head (get_tail args))))
    (and (is <long> type) (is <long> size)
         (new-oops (get_long type) (* (get_long size) 4)))))

(define-subr type-of   (and args (new-<long> (k/type-of (k/car args)))))
(define-subr stringP   (and (is <string> (k/car args)) s_t))
(define-subr symbolP   (and (is <symbol> (k/car args)) s_t))
(define-subr pairP     (and (is <pair> (k/car args)) s_t))
(define-subr arrayP    (and (is <array> (k/car args)) s_t))
(define-subr car       (k/car (k/car args)))
(define-subr cdr       (k/cdr (k/car args)))

(define-subr oop-at
  (arity2 "oop-at" args)
  (let ((obj (get_head args))
        (idx (get_head (get_tail args))))
    (safe (k/assert (and obj (is <long> idx))))
    (oop-at obj (get_long idx))))

(define-subr set-oop-at
  (arity3 "set-oop-at" args)
  (let ((obj (get_head args))
        (idx (get_head (get_tail args)))
        (val (get_head (get_tail (get_tail args)))))
    (safe (k/assert (and obj (is <long> idx))))
    (set-oop-at obj (get_long idx) val)))

(define-subr array-length
  (arity1 "array-length" args)
  (new-<long> (k/array-length (k/car args))))

(define-subr array-at
  (arity2 "array-at" args)
  (let ((arr (get_head args))
        (idx (get_head (get_tail args))))
    (safe (k/assert (and (is <array> arr) (is <long> idx))))
    (k/array-at arr (get_long idx))))

(define-subr set-array-at
  (arity3 "set-array-at" args)
  (let ((arr (get_head args))
        (idx (get_head (get_tail args)))
        (val (get_head (get_tail (get_tail args)))))
    (safe (k/assert (and (is <array> arr) (is <long> idx))))
    (k/set-array-at arr (get_long idx) val)))

(define-subr string-length
  (arity1 "string-length" args)
  (let ((arg (k/car args)))
    (safe (k/assert (is <string> arg)))
    (get <string> size arg)))

(define-subr string-at
  (arity2 "string-at" args)
  (let ((arr (get_head args))
        (arg (get_head (get_tail args))))
    (safe (k/assert (and (is <string> arr) (is <long> arg))))
    (let ((idx (get_long arg)))
      (and (<= 0 idx)
           (< idx (k/string-length arr))
           (new-<long> (string-at (get <string> _bits arr) idx))))))

(define-subr set-string-at
  (arity3 "set-string-at" args)
  (let ((arr (get_head args))
        (arg (get_head (get_tail args)))
        (val (get_head (get_tail (get_tail args)))))
    (safe (k/assert (and (is <string> arr) (is <long> val))))
    (let ((idx (get_long arg)))
      (and (<= 0 idx)
           (< idx (k/string-length arr))
           (let ()
             (set-string-at (get <string> _bits arr) idx (get_long val))
             val)))))

(define-subr string->symbol
  (let ((arg (k/car args)))
    (if (is <symbol> arg)
        arg
      (and (is <string> arg)
           (intern (get <string> _bits arg))))))

(define-subr symbol->string
  (let ((arg (k/car args)))
    (if (is <string> arg)
        arg
      (and (is <symbol> arg)
           (new-<string> (get <symbol> _bits arg))))))

(define-subr long->string
  (let ((arg (k/car args)))
    (if (is <string> arg)
        arg
      (and (is <long> arg)
           (let ((buf (libc/malloc 32)))
             (libc/sprintf buf "%ld" (get_long arg))
             (let ((result (new-<string> buf)))
               (libc/free buf)
               result))))))

(define-subr current-environment
  env)

;;; ----------------------------------------------------------------

(define-function repl_stream (stream)
  (let ((res 0))
    (libc/fscanf stream "#!%*[^\012\015]")
    (while (!= EOF (set res (k/read stream)))
      (gc-protect (res)
        (and (> opt_verbose 0) (libc/printf ";;; ") (k/dumpln res))
        (set res (k/expand res globals))        (and (> opt_verbose 2) (libc/printf "expd--> ") (k/dumpln res))
        (set res (k/encode res globals))        (and (> opt_verbose 2) (libc/printf "encd--> ") (k/dumpln res))
        (set res (k/eval   res globals))        (and (> opt_verbose 1) (libc/printf "eval--> ") (k/dumpln res))
        ))))

(define-function instantiate-subr (name imp)
  (let ((tmp (new-<subr> imp name)))
    (gc-protect (tmp)
      (k/define (intern name) tmp globals))))

(define-function instantiate-fsubr (name imp)
  (let ((tmp (new-<subr> imp name)))
    (gc-protect (tmp)
      (set tmp (new-<fixed> tmp))
      (k/define (intern name) tmp globals))))

(define-function libc/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

(define-function main (argc argv)
  ;; we need to dereference them once
  (set libc/stdout (oop-at libc/stdout 0))
  (set libc/stderr (oop-at libc/stderr 0))

  (gc/initialise)               (gc/debug (set gc/frequency 1))

  (gc/push-root (address-of symbols))

  (set s_t                      (intern "t"))
  (set s_dot                    (intern "."))
  (set s_set                    (intern "set"))
  (set s_lambda                 (intern "lambda"))
  (set s_let                    (intern "let"))
  (set s_quote                  (intern "quote"))
  (set s_quasiquote             (intern "quasiquote"))
  (set s_unquote                (intern "unquote"))
  (set s_unquote_splicing       (intern "unquote-splicing"))

  (gc/push-root (address-of globals    ))
  (gc/push-root (address-of expanders  ))
  (gc/push-root (address-of encoders   ))
  (gc/push-root (address-of evaluators ))
  (gc/push-root (address-of applicators))

  (let ((tmp (new-<pair> (intern "*globals*") globals)))
    (gc-protect (tmp)
      (set globals (new-<pair> tmp globals))
      (set_tail tmp globals)
      (set tmp (new-<array> 0))  (set expanders   (k/define (intern "*expanders*"  ) tmp globals))
      (set tmp (new-<array> 0))  (set encoders    (k/define (intern "*encoders*"   ) tmp globals))
      (set tmp (new-<array> 0))  (set evaluators  (k/define (intern "*evaluators*" ) tmp globals))
      (set tmp (new-<array> 0))  (set applicators (k/define (intern "*applicators*") tmp globals))
      (k/set-array-at (get_tail evaluators)  <symbol> (new-<subr> subr/eval-symbol "eval-<symbol>"))
      (k/set-array-at (get_tail evaluators)  <pair>   (new-<subr> subr/eval-pair   "eval-<pair>"  ))
      (k/set-array-at (get_tail applicators) <fixed>  (new-<subr> subr/apply-fixed "apply-<fixed>"))
      (k/set-array-at (get_tail applicators) <expr>   (new-<subr> subr/apply-expr  "apply-<expr>" ))
      ))

  (instantiate-fsubr "define"                subr/define)
  (instantiate-fsubr "lambda"                subr/lambda)
  (instantiate-fsubr "let"                   subr/let)
  (instantiate-fsubr "set"                   subr/set)
  (instantiate-fsubr "while"                 subr/while)
  (instantiate-fsubr "if"                    subr/if)
  (instantiate-fsubr "or"                    subr/or)
  (instantiate-fsubr "and"                   subr/and)
  (instantiate-fsubr "quote"                 subr/quote)

  (instantiate-subr  "not"                   subr/not)
  (instantiate-subr  "&"                     subr/bitand)
  (instantiate-subr  "|"                     subr/bitor)
  (instantiate-subr  "^"                     subr/bitxor)
  (instantiate-subr  "+"                     subr/add)
  (instantiate-subr  "-"                     subr/sub)
  (instantiate-subr  "*"                     subr/mul)
  (instantiate-subr  "/"                     subr/div)
  (instantiate-subr  "<<"                    subr/shl)
  (instantiate-subr  ">>"                    subr/shr)
  (instantiate-subr  "<"                     subr/lt)
  (instantiate-subr  "<="                    subr/le)
  (instantiate-subr  "!="                    subr/ne)
  (instantiate-subr  "="                     subr/eq)
  (instantiate-subr  ">"                     subr/gt)
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
  (instantiate-subr  "string?"               subr/stringP)
  (instantiate-subr  "symbol?"               subr/symbolP)
  (instantiate-subr  "pair?"                 subr/pairP)
  (instantiate-subr  "array?"                subr/arrayP)
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

  (set f_set    (k/cdr (k/assq s_set    globals)))              (gc/push-root (address-of f_set   ))
  (set f_quote  (k/cdr (k/assq s_quote  globals)))              (gc/push-root (address-of f_quote ))
  (set f_lambda (k/cdr (k/assq s_lambda globals)))              (gc/push-root (address-of f_lambda))
  (set f_let    (k/cdr (k/assq s_let    globals)))              (gc/push-root (address-of f_let   ))

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
  (and (> opt_verbose 0)
       (let ()
         (gc/collect)
         (libc/printf "GC: %d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)))

  (libc/fprintf libc/stderr "%d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)
  (libc/flush-streams)
  0)

(compile-end)
