;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion-min.l")

(define-primitive-function (define () fixed) ((variable <variable>) value-form)
  (let ((value (eval value-form -ctx-)))
    (set (<variable>-value variable) value)
    ;; maybe set the <expr>'s name slot
    (when-at-expand feature/track-expr-names
      (let ((tmp value))
        (when (is <form> tmp)
          (set tmp (<form>-function tmp)))
        (when (and (is <expr> tmp)
                   (not (<expr>-name tmp)))
          (set (<expr>-name tmp) (<variable>-name variable)))))
    value))

;; TODO ideally, but it needs a gc/let*:(define-primitive-function (eval ()) (form (env <env> (environment (module-env *module*) 1 0)))
(define-primitive-function (eval ()) _
  (let ((env (if (cdr -args-) ; let's not tolerate being called with nil env
                 (cadr -args-)
               (module-env *module*))))
    (let* ((toplevel-env?	(= 0 (unbox <long> (<env>-level env))))
           (prev-globals	(module-env *module*))
           result)
      (when toplevel-env?
        (set (<variable>-value (<module>-globals *module*)) env)
        (capture-well-known-module-values))
      (set result (gc/let* ((child-env (environment env 1 0)))
                    ;; TODO resolve this naming anomaly somehow
                    (expand-encode-eval (car -args-) child-env)))
      (when toplevel-env?
        (set (<variable>-value (<module>-globals *module*)) prev-globals)
        (capture-well-known-module-values))
      result)))

(define-primitive-function (eval-in-module ()) ((module <module>) form)
  (verbosity 2 (debug-print ";;; ? "module" "form))
  (gc/let* ((env (environment (module-env module) 1 0))) ; errr, why not straight in the module's env?
    (with-current-module module
      (expand-encode-eval form env))))

(define-primitive-function (lambda () fixed) ((env <env>) parameters . body)
  (assert (or (not parameters) (is <variable> parameters) (pair? parameters)) "lambda primitive-function: parameters is of wrong type: " parameters)
  (expr parameters body env -ctx-))

(define-primitive-function (let () fixed) (env bindings . body)
  (let ((locals (<context>-bindings -ctx-)))
    (gc/let* (tmp)
      (list-do binding bindings
        (when (pair? binding)
          (let ((var  (get/head binding))
                (prog (get/tail binding)))
            (debug-print "let primitive-function is initializing var "var" in context "-ctx-)
            (set tmp ())
            (while (pair? prog)
              (set tmp (eval (get/head prog) -ctx-))
              (set prog (get/tail prog)))
            (debug-print "let primitive-function is setting var "var" to value "tmp" in context "-ctx-)
            (set (array-at locals (unbox <long> (<variable>-index var))) tmp))))
      (set tmp ())
      (list-do exp body
        (set tmp (eval exp -ctx-)))
      tmp)))

(define-primitive-function (set () fixed) ((var <variable>) value-form)
  (debug-print "SET "var" = "value-form" IN "-ctx-)
  (let ((value (eval value-form -ctx-)))
    (if (global-variable? var)
        (set (<variable>-value var) value)
      (let ((delta (- (unbox <long> (<env>-level (<context>-env -ctx-)))
                  (unbox <long> (<env>-level (<variable>-env var))))))
        (debug-print "set primitive-function is writing local var "var" with delta "(box <long> delta))
        (while (< 0 delta)
          (set -ctx- (<context>-home -ctx-))
          (decr delta))
        (let ((index (unbox <long> (<variable>-index var))))
          (debug-print "set primitive-function is setting local var in context "-ctx-" at index "(box <long> index)", to value "value)
          (set (array-at (<context>-bindings -ctx-) index) value))))))

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
  (let ((result	(unbox <long> (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (- result (unbox <long> (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (- result)))
    (box <long> result)))

(define-primitive-function (+ ()) _
  (let ((result	0)
        (rest	()))
    (when (pair? -args-)
      (set result (unbox <long> (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (pair? rest)
      (set result (+ result (unbox <long> (get/head rest))))
      (set rest (get/tail rest)))
    (box <long> result)))

(define-primitive-function (/ ()) _
  (or (pair? -args-) (error "operator '/' called with zero arguments"))
  (let ((result	(unbox <long> (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (/ result (unbox <long> (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (/ 1 result)))
    (box <long> result)))

(define-primitive-function (* ()) _
  (let ((result	1)
        (rest	()))
    (when (pair? -args-)
      (set result (unbox <long> (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (pair? rest)
      (set result (* result (unbox <long> (get/head rest))))
      (set rest (get/tail rest)))
    (box <long> result)))

(define-form define-binary-operator (op)
  `(define-primitive-function (,op ()) ((lhs <long>) (rhs <long>))
     (box <long> (,op lhs rhs))))

(define-binary-operator bitwise-and)
(define-binary-operator bitwise-or)
(define-binary-operator bitwise-xor)

(define-primitive-function (bitwise-not ()) ((value <long>))
  (box <long> (bitwise-not value)))

(define-primitive-function (bitwise-shift ()) ((value <long>) (shift <long>))
  (box <long> (bitwise-shift value shift)))

(define-form define-relation (op)
  `(define-primitive-function (,op ()) ((lhs <long>) (rhs <long>))
     (and (,op lhs rhs)
          symbol/true)))

(define-relation <)
(define-relation <=)
(define-relation >=)
(define-relation >)

;; FIXME restore arity check
(define-primitive-function (= ()) _
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-))))
    (typecase lhs
      (<long>		(and (long? rhs)
                             (= (unbox <long> lhs)
                                (unbox <long> rhs))
                             symbol/true))
      (<string>		(and (string? rhs)
                             (= 0 (compare-strings lhs rhs))
                             symbol/true))
      (else		(and (= lhs rhs)
                             symbol/true)))))

(define-primitive-function (exit ()) ((exit-code <long> 0))
  (when-at-expand feature/profiler
    (profiler/disable))
  (platform/flush-streams)
  (platform/halt exit-code))

(define-primitive-function (warn ()) _
  (list-do arg -args-
    (do-print *error-output* arg false))
  (platform/flush-streams))

(define-primitive-function (type-of ())	(thing) (box <long> (type-of thing)))
(define-primitive-function (string? ())	(thing) (and (string? thing) symbol/true))
(define-primitive-function (symbol? ())	(thing) (and (symbol? thing) symbol/true))
(define-primitive-function (pair?   ())	(thing) (and (pair?   thing) symbol/true))
(define-primitive-function (array?  ())	(thing)	(and (array?  thing) symbol/true))

(define-primitive-function set-car ((pair <pair>) value)
  (set (<pair>-head pair) value))

(define-primitive-function set-cdr ((pair <pair>) value)
  (set (<pair>-tail pair) value))

(define-form define-oop-at-primfn (name args)
  `(define-primitive-function (,name ()) (base (wordindex <long>) ,@args)
     (safety 2
       (let ((header (gc/header-of base)))
         (assert (and (gc/valid-header-canary? header)
                      (<= 0 wordindex)
                      (<= (words-to-bytes (+ 1 wordindex)) (<header>-size header)))
                 ,(concat-string (symbol->string name) ": trying to access beyond the gc chunk boundaries"))))
     (,name base wordindex ,@args)))

(define-oop-at-primfn oop-at		())
(define-oop-at-primfn set-oop-at	(value))

;; (define-primitive-function (copy-oops ()) (from to (wordcount <long>))
;;   (error "copy-oops: who called me in interpreted code?! TODO i need proper bounds checking added.")
;;   (copy-oops from to wordcount))

;; bytes stuff is used by buffer.l, which is in turn is used by test-elf.l
;; TODO this should better be done by some magic that automatically exports
;; a kernel buffer.l implementation with types and functions into the evaluator
(define-primitive-function (copy-bytes ()) (from to (count <long>))
  ;; TODO check bounds
  (copy-bytes from to count))

(define-primitive-function (byte-at ()) (base (index <long>))
  ;; TODO check bounds
  (box <long> (byte-at base index)))

(define-primitive-function (set-byte-at ()) (base (index <long>) (value <long>))
  ;; TODO check bounds
  (safety 2 (assert (and (<= value 256) (<= 0 value)) "set-byte-at: value is out of range: "(box <long> value)))
  (box <long> (set-byte-at base index value)))

;; NOTE used by the assembler proof-of-concept in test-elf.l
(define-primitive-function (address-of ()) (thing)
  ;; KLUDGE when <long> is a tagged immediate then the address may get truncated.
  ;; add an assert?
  ;; or return a <target-pointer> here and define arithmetics on them?
  ;; or implement various boxed data types and return a boxed word-sized integer here?
  (box <long> thing))

(define-primitive-function (array-length ()) ((arg <array>))
  (<array>-size arg))

(define-primitive-function (string-length ()) ((arg <string>))
  (<string>-size arg))

(define-primitive-function (array-at ()) ((array <array>) (index <long>))
  (array-at array index))

(define-primitive-function (string-at ()) ((string <string>) (index <long>))
  (box <long> (string-at string index)))

;; adding [set-]char-at to the evaluator makes it source-level compatible with the level-shifted code, and with that enables us to load files like buffer.l into both worlds
(define-primitive-function (char-at ()) ((string <string>) (index <long>))
  (box <long> (string-at string index)))

(define-primitive-function (set-array-at ()) ((array <array>) (index <long>) value)
  (set-array-at array index value))

(define-primitive-function (set-string-at ()) ((string <string>) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 2 (assert (<= index (string-length string))))
  (set-string-at string index value)
  (box <long> value))

(define-primitive-function (set-char-at ()) ((string <string>) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 2 (assert (<= index (string-length string))))
  (safety 2 (assert (and (<= value 256) (<= 0 value)) "set-char-at: value is out of range: "(box <long> value)))
  (set-string-at string index value)
  (box <long> value))

(define-primitive-function (array-insert ()) ((array <array>) (index <long>) value))

(define-primitive-function (string-insert ()) ((string <string>) (index <long>) (value <long>))
  (safety 2 (assert (and (<= value 256) (<= 0 value)) "string-insert: value is out of range: "(box <long> value)))
  (string-insert string index value)
  (box <long> value))

(define-primitive-function (array-append ()) ((array <array>) value))

(define-primitive-function (string-append ()) ((string <string>) (value <long>))
  (safety 2 (assert (and (<= value 255) (<= 0 value)) "string-append: value is out of range: "(box <long> value)))
  (box <long> (string-append string value)))

(define-primitive-function number->string ((num <long>) (radix <long> 10))
  (long->string* num radix))

(define-primitive-function integer->string ((num <long>) (radix <long> 10))
  (long->string* num radix))

(define-primitive-function string->number ((str <string>) (radix <long> 10))
  (let ((res (string->long* str radix)))
    (when (= res +end+)
      (error "string->number: failed for "str))
    (box <long> res)))

(define-primitive-function string->integer ((str <string>) (radix <long> 10))
  (let ((res (string->long* str radix)))
    (when (= res +end+)
      (error "string->integer: failed for "str))
    (box <long> res)))

(when-at-expand (= +architecture+ 'IA-32)
  (define-primitive-function call-IA-32-machine-code (fn)
    (debug-print "call-IA-32-machine-code will call "fn)
    (assert (is <target-function> fn) "call-IA-32-machine-code: cannot call object of type "(type-of fn)", printing as "fn)
    (fn)
    (debug-print "call-IA-32-machine-code got back the control from "fn)
    ()))

(when-at-expand (= +architecture+ 'x86-64)
  (define-primitive-function call-x86-64-machine-code (fn)
    (debug-print "call-x86-64-machine-code will call "fn)
    (assert (is <target-function> fn) "call-x86-64-machine-code: cannot call object of type "(type-of fn)", printing as "fn)
    (fn)
    (debug-print "call-x86-64-machine-code got back the control from "fn)
    ()))

(when-at-expand feature/debug-output
  (define-primitive-function enable-debug-output	() (set *debug-output-enabled?* true))
  (define-primitive-function disable-debug-output	() (set *debug-output-enabled?* false)))
