;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion-min.l")

;; NOTE: not all of them are in this file.

(define-vm-function (define () fixed) ((variable <variable>) value-form)
  (let ((value (eval value-form -ctx-)))
    (set (<variable>-value variable) value)
    ;; maybe set the <expr>'s name slot
    (when-at-expand (feature track-expr-names)
      (let ((tmp value))
        (when (is <form> tmp)
          (set tmp (<form>-function tmp)))
        (when (and (is <expr> tmp)
                   (not (<expr>-name tmp)))
          (set (<expr>-name tmp) (<variable>-name variable)))))
    value))

;; TODO ideally, but it needs a gc/let*:(define-vm-function (eval ()) (form (env <env> (environment *globals* 1 0)))
(define-vm-function (eval ()) _
  (let ((env (if (cdr -args-) ; let's fail early when called with nil env
                 (cadr -args-)
               *globals*)))
    (let ((toplevel-env?	(= 0 (unbox <long> (<env>-level env))))
          (prev-globals	*globals*)
          result)
      (when toplevel-env?
        (set-current-globals env))
      (set result (gc/let* ((child-env (environment env 1 0)))
                    ;; TODO resolve this naming anomaly somehow
                    (expand-encode-eval* (car -args-) child-env)))
      (when toplevel-env?
        (set-current-globals prev-globals))
      result)))

(define-vm-function (lambda () fixed) ((env <env>) parameters . body)
  (assert (or (not parameters) (is <variable> parameters) (pair? parameters)) "lambda vm-function: parameters is of wrong type: " parameters)
  (expr parameters body env -ctx-))

(define-vm-function (let () fixed) (env bindings . body)
  (let ((locals (<context>-bindings -ctx-)))
    (gc/let* (tmp)
      (list-do binding bindings
        (when (pair? binding)
          (let ((var  (get/head binding))
                (prog (get/tail binding)))
            (debug-print "let vm-function is initializing var "var" in context "-ctx-)
            (set tmp ())
            (while (pair? prog)
              (set tmp (eval (get/head prog) -ctx-))
              (set prog (get/tail prog)))
            (debug-print "let vm-function is setting var "var" to value "tmp" in context "-ctx-)
            (set (array-at locals (unbox <long> (<variable>-index var))) tmp))))
      (set tmp ())
      (list-do exp body
        (set tmp (eval exp -ctx-)))
      tmp)))

(define-vm-function (set () fixed) ((var <variable>) value-form)
  (debug-print "SET "var" = "value-form" IN "-ctx-)
  (gc/let* ((value (eval value-form -ctx-)))
    (if (global-variable? var)
        (set (<variable>-value var) value)
      (let ((delta (- (unbox <long> (<env>-level (<context>-env -ctx-)))
                  (unbox <long> (<env>-level (<variable>-env var))))))
        (debug-print "set vm-function is writing local var "var" with delta "(box <long> delta))
        (while (< 0 delta)
          (set -ctx- (<context>-home -ctx-))
          (decr delta))
        (let ((index (unbox <long> (<variable>-index var))))
          (debug-print "set vm-function is setting local var in context "-ctx-" at index "(box <long> index)", to value "value)
          (set (array-at (<context>-bindings -ctx-) index) value))))))

(define-vm-function (while () fixed) _
  (let ((test	(car -args-))
        (prog	-args-))
    (while (eval test -ctx-)
      (let ((body prog))
        (while (pair? (set body (cdr body)))
          (eval (get/head body) -ctx-))))))

(define-vm-function (if () fixed) (test then . else)
  (if (eval test -ctx-)
      (eval then -ctx-)
    (let ((ans ()))
      (while (pair? else)
        (set ans (eval (get/head else) -ctx-))
        (set else (cdr else)))
      ans)))

(define-vm-function (or () fixed) _
  (let ((ans ()))
    (while (pair? -args-)
      (and (set ans (eval (get/head -args-) -ctx-))
           (return ans))
      (set -args- (get/tail -args-)))))

(define-vm-function (and () fixed) _
  (let ((ans symbol/true))
    (while (pair? -args-)
      (or (set ans (eval (get/head -args-) -ctx-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-vm-function (quote () fixed) (thing)
  thing)

(define-vm-function (not ()) (thing)
  (if thing () symbol/true))

;; -, +, *, and / all have some peculiarities that makes them somewhat resistant to macrology
(define-vm-function (- ()) _
  (or (pair? -args-) (error "operator '-' called with zero arguments"))
  (let ((result	(unbox <long> (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (- result (unbox <long> (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (- result)))
    (box <long> result)))

(define-vm-function (+ ()) _
  (let ((result	0)
        (rest	()))
    (when (pair? -args-)
      (set result (unbox <long> (get/head -args-)))
      (set rest   (get/tail -args-)))
    (while (pair? rest)
      (set result (+ result (unbox <long> (get/head rest))))
      (set rest (get/tail rest)))
    (box <long> result)))

(define-vm-function (/ ()) _
  (or (pair? -args-) (error "operator '/' called with zero arguments"))
  (let ((result	(unbox <long> (get/head -args-)))
        (rest	(get/tail -args-)))
    (if (pair? rest)
        (while (let ()
                 (set result (/ result (unbox <long> (get/head rest))))
                 (pair? (set rest (get/tail rest)))))
      (set result (/ 1 result)))
    (box <long> result)))

(define-vm-function (* ()) _
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
  `(define-vm-function (,op ()) ((lhs <long>) (rhs <long>))
     (box <long> (,op lhs rhs))))

(define-binary-operator bitwise-and)
(define-binary-operator bitwise-or)
(define-binary-operator bitwise-xor)

(define-vm-function (bitwise-not ()) ((value <long>))
  (box <long> (bitwise-not value)))

(define-vm-function (bitwise-shift ()) ((value <long>) (shift <long>))
  (box <long> (bitwise-shift value shift)))

(define-form define-relation (op)
  `(define-vm-function (,op ()) ((lhs <long>) (rhs <long>))
     (and (,op lhs rhs)
          symbol/true)))

(define-relation <)
(define-relation <=)
(define-relation >=)
(define-relation >)

;; FIXME restore arity check
(define-vm-function (= ()) _
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-))))
    (typecase lhs
      (<long>		(and (long? rhs)
                             (= (unbox <long> lhs)
                                (unbox <long> rhs))
                             symbol/true))
      (<string>		(and (string? rhs)
                             (= 0 (string-compare lhs rhs))
                             symbol/true))
      (<lower-cell>	(and (is <lower-cell> rhs)
                             (= (unbox <lower-cell> lhs)
                                (unbox <lower-cell> rhs))))
      (else		(and (= lhs rhs)
                             symbol/true)))))

(define-vm-function (exit ()) ((exit-code <long> 0))
  (when-at-expand (feature profiler)
    (profiler/disable))
  (platform/flush-streams)
  (platform/halt exit-code))

(define-vm-function (warn ()) _
  (list-do arg -args-
    (do-print *error-output* arg false))
  (platform/flush-streams))

(define-vm-function (type-of ())	(thing) (box <long> (type-of thing)))
(define-vm-function (string? ())	(thing) (and (string? thing) symbol/true))
(define-vm-function (symbol? ())	(thing) (and (symbol? thing) symbol/true))
(define-vm-function (pair?   ())	(thing) (and (pair?   thing) symbol/true))
(define-vm-function (array?  ())	(thing)	(and (array?  thing) symbol/true))

(define-vm-function set-car ((pair <pair>) value)
  (set (<pair>-head pair) value))

(define-vm-function set-cdr ((pair <pair>) value)
  (set (<pair>-tail pair) value))

;; TODO change this to a with-forms with-range-check, and
;; then implement the setter so that it unboxes <lower-cell> values.
;; probably the getter should also box its return value into it.
;; FIXME is this oop-at or a raw cell-at? rename/cleanup
(with-forms
    ((with-bounds-checking
         (body
          `(begin
            (safety 2 (let ((header (gc/header-of base)))
                        (assert (and (gc/valid-header-canary? header)
                                     (<= 0 cellindex)
                                     (<= (words-to-bytes (+ 1 cellindex)) (<header>-size header)))
                                "[set-]oop-at: trying to access beyond the gc chunk boundaries")))
            ,@body))))

  (define-vm-function (oop-at ()) (base (cellindex <long>))
    (with-bounds-checking
      (oop-at base cellindex)))

  (define-vm-function (set-oop-at ()) (base (cellindex <long>) value)
    (with-bounds-checking
      (set (oop-at base cellindex) value))))

(when-at-expand (feature lower/array)
  (with-forms
      ((with-bounds-checking
           (body
            `(begin
              (safety 2 (let ((header (gc/header-of base)))
                          (assert (and (gc/valid-header-canary? header)
                                       (<= 0 byteindex)
                                       (<= (+ byteindex +word-size-in-bytes+) (<header>-size header)))
                                  "[set-]cell-at: trying to access beyond the gc chunk boundaries")))
              ,@body))))

    (define-vm-function (cell-at ()) (base (byteindex <long>))
      (with-bounds-checking
        (box <lower-cell> (cell-at base byteindex))))

    (define-vm-function (set-cell-at ()) (base (byteindex <long>) value)
      (with-bounds-checking
        (set (cell-at base byteindex)
             (typecase value
               (<lower-cell>	(unbox <lower-cell> value))
               ;; FIXME should it allow <long> at all?
               (<long>		(unbox <long> value))
               (else (error "set-cell-at called with an unexpected type: "(type-of value)))))))))

(define-vm-function lower-cell->long ((value <lower-cell>))
  ;; this is potentially a lossy conversion, depending on the chosen
  ;; representation of <long>. when <long> is a tagged immediate, then
  ;; this loses some bits of precision from the high end, typically
  ;; just one bit, though.
  (box <long> value))

(define-vm-function long->lower-cell ((value <long>))
  (box <lower-cell> value))

;; (define-vm-function (copy-oops ()) (from to (wordcount <long>))
;;   (error "copy-oops: who called me in interpreted code?! TODO i need proper bounds checking added.")
;;   (copy-oops from to wordcount))

(define-vm-function (array-length ()) ((arg <array>))
  (<array>-size arg))

(define-vm-function (string-length ()) ((arg <string>))
  (<string>-size arg))

(define-vm-function (string-compare ()) ((s1 <string>) (s2 <string>)))

(define-vm-function (array-at ()) ((array <array>) (index <long>))
  (array-at array index))

(define-vm-function (string-at ()) ((string <string>) (index <long>))
  (box <long> (string-at string index)))

;; adding [set-]char-at to the evaluator makes it source-level compatible with the level-shifted code, and with that enables us to load files like buffer.l into both worlds
(define-vm-function (char-at ()) ((string <string>) (index <long>))
  (box <long> (string-at string index)))

(define-vm-function (set-array-at ()) ((array <array>) (index <long>) value)
  (set-array-at array index value))

(define-vm-function (set-string-at ()) ((string <string>) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 2 (assert (<= index (string-length string))))
  (set-string-at string index value)
  (box <long> value))

(define-vm-function (set-char-at ()) ((string <string>) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 2 (assert (<= index (string-length string))))
  (safety 2 (assert (and (<= value 256) (<= 0 value)) "set-char-at: value is out of range: "(box <long> value)))
  (set-string-at string index value)
  (box <long> value))

(define-vm-function (array-insert ()) ((array <array>) (index <long>) value))

(define-vm-function (string-insert ()) ((string <string>) (index <long>) (value <long>))
  (safety 2 (assert (and (<= value 256) (<= 0 value)) "string-insert: value is out of range: "(box <long> value)))
  (string-insert string index value)
  (box <long> value))

(define-vm-function (array-append ()) ((array <array>) value))

(define-vm-function (string-append ()) ((string <string>) (value <long>))
  (safety 2 (assert (and (<= value 255) (<= 0 value)) "string-append: value is out of range: "(box <long> value)))
  (box <long> (string-append string value)))

(define-vm-function number->string ((num <long>) (radix <long> 10))
  (long->string* num radix))

(define-vm-function integer->string ((num <long>) (radix <long> 10))
  (long->string* num radix))

(define-vm-function string->number ((str <string>) (radix <long> 10))
  (let ((res (string->long* str radix)))
    (when (= res +end+)
      (error "string->number: failed for "str))
    (box <long> res)))

(define-vm-function string->integer ((str <string>) (radix <long> 10))
  (let ((res (string->long* str radix)))
    (when (= res +end+)
      (error "string->integer: failed for "str))
    (box <long> res)))

(define-vm-function pointer->target-function (ptr)
  (make <target-function>
    (program-code ptr)))

(when-at-expand (= +architecture+ 'IA-32)
  (define-vm-function call-IA-32-machine-code (fn)
    (debug-print "call-IA-32-machine-code will call "fn)
    (assert (is <target-function> fn) "call-IA-32-machine-code: cannot call object of type "(type-of fn)", printing as "fn)
    (let ((result (box <long> (fn))))
      (debug-print "call-IA-32-machine-code got back the control from "fn)
      result)))

(when-at-expand (= +architecture+ 'x86-64)
  (define-vm-function call-x86-64-machine-code (fn)
    (debug-print "call-x86-64-machine-code will call "fn)
    (assert (is <target-function> fn) "call-x86-64-machine-code: cannot call object of type "(type-of fn)", printing as "fn)
    (let ((result (box <long> (fn))))
      (debug-print "call-x86-64-machine-code got back the control from "fn)
      result)))

(when-at-expand (feature debug-output)
  (define-vm-function enable-debug-output	() (set *debug-output-enabled?* true))
  (define-vm-function disable-debug-output	() (set *debug-output-enabled?* false)))
