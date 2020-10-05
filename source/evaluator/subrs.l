;;; -*- mode: lisp; coding: us-ascii -*-

(define-form define-subr (name-and-props . body)
  (unless (pair? name-and-props)
    (set name-and-props (list name-and-props)))
  (let ((name (car name-and-props))
        (arity (cadr name-and-props))
        (fixed? (caddr name-and-props)))
    (assert (symbol? name))
    (push *subr-registry* (list name arity fixed?))
    `(define-function ,(concat-symbol 'subr/ name) (-args- -ctx-)
       ,@(when arity
           `((safety 2 (%check-arity (new-<string>-from-cstring ,(symbol->string name)) ,arity -args-))))
       ,@body)))

(define-function %check-arity (op arity args)
  (let ((count arity)
        (lst args))
    (while (and (< 0 count)
                (is/pair lst))
      (set lst (get/tail lst))
      (set count (- count 1)))
    (or (and (= 0 count) (not lst))
        (k/error "Operator '" op "' called with the wrong number of arguments: " args))))

(define-subr (define () fixed)
  (let ((var (k/car -args-)))
    (unless (is <variable> var)
      ;; FIXME? use k/error? why the dumpln? test it...
      (libc/printf "\nerror: non-variable in define: ")
      (k/dumpln var)
      (fatal "aborting"))
    (let ((val (k/eval (k/cadr -args-) -ctx-)))
      (put (<variable> value) var val)
      ;; optionally set the <expr>'s name slot
      (when-at-expand feature/track-expr-names
        (let ((tmp val))
          (when (is <form> tmp)
            (set tmp (get (<form> function) tmp)))
          (when (and (is <expr> tmp)
                     (not (get (<expr> name) tmp)))
            (put (<expr> name) tmp (get (<variable> name) var)))))
      val)))

(define-subr (defined? 1)
  (let ((name (get/head -args-))
        (env (or (k/cadr -args-) (get/globals))))
    (k/env/lookup-variable env name)))

(define-subr (lambda () fixed)
  (let ((env		(k/car  -args-)) ; see k/encode/pair; it puts the env as the first arg
        (parameters	(k/cadr -args-))
        (body		(k/cddr -args-)))
    (k/assert (is <env> env))
    (new-<expr> parameters body env -ctx-)))

(define-subr (let () fixed)
  (let* ((tmp      ())
         (bindings (k/cadr -args-))
         (locals   (get (<context> bindings) -ctx-))
         (body     (k/cddr -args-)))
    (gc/protect (tmp)
      (while (is/pair bindings)
        (let ((binding (get/head bindings)))
          (when (is/pair binding)
            (let ((var  (get/head binding))
                  (prog (get/tail binding)))
              (set tmp ())
              (while (is/pair prog)
                (set tmp (k/eval (get/head prog) -ctx-))
                (set prog (get/tail prog)))
              (set (k/array-at locals (get/long (get (<variable> index) var))) tmp))))
        (set bindings (get/tail bindings)))
      (set tmp ())
      (while (is/pair body)
        (set tmp (k/eval (get/head body) -ctx-))
        (set body (get/tail body))))
    tmp))

(define-subr (set 2 fixed)
  ;;(printf "SET ") (k/print args) (libc/printf " IN ") (k/println -ctx-)
  (let ((var (get/head -args-)))
    (unless (is <variable> var)
      ;; FIXME? use k/error? why the dumpln? test it... was: (k/error "undefined variable: (set "-args-")")
      (libc/printf "\ncannot set undefined variable: ")
      (k/dumpln var)
      (fatal "aborting"))
    (let ((val (k/eval (get/head (get/tail -args-)) -ctx-)))
      (if (global-variable? var)
          (put (<variable> value) var val)
        (let ((delta (- (get/long (get (<env> level) (get (<context>  env) -ctx-)))
                        (get/long (get (<env> level) (get (<variable> env) var))))))
          (while (< 0 delta)
            (set -ctx- (get (<context> home) -ctx-))
            (set delta (- delta 1)))
          (set (k/array-at (get (<context> bindings) -ctx-) (get/long (get (<variable> index) var))) val))))))

(define-subr (while () fixed)
  (let ((tst  (k/car -args-))
        (prog -args-))
    (while (k/eval tst -ctx-)
      (let ((body prog))
        (while (is/pair (set body (k/cdr body)))
          (k/eval (get/head body) -ctx-))))))

(define-subr (if () fixed)
  (if (k/eval (k/car  -args-) -ctx-)
      (k/eval (k/cadr -args-) -ctx-)
    (let ((ans ()))
      (set -args- (k/cdr -args-))
      (while (is/pair (set -args- (k/cdr -args-)))
        (set ans (k/eval (get/head -args-) -ctx-)))
      ans)))

(define-subr (or () fixed)
  (let ((ans ()))
    (while (is/pair -args-)
      (and (set ans (k/eval (get/head -args-) -ctx-))
           (return ans))
      (set -args- (get/tail -args-)))))

(define-subr (and () fixed)
  (let ((ans symbol/true))
    (while (is/pair -args-)
      (or (set ans (k/eval (get/head -args-) -ctx-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-subr (quote 1 fixed)
  (get/head -args-))

(define-subr (not 1)
  (if (get/head -args-) () symbol/true))

(define-subr (fixed 1)
  (new-<fixed> (get/head -args-)))

(define-subr (variable 4)
  (new-<variable> (get/head -args-)
                  (get/head (set -args- (get/tail -args-)))
                  (get/head (set -args- (get/tail -args-)))
                  (get/head (get/tail -args-))))

(define-subr (environment 1)
  (let ((parent (get/head -args-)))
    (k/assert (is <env> parent))
    (new-<env> parent 0 (get/long (get (<env> offset) parent)))))

(define-subr (environment-define 3)
  (let ((env   (get/head -args-))
        (name  (get/head (set -args- (get/tail -args-))))
        (value (get/head (get/tail -args-))))
    (k/env/define env name value)))

;; -, +, *, and / all have some peculiarities that makes them somewhat resistant to macrology
(define-subr -
  (or (is/pair -args-) (k/error "operator '-' called with zero arguments"))
  (let ((result	(get/long (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (is/pair rest)
        (while (let ()
                 (set result (- result (get/long (get/head rest))))
                 (is/pair (set rest (get/tail rest)))))
      (set result (- result)))
    (new-<long> result)))

(define-subr +
  (let ((result	0)
        (rest	()))
    (when (is/pair -args-)
      (set result (get/long (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (is/pair rest)
      (set result (+ result (get/long (get/head rest))))
      (set rest (get/tail rest)))
    (new-<long> result)))

(define-subr /
  (or (is/pair -args-) (k/error "operator '/' called with zero arguments"))
  (let ((result	(get/long (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (is/pair rest)
        (while (let ()
                 (set result (/ result (get/long (get/head rest))))
                 (is/pair (set rest (get/tail rest)))))
      (set result (/ 1 result)))
    (new-<long> result)))

(define-subr *
  (let ((result	1)
        (rest	()))
    (when (is/pair -args-)
      (set result (get/long (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (is/pair rest)
      (set result (* result (get/long (get/head rest))))
      (set rest (get/tail rest)))
    (new-<long> result)))

(define-form define-binary-operator (op)
  `(define-subr (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (new-<long> (,op (get/long lhs) (get/long rhs))))))

(define-binary-operator bitwise-and)
(define-binary-operator bitwise-or)
(define-binary-operator bitwise-xor)

(define-subr (bitwise-not 1)
  (let ((value (get/head -args-)))
    (safety 1 (or (is/long value) (k/error "non-numeric argument for bitwise-not: "value)))
    (new-<long> (bitwise-not (get/long value)))))

(define-subr (bitwise-shift 2)
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
  `(define-subr (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (and (,op (get/long lhs) (get/long rhs))
            symbol/true))))

(define-relation <)
(define-relation <=)
(define-relation >=)
(define-relation >)

;; FIXME strcmp is broken for strings that contain zeros
(define-subr (= 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (get/type lhs)))
    (cond
      ((= type <long>)		(and (is/long rhs) (= (get/long lhs) (get/long rhs)) symbol/true))
      ((= type <string>)	(and (is <string> rhs) (not (libc/strcmp (get/string lhs) (get/string rhs))) symbol/true))
      (else                     (and (= lhs rhs) symbol/true)))))

(define-subr (!= 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (get/type lhs)))
    (cond
      ((= type <long>)		(and (is/long rhs) (!= (get/long lhs) (get/long rhs)) symbol/true))
      ((= type <string>)	(and (is <string> rhs) (libc/strcmp (get/string lhs) (get/string rhs))) symbol/true)
      (else                     (and (!= lhs rhs) symbol/true)))))

(define-subr (abort 0)
  (print-backtrace)
  (libc/flush-streams)
  (libc/abort))

(define-subr (exit 1)
  (let ((arg (get/head -args-)))
    (or (is/long arg)
        (k/error "argument to subr_exit is not a <long>: " arg))
    (when-at-expand feature/profiler
      (profiler/disable))
    (libc/flush-streams)
    (libc/exit (get/long arg))))

(define-subr (libc/fopen 2)
  (let ((path (get/head -args-))
        (mode (get/head (get/tail -args-))))
    (let ((stream (libc/fopen (get/string path) (get/string mode))))
      (and stream (new-<target-vm-pointer> stream)))))

(define-subr (libc/fclose 1)
  (let ((stream (get/head -args-)))
    (libc/fclose (get/tvmptr stream))
    ()))

(define-subr (libc/fgetc 1)
  (let ((stream	(get/head -args-))
        (c	(libc/fgetc (get/tvmptr stream))))
    (and (>= c 0)
         (new-<long> c))))

(define-subr (libc/fputc 2)
  (let ((char	(get/head -args-))
        (stream	(get/head (get/tail -args-))))
    (new-<long> (libc/fputc (get/long char) (get/tvmptr stream)))))

(define-subr (libc/format 2)
  (let ((ofmt (get/head -args-))
        (oarg (get/head (get/tail -args-))))
    (or (is <string> ofmt) (fatal "subr/libc/format: non-string format"))
    (let ((fmt (get/string ofmt))
          (typ (get/type oarg))
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

(define-subr (repl-stream 1)
  (let ((stream (get/head -args-)))
    ;;(or stream (set stream (get/variable-value var/*input*)))
    (k/repl-stream (get/tvmptr stream))))

(define-subr dump
  (while (is/pair -args-)
    (k/dump (get/head -args-))
    (set -args- (get/tail -args-))))

(define-subr print
  (while (is/pair -args-)
    (k/print (get/head -args-))
    (set -args- (get/tail -args-))))

(define-subr warn
  (while (is/pair -args-)
    (let* ((arg  (get/head -args-))
           (type (get/type arg)))
      (cond
        ((= type <string>) (libc/fprintf libc/stderr "%s" (get/string arg)))
        ((= type <symbol>) (libc/fprintf libc/stderr "%s" (get/symbol arg)))
        ((= type <long>)   (libc/fprintf libc/stderr "%ld" (get/long   arg)))
        (else
         ;; TODO
         (libc/fprintf libc/stderr "<unable to print {%p} of type %ld>" arg type))))
    (set -args- (get/tail -args-)))
  (libc/flush-streams))

(define-subr (apply 2)
  (k/apply (get/head -args-) (get/head (get/tail -args-)) -ctx-))

(define-subr eval
  (gc/let* ((e (or (k/cadr -args-) (new-<env> (get/globals) 1 0))))
    (k/expand-encode-eval (k/car -args-) e)))

(define-subr encode
  (k/encode (k/car -args-)
            (or (k/cadr -args-)
                (get (<context> env) -ctx-))))

(define-subr expand
  (k/expand (k/car -args-)
            (or (k/cadr -args-)
                (get (<context> env) -ctx-))))

(define-subr cons       (new-<pair> (k/car -args-) (k/cadr -args-)))
(define-subr (string 1)	(new-<string>-of-length (get/long (get/head -args-))))
(define-subr array      (new-<array> (and (is/long (k/car -args-)) (get/long (get/head -args-)))))
(define-subr form       (new-<form> (k/car -args-) (k/cadr -args-)))

(define-subr (allocate 2)
  (let ((type (get/head -args-))
        (size (get/head (get/tail -args-))))
    (safety 1 (k/assert (is/long type) "allocate: invalid type "type))
    (safety 1 (k/assert (is/long size) "allocate: invalid size "size))
    (gc/allocate (get/long type) (words-to-bytes (get/long size)))))

(define-subr (allocate-data 1)
  (let ((size (get/head -args-)))
    (safety 1 (k/assert (is/long size) "allocate-data: invalid size "size))
    (gc/allocate-opaque <data> (get/long size))))

(define-subr (type-of 1) (new-<long> (get/type (get/head -args-))))
(define-subr (string? 1) (and (is <string> (get/head -args-)) symbol/true))
(define-subr (symbol? 1) (and (is <symbol> (get/head -args-)) symbol/true))
(define-subr (pair? 1)   (and (is <pair>   (get/head -args-)) symbol/true))
(define-subr (array? 1)  (and (is <array>  (get/head -args-)) symbol/true)) ; TODO move to boot.l?
(define-subr (car 1)     (k/car (get/head -args-)))
(define-subr (cdr 1)     (k/cdr (get/head -args-)))

(define-subr (set-car 2)
  (let ((obj (get/head -args-)))
    ;; TODO assert the type
    (and (is/pair obj)
         (put (<pair> head) obj (get/head (get/tail -args-))))))

(define-subr (set-cdr 2)
  (let ((obj (get/head -args-)))
    (and (is/pair obj)
         (put (<pair> tail) obj (get/head (get/tail -args-))))))

(define-subr (copy-oops 3)
  (let ((from	(get/head -args-))
        (to	(get/head (get/tail -args-)))
        (count	(get/long (get/head (get/tail (get/tail -args-))))))
    (copy-oops from to count)
    ()))

(define-subr (oop-at 2)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 3 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (oop-at obj (get/long idx))))

(define-subr (set-oop-at 3)
  (let ((obj (get/head -args-))
        (idx (get/head (set -args- (get/tail -args-))))
        (val (get/head (get/tail -args-))))
    (safety 3 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (set-oop-at obj (get/long idx) val)))

(define-subr (address-of 1)
  ;; TODO what about when <long> is a tagged immediate and the address is truncated?
  ;; or return a target-vm-pointer here and define pointer arithmetics?
  ;; or implement various boxed data types and return a word-sized integer here?
  (new-<long> (get/head -args-)))

(define-subr (copy-bytes 3)
  (let ((from	(get/head -args-))
        (to	(get/head (get/tail -args-)))
        (count	(get/long (get/head (get/tail (get/tail -args-))))))
    (copy-bytes from to count)
    ()))

(define-subr (byte-at 2)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 3 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (new-<long> (byte-at obj (get/long idx)))))

(define-subr (set-byte-at 3)
  (let ((obj		(get/head -args-))
        (idx		(get/head (set -args- (get/tail -args-))))
        (val		(get/head (get/tail -args-)))
        (unboxed-val	(get/long val)))
    (safety 3 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (safety 1 (k/assert (and (<= unboxed-val 256) (<= 0 unboxed-val)) "set-byte-at: value is out of range: "unboxed-val))
    (set-byte-at obj (get/long idx) unboxed-val)))

(define-subr (array-length 1)
  (let ((arg (get/head -args-)))
    (safety 1 (k/assert (is <array> arg)))
    (get (<array> size) arg)))

(define-subr (string-length 1)
  (let ((arg (get/head -args-)))
    (safety 1 (k/assert (is <string> arg)))
    (get (<string> size) arg)))

(define-subr (array-at 2)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (get/tail -args-)))))
    (k/array-at arr idx)))

(define-subr (string-at 2)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (get/tail -args-)))))
    (new-<long> (k/string-at arr idx))))

(define-subr (set-array-at 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (set -args- (get/tail -args-)))))
        (val (get/head (get/tail -args-))))
    (set (k/array-at arr idx) val)
    val))

(define-subr (set-string-at 3)
  (let* ((arr (get/head -args-))
         (idx (get/long (get/head (set -args- (get/tail -args-)))))
         (val (get/head (get/tail -args-))))
    ;; NOTE set-k/string-at happily extends the string with a gap of zeores, so
    ;; we also assert here that idx is out of bounds at most by +1.
    (safety 1 (k/assert (<= idx (k/string-length arr))))
    (set (k/string-at arr idx) (get/long val))
    val))

(define-subr (array-insert 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (set -args- (get/tail -args-)))))
        (val (get/head (get/tail -args-))))
    (k/array-insert arr idx val)
    val))

(define-subr (string-insert 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (set -args- (get/tail -args-)))))
        (val (get/head (get/tail -args-))))
    (k/string-insert arr idx (get/long val))
    val))

(define-subr (string->symbol 1)
  (let ((arg (get/head -args-)))
    ;; FIXME this is too permissive, and returns nil when called with an unexpected type
    (if (is <symbol> arg)
        arg
      (and (is <string> arg)
           (k/intern (get/string arg))))))

(define-subr (symbol->string 1)
  (let ((arg (get/head -args-)))
    ;; FIXME this is too permissive, and returns nil when called with an unexpected type
    (if (is <string> arg)
        arg
      (and (is <symbol> arg)
           (new-<string>-from-cstring (get/symbol arg))))))

(define-subr (long->string 1)
  (let ((arg (get/head -args-)))
    (k/assert (is/long arg))
    (let ((buf (gc/allocate-opaque <data> 32))) ; safe up until 64 bits
      (libc/sprintf buf "%ld" (get/long arg))
      (new-<string>-from-cstring buf))))

(define-subr (string->long 1)
  (let ((arg (get/head -args-)))
    (k/assert (is <string> arg))
    (let* ((str		(get/string arg))
           (endptr	str)
           (result	(libc/strtol str (address-of endptr) 10)))
      (if (= (string-at endptr 0) ?\x00)
          (new-<long> result)
        (fatal1 "invalid number in string->long, libc/strtol failed for '%s'" str)))))

;; TODO is this the actual primitive that we want to publish? maybe a just read-form?
(define-subr read
  (if (= () -args-)
      (let ((obj (k/read libc/stdin)))
        (and (= k/+end+ obj) (set obj ()))
        obj)
    (let ((arg (k/car -args-)))
      (or (is <string> arg) (fatal1 "read: non-String argument: " arg))
      (let* ((path   (get/string arg))
             (stream (libc/fopen path "r")))
        ;; TODO error handling
        (if stream
            (let* ((head (new-<pair> () ()))
                   (tail head)
                   (obj  ()))
              (gc/protect (head obj)
                (while (!= k/+end+ (set obj (k/read stream)))
                  (set tail (put/tail tail (new-<pair> obj ())))))
              (libc/fclose stream)
              (get/tail head))
          ())))))

(define-subr (current-module 0)
  *module*)

(define-subr (set-current-module 1)
  (let ((module (get/head -args-)))
    (safety 1 (k/assert (is <module> module) "set-current-module: called with not a <module>: "module))
    (k/set-current-module module))
  ())

(define-subr (create-module 0)
  (new-<module>))

(define-subr (eval-in-module 2)
  (let ((new-module (get/head -args-))
        (form (get/head (get/tail -args-)))
        (previous-module *module*))
    (safety 1 (k/assert (is <module> new-module) "eval-in-module: called with not a <module>: "new-module))
    (debug (libc/printf "eval-in-module: form ") (k/dumpln form))
    (k/set-current-module new-module)
    (gc/let* ((result (k/expand-encode-eval form (get/globals* new-module))))
      (k/set-current-module previous-module)
      (debug (libc/printf "eval-in-module is done\n"))
      result)))

(when-at-expand (= target/machine "IA-32")
  (define-subr (call-IA-32-machine-code 1)
    (let ((data (get/head -args-)))
      (debug (libc/printf "call-IA-32-machine-code will call %p\n" data))
      (k/assert (is <data> data) "call-IA-32-machine-code: cannot call object of type "(get/type data)", printing as "data)
      (data)
      (debug (libc/printf "call-IA-32-machine-code got back the control from %p\n" data))
      ())))

(when-at-expand (= target/machine "x86-64")
  (define-subr (call-x86-64-machine-code 1)
    (let ((data (get/head -args-)))
      (debug (libc/printf "call-x86-64-machine-code will call %p\n" data))
      (k/assert (is <data> data) "call-x86-64-machine-code: cannot call object of type "(get/type data)", printing as "data)
      (data)
      (debug (libc/printf "call-x86-64-machine-code got back the control from %p\n" data))
      ())))
