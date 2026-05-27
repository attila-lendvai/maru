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
  (if (pair? -args-)
      (let ((value	(if (pair? (get/tail -args-))
                            ;; 2+ args
                            (unbox <long> (pop -args-))
                          ;; 1 arg
                          0)))
        (while (pair? -args-)
          (set value (- value (unbox <long> (pop -args-)))))
        (box <long> value))
    ;; 0 args
    (box <long> 0)))

(define-vm-function (+ ()) _
  (let ((value	0))
    (while -args-
      (set value (+ value (unbox <long> (pop -args-)))))
    (box <long> value)))

(define-vm-function (/ ()) _
  (if (pair? -args-)
      (let ((value	(unbox <long> (pop -args-))))
        (while (pair? -args-)
          (set value (/ value (unbox <long> (pop -args-)))))
        (box <long> value))
    (error "operator '/' needs at least one argument")))

(define-vm-function (* ()) _
  (let ((value	1))
    (while -args-
      (set value (* value (unbox <long> (pop -args-)))))
    (box <long> value)))

(define-form define-bitwise-operator (op)
  `(define-vm-function (,op ()) _
     (or (pair? -args-) (error ,(concat-strings "operator '"(symbol->string op)"': called with zero arguments")))
     (let ((value (unbox <long> (pop -args-))))
       (while -args-
         (set value (,op value (unbox <long> (pop -args-)))))
       (box <long> value))))

(define-bitwise-operator bitwise-and)
(define-bitwise-operator bitwise-or)
(define-bitwise-operator bitwise-xor)

(define-vm-function (bitwise-not ()) ((value <long>))
  (box <long> (bitwise-not value)))

(define-vm-function (bitwise-shift ()) ((value <long>) (shift <long>))
  (box <long> (bitwise-shift value shift)))

(define-form define-relation (op)
  `(define-vm-function (,op ()) _
     (unless (pair? -args-)
       (return symbol/true))
     (let ((current	(unbox <long> (pop -args-)))
           next)
       (while (pair? -args-)
         ;; TODO this could use (set current (unbox <long> (pop
         ;; -args-))) but that heavily relies on the specifics of
         ;; compiler semantics (and doesn't work currently)
         (let ((next (unbox <long> (pop -args-))))
           (unless (,op current next)
             (return false))
           (set current next)))
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
      ;; TODO dispatch on the meta-type and handle entire
      ;; classes. there's no point in a separate <long> and
      ;; <lower-cell> case when both can be covered by e.g. a boxed
      ;; word branch.
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

(with-forms
    ((with-bounds-checking
         (body
          `(begin
            (safety 2 (let ((header (gc/header-of base)))
                        (assert (and (gc/valid-header-canary? header)
                                     (<= 0 cellindex)
                                     (<= (words-to-bytes (+ 1 cellindex)) (<header>-size header)))
                                "[set-]oop-at: trying to access beyond the gc chunk boundaries")
                        (assert (not (bitwise-and (<header>-flags header) <header>-flags/opaque))
                                "[set-]oop-at: trying to access an opaque object")))
            ,@body))))

  (define-vm-function (oop-at ()) (base (cellindex <long>))
    (with-bounds-checking
      (oop-at base cellindex)))

  (define-vm-function (set-oop-at ()) (base (cellindex <long>) value)
    (with-bounds-checking
      (set (oop-at base cellindex) value))))

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

;; TODO delme; instead somehow export $put-all as a selector into the upper
(define-vm-function lower/$put-all (stream thing)
  ($put-all stream thing))

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

;; FIXME WHEN-AT-EXPAND body loses toplevelness, so it must be outside of it
(define-form with-open-pipe (args . body)
  (let ((read-fd-name  (pop args))
        (write-fd-name (pop args)))
    `(let ((__pipe-val__ 0)
           ,read-fd-name
           ,write-fd-name)
       (posix/pipe (address-of __pipe-val__))
       (set ,read-fd-name  (bitwise-and   __pipe-val__ 0xFFFFFFFF))
       (set ,write-fd-name (bitwise-shift __pipe-val__ -32))
       ,@body)))

;; FIXME: why do i need the HOST-VALUE here?! WHEN-AT-EXPAND should be
;; evaluating in the slave env, where the unwrapped DEFINED? should
;; just work. instead i get: form encountered in interpreted code with
;; args ((oop-at.0+29 obj.2+0 0) 1)
(when-at-expand (and (feature lower/array)
                     (host-value (defined? 'posix/spawn-program *target-env*)))

(define-vm-function spawn-program ((path <string>)
                                   argv envp
                                   (stdout-fd <long> -1) (stderr-fd <long> -1))
  (safety 2 (or (not argv) (pair? argv) (is <array> argv) (error "spawn-program: argv is of type " (type-of argv))))
  ;; TODO actually use envp
  (let ((argv/lower (to-lower-array argv 1))
        (path/lower (string->C-string path)))
    ;; argv[0] is the path of the binary
    (set (oop-at (<lower/array>-elements argv/lower) 0) path/lower)
    ;; NULL terminated
    (let ((i (bytes-to-words (lower/array-length argv/lower))))
      (lower/array-ensure-capacity/cell argv/lower i)
      (set (oop-at (<lower/array>-elements argv/lower) i) 0))

    (box <long> (platform/spawn-program path/lower
                                        (<lower/array>-elements argv/lower)
                                        (platform/envp)
                                        stdout-fd
                                        stderr-fd))))

(define-vm-function (run-program ()) _
  (let* ((path (or (pop -args-)
                   (error "run-program: path is mandatory")))
         (argv (pop -args-))
         ;; TODO (envp (pop -args-))
         (child-pid (unbox <long> (spawn-program path argv 0 -1 -1))))
    (box <long> (platform/waitpid child-pid 0))))

(define-vm-function (run-program/stdout ()) _
  (let* ((path (or (pop -args-)
                   (error "run-program/capture: path is mandatory")))
         (argv (pop -args-))
         ;; TODO (envp (pop -args-))
         )
    (with-open-pipe ()
      (let ((child-pid (unbox <long> (spawn-program path argv 0
                                                    -write-fd- -1))))
        (platform/close-fd -write-fd-)

        (let ((result (string 16))
              char)
          (while (<= 0 (set char (platform/read-byte -read-fd-)))
            (string-append result char))

          (platform/close-fd -read-fd-)

          (let ((exit-code (platform/waitpid child-pid 0)))
            (unless (= 0 exit-code)
              (error "spawn-program returned exit code: "exit-code)))
          result)))))
)
