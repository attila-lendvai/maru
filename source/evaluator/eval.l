;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; The Maru VM, written in a dialect of Maru.
;;;

(load "source/evaluator/types.l")

;; cache some symbols into the symbol/foo global variables
;; TODO add compilation of symbols and drop this cache
(define-form define-symbol-cache symbols
  `(let ()
     ,@(map (lambda (name)
              `(define ,(concat-symbol 'symbol/ name)))
            symbols)
     (define-function initialize-symbol-cache ()
       ,@(map (lambda (name)
                `(set ,(concat-symbol 'symbol/ name)
                      (string->symbol ,(symbol->string name))))
              symbols))))

(define-symbol-cache
    true define set quote quasiquote unquote unquote-splicing expand encode apply "." ; dot has a syntactic meaning
  lambda let *globals* *expanders* *encoders* *evaluators* *applicators*
  *standard-input* *standard-output* *error-output* *debug-output* *verbosity* *optimised*)

;; TODO should we turn these into macros? or introduce compiler macros?
(define-primitive-function car (list)
  (when list
    (safety 2 (assert (pair? list) "car called on non-list: " list))
    (get/head list)))

(define-primitive-function cdr (list)
  (when list
    (safety 2 (assert (pair? list) "cdr called on non-list: " list))
    (get/tail list)))

(load "source/list-min.l")

;;;
;;; object instantiation
;;; ----------------------------------------------------------------

;; TODO try to eliminate this opaque anomaly leaking here... maybe by annotating this on the type?
(define-form make/opaque (type-name . inits)
  (let ((type (eval type-name)))
    `(gc/let* ((self (gc/allocate-opaque ,type-name ,(words-to-bytes (record/effective-slot-count type)))))
       (with-instance-accessors self ,type-name
         ,@(%make-make-inits *env* 'self. inits)
         self))))

(define-primitive-function (allocate ()) (type (slot-count <long>))
  ;; allocates a lisp object with the given type. size is given as a count of the slots (pointers).
  (allocate (cond
              ((is <long> type)
               (unbox <long> type))
              ((or (is <type> type)
                   (is <record> type))
               ;; KLUDGE we need to disable accessor typecheck here, because when it's a <record>, then it gets triggereed, because the target universe is unaware of inheritance
               (unbox <long> (with-forms ((%accessor-typecheck ((type obj) obj)))
                               (<type>-id type))))
              (else
               (error "allocate: illegal type specifier: "type)))
            slot-count))

(define-primitive-function allocate-data ((byte-size <long>))
  (gc/allocate-opaque <data> byte-size))

(define-primitive-function cons ((head () ()) (tail () ()))
  (make <pair>
    (head head)
    (tail tail)))

(define-primitive-function string ((length <long> 0))
  (make <string>
    (size	(box <long> 0))
    (elements	(when (< 0 length)
                  (allocate-data length)))))

(define-function ascii-bytes->string (buf length)
  (let ((str (string length)))
    (copy-bytes buf (<string>-elements str) length)
    str))

(define-function symbol (name)
  (safety 1 (assert (string? name)))
  (make <symbol>
    (name	name)))

(define-primitive-function array ((capacity <long> 0))
  (make <array>
    (size	(box <long> 0))
    (elements	(when (> capacity 0)
                  (allocate <data> capacity)))))

(define-function expr (parameters body env ctx)
  (make <expr>
    (parameters	parameters)
    (body	body)
    (env	env)
    (ctx	ctx)
    (when-at-expand feature/profiler
      (profiler-counter (box <long> 0)))))

(define-primitive-function form (fn (sym () ()))
  (make <form>
    (function	fn)
    (symbol	sym)))

(define-primitive-function fixed (fn)
  (make <fixed>
    (function fn)))

(define-function primitive-function (code name)
  (safety 2 (assert (and (is <target-pointer> code) (is <string> name))))
  (make <target-function>
    (program-code	code)
    (name		name)
    (when-at-expand feature/profiler
      (profiler-counter	(box <long> 0)))))

(define-primitive-function variable ((name <symbol>) value (env <env>) (index <long>))
  (make <variable>
    (name	name)
    (value	value)
    (env	env)
    (index	(box <long> index))))

(define-primitive-function environment ((parent <env>) (level <long> 0) (offset <long> (unbox <long> (<env>-offset parent))))
  (make <env>
    (parent	parent)
    (level	(box <long> (if parent (+ (unbox <long> (<env>-level parent)) level) 0)))
    (offset	(box <long> offset))
    (bindings	(array 0))
    (stable	false))) ; using false here is fine because false = 0 = (), i.e. it's a valid Lisp object

(define-function base-context (home env)
  (make <context>
    (home	home)	; the context in which the currently applied <expr> was instantiated
    (env	env)	; the env in which the currently applied <expr> was defined
    (bindings	(array 0))))

;; (define-function context (home caller env)
;;   (let ((obj ()))
;;     (if (and caller
;;              (set obj (<context>-callee caller)))
;;         (let ()
;;           (set (<context>-home obj) home)
;;           (set (<context>-env  obj) env))
;;       (set obj (base-context home env))
;;       (when caller
;;         (set (<context>-callee caller) obj)))
;;     obj))

(define-function context (home caller env)
  (let ((res (base-context home env)))
    (when caller
      (set (<context>-callee caller) res))
    res))

;;;
;;; more utils
;;; ----------------------------------------------------------------

(define-function list2 (a b)
  (gc/let* ((tmp (cons b ())))
    (cons a tmp)))

(define-function list3 (a b c)
  (gc/let* ((tmp (list2 b c)))
    (cons a tmp)))

(define-function concat-list (head tail)
  (if (pair? head)
      (gc/let* ((new-tail (concat-list (get/tail head) tail)))
        (cons (get/head head) new-tail))
    tail))

(require "source/evaluator/arrays.l")

;; TODO these should be in platforms/platform-c-based.l, but they need
;; arrays.l and other stuff.
(define-function %string->C-string (obj)
  (<string>-elements (string-ensure-zero-terminated obj)))

(define-function C-string->string (cstr)
  (let* ((len (C-string-length cstr))
         (obj (string len)))
    (set (slot-value <string> size obj) (box <long> len))
    (copy-bytes cstr (<string>-elements obj) len)
    obj))

(require "source/conversion-min.l")
(require "source/sequences-min.l")

;;;
;;; env
;;; ----------------------------------------------------------------

(define-primitive-function string->symbol ((str <string>))
  (array-binary-search *symbols*
                       str
                       (lambda (str candidate) ; TODO there's no support yet for capturing str into the closure
                         (compare-strings str (<symbol>-name candidate)))
                       (lambda (array index str)
                         ;; TODO do we want to make a copy of str here? because str may be mutable...
                         ;; TODO instantiate a read-only string as the name
                         (gc/let* ((sym		(symbol str)))
                           (debug (platform/print-diag "interning "str))
                           (array-insert array index sym)
                           sym))))

(define-primitive-function symbol->string (symbol)
  ;; FIXME? isn't this too permissive? enable type check at the arg, and delete the if... and then fix the code that relies on this.
  (if (string? symbol)
      symbol
    (<symbol>-name symbol)))

(require "source/env-min.l")

;; TODO this is ready to be moved into env-min.l, but then it redefines the host's defined?
;; and breaks something when it's loaded while not bootstrapping.
;; think this through: the host hands over to us <env>'s in e.g. <form>s
;; or as the module's env, and we need to access them, even while we load our own stuff
;; into the slave. we can't just redefine the host's DEFINED? function. this also applies to
(define-primitive-function defined? ((name <symbol>) (env <env> *globals*))
  (let ((result ()))
    (while (and env
                (not (set result (find-local-variable env name))))
      (set env (<env>-parent env)))
    result))

;; TODO use quicksearch?
(define-function new-variable (env name)
  (safety 2 (assert (is <env> env)	"new-variable: env arg is not of type <env>: "env))
  (safety 2 (assert (symbol? name)	"new-variable: name arg is not of type <symbol>: "name))
  ;; TODO delme?
  (safety 4 (assert (not (find-local-variable env name)) "new-variable was about to shadow "name))
  (let ((offset (unbox <long> (<env>-offset env))))
    (gc/let* ((var (variable name () env offset)))
      (set (<env>-offset env) (box <long> (+ offset 1)))
      (array-append (<env>-bindings env) var))))

(define-primitive-function environment-define ((env <env>) (name <symbol>) value)
  (debug-print "environment-define called, name is "(<symbol>-name name))
  (let ((var (find-local-variable env name)))
    (if var
        (let ()
          ;;(print-all *debug-output* "warning: environment-define: variable "var" is already defined in env "env"\n")
          ;;(platform/print-diag-fmt "warning: environment-define: variable %s is already defined in this env\n" (string->C-string (symbol->string name)))
          )
      (set var (new-variable env name)))
    (set (<variable>-value var) value)
    var))

(define-function maybe-object-in-variable (var type)
  (let ((tmp var))
    (and tmp
         (is <variable> tmp)
         (set tmp (<variable>-value tmp))
         (or (not type)
             (= type (type-of tmp)))
         tmp)))

(define-function maybe-object-in-env (env name type)
  (when (symbol? name)
    (maybe-object-in-variable (defined? name env) type)))

;;;
;;; globals
;;; ----------------------------------------------------------------

(define-primitive-function (current-globals ()) ()
  *globals*)

(define-primitive-function set-current-globals ((env <env>))
  (debug-print "set-current-globals "env)
  (set *globals* env)
  (capture-well-known-globals)
  env)

;; TODO move this also into env-min.l, but for that we need smart accessors in the
;; level-shifted code that automatically do the unboxing of slot values
(define-function global-variable? (var)
  (let ((env (<variable>-env var)))
    (= 0 (unbox <long> (<env>-level env)))))

;;; ----------------------------------------------------------------

(load "source/evaluator/reader.l")
(load "source/evaluator/printer.l")

;;;
;;; backtrace
;;; ----------------------------------------------------------------

(define-record <call-frame> () (callee-designator callee arguments env))

(define-form with-new-call-frame (args . body)
  (let ((call-depth-check `(when (> (incr *call-stack-index*) +maximum-call-stack-depth+)
                             (fatal1 "infinite recursion guard triggered at call depth %ld" *call-stack-index*))))
    `(let ((__result__ ,(if feature/backtrace
                            `(let ((-call-frame- (%new-call-frame ,@args)))
                               ,call-depth-check
                               ,@body)
                          `(let ()
                             ,call-depth-check
                             ,@body))))
       (decr *call-stack-index*)
       ,(when feature/backtrace
          '(when (<= 0 *call-stack-index*)
            ;; gc optimization: clear the now unused call-frame
            (let ((frame (array-at *call-stack* *call-stack-index*)))
              (with-instance-accessors frame <call-frame>
                (set frame.callee-designator	())
                (set frame.callee		())
                (set frame.arguments		())))))
       ;;(debug (platform/print "with-new-call-frame returning with result: ") (println __result__))
       __result__)))

(when-at-expand feature/backtrace
  (define-function %new-call-frame (callee-designator callee args)
    (safety 3 (unless (gc/valid-maru-value? callee-designator)	(fatal1 "new-call-frame: encountered an untagged callee-designator: %p" callee-designator)))
    (safety 3 (unless (gc/valid-maru-value? callee)		(fatal1 "new-call-frame: encountered an untagged callee %p" callee)))
    (let ((frame (array-at *call-stack* *call-stack-index*)))
      (if frame
          (safety 3 (assert (is <call-frame> frame) "new-call-frame: found a non-<call-frame> in the *call-stack*, type: " (type-of frame)))
        (gc/let* ((new-frame (new <call-frame>)))
          (set (array-at *call-stack* *call-stack-index*) new-frame)
          (set frame new-frame)))
      (with-instance-accessors frame <call-frame>
        (set frame.callee-designator	callee-designator)
        (set frame.callee		callee)
        (set frame.arguments		args))
      frame))

  (define-function current-call-frame ()
    (when (< 0 *call-stack-index*)
      (array-at *call-stack* (- *call-stack-index* 1)))))

(define-function print-backtrace ()
  (if-at-expand feature/backtrace
      (let ((out *debug-output*))
        (for (i 0 *call-stack-index*)
          (platform/flush-streams) ; seems like that in case of a sigsegv it doesn't get flushed
          (let* ((call-frame	(array-at *call-stack* i))
                 (index-label	(long->string i))
                 (callee-des	(<call-frame>-callee-designator call-frame))
                 (expand-or-encode? (or (= callee-des symbol/expand)
                                        (= callee-des symbol/encode))))
            (times-do (- 3 (string-length index-label))
              (string-insert index-label 0 ?\ ))
            (print-all out index-label": "(<call-frame>-callee-designator call-frame)"\n")

            (unless expand-or-encode?
              (print-all out "\tcallee:\t"(<call-frame>-callee call-frame)"\n"))

            (when (<= *error-level* 1)
              (let ((args (<call-frame>-arguments call-frame)))
                (cond
                  (expand-or-encode?
                   (print-all out "\texpr: "args"\n")
                   (print-all out "\tenv: "(<call-frame>-env call-frame)"\n"))
                  (else
                   (let ((arg-index 0))
                     (list-do arg args
                       (print-all out "\targ "(long->string arg-index)":\t"arg"\n")
                       (incr arg-index)))))))))
        ;; man exit says that it's flushed, but looks like it's not. plus there's this: https://wiki.sei.cmu.edu/confluence/display/c/FIO23-C.+Do+not+exit+with+unflushed+data+in+stdout+or+stderr
        (platform/flush-streams))
    (print-all *error-output* "print-backtrace: call-frame tracking is disabled in this build. current call depth is "*call-stack-index*"\n")))

;;;
;;; apply
;;; TODO move this into the expand-encode-eval-apply order
;;; ----------------------------------------------------------------

(define-function apply/expr (fun arguments parent-ctx)
  (verbosity 3 (debug-print "  A  "fun" "arguments" "parent-ctx))
  (let ((env	(<expr>-env fun))
        (params	(<expr>-parameters fun)))
    (gc/let* ((inner-context (context (<expr>-ctx fun) parent-ctx env)))
      (let ((locals (<context>-bindings inner-context))
            (args   arguments))
        (while (pair? params)
          (or (pair? args) (error "too few arguments for "fun": "arguments))
          (set (array-at locals (unbox <long> (<variable>-index (get/head params))))
               (get/head args))
          (set params	(get/tail params))
          (set args	(get/tail args)))
        ;; the cdr position
        (when (is <variable> params)
          (set (array-at locals (unbox <long> (<variable>-index params))) args)
          (set args ()))
        (when args
          (error "too many arguments for "fun": "arguments)))
      (gc/let* ((result ()))
        (list-do exp (<expr>-body fun)
          (set result (eval exp inner-context)))
        (when (<env>-stable env)
          (set (<context>-callee inner-context) ()))
        result))))

(define-function apply (fun arguments ctx)
  (debug-print "apply, function "fun", arguments: "arguments)
  (with-new-call-frame (symbol/apply fun arguments)
    (let ((type (type-of fun)))
      ;; TODO use typecase
      (cond
        ((= type <expr>)
         (apply/expr fun arguments ctx))

        ((= type <target-function>)
         (let* ((code	(unbox <target-pointer> (<target-function>-program-code fun)))
                (result	(code arguments ctx)))
           (safety 3 (or (gc/valid-maru-value? result)
                         (error "<target-function> "fun" returned with something unboxed")))
           result))

        (else
         (aif (and *applicators-var*
                   (set it (maybe-object-in-variable *applicators-var* <array>))
                   (array-at it type))
             (gc/let* ((args (cons fun arguments)))
               (apply it args ctx))
           (error "cannot apply: "fun", *globals*: "*globals*", *applicators* is: "
                  (and *applicators-var* (<variable>-value *applicators-var*)))))))))

(define-primitive-function (apply ()) (fn args)
  (apply fn args -ctx-))

;;;
;;; expand
;;; ----------------------------------------------------------------

(define-function maybe-form-in-env/function (env name)
  (awhen (maybe-object-in-env env name <form>)
    (<form>-function it)))

(define-function maybe-form-in-env/symbol (env name)
  (awhen (maybe-object-in-env env name <form>)
    (<form>-symbol it)))

(define-function expand-all (list env one-step?)
  (if (pair? list)
      (gc/let* ((head (expand		(get/head list) env one-step?))
                (tail (expand-all	(get/tail list) env one-step?)))
        (cons head tail))
    (expand list env one-step?)))

(define-function setter-name-for (fn-name env)
  (let ((prefix		"set-")
        (fn-name-str	(<symbol>-name fn-name)))
    (gc/let* ((setter-name-str (string (+ (string-length fn-name-str)
                                          (string-length prefix)))))
      (string-append-all setter-name-str prefix)
      (string-append-all setter-name-str fn-name-str)
      (gc/let* ((setter-name (string->symbol setter-name-str)))
        (when (maybe-object-in-env env setter-name ())
          setter-name)))))

(define-function maybe-fn-name-from-expr (expr)
  (when (pair? expr)
    (let ((fn-name (get/head expr)))
      (when (symbol? fn-name)
        fn-name))))

(define-function attempt-set-convert (place value env one-step?)
  (let ((fn-name (maybe-fn-name-from-expr place)))
    (when fn-name
      ;; it's a set form such as: (set (fn-name a b c) new-value). let's try to convert it to
      ;; (set-fn-name a b c new-value) if set-fn-name is defined.
      (awhen (setter-name-for fn-name env)
        ;; TODO? the value should be inserted as the first arg to not disrupt &rest parsing
        (gc/let* ((args (get/tail place))
                  (last (cons value ())))
          (set args (expand-all args env one-step?))
          (set args (concat-list args last))
          (cons it args))))))

(define-function expand/pair (exp env one-step? -call-frame-)
  (gc/let* ((head (expand (get/head exp) env one-step?)))
    (debug-print "expand/pair on head "head)
    (when-at-expand feature/backtrace
      (unless (= head (get/head exp))
        (set (<call-frame>-callee		-call-frame-) head))
      (set (<call-frame>-arguments		-call-frame-) exp))
    (let (expander)
      ;; TODO use switch
      (cond
        ((= head symbol/let)
         ;; TODO use a collecting macro to simplify this
         (gc/let* ((new-bindings ()))
           (let ((bindings (cadr exp))
                 new-bindings/last)
             (list-do entry bindings
               (let (var-name)
                 (gc/let* (var-init-prog)
                   (if (pair? entry)
                       (let ()
                         (set var-name		(get/head entry))
                         (set var-init-prog	(expand-all (get/tail entry) env one-step?)))
                     (set var-name	entry)
                     (set var-init-prog	(cons () ())))
                   (gc/let* ((new-entry (cons var-name var-init-prog)))
                     (set new-bindings/last (if new-bindings
                                                (put/tail new-bindings/last (cons new-entry ()))
                                              (set new-bindings (cons new-entry ())))))))))
           (gc/let* ((tmp (expand-all (cddr exp) env one-step?))) ; the body
             (set tmp (cons new-bindings tmp))
             (set tmp (cons symbol/let tmp))
             tmp)))

        ((= head symbol/quote)
         (cons symbol/quote (get/tail exp)))

        ((= head symbol/set)
         (safety 1 (assert (and (cddr exp) (not (cdddr exp))) "illegal set form: " exp))
         (debug-print "expand/set on form "exp)
         ;; try to set-transform (set (place-accessor ...) value) forms while expanding. try "more abstract" set-foo forms first,
         ;; and only recursively expand the body if they are not defined.
         ;; this setup allows defining e.g. a SET-SLOT-VALUE form to override its behavior. the old way was to first expand
         ;; the body, i.e. a (SLOT-VALUE ...) form into an (OOP-AT ...) form, and only then attempt to set-convert it to SET-OOP-AT.
         (let ((vanilla-place	(second exp)))
           (gc/let* ((value	(expand (third exp) env one-step?))
                     (converted	(attempt-set-convert vanilla-place value env one-step?)))
             (if converted
                 (if one-step?
                     converted
                   (expand converted env one-step?))
               ;; we descend here with one-step? = true, so that we can attempt the set-conversion at each step of expansion
               (gc/let* ((expanded-place (expand vanilla-place env true)))
                 (if (set converted (attempt-set-convert expanded-place value env one-step?))
                     (if one-step?
                         converted
                       (expand converted env one-step?))
                   (let ((fn-name (maybe-fn-name-from-expr expanded-place)))
                     ;; we need to "look ahead" and only attempt recursive expansion when there's any work left to do.
                     ;; otherwise the following form would lead to infinite recursion: (set (without-set-version ...) ...)
                     (set converted (list3 symbol/set expanded-place value))
                     (if (and (not one-step?)
                              fn-name
                              (or (maybe-object-in-env env fn-name <form>)
                                  (setter-name-for fn-name env)))
                         (expand converted env one-step?)
                       converted))))))))

        ((= head symbol/define)
         (safety 1 (assert (not (cdddr exp)) "illegal define form: " exp))
         (let ((name	(second exp))
               (value	(third exp)))
           (gc/let* ((expanded-value (expand value env one-step?)))
             (list3 symbol/define name expanded-value))))

        ((= head symbol/lambda)
         (let ((params	(cadr exp))
               (body	(cddr exp)))
           (gc/let* ((tmp (expand-all body env one-step?)))
             (set tmp (cons params tmp))
             (cons symbol/lambda tmp))))

        ((set expander (maybe-form-in-env/function env head))
         ;; head is a <form> found in *env* (which may hold lexically scoped forms, and i think delegates all the way up to the module's env)
         (gc/let* ((args (cons env (get/tail exp)))
                   (expansion (apply expander args ())))
           (debug-print "expand/pair, found in local env, expanded to "expansion)
           (if one-step?
               expansion
             (expand expansion env one-step?))))

        ;; TODO also handle literal <form> objects here?

        (else
         ;; head is not a <form> nor a <fixed> special form
         (gc/let* ((tail (expand-all (get/tail exp) env one-step?)))
           (cons head tail)))))))

(define-function expand/symbol (exp env one-step?)
  (debug-print "expand/symbol, exp "exp", env "env)
  (aif (maybe-form-in-env/symbol env exp)
      ;; head is a <form> found in *env* (which may hold lexically scoped forms, and i think delegates all the way up to the module's env)
      (gc/let* ((args (list2 env exp))
                (expansion (apply it args ())))
        (debug-print "expand/symbol, found in local env, expanded to "expansion)
        (if one-step?
            expansion
          (expand expansion env one-step?)))
    exp))

;; TODO that <long> for the boolean is not ok
(define-primitive-function expand (exp (env <env> (<context>-env -ctx-)) (one-step? <long> false))
  (debug-print "expand, exp "exp", env "env)
  (with-new-call-frame (symbol/expand () exp)
    (set (<call-frame>-env -call-frame-) env)
    ;; TODO use typecase
    (cond
      ((pair? exp)	(expand/pair	exp env one-step? -call-frame-))
      ((symbol? exp)	(expand/symbol	exp env one-step?))
      (else
       ;; consult the *expanders* array to see if there's any custom expander for this type
       (aif (and *expanders-var*
                 (set it (maybe-object-in-variable *expanders-var* <array>))
                 (array-at it (type-of exp)))
           (gc/let* ((args (cons exp ())))
             ;; deliberate simplification: the next APPLY will record the callee and the args in the backtrace anyway
             (apply it args ()))
         exp)))))

;;;
;;; encode
;;; ----------------------------------------------------------------

(define-function encode-all (list env)
  (if (pair? list)
      (gc/let* ((head (encode		(get/head list) env))
                (tail (encode-all	(get/tail list) env)))
        (cons head tail))
    (encode list env)))

(define-function encode/pair (exp env)
  (gc/let* ((head (encode (get/head exp) env))
            (tail (get/tail exp)))
    (debug-print "encode/pair of head "head", in env "env)
    ;; TODO use switch
    (cond
      ((= head fixed-primitive-function/let)
       ;; KLUDGE? to make encode idempotent, this is how we detect that this let has already been encoded. same below.
       (unless (is <env> (first tail))
         (gc/let* ((vars	())
                   (inner-env	(environment env 0 (unbox <long> (<env>-offset env)))))
           ;; phase 1: first define the let variables into inner-env
           (let (vars/last)
             (list-do entry (first tail)
               (debug-print "encode/let visiting entry "entry)
               (let* ((var-name	(first entry))
                      (var-obj	(environment-define inner-env var-name ())))
                 (set vars/last (if vars
                                    (put/tail vars/last (cons var-obj ()))
                                  (set vars (cons var-obj ())))))))
           ;; update the offset of the parent env to "skip" the indices of our let variables
           (set (<env>-offset env) (<env>-offset inner-env))
           ;; phase 2: encode-all the init-progs and build the new bindings list
           (gc/let* (var
                     new-bindings)
             (let (new-bindings/last)
               (list-do entry (first tail)
                 (gc/let* ((init-prog	(encode-all (get/tail entry) env))
                           (new-entry	(cons (pop vars) init-prog)))
                   (set new-bindings/last (if new-bindings
                                              (put/tail new-bindings/last (cons new-entry ()))
                                            (set new-bindings (cons new-entry ())))))))
             (set tail (encode-all (cdr tail) inner-env)) ; encode the body
             (set tail (cons new-bindings tail))
             (set tail (cons inner-env tail))))))

      ((= head fixed-primitive-function/lambda)
       (let ((args (first tail)))
         (unless (is <env> args)
           (gc/let* ((inner-env (environment env 1 0)))
             (while (pair? args)
               (environment-define inner-env (get/head args) ())
               (set args (get/tail args)))
             (when args
               (environment-define inner-env args ()))
             (set tail (encode-all tail inner-env))
             (set tail (cons inner-env tail))))))

      ((= head fixed-primitive-function/define)
       (unless (is <variable> (first tail))
         ;; DEFINE unconditionally defines into *globals*
         ;; TODO ponder about this... it leads to a somewhat confusing behavior.
         ;; maybe DEFINE should define locally that sometimes happens to be *globals*?
         ;; what about this: (define foo (lambda (arg) (define nested 42)))
         (let ((var (environment-define *globals* (first tail) ())))
           (set tail (encode-all (cdr tail) env))
           (set tail (cons var tail)))))

      ((= head fixed-primitive-function/set)
       (typecase (first tail)
         (<symbol>
          (let ((var (or (defined? (first tail) env)
                         (error "set: undefined variable: " (first tail)))))
            (assert (and (car tail) (not (cddr tail))) "encode: malformed SET expression: "exp)
            (set tail (encode-all (cdr tail) env))
            (set tail (cons var tail))))
         (<variable>) ; NOP, already encoded
         (else
          (error "encode/pair encountered an unexpected set form: "exp))))

      ((= head fixed-primitive-function/quote)) ; ignore quotes

      (else
       (set tail (encode-all tail env))))
    ;; return value
    (cons head tail)))

(define-function encode/symbol (sym env)
  (debug-print "encode/symbol of '"sym"', in env "env)
  (let ((var (or (defined? sym env)
                 (error "encode/symbol: failed for "sym", *globals* "*globals*", env "env))))
    (if (global-variable? var)
        (let ((val (<variable>-value var)))
          (when (or (is <form> val) ; TODO ? how can <form>s show up here, after expand?
                    (is <fixed> val))
            (return val)))
      (let* ((var-env	(<variable>-env var))
             (var-level	(unbox <long> (<env>-level var-env)))
             (env-level	(unbox <long> (<env>-level env))))
        (safety 1 (assert (<= var-level env-level)))
        (when (< var-level env-level)
          (set (<env>-stable var-env) symbol/true))))
    var))

(define-primitive-function encode (exp (env <env> (<context>-env -ctx-)))
  (debug-print "encode of exp "exp", in env "env)
  (with-new-call-frame (symbol/encode () exp)
    (set (<call-frame>-env -call-frame-) env)
    (debug-print "encode is dispatching on type "(box <long> (type-of exp)))
    ;; TODO use typecase
    (cond
      ((pair? exp)	(encode/pair	exp env))
      ((symbol? exp)	(encode/symbol	exp env))
      (else
       (aif (and *encoders-var*
                 (set it (maybe-object-in-variable *encoders-var* <array>))
                 (array-at it (type-of exp)))
           (gc/let* ((args (list2 exp env)))
             ;; deliberate simplification: the next APPLY will record the callee and the args in the backtrace anyway
             (debug-print "encode/other: applying fn: "it" "args" "env)
             (apply it args ()))
         exp)))))

;;;
;;; eval
;;; ----------------------------------------------------------------

(define-function eval-all (obj ctx)
  (if (pair? obj)
      (gc/let* ((head (eval	(get/head obj) ctx))
                (tail (eval-all	(get/tail obj) ctx)))
        (cons head tail))
    obj))

(define-function eval/with-call-frame (type exp ctx)
  (with-new-call-frame (() () ())
    (cond
      ((= type <pair>)
       (when-at-expand feature/backtrace
         (set (<call-frame>-callee-designator	-call-frame-) (get/head exp))
         (set (<call-frame>-arguments		-call-frame-) (get/tail exp)))
       (gc/let* ((evaled-head (eval (get/head exp) ctx)))
         (debug-print "eval of pair, head eval'ed to "evaled-head)
         (when-at-expand feature/backtrace
           (set (<call-frame>-callee -call-frame-) evaled-head))
	 (if (is <fixed> evaled-head)
	     (apply (<fixed>-function evaled-head) (get/tail exp) ctx)
	   (gc/let* ((args (eval-all (get/tail exp) ctx)))
             (when-at-expand feature/backtrace
               (set (<call-frame>-arguments -call-frame-) args))
             (apply evaled-head args ctx)))))
      (else
       (when-at-expand feature/backtrace
         (set (<call-frame>-callee-designator -call-frame-) exp))
       (aif (and *evaluators-var*
                 (set it (maybe-object-in-variable *evaluators-var* <array>))
                 (array-at it type))
	   (gc/let* ((args (cons exp ())))
	     (when-at-expand feature/backtrace
               (set (<call-frame>-callee -call-frame-) it)
               (set (<call-frame>-arguments -call-frame-) args))
	     (apply it args ctx))
         exp)))))

(define-function eval/variable (var ctx)
  (if (global-variable? var)
      (let ()
        (debug-print "eval is reading global var "var)
        (<variable>-value var))
    (let ((delta (- (unbox <long> (<env>-level (<context>-env ctx)))
		(unbox <long> (<env>-level (<variable>-env var))))))
      (debug-print "eval is reading local var "var" with delta " (box <long> delta))
      (while (< 0 delta)
	(set ctx (<context>-home ctx))
	(decr delta))
      (let* ((index (unbox <long> (<variable>-index var)))
             (value (array-at (<context>-bindings ctx) index)))
        (debug-print "eval is reading local var from context "ctx" at index "(box <long> index)", holding value "value)
	value))))

(define-function eval (exp ctx)
  (verbosity 3 (debug-print "  E  "exp" "ctx))
  (let ((type (type-of exp)))
    ;; TODO use typecase
    (cond
      ((= type <undefined>)	exp)
      ((= type <long>)		exp)
      ((= type <string>)	exp)
      ((= type <variable>)	(eval/variable exp ctx))
      ((= type <symbol>)	(error "encountered a <symbol> in eval. this shouldn't happen!"))
      (else			(eval/with-call-frame type exp ctx)))))

(define-function expand-encode-eval* (form env)
  (debug-print "expand-encode-eval for form "form)
  (gc/let* ((x form))
					(verbosity 2 (debug-print ";;; ? "x))
    (set x (expand x env false))	(verbosity 2 (debug-print ";;; expd--> "x))
    (set x (encode x env))		(verbosity 2 (debug-print ";;; encd--> "x))
    (gc/let* ((ctx (base-context () env)))
      (set x (eval   x ctx)))
					(verbosity 2 (debug-print ";;; => "x))
    (debug-print "expand-encode-eval for form "form" is returning with "x)
    x))

(define-function expand-encode-eval (form)
  (gc/let* ((env (environment *globals* 1 0)))
    (expand-encode-eval* form env)))

(define-function expand-encode-eval-stream (stream)
  (gc/let* (form
            res)
    (until (= +end+ (set form (read stream)))
      (set res (expand-encode-eval form)))
    res))

(when-at-expand feature/profiler
  ;; these are coming from profiler.c
  (define-C-function install_profiler_handler void install_profiler_handler (*))
  (define-C-function set_profiler_interval void set_profiler_interval (int))

  (define profiler/sample-counter 0)

  (define-function profiler/take-sample-at-frame (frame)
    (let* ((callee	(<call-frame>-callee frame))
           (callee-type	(type-of callee)))
      (with-forms ((incr-boxed ((place) `(set ,place (box <long> (+ 1 (unbox <long> ,place)))))))
        ;; TODO use typecase
        (cond
          ((= callee-type <expr>)
           (incr-boxed (<expr>-profiler-counter callee)))

          ((= callee-type <target-function>)
           (incr-boxed (<target-function>-profiler-counter callee)))))))

  (define-function profiler/take-sample (_)
    (incr profiler/sample-counter)
    (if-at-expand feature/profiler/cumulative
        (for (i 0 *call-stack-index*)
          (profiler/take-sample-at-frame (array-at *call-stack* i)))
      (awhen (current-call-frame)
        (profiler/take-sample-at-frame it))))

  (define-function profiler/disable ()
    (set_profiler_interval 0)
    (when (< 0 profiler/sample-counter)
      (print-all *debug-output* "Profiler took "(box <long> profiler/sample-counter)" samples:")
      (let ((obj (gc/first-object)))
        (while obj
          (let ((type (type-of obj))
                (name ())
                (counter ()))
            (cond
              ((and (= type <expr>)
                    (< 0 (set counter (unbox <long> (<expr>-profiler-counter obj)))))
               (set name (<expr>-name obj)))

              ((and (= type <target-function>)
                    (< 0 (set counter (unbox <long> (<target-function>-profiler-counter obj)))))
               (set name (<target-function>-name obj))))
            (when counter
              (print-all *debug-output* (box <long> counter)"\t"(or name "n/a"))))
          (set obj (gc/next-object obj)))))))
