;;; -*- mode: lisp; coding: us-ascii -*-

(define-primitive-function (define () fixed) ((variable <variable>) value-form)
  (let ((value (eval value-form -ctx-)))
    (put (<variable> value) variable value)
    ;; maybe set the <expr>'s name slot
    (when-at-expand feature/track-expr-names
      (let ((tmp value))
        (when (is <form> tmp)
          (set tmp (get (<form> function) tmp)))
        (when (and (is <expr> tmp)
                   (not (get (<expr> name) tmp)))
          (put (<expr> name) tmp (get (<variable> name) variable)))))
    value))

(define-primitive-function (lambda () fixed) ((env <env>) parameters . body)
  (assert (or (not parameters) (is <variable> parameters) (pair? parameters)) "lambda primitive-function: parameters is of wrong type: " parameters)
  (new-<expr> parameters body env -ctx-))

(define-primitive-function (let () fixed) (env bindings . body)
  (let ((locals (get (<context> bindings) -ctx-)))
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

(define-primitive-function (set () fixed) ((var <variable>) value-form)
  (debug (libc/printf "SET ") (print var) (print value-form) (libc/printf " IN ") (println -ctx-))
  (let ((value (eval value-form -ctx-)))
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

(define-primitive-function (while () fixed) _
  (let ((test	(car -args-))
        (prog	-args-))
    (while (eval test -ctx-)
      (let ((body prog))
        (while (pair? (set body (cdr body)))
          (eval (get/head body) -ctx-))))))

(define-primitive-function (if () fixed) (test then . else)
  (if (eval test -ctx-)
      (eval then -ctx-)
    (let ((ans ()))
      (while (pair? else)
        (set ans (eval (get/head else) -ctx-))
        (set else (cdr else)))
      ans)))

(define-primitive-function (or () fixed) _
  (let ((ans ()))
    (while (pair? -args-)
      (and (set ans (eval (get/head -args-) -ctx-))
           (return ans))
      (set -args- (get/tail -args-)))))

(define-primitive-function (and () fixed) _
  (let ((ans symbol/true))
    (while (pair? -args-)
      (or (set ans (eval (get/head -args-) -ctx-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-primitive-function (quote () fixed) (thing)
  thing)

(define-primitive-function (not ()) (thing)
  (if thing () symbol/true))

;; -, +, *, and / all have some peculiarities that makes them somewhat resistant to macrology
(define-primitive-function (- ()) _
  (or (pair? -args-) (error "operator '-' called with zero arguments"))
  (let ((result	(get/long (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (- result (get/long (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (- result)))
    (new-<long> result)))

(define-primitive-function (+ ()) _
  (let ((result	0)
        (rest	()))
    (when (pair? -args-)
      (set result (get/long (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (pair? rest)
      (set result (+ result (get/long (get/head rest))))
      (set rest (get/tail rest)))
    (new-<long> result)))

(define-primitive-function (/ ()) _
  (or (pair? -args-) (error "operator '/' called with zero arguments"))
  (let ((result	(get/long (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (/ result (get/long (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (/ 1 result)))
    (new-<long> result)))

(define-primitive-function (* ()) _
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
  `(define-primitive-function (,op ()) ((lhs <long>) (rhs <long>))
     (new-<long> (,op lhs rhs))))

(define-binary-operator bitwise-and)
(define-binary-operator bitwise-or)
(define-binary-operator bitwise-xor)

(define-primitive-function (bitwise-not ()) ((value <long>))
  (new-<long> (bitwise-not value)))

(define-primitive-function (bitwise-shift ()) ((value <long>) (shift <long>))
  (let* ((bit-length-of-<long> 31) ; TODO FIXME arrange for using the actual value here
         (max-shift (- bit-length-of-<long> 1)))
    (new-<long>
     (cond
       ((< max-shift shift)	0)
       ((< 0 shift)		(<< value shift))
       ((< shift (- max-shift))	(if (< value 0) -1 0))
       ((< shift 0)		(>> value (- shift)))
       ((= 0 shift)		value)))))

(define-form define-relation (op)
  `(define-primitive-function (,op ()) ((lhs <long>) (rhs <long>))
     (and (,op lhs rhs)
          symbol/true)))

(define-relation <)
(define-relation <=)
(define-relation >=)
(define-relation >)

;; FIXME strcmp is inappropriate for strings that contain zeros
;; FIXME restore arity check
(define-primitive-function (= ()) _
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (type-of lhs)))
    (cond
      ((= type <long>)		(and (long? rhs) (= (get/long lhs) (get/long rhs)) symbol/true))
      ((= type <string>)	(and (string? rhs) (not (libc/strcmp (get/string lhs) (get/string rhs))) symbol/true))
      (else                     (and (= lhs rhs) symbol/true)))))

;; FIXME restore arity check
(define-primitive-function (!= ()) _
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (type-of lhs)))
    (cond
      ((= type <long>)		(and (long? rhs) (!= (get/long lhs) (get/long rhs)) symbol/true))
      ((= type <string>)	(and (string? rhs) (libc/strcmp (get/string lhs) (get/string rhs))) symbol/true)
      (else                     (and (!= lhs rhs) symbol/true)))))

(define-primitive-function (exit ()) ((exit-code <long> 0))
  (when-at-expand feature/profiler
    (profiler/disable))
  (libc/flush-streams)
  (libc/exit exit-code))

(define-primitive-function (libc/fopen ()) ((path <string>) (mode <string>))
  (let ((stream (libc/fopen path mode)))
    (and stream (new-<target-vm-pointer> stream))))

(define-primitive-function (libc/fclose ()) ((stream <target-vm-pointer>))
  (libc/fclose stream))

(define-primitive-function (libc/fgetc ()) ((stream <target-vm-pointer>))
  (let ((c (libc/fgetc stream)))
    (and (>= c 0)
         (new-<long> c))))

(define-primitive-function (libc/fputc ()) ((char <long>) (stream <target-vm-pointer>))
  (new-<long> (libc/fputc char stream)))

(define-primitive-function (libc/format ()) ((fmt <string>) oarg)
  (let ((typ (type-of oarg))
        (arg ()))
    (cond
      ((= typ <undefined>))
      ((= typ <long>)		(set arg (get/long oarg)))
      ((= typ <string>)		(set arg (get/string oarg)))
      ((= typ <symbol>)		(set arg (get/symbol oarg)))
      (else			(set arg oarg)))
    (let ((size 100)
          (result ()))
      (gc/let* ((buf ()))
        (while (not result)
          (set buf (allocate-data size))
          (let ((n (libc/snprintf buf size fmt arg)))
            (if (and (<= 0 n)
                     (< n size))
                (set result (new-<string>-from-cstring buf))
              (set size (* size 2))))))
      result)))

;; TODO which one is the actual primitive that we want to publish? maybe just a read-form?
(define-primitive-function (read ()) _
  (if (= () -args-)
      (let ((obj (read libc/stdin)))
        (when (= +end+ obj)
          (set obj ()))
        obj)
    (let ((arg (car -args-)))
      (or (string? arg) (fatal1 "read: argument is not a <string> "arg))
      (let ((stream (libc/fopen (get/string arg) "r")))
        ;; TODO error handling
        (when stream
          (gc/let* ((head (cons () ()))
                    obj)
            (let ((tail head))      ; TODO use collecting macro
              (while (!= +end+ (set obj (read stream)))
                (set tail (put/tail tail (cons obj ()))))
              (libc/fclose stream)
              (get/tail head))))))))

(define-primitive-function (load ()) (path)
  (let* ((stream	(or (cond
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

(define-primitive-function (dump ()) _
  (list-do arg -args-
    (dump arg))
  (first -args-))

(define-primitive-function (print ()) _
  (list-do arg -args-
    (print arg))
  (first -args-))

(define-primitive-function (warn ()) _
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

(define-primitive-function (eval ()) _
  (gc/let* ((env (or (cadr -args-)
                     (environment (module-env *module*) 1 0))))
    ;; TODO resolve this naming anomaly somehow
    (expand-encode-eval (car -args-) env)))

(define-primitive-function (type-of ())	(thing) (new-<long> (type-of thing)))
(define-primitive-function (string? ())	(thing) (and (string? thing) symbol/true))
(define-primitive-function (symbol? ())	(thing) (and (symbol? thing) symbol/true))
(define-primitive-function (pair? ())		(thing) (and (pair?   thing) symbol/true))
(define-primitive-function (array? ())		(thing)	(and (array?  thing) symbol/true))

(define-primitive-function set-car ((pair <pair>) value)
  (put (<pair> head) pair value))

(define-primitive-function set-cdr ((pair <pair>) value)
  (put (<pair> tail) pair value))

(define-primitive-function copy-oops		(from to (wordcount <long>)))
(define-primitive-function oop-at		(base (index <long>)))
(define-primitive-function set-oop-at		(base (index <long>) value))
(define-primitive-function copy-bytes		(from to (count <long>)))

(define-primitive-function byte-at (base (index <long>))
  (new-<long> (byte-at base index)))

(define-primitive-function set-byte-at (base (index <long>) (value <long>))
  (safety 1 (assert (and (<= value 256) (<= 0 value)) "set-byte-at: value is out of range: "(new-<long> value)))
  (set (byte-at base index) value))

(define-primitive-function (address-of ()) (thing)
  ;; TODO what about when <long> is a tagged immediate and the address is truncated?
  ;; or return a target-vm-pointer here and define pointer arithmetics?
  ;; or implement various boxed data types and return a word-sized integer here?
  (new-<long> thing))

(define-primitive-function (array-length ()) ((arg <array>))
  (get (<array> size) arg))

(define-primitive-function (string-length ()) ((arg <string> _ nounbox))
  (get (<string> size) arg))

(define-primitive-function (array-at ()) ((array <array>) (index <long>))
  (array-at array index))

(define-primitive-function (string-at ()) ((string <string> _ nounbox) (index <long>))
  (new-<long> (string-at string index)))

;; adding [set-]char-at to the evaluator makes it source-level compatible with the level-shifted code, and with that enables us to load files like buffer.l into both worlds
(define-primitive-function (char-at ()) ((string <string> _ nounbox) (index <long>))
  (new-<long> (string-at string index)))

(define-primitive-function (set-array-at ()) ((array <array>) (index <long>) value)
  (set (array-at array index) value))

(define-primitive-function (set-string-at ()) ((string <string> _ nounbox) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 1 (assert (<= index (string-length string))))
  (set (string-at string index) value)
  (new-<long> value))

(define-primitive-function (set-char-at ()) ((string <string> _ nounbox) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 1 (assert (<= index (string-length string))))
  (safety 1 (assert (and (<= value 256) (<= 0 value)) "set-char-at: value is out of range: "(new-<long> value)))
  (set (string-at string index) value)
  (new-<long> value))

(define-primitive-function (array-insert ()) ((array <array>) (index <long>) value))

(define-primitive-function (string-insert ()) ((string <string> _ nounbox) (index <long>) (value <long>))
  (safety 1 (assert (and (<= value 256) (<= 0 value)) "string-insert: value is out of range: "(new-<long> value)))
  (string-insert string index value)
  (new-<long> value))

(define-primitive-function (array-append ()) ((array <array>) value))

(define-primitive-function (string-append ()) ((string <string> _ nounbox) (value <long>))
  (safety 1 (assert (and (<= value 256) (<= 0 value)) "string-append: value is out of range: "(new-<long> value)))
  (string-append string value)
  (new-<long> value))

(define-primitive-function symbol->string (symbol)
  ;; FIXME isn't this too permissive? enable type check at the arg, and delete the if... and then fix the code that relies on this.
  (if (string? symbol)
      symbol
    (new-<string>-from-cstring (get/symbol symbol))))

(define-primitive-function long->string ((arg <long>))
  (let ((buf (allocate-data 32))) ; safe up until 64 bits
    (libc/sprintf buf "%ld" arg)
    (new-<string>-from-cstring buf)))

(define-primitive-function string->long ((str <string>))
  (let* ((endptr	str)
         (result	(libc/strtol str (address-of endptr) 10)))
    (if (= (char-at endptr 0) ?\x00)
        (new-<long> result)
      (error "invalid number in string->long, libc/strtol has failed for string " (new-<string>-from-cstring str)))))

(define-primitive-function (create-module ()) ((name <string> _ nounbox))
  (new-<module> name))

(define-primitive-function (eval-in-module ()) ((module <module>) form)
  (debug (libc/printf "eval-in-module: form ") (dumpln form))
  (gc/let* ((env (environment (module-env module) 1 0))) ; errr, why not straight in the module's env?
    (with-current-module module
      (expand-encode-eval form env))))

(when-at-expand (= +architecture+ 'IA-32)
  (define-primitive-function call-IA-32-machine-code (data)
    (debug (libc/printf "call-IA-32-machine-code will call %p\n" data))
    (assert (is <data> data) "call-IA-32-machine-code: cannot call object of type "(type-of data)", printing as "data)
    (data)
    (debug (libc/printf "call-IA-32-machine-code got back the control from %p\n" data))
    ()))

(when-at-expand (= +architecture+ 'x86-64)
  (define-primitive-function call-x86-64-machine-code (data)
    (debug (libc/printf "call-x86-64-machine-code will call %p\n" data))
    (assert (is <data> data) "call-x86-64-machine-code: cannot call object of type "(type-of data)", printing as "data)
    (data)
    (debug (libc/printf "call-x86-64-machine-code got back the control from %p\n" data))
    ()))

(when-at-expand feature/debug-output
  (define-primitive-function enable-debug-output	() (set *debug-output-enabled?* true))
  (define-primitive-function disable-debug-output	() (set *debug-output-enabled?* false)))
