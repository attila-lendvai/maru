;;; -*- mode: lisp; coding: us-ascii -*-

(eval-in-module *slave-module*
  '(define *primitive-function-registry* ()))

(define-form define-primitive-function (name-and-props . body)
  (unless (pair? name-and-props)
    (set name-and-props (list name-and-props)))
  (let* (((name arity fixed?) name-and-props))
    (assert (symbol? name))
    (push *primitive-function-registry* (list name arity fixed?))
    `(define-function ,(concat-symbol 'primitive-function/ name) (-args- -ctx-)
       ,@(when arity
           `((safety 2 (%check-arity (new-<string>-from-cstring ,(symbol->string name)) ,arity -args-))))
       ,@body)))

(define-function %check-arity (op arity args)
  (let ((count arity)
        (lst args))
    (while (and (< 0 count)
                (pair? lst))
      (set lst (get/tail lst))
      (set count (- count 1)))
    (or (and (= 0 count) (not lst))
        (error "Operator '" op "' called with the wrong number of arguments: " args))))

(define-function instantiate-primitive-function (module name imp fixed?)
  (gc/let* ((tmp (new-<primitive-function> imp name)))
    (when fixed?
      (set tmp (new-<fixed> tmp)))
    (environment-define (module-env module) (string->symbol name) tmp)))

(define-form instantiate-primitive-functions (module)
  `(let ((__module__ ,module))
     ,@(map (lambda (entry)
              (let* ((name	(first entry))
                     (impl-name	(concat-symbol 'primitive-function/ name))
                     (fixed?	(third entry)))
                `(instantiate-primitive-function __module__ ,(symbol->string name) ,impl-name ,(target-boolean fixed?))))
            *primitive-function-registry*)))

(define-primitive-function (define () fixed)
  (let ((var (car -args-)))
    (assert (is <variable> var) "non-variable in define: "var)
    (let ((val (eval (cadr -args-) -ctx-)))
      (put (<variable> value) var val)
      ;; maybe set the <expr>'s name slot
      (when-at-expand feature/track-expr-names
        (let ((tmp val))
          (when (is <form> tmp)
            (set tmp (get (<form> function) tmp)))
          (when (and (is <expr> tmp)
                     (not (get (<expr> name) tmp)))
            (put (<expr> name) tmp (get (<variable> name) var)))))
      val)))

(define-primitive-function (defined? 1)
  (let ((name (get/head -args-))
        (env (or (cadr -args-) (module-env *module*))))
    (lookup-variable env name)))

(define-primitive-function (lambda () fixed)
  (let* (((env parameters . body) -args-)) ; see encode/pair, it puts the env as the first arg
    (assert (is <env> env) "lambda primitive-function: env is "env)
    (assert (or (not parameters) (is <variable> parameters) (pair? parameters)) "lambda primitive-function: parameters is of wrong type: " parameters)
    (new-<expr> parameters body env -ctx-)))

(define-primitive-function (let () fixed)
  (let* ((bindings (cadr -args-))
         (locals   (get (<context> bindings) -ctx-))
         (body     (cddr -args-)))
    (gc/let* (tmp)
      (list-do binding bindings
        (when (pair? binding)
          (let ((var  (get/head binding))
                (prog (get/tail binding)))
            (debug (libc/printf "let primitive-function is initializing var ") (dump var) (libc/printf " in context ") (dumpln -ctx-))
            (set tmp ())
            (while (pair? prog)
              (set tmp (eval (get/head prog) -ctx-))
              (set prog (get/tail prog)))
            (debug (libc/printf "let primitive-function is setting var ") (dump var) (libc/printf " to value ") (print tmp) (libc/printf " in context ") (dumpln -ctx-))
            (set (array-at locals (get/long (get (<variable> index) var))) tmp))))
      (set tmp ())
      (list-do exp body
        (set tmp (eval exp -ctx-)))
      tmp)))

(define-primitive-function (set 2 fixed)
  (debug (libc/printf "SET ") (print -args-) (libc/printf " IN ") (println -ctx-))
  (let ((var (get/head -args-))
        (value (eval (get/head (get/tail -args-)) -ctx-)))
    (assert (is <variable> var) "non-variable in set: "var)
    (if (global-variable? var)
        (put (<variable> value) var value)
      (let ((delta (- (get/long (get (<env> level) (get (<context>  env) -ctx-)))
                  (get/long (get (<env> level) (get (<variable> env) var))))))
        (debug (libc/printf "set primitive-function is writing local var ") (dump var) (libc/printf " with delta %ld\n" delta))
        (while (< 0 delta)
          (set -ctx- (get (<context> home) -ctx-))
          (decr delta))
        (let ((index (get/long (get (<variable> index) var))))
          (debug (libc/printf "set primitive-function is setting local var in context ") (dump -ctx-) (libc/printf " at index %ld, to value " index) (dumpln value))
          (set (array-at (get (<context> bindings) -ctx-) index) value))))))

(define-primitive-function (while () fixed)
  (let ((tst  (car -args-))
        (prog -args-))
    (while (eval tst -ctx-)
      (let ((body prog))
        (while (pair? (set body (cdr body)))
          (eval (get/head body) -ctx-))))))

(define-primitive-function (if () fixed)
  (if (eval (car  -args-) -ctx-)
      (eval (cadr -args-) -ctx-)
    (let ((ans ()))
      (set -args- (cdr -args-))
      (while (pair? (set -args- (cdr -args-)))
        (set ans (eval (get/head -args-) -ctx-)))
      ans)))

(define-primitive-function (or () fixed)
  (let ((ans ()))
    (while (pair? -args-)
      (and (set ans (eval (get/head -args-) -ctx-))
           (return ans))
      (set -args- (get/tail -args-)))))

(define-primitive-function (and () fixed)
  (let ((ans symbol/true))
    (while (pair? -args-)
      (or (set ans (eval (get/head -args-) -ctx-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-primitive-function (quote 1 fixed)
  (get/head -args-))

(define-primitive-function (not 1)
  (if (get/head -args-) () symbol/true))

(define-primitive-function (fixed 1)
  (new-<fixed> (get/head -args-)))

(define-primitive-function (variable 4)
  (new-<variable> (get/head -args-)
                  (get/head (set -args- (get/tail -args-)))
                  (get/head (set -args- (get/tail -args-)))
                  (get/head (get/tail -args-))))

(define-primitive-function (environment 1)
  (let ((parent (get/head -args-)))
    (assert (is <env> parent))
    (new-<env> parent 0 (get/long (get (<env> offset) parent)))))

(define-primitive-function (environment-define 3)
  (let ((env   (get/head -args-))
        (name  (get/head (set -args- (get/tail -args-))))
        (value (get/head (get/tail -args-))))
    (environment-define env name value)))

;; -, +, *, and / all have some peculiarities that makes them somewhat resistant to macrology
(define-primitive-function -
  (or (pair? -args-) (error "operator '-' called with zero arguments"))
  (let ((result	(get/long (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (- result (get/long (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (- result)))
    (new-<long> result)))

(define-primitive-function +
  (let ((result	0)
        (rest	()))
    (when (pair? -args-)
      (set result (get/long (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (pair? rest)
      (set result (+ result (get/long (get/head rest))))
      (set rest (get/tail rest)))
    (new-<long> result)))

(define-primitive-function /
  (or (pair? -args-) (error "operator '/' called with zero arguments"))
  (let ((result	(get/long (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (/ result (get/long (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (/ 1 result)))
    (new-<long> result)))

(define-primitive-function *
  (let ((result	1)
        (rest	()))
    (when (pair? -args-)
      (set result (get/long (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (pair? rest)
      (set result (* result (get/long (get/head rest))))
      (set rest (get/tail rest)))
    (new-<long> result)))

(define-form define-binary-operator (op)
  `(define-primitive-function (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (long? lhs) (long? rhs)) (error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (new-<long> (,op (get/long lhs) (get/long rhs))))))

(define-binary-operator bitwise-and)
(define-binary-operator bitwise-or)
(define-binary-operator bitwise-xor)

(define-primitive-function (bitwise-not 1)
  (let ((value (get/head -args-)))
    (safety 1 (or (long? value) (error "non-numeric argument for bitwise-not: "value)))
    (new-<long> (bitwise-not (get/long value)))))

(define-primitive-function (bitwise-shift 2)
  (let* ((value (get/long (get/head -args-)))
         (shift (get/long (get/head (get/tail -args-))))
         (bit-length-of-<long> 31) ; TODO FIXME arrange for using the actual value here
         (max-shift (- bit-length-of-<long> 1)))
    (new-<long>
     (cond
       ((< max-shift shift)	0)
       ((< 0 shift)		(<< value shift))
       ((< shift (- max-shift))	(if (< value 0) -1 0))
       ((< shift 0)		(>> value (- shift)))
       ((= 0 shift)		value)))))

(define-form define-relation (op)
  `(define-primitive-function (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (long? lhs) (long? rhs)) (error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (and (,op (get/long lhs) (get/long rhs))
            symbol/true))))

(define-relation <)
(define-relation <=)
(define-relation >=)
(define-relation >)

;; FIXME strcmp is broken for strings that contain zeros
(define-primitive-function (= 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (type-of lhs)))
    (cond
      ((= type <long>)		(and (long? rhs) (= (get/long lhs) (get/long rhs)) symbol/true))
      ((= type <string>)	(and (string? rhs) (not (libc/strcmp (get/string lhs) (get/string rhs))) symbol/true))
      (else                     (and (= lhs rhs) symbol/true)))))

(define-primitive-function (!= 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (type-of lhs)))
    (cond
      ((= type <long>)		(and (long? rhs) (!= (get/long lhs) (get/long rhs)) symbol/true))
      ((= type <string>)	(and (string? rhs) (libc/strcmp (get/string lhs) (get/string rhs))) symbol/true)
      (else                     (and (!= lhs rhs) symbol/true)))))

(define-primitive-function abort
  (libc/printf "ABORTED: ")
  (dumpln -args-)
  (print-backtrace)
  (libc/flush-streams)
  (libc/abort))

(define-primitive-function (exit 1)
  (let ((arg (get/head -args-)))
    (assert (long? arg) "exit primitive-function: argument is not an integer: "arg)
    (when-at-expand feature/profiler
      (profiler/disable))
    (libc/flush-streams)
    (libc/exit (get/long arg))))

(define-primitive-function (libc/fopen 2)
  (let ((path (get/head -args-))
        (mode (get/head (get/tail -args-))))
    (let ((stream (libc/fopen (get/string path) (get/string mode))))
      (and stream (new-<target-vm-pointer> stream)))))

(define-primitive-function (libc/fclose 1)
  (let ((stream (get/head -args-)))
    (libc/fclose (get/tvmptr stream))
    ()))

(define-primitive-function (libc/fgetc 1)
  (let* ((stream	(get/head -args-))
         (c		(libc/fgetc (get/tvmptr stream))))
    (and (>= c 0)
         (new-<long> c))))

(define-primitive-function (libc/fputc 2)
  (let ((char	(get/head -args-))
        (stream	(get/head (get/tail -args-))))
    (new-<long> (libc/fputc (get/long char) (get/tvmptr stream)))))

(define-primitive-function (libc/format 2)
  (let ((ofmt (get/head -args-))
        (oarg (get/head (get/tail -args-))))
    (assert (string? ofmt) "libc/format primitive-function: non-string format")
    (let ((fmt (get/string ofmt))
          (typ (type-of oarg))
          (arg ()))
      (cond
        ((= typ <undefined>))
        ((= typ <long>)		(set arg (get/long oarg)))
        ((= typ <string>)	(set arg (get/string oarg)))
        ((= typ <symbol>)	(set arg (get/symbol oarg)))
        (else			(set arg oarg)))
      (let ((size 100)
            (result ()))
        (gc/let* ((buf ()))
          (while (not result)
            (set buf (gc/allocate-opaque <data> size))
            (let ((n (libc/snprintf buf size fmt arg)))
              (if (and (<= 0 n)
                       (< n size))
                  (set result (new-<string>-from-cstring buf))
                (set size (* size 2))))))
        result))))

;; TODO which one is the actual primitive that we want to publish? maybe just a read-form?
(define-primitive-function read
  (if (= () -args-)
      (let ((obj (read libc/stdin)))
        (and (= k/+end+ obj) (set obj ()))
        obj)
    (let ((arg (car -args-)))
      (or (string? arg) (fatal1 "read: argument is not a <string> "arg))
      (let ((stream (libc/fopen (get/string arg) "r")))
        ;; TODO error handling
        (when stream
          (gc/let* ((head (cons () ()))
                    obj)
            (let ((tail head))      ; TODO use collecting macro
              (while (!= k/+end+ (set obj (read stream)))
                (set tail (put/tail tail (cons obj ()))))
              (libc/fclose stream)
              (get/tail head))))))))

(define-primitive-function (load 1)
  (let* ((path		(get/head -args-))
         (stream	(or (cond
                              ((string? path)
                               (verbosity 1 (libc/fprintf libc/stderr "loading file: %s\n" (get/string path)))
                               (libc/fopen (get/string path) "r"))
                              ((not path)
                               (verbosity 1 (libc/fprintf libc/stderr "loading from stdin\n"))
                               (libc/fdopen libc/stdin "r"))
                              (else
                               (error "load: don't know how to open "path)))
                            (error "load: fopen failed on "path)))
         (result	(repl-stream stream)))
    (libc/fclose stream)
    result))

;; TODO delme?
(define-primitive-function (repl-stream 1)
  (let ((stream (get/head -args-)))
    ;;(or stream (set stream (get/variable-value var/*input*)))
    (repl-stream (get/tvmptr stream))))

(define-primitive-function dump
  (list-do arg -args-
    (dump arg))
  (first -args-))

(define-primitive-function print
  (list-do arg -args-
    (print arg))
  (first -args-))

(define-primitive-function warn
  (list-do arg -args-
    (let ((type (type-of arg)))
      (cond
        ((= type <string>) (libc/fprintf libc/stderr "%s" (get/string arg)))
        ((= type <symbol>) (libc/fprintf libc/stderr "%s" (get/symbol arg)))
        ((= type <long>)   (libc/fprintf libc/stderr "%ld" (get/long   arg)))
        (else
         ;; TODO
         (libc/fprintf libc/stderr "<unable to print {%p} of type %ld>" arg type)))))
  (libc/flush-streams))

(define-primitive-function (apply 2)
  (apply (get/head -args-) (get/head (get/tail -args-)) -ctx-))

;; TODO rename to eval-sexp to differentiate from eval-encoded? find some better names...
(define-primitive-function eval
  (gc/let* ((env (or (cadr -args-)
                     (new-<env> (module-env *module*) 1 0))))
    (expand-encode-eval (car -args-) env)))

(define-primitive-function eval-encoded
  ;; TODO investigate: why is this needed? try to eliminate it
  (gc/let* ((env (or (cadr -args-)
                     (new-<env> (module-env *module*) 1 0))))
    (eval (car -args-) env)))

(define-primitive-function encode
  (encode (car -args-)
          (or (cadr -args-)
              (get (<context> env) -ctx-))))

(define-primitive-function expand
  (expand (car -args-)
          (or (cadr -args-)
              (get (<context> env) -ctx-))))

(define-primitive-function cons		(cons (car -args-) (cadr -args-)))
(define-primitive-function (string 1)	(new-<string>-of-length (get/long (get/head -args-))))
(define-primitive-function array	(new-<array> (and (long? (car -args-)) (get/long (get/head -args-)))))
(define-primitive-function form		(new-<form> (car -args-) (cadr -args-)))
(define-primitive-function (type-of 1)	(new-<long> (type-of (get/head -args-))))
(define-primitive-function (car 1)	(car (get/head -args-)))
(define-primitive-function (cdr 1)	(cdr (get/head -args-)))
(define-primitive-function (string? 1)	(and (string? (get/head -args-)) symbol/true))
(define-primitive-function (symbol? 1)	(and (symbol? (get/head -args-)) symbol/true))
(define-primitive-function (pair? 1)	(and (pair?   (get/head -args-)) symbol/true))
(define-primitive-function (array? 1)	(and (array?  (get/head -args-)) symbol/true)) ; TODO move to boot.l?

(define-primitive-function (allocate 2)
  (let ((type (get/head -args-))
        (size (get/head (get/tail -args-))))
    (safety 1 (assert (long? type) "allocate: invalid type "type))
    (safety 1 (assert (long? size) "allocate: invalid size "size))
    (gc/allocate (get/long type) (words-to-bytes (get/long size)))))

(define-primitive-function (allocate-data 1)
  (let ((size (get/head -args-)))
    (safety 1 (assert (long? size) "allocate-data: invalid size "size))
    (gc/allocate-opaque <data> (get/long size))))

(define-primitive-function (set-car 2)
  (let ((obj (get/head -args-)))
    ;; TODO assert the type
    (and (pair? obj)
         (put (<pair> head) obj (get/head (get/tail -args-))))))

(define-primitive-function (set-cdr 2)
  (let ((obj (get/head -args-)))
    (and (pair? obj)
         (put (<pair> tail) obj (get/head (get/tail -args-))))))

(define-primitive-function (copy-oops 3)
  (let ((from	(get/head -args-))
        (to	(get/head (get/tail -args-)))
        (count	(get/long (get/head (get/tail (get/tail -args-))))))
    (copy-oops from to count)
    ()))

(define-primitive-function (oop-at 2)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 3 (assert (and obj (long? idx) (not (long? obj)))))
    (oop-at obj (get/long idx))))

(define-primitive-function (set-oop-at 3)
  (let ((obj (get/head -args-))
        (idx (get/head (set -args- (get/tail -args-))))
        (val (get/head (get/tail -args-))))
    (safety 3 (assert (and obj (long? idx) (not (long? obj)))))
    (set-oop-at obj (get/long idx) val)))

(define-primitive-function (address-of 1)
  ;; TODO what about when <long> is a tagged immediate and the address is truncated?
  ;; or return a target-vm-pointer here and define pointer arithmetics?
  ;; or implement various boxed data types and return a word-sized integer here?
  (new-<long> (get/head -args-)))

(define-primitive-function (copy-bytes 3)
  (let ((from	(get/head -args-))
        (to	(get/head (get/tail -args-)))
        (count	(get/long (get/head (get/tail (get/tail -args-))))))
    (copy-bytes from to count)
    ()))

(define-primitive-function (byte-at 2)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 3 (assert (and obj (long? idx) (not (long? obj)))))
    (new-<long> (byte-at obj (get/long idx)))))

(define-primitive-function (set-byte-at 3)
  (let* ((obj		(get/head -args-))
         (idx		(get/head (set -args- (get/tail -args-))))
         (val		(get/head (get/tail -args-)))
         (unboxed-val	(get/long val)))
    (safety 3 (assert (and obj (long? idx) (not (long? obj)))))
    (safety 1 (assert (and (<= unboxed-val 256) (<= 0 unboxed-val)) "set-byte-at: value is out of range: "unboxed-val))
    (set (byte-at obj (get/long idx)) unboxed-val)))

(define-primitive-function (array-length 1)
  (let ((arg (get/head -args-)))
    (safety 1 (assert (array? arg)))
    (get (<array> size) arg)))

(define-primitive-function (string-length 1)
  (let ((arg (get/head -args-)))
    (safety 1 (assert (string? arg)))
    (get (<string> size) arg)))

(define-primitive-function (array-at 2)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (get/tail -args-)))))
    (array-at arr idx)))

(define-primitive-function (string-at 2)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (get/tail -args-)))))
    (new-<long> (string-at arr idx))))

;; adding [set-]char-at to the evaluator makes it source-level compatible with the level-shifted code, and with that enables us to load files like buffer.l into both worlds
(define-primitive-function (char-at 2)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (get/tail -args-)))))
    (new-<long> (string-at arr idx))))

(define-primitive-function (set-array-at 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (set -args- (get/tail -args-)))))
        (val (get/head (get/tail -args-))))
    (set (array-at arr idx) val)
    val))

(define-primitive-function (set-string-at 3)
  (let* ((arr (get/head -args-))
         (idx (get/long (get/head (set -args- (get/tail -args-)))))
         (val (get/head (get/tail -args-))))
    ;; NOTE set-string-at happily extends the string with a gap of zeores, so
    ;; we also assert here that idx is out of bounds at most by +1.
    (safety 1 (assert (<= idx (string-length arr))))
    (set (string-at arr idx) (get/long val))
    val))

(define-primitive-function (set-char-at 3)
  (let* ((arr (get/head -args-))
         (idx (get/long (get/head (set -args- (get/tail -args-)))))
         (val (get/head (get/tail -args-))))
    ;; NOTE set-string-at happily extends the string with a gap of zeores, so
    ;; we also assert here that idx is out of bounds at most by +1.
    (safety 1 (assert (<= idx (string-length arr))))
    (set (string-at arr idx) (get/long val))
    val))

(define-primitive-function (array-insert 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (set -args- (get/tail -args-)))))
        (val (get/head (get/tail -args-))))
    (array-insert arr idx val)
    val))

(define-primitive-function (string-insert 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (set -args- (get/tail -args-)))))
        (val (get/head (get/tail -args-))))
    (string-insert arr idx (get/long val))
    val))

(define-primitive-function (string->symbol 1)
  (let ((arg (get/head -args-)))
    ;; FIXME this is too permissive, and returns nil when called with an unexpected type
    (if (symbol? arg)
        arg
      (and (string? arg)
           (string->symbol (get/string arg))))))

(define-primitive-function (symbol->string 1)
  (let ((arg (get/head -args-)))
    ;; FIXME this is too permissive, and returns nil when called with an unexpected type
    (if (string? arg)
        arg
      (and (symbol? arg)
           (new-<string>-from-cstring (get/symbol arg))))))

(define-primitive-function (long->string 1)
  (let ((arg (get/head -args-)))
    (assert (long? arg))
    (let ((buf (gc/allocate-opaque <data> 32))) ; safe up until 64 bits
      (libc/sprintf buf "%ld" (get/long arg))
      (new-<string>-from-cstring buf))))

(define-primitive-function (string->long 1)
  (let ((arg (get/head -args-)))
    (assert (string? arg))
    (let* ((str		(get/string arg))
           (endptr	str)
           (result	(libc/strtol str (address-of endptr) 10)))
      (if (= (char-at endptr 0) ?\x00)
          (new-<long> result)
        (fatal1 "invalid number in string->long, libc/strtol failed for '%s'" str)))))

(define-primitive-function (current-module 0)
  *module*)

(define-primitive-function (set-current-module 1)
  (let ((module (get/head -args-)))
    (safety 1 (assert (is <module> module) "set-current-module: called with not a <module>: "module))
    (k/set-current-module module))
  ())

(define-primitive-function create-module
  (new-<module> (awhen (car -args-)
                  (get/string it))))

(define-primitive-function (eval-in-module 2)
  (let ((new-module	(get/head -args-))
        (form		(get/head (get/tail -args-))))
    (safety 1 (assert (is <module> new-module) "eval-in-module: called with not a <module>: "new-module))
    (debug (libc/printf "eval-in-module: form ") (dumpln form))
    (gc/let* ((env (new-<env> (module-env new-module) 1 0)))
      (with-current-module new-module
        (expand-encode-eval form env)))))

(when-at-expand (= +architecture+ 'IA-32)
  (define-primitive-function (call-IA-32-machine-code 1)
    (let ((data (get/head -args-)))
      (debug (libc/printf "call-IA-32-machine-code will call %p\n" data))
      (assert (is <data> data) "call-IA-32-machine-code: cannot call object of type "(type-of data)", printing as "data)
      (data)
      (debug (libc/printf "call-IA-32-machine-code got back the control from %p\n" data))
      ())))

(when-at-expand (= +architecture+ 'x86-64)
  (define-primitive-function (call-x86-64-machine-code 1)
    (let ((data (get/head -args-)))
      (debug (libc/printf "call-x86-64-machine-code will call %p\n" data))
      (assert (is <data> data) "call-x86-64-machine-code: cannot call object of type "(type-of data)", printing as "data)
      (data)
      (debug (libc/printf "call-x86-64-machine-code got back the control from %p\n" data))
      ())))

(when-at-expand feature/debug-output
  (define-primitive-function (enable-debug-output 0)	(set *debug-output-enabled?* true))
  (define-primitive-function (disable-debug-output 0)	(set *debug-output-enabled?* false)))
