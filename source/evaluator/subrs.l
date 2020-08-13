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
      (put <variable> value var val))))

(define-subr (defined? 1)
  (let ((name (k/car -args-))
        (env (or (k/cadr -args-) (get/globals))))
    (k/env/lookup-variable env name)))

(define-subr (lambda () fixed)
  (new-<expr> -args- -ctx-))

(define-subr (let () fixed)
  (let* ((tmp      ())
         (bindings (k/cadr -args-))
         (locals   (get <context> bindings -ctx-))
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
              (k/set-array-at locals (get/long (get <variable> index var)) tmp))))
        (set bindings (get/tail bindings)))
      (set tmp ())
      (while (is/pair body)
        (set tmp (k/eval (get/head body) -ctx-))
        (set body (get/tail body))))
    tmp))

(define-subr (set 2 fixed)
  ;;(printf "SET ") (k/print args) (libc/printf " IN ") (k/println -ctx-)
  (let ((var (k/car -args-)))
    (or (is <variable> var)
        (let ()
          ;; FIXME? use k/error? why the dumpln? test it... was: (k/error "undefined variable: (set "-args-")")
          (libc/printf "\ncannot set undefined variable: ")
          (k/dumpln var)
          (fatal "aborting")))
    (let ((val (k/eval (k/cadr -args-) -ctx-)))
      (if (global-variable? var)
          (put <variable> value var val)
        (let ((delta (- (get/long (get <env> level (get <context>  env -ctx-)))
                        (get/long (get <env> level (get <variable> env var))))))
          (while (< 0 delta)
            (set -ctx- (get <context> home -ctx-))
            (set delta (- delta 1)))
          (k/set-array-at (get <context> bindings -ctx-) (get/long (get <variable> index var)) val))))))

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
  (let ((ans symbol/t))
    (while (is/pair -args-)
      (or (set ans (k/eval (get/head -args-) -ctx-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-subr (quote 1 fixed)
  (k/car -args-))

(define-subr (not 1)
  ;; TODO wouldn't it be nicer if we returned here something that self-evaluates?
  (if (k/car -args-) () symbol/t))

(define-subr (fixed 1)
  (new-<fixed> (k/car -args-)))

(define-subr (variable 4)
  (new-<variable> (k/car -args-) (k/cadr -args-) (k/caddr -args-) (k/cadddr -args-)))

(define-subr (environment 1)
  (let ((parent (k/car -args-)))
    (k/assert (is <env> parent))
    (new-<env> parent 0 (get/long (get <env> offset parent)))))

(define-subr (environment-define 3)
  (let ((env   (k/car -args-))
        (name  (k/cadr -args-))
        (value (k/caddr -args-)))
    (k/assert (is <env> env))
    (k/assert (is <symbol> name))
    (let* ((bindings (get <env> bindings env))
           (offset (get/long (get <env> offset env)))
           (var (new-<variable> name value env offset)))
      (gc/protect (var)
        (put <env> offset env (new-<long> (+ offset 1)))
        (k/array-append bindings var)
        var))))

(define-subr -
  (safety 1 (or (and (k/car -args-) (not (k/cddr -args-))) (k/error "operator '-' expected 1 or 2 arguments, got: " -args-)))
  (let ((lhs (get/head -args-))
        (rhs (get/tail -args-)))
    (if (is/pair rhs)
        (let ()
          (set rhs (get/head rhs))
          (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (- "lhs" "rhs")")))
          (new-<long> (- (get/long lhs) (get/long rhs))))
      (safety 1 (or (is/long lhs) (k/error "non-numeric argument: (- "lhs")")))
      (new-<long> (- (get/long lhs))))))

(define-form define-binary (op)
  `(define-subr (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (new-<long> (,op (get/long lhs) (get/long rhs))))))

(define-binary &)
(define-binary |)
(define-binary ^)
(define-binary +)
(define-binary *)
(define-binary /)
(define-binary <<)
(define-binary >>)

(define-form define-relation (op)
  `(define-subr (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (and (,op (get/long lhs) (get/long rhs))
            symbol/t))))

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
      ((= type k/<long>)        (and (is/long rhs) (= (get/long lhs) (get/long rhs)) symbol/t))
      ((= type k/<string>)      (and (is <string> rhs) (not (libc/strcmp (get/string lhs) (get/string rhs))) symbol/t))
      (else                     (and (= lhs rhs) symbol/t)))))

(define-subr (!= 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (get/type lhs)))
    (cond
      ((= type k/<long>)        (and (is/long rhs) (!= (get/long lhs) (get/long rhs)) symbol/t))
      ((= type k/<string>)      (and (is <string> rhs) (libc/strcmp (get/string lhs) (get/string rhs))) symbol/t)
      (else                     (and (!= lhs rhs) symbol/t)))))

(define-subr (abort 0)
  (print-backtrace)
  (libc/flush-streams)
  (libc/abort))

(define-subr (exit 1)
  (let ((arg (k/car -args-)))
    (or (is/long arg)
        (k/error "argument to subr_exit is not a <long>: " arg))
    (libc/flush-streams)
    (libc/exit (get/long arg))))

(define-subr (libc/fopen 1)
  (let ((path (k/car -args-)))
    (let ((stream (libc/fopen (get/string path) "rb")))
      (and stream (new-<target-vm-pointer> stream)))))

(define-subr (libc/fclose 1)
  (let ((stream (k/car -args-)))
    (libc/fclose (get/tptr stream))
    ()))

(define-subr libc/fgetc
  (let ((stream (k/car -args-)))
    (or stream (set stream (get/variable-value var/*input*)))
    (let ((c (libc/fgetc (get/tptr stream))))
      (and (>= c 0)
           (new-<long> c)))))

(define-subr libc/fputc
  (let ((stream (k/car -args-))
        (obj (k/cadr -args-)))
    (or stream (set stream (get/variable-value var/*input*)))
    (new-<long> (libc/fputc (get/tptr stream) (get/long obj)))))

(define-subr (libc/format 2)
  (let ((ofmt (k/car -args-))
        (oarg (k/cadr -args-)))
    (or (is <string> ofmt) (fatal "subr/libc/format: non-string format"))
    (let ((fmt (get/string ofmt))
          (typ (get/type oarg))
          (arg ()))
      (cond
        ((= typ k/<undefined>))
        ((= typ k/<long>)	(set arg (get/long oarg)))
        ((= typ k/<string>)	(set arg (get/string oarg)))
        ((= typ k/<symbol>)	(set arg (get/symbol oarg)))
        (else			(set arg oarg)))
      (let ((size 100)
            (p)
            (np))
        (or (set p (libc/malloc size))
            (return "out of memory"))
        (while 1
          (let ((n (libc/snprintf p size fmt arg)))
            (and (<= 0 n) (< n size)
                 (let ((ans (new-<string>-from-cstring p)))
                   (libc/free p)
                   (return ans)))
            (set size (* size 2)))
          (or (set np (libc/realloc p size))
              (let ()
                (libc/free p)
                (return "out of memory")))
          (set p np))))))

(define-subr repl-stream
  (let ((stream (k/car -args-)))
    (or stream (set stream (get/variable-value var/*input*)))
    (k/repl-stream (get/tptr stream))))

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
        ((= type k/<string>) (libc/fprintf libc/stderr "%s" (get/string arg)))
        ((= type k/<symbol>) (libc/fprintf libc/stderr "%s" (get/symbol arg)))
        ((= type k/<long>)   (libc/fprintf libc/stderr "%d" (get/long   arg)))
        (else
         ;; TODO
         (libc/fprintf libc/stderr "<unable to print {%p} of type %d>" arg type))))
    (set -args- (get/tail -args-))))

(define-subr (apply 2)
  (k/apply (k/car -args-) (k/cadr -args-) -ctx-))

(define-subr eval
  (gc/let* ((e (or (k/cadr -args-) (new-<env> (get/globals) 1 0))))
    (k/expand-encode-eval (k/car -args-) e)))

(define-subr encode
  (k/encode (k/car -args-)
            (or (k/cadr -args-)
                (get <context> env -ctx-))))

(define-subr expand
  (k/expand (k/car -args-)
            (or (k/cadr -args-)
                (get <context> env -ctx-))))

(define-subr cons       (new-<pair> (k/car -args-) (k/cadr -args-)))
(define-subr (string 1) (new-<string>-of-length (and (is/long (k/car -args-)) (get/long (get/head -args-)))))
(define-subr array      (new-<array> (and (is/long (k/car -args-)) (get/long (get/head -args-)))))
(define-subr form       (new-<form> (k/car -args-) (k/cadr -args-)))

(define-subr (allocate 2)
  (let ((type (get/head -args-))
        (size (get/head (get/tail -args-))))
    (safety 1 (k/assert (is/long type) "allocate: invalid type "type))
    (safety 1 (k/assert (is/long size) "allocate: invalid size "size))
    (%new-object (get/long type) (words-to-bytes (get/long size)))))

(define-subr (type-of 1) (and -args- (new-<long> (get/type (k/car -args-)))))
(define-subr (string? 1) (and (is <string> (k/car -args-)) symbol/t))
(define-subr (symbol? 1) (and (is <symbol> (k/car -args-)) symbol/t))
(define-subr (pair? 1)   (and (is <pair>   (k/car -args-)) symbol/t))
(define-subr (array? 1)  (and (is <array>  (k/car -args-)) symbol/t)) ; TODO move to boot.l?
(define-subr (car 1)     (k/car (k/car -args-)))
(define-subr (cdr 1)     (k/cdr (k/car -args-)))

(define-subr (set-car 2)
  (let ((obj (k/car -args-)))
    (and (is/pair obj)
         (put <pair> head obj (k/cadr -args-)))))

(define-subr (set-cdr 2)
  (let ((obj (k/car -args-)))
    (and (is/pair obj)
         (put <pair> tail obj (k/cadr -args-)))))

(define-subr (oop-at 2)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 1 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (oop-at obj (get/long idx))))

(define-subr (set-oop-at 3)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (set-oop-at obj (get/long idx) val)))

(define-subr (array-length 1)
  (let ((arg (k/car -args-)))
    (safety 1 (k/assert (is <array> arg)))
    (get <array> size arg)))

(define-subr (string-length 1)
  (let ((arg (k/car -args-)))
    (safety 1 (k/assert (is <string> arg)))
    (get <string> size arg)))

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
        (idx (get/long (get/head (get/tail -args-))))
        (val (get/head (get/tail (get/tail -args-)))))
    (k/set-array-at arr idx val)))

(define-subr (set-string-at 3)
  (let* ((arr (get/head -args-))
         (idx (get/long (get/head (get/tail -args-))))
         (val (get/long (get/head (get/tail (get/tail -args-))))))
    ;; NOTE k/set-string-at happily extends the string with a gap of zeores, so
    ;; we also assert here that idx is out of bounds at most by +1.
    (safety 1 (k/assert (<= idx (k/string-length arr))))
    (k/set-string-at arr idx val)))

(define-subr (array-insert 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (get/tail -args-))))
        (val (get/head (get/tail (get/tail -args-)))))
    (k/array-insert arr idx val)))

(define-subr (string-insert 3)
  (let ((arr (get/head -args-))
        (idx (get/long (get/head (get/tail -args-))))
        (val (get/long (get/head (get/tail (get/tail -args-))))))
    (k/string-insert arr idx val)))

(define-subr (string->symbol 1)
  (let ((arg (k/car -args-)))
    ;; FIXME this is too permissive, and returns nil when called with an unexpected type
    (if (is <symbol> arg)
        arg
      (and (is <string> arg)
           (k/intern (get/string arg))))))

(define-subr (symbol->string 1)
  (let ((arg (k/car -args-)))
    ;; FIXME this is too permissive, and returns nil when called with an unexpected type
    (if (is <string> arg)
        arg
      (and (is <symbol> arg)
           (new-<string>-from-cstring (get <symbol> _bits arg))))))

(define-subr (long->string 1)
  (let ((arg (k/car -args-)))
    (if (is <string> arg)
        arg
      (and (is/long arg)
           (let ((buf (libc/malloc 32)))
             (libc/sprintf buf "%ld" (get/long arg))
             (let ((result (new-<string>-from-cstring buf)))
               (libc/free buf)
               result))))))

;; TODO is this the actual primitive that we want to publish? maybe a just read-form?
(define-subr read
  (if (= () -args-)
      (let ((obj (k/read libc/stdin)))
        (and (= k/+done+ obj) (set obj ()))
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
                (while (!= k/+done+ (set obj (k/read stream)))
                  (set tail (put/tail tail (new-<pair> obj ())))))
              (libc/fclose stream)
              (get/tail head))
          ())))))

(define-subr (current-module 0)
  *module*)

(define capture-well-known-vm-values) ; forward
(define populate-module-with-primitives) ; forward

(define-function k/set-current-module (module)
  (debug (libc/printf "k/set-current-module {%p}\n" module))
  (set *module* module)
  (capture-well-known-vm-values))

(define-subr (set-current-module 1)
  (let ((module (k/car -args-)))
    (safety 1 (k/assert (is <module> module) "set-current-module: called with not a <module>: "module))
    (k/set-current-module module))
  ())

(define-subr (create-module 0)
  (gc/let* ((module (new-<module>)))
    (populate-module-with-primitives module)
    module))

(define-subr (eval-in-module 2)
  (let ((new-module (k/car -args-))
        (form (k/cadr -args-))
        (previous-module *module*))
    (safety 1 (k/assert (is <module> new-module) "eval-in-module: called with not a <module>: "new-module))
    (debug (libc/printf "eval-in-module: form ") (k/dumpln form))
    (k/set-current-module new-module)
    (gc/let* ((result (k/expand-encode-eval form (get/globals* new-module))))
      (k/set-current-module previous-module)
      (debug (libc/printf "eval-in-module is done\n"))
      result)))
