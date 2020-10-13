;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; The Maru VM, written in a dialect of Maru.
;;;

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
;;; k/ prefix means that it's something that is part of the kernel of the
;;;    codebase, i.e. the stuff that implements the Maru vm. Often it's
;;;    necessary to distinguish a name that exists both in the Maru vm,
;;;    and in the kernel (e.g. car and k/car). It's not exhasutive, i.e.
;;;    not all that is part of the kernel is prefixed with k/.
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
;;;  - () is the false value, and is mapped to 0 in the target. Its type is the <undefined> type,
;;;    which is denoted in the target by some integer assigned as per the type definition order.
;;;

(define-constant +maximum-call-stack-depth+	10000) ; to detect infinite recursion before the info gets lost into a sigsegv...
(define-constant feature/backtrace		(or true  feature/profiler (< 0 *safety*)))
(define-constant feature/object-canary		(or () (<= 3 *safety*)))
(define-constant feature/debug-output		(or () (<= 3 *safety*)))

(define-form debug		prog ())
(define-form debug/identities	prog ())
(define-form gc/debug		prog ())

(when-at-expand feature/debug-output
  (define *debug-output-enabled?* false)

  (define-form debug		prog	`(when *debug-output-enabled?* ,@prog))
  ;;(define-form debug/identities	prog	`(when *debug-output-enabled?* ,@prog))
  ;;(define-form gc/debug		prog	`(when *debug-output-enabled?* ,@prog))
  )

;; TODO use print-to-string eventually to generate the default assertion message, or add support for list literals in the compiler
;;(define-form assert		prog ())
(define-form assert		(test . args)	`(or ,test (error ,@(or args (list "kernel assertion failed")))))

;; these are deliberately named the same as the binding in the evaluator, so that e.g. the verbosity macro works as expected also in the level-shifted code
(define *verbosity*		0)
(define *optimised*		0)

(define-constant oop/alignment-in-bytes		+word-size-in-bytes+)
(define-constant oop/align-padding		(- oop/alignment-in-bytes 1))
(define-constant oop/payload-mask		(- oop/alignment-in-bytes))
(define-constant oop/tag-mask			(bitwise-not oop/payload-mask))

(verbosity 1 (warn "oop/alignment-in-bytes is "oop/alignment-in-bytes", oop/align-padding is "oop/align-padding", oop/payload-mask is "oop/payload-mask", oop/tag-mask is "oop/tag-mask"\n"))

(define-form oop/align (value)
  `(bitwise-and (+ ,value ,oop/align-padding)
                ,oop/payload-mask))

(define-form aligned-to-oop? (ptr)
  `(= 0 (bitwise-and ,ptr
                     ,oop/tag-mask)))

(define-form oop? (word)
  `(aligned-to-oop? ,word))

(define-form immediate? (word)
  `(not (oop? ,word)))

(define-form copy-oops (from to wordcount)
  `(libc/memcpy ,to ,from (words-to-bytes ,wordcount)))

(define-form move-oops (from to wordcount)
  `(libc/memmove ,to ,from (words-to-bytes ,wordcount)))

(define-form copy-bytes (from to count)
  `(libc/memcpy ,to ,from ,count))

(define-form move-bytes (from to count)
  `(libc/memmove ,to ,from ,count))

;; redefine %accessor-typecheck with a macro that redirects to a kernel version that drops the slot-name,
;; because the compiler cannot emit symbols yet
;; TODO this is ugly for now
(define-form %accessor-typecheck (expected-type-id slot-name object)
  ;; TODO? `(k/%accessor-typecheck ,expected-type-id ,object)
  object)

;;;
;;; forward definitions, so that the variables get created early enough for building the graph
;;; ----------------------------------------------------------------
(define-form define-forwards names
  `(let ()
     ,@(map (lambda (name) (list 'define name))
            names)))

(define-forwards
    fixed-primitive-function/quote
    fixed-primitive-function/lambda
    fixed-primitive-function/let
    fixed-primitive-function/define
    fixed-primitive-function/set

    k/+end+ ; a unique value that cannot ever be read from any source file; will be initialized at startup to an uninterned symbol

    libc/stdin libc/stdout libc/stderr

    ;; and finally, these are the names of our own functions. we need to resolve some circular references this way.
    print-backtrace capture-well-known-module-values populate-module-with-maru-primitives
    print println read encode expand eval string->symbol k/%accessor-typecheck)

;;;
;;; libc
;;; ----------------------------------------------------------------

(define-foreign-functions/libc)

(define-function libc/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

;;;
;;; utils
;;; ----------------------------------------------------------------

(define-function max (a b)
  (if (> a b) a b))

;;;
;;; global state
;;;
;;; Some of the state of the Maru VM being implemented needs to be
;;; captured/known by the code implementing it in the target VM.
;;; ----------------------------------------------------------------

(define *module*)
(define *maru-module*)
(define *symbols*)

(define *call-stack-index*	0)
(when-at-expand feature/backtrace
  (define *call-stack*		0))

;; cache some symbols into the symbol/foo global variables
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
    lambda let *globals*)

;;;
;;; error handling
;;; ----------------------------------------------------------------

(define-function die ()
  (libc/fprintf libc/stderr "\nDIE called...\n")
  (libc/flush-streams)
  (print-backtrace)
  (libc/flush-streams)
  (libc/abort))

;; FATAL directly uses the libc printf (i.e. it cannot print maru objects), while
;; ERROR goes through the maru printing facility (i.e. must not be called with an .asciz).
(define-function fatal  (fmt)           (libc/fprintf libc/stderr fmt)           (libc/fprintf libc/stderr "\n") (die))
(define-function fatal1 (fmt arg)       (libc/fprintf libc/stderr fmt arg)       (libc/fprintf libc/stderr "\n") (die))
(define-function fatal2 (fmt arg1 arg2) (libc/fprintf libc/stderr fmt arg1 arg2) (libc/fprintf libc/stderr "\n") (die))

;; FIXME it would be nice for ERROR to be a function (or at least expand to a breakpoint'able function call),
;; but that would need the compiler to support variable nr of args, or literal lists
(define-form error args
  `(let ()
     (libc/printf "\nerror: ")
     ,@(map (lambda (arg)
              ;; string literals are turned into pointers to .asciz, therefore
              ;; we need to print them using libc/printf (or instantiate
              ;; them into Maru objects using new-<string>-from-cstring).
              (if (string? arg)
                  `(libc/printf ,arg)
                  `(print ,arg)))
            args)
     (libc/printf "\n")
     (die)))

;;;
;;; copy the types here that should be visible to the target code
;;; ----------------------------------------------------------------

(define-form define-target-types names
  `(let ()
     ,@(map (lambda (name)
              `(define ,name (eval-in-module *slave-module* ',name)))
            names)))

(define-target-types
    <data> <undefined> <long> <array> <string> <expr> <form> <fixed> <primitive-function>
    <variable> <env> <context> <module> <target-vm-pointer> <symbol> <pair>)

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")

;;;
;;; types and their kernel accessors (get, put, is)
;;;
;;; unsurprisingly, types are represented in the target as integers.
;;; <undefined> doesn't necessarily need to be denoted by zero.
;;; the primitive-functions encode/implement the behavior of the primitive types.
;;; ----------------------------------------------------------------

(define-form define-type-of ()
  (let ((conds-early	())
        (conds-late	()))
    (types-do type
      (when (immediate-type? type)
        (let* ((tag-value	(<immediate-type>-tag-value type))
               (tag-width	(<immediate-type>-tag-width type)))
          (if tag-width
              (let ((tag-mask (bitwise-not (- (bitwise-shift 1 tag-width)))))
                (push conds-late `((= ,tag-value (bitwise-and ptr ,tag-mask)) ,(<type>-name type))))
            (push conds-early `((= ,tag-value ptr) ,(<type>-name type)))))))
    `(define-function type-of (ptr)
       (cond
         ,@conds-early
         ((oop? ptr)	(let ((header (gc/header-of ptr)))
                          (safety 3 (or (gc/valid-header-canary? header) (fatal1 "type-of: encountered an untagged pointer: %p" ptr)))
                          (safety 1 (or (bitwise-and <header>-flags/used (<header>-flags header)) (fatal1 "type-of: attempt to access dead object: %p" ptr)))
                          (<header>-type header)))
         ,@conds-late
         (else (fatal1 "type-of: encountered something unidentifiable: {%p}" ptr))))))

(define-type-of)

(define-form is (type ptr)
  `(= ,type (type-of ,ptr)))

(define-function k/%accessor-typecheck (expected-type-id object)
  (let ((type (type-of object)))
    (or (= type expected-type-id)
        (fatal2 "kernel get/put type error: expected type id %ld, got %ld" expected-type-id type)))
  (return object))

;; "one of the reasons for having all accesses to object fields go through get() and set() was to make it ridiculously easy to add read and write barriers" - Piumarta
(define-form get (designator object)
  (let* ((type-name	(first designator))
         (slot		(second designator))
         (type		(eval type-name)))
    (assert (not (cddr designator)) "malformed get designator: "designator)
    ;; we could use the accessors, too:
    ;; (,(concat-symbol (concat-symbol type-name '-) slot) __obj__)
    `(oop-at ,(if feature/typecheck-slot-access
                  `(k/%accessor-typecheck ,type-name ,object)
                object)
             ,(record/slot-index type slot))))

(define-form put (designator object value)
  (let* ((type-name	(first designator))
         (slot		(second designator))
         (type		(eval type-name)))
    (assert (not (cddr designator)) "malformed put designator: "designator)
    ;; we could use the accessors, too:
    ;; (set (,(concat-symbol (concat-symbol type-name '-) slot) __obj__) ,value)
    `(set (oop-at ,(if feature/typecheck-slot-access
                       `(k/%accessor-typecheck ,type-name ,object)
                     object)
                  ,(record/slot-index type slot))
          ,value)))

;; shorthands (and optimizations)
(define-form long?		(obj)		`(is <long> ,obj))
(define-form pair?		(obj)		`(is <pair> ,obj))
(define-form string?		(obj)		`(is <string> ,obj))
(define-form symbol?		(obj)		`(is <symbol> ,obj))
(define-form array?		(obj)		`(is <array> ,obj))
(define-form get/long		(obj)		(if (immediate-type? <long>)
                                                    (if (< *safety* 2)
                                                        `(>> ,obj ,(<immediate-type>-tag-width <long>))
                                                      `(let ((__obj__ ,obj))
                                                         (assert (long? __obj__))
                                                         (>> __obj__ ,(<immediate-type>-tag-width <long>))))
                                                  (if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <long> '_bits))	`(get (<long> _bits) ,obj))))
(define-form get/head		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'head))	`(get (<pair> head) ,obj)))
(define-form put/head		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'head) ,val)	`(put (<pair> head) ,obj ,val)))
(define-form get/tail		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'tail))	`(get (<pair> tail) ,obj)))
(define-form put/tail		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'tail) ,val)	`(put (<pair> tail) ,obj ,val)))

;;(define-form is/tvmptr	(obj)		`(is <target-vm-pointer> ,obj))
(define-form get/tvmptr		(obj)		`(get (<target-vm-pointer> _bits) ,obj))

(define-form get/string		(obj)		`(get (<string> elements) (string-ensure-zero-terminated ,obj)))
(define-form get/symbol		(obj)		`(get (<symbol> _bits) ,obj))

(define-form get/variable-value	(var)		`(get (<variable> value)
                                                      ,(if (string? var)
                                                           `(defined? (string->symbol ,var) (module-env *module*))
                                                         var)))

(define-form put/variable-value	(var val)	`(put (<variable> value)
                                                      ,(if (string? var)
                                                           `(defined? (string->symbol ,var) (module-env *module*))
                                                         var)
                                                      ,val))
;; TODO should we turn these into macros? or introduce compiler macros?
(define-function car (list)
  (when list
    (safety 1 (assert (pair? list) "car called on non-list: " list))
    (get/head list)))

(define-function cdr (list)
  (when list
    (safety 1 (assert (pair? list) "cdr called on non-list: " list))
    (get/tail list)))

(load "source/list-min.l")

;;;
;;; object instantiation
;;; ----------------------------------------------------------------

(define-form new-record-instance (type)
  (set type (eval type))
  (assert (subtype? (type-of type) <record>))
  `(gc/allocate ,(<type>-slave-id type) ,(words-to-bytes (record/effective-slot-count type))))

(define-form new-record-instance/opaque (type)
  (set type (eval type))
  (assert (subtype? (type-of type) <record>))
  `(gc/allocate-opaque ,(<type>-slave-id type) ,(words-to-bytes (record/effective-slot-count type))))

(define-form new-<long> (bits)
  (if (immediate-type? <long>)
      `(+ (<< ,bits ,(<immediate-type>-tag-width <long>))
          ,(<immediate-type>-tag-value <long>))
    `(let ((obj (new-record-instance/opaque <long>)))
       (set (<long>-_bits obj) ,bits)
       obj)))

(define-function new-<target-vm-pointer> (bits)
  (let ((obj (new-record-instance/opaque <target-vm-pointer>)))
    (set (<target-vm-pointer>-_bits obj) bits)
    obj))

(define-function cons (head tail)
  (let ((obj (new-record-instance <pair>)))
    (set (<pair>-head obj) head)
    (set (<pair>-tail obj) tail)
    obj))

(define-function string (len)
  (gc/let* ((str (new-record-instance <string>)))
    (put (<string> size) str (new-<long> len))
    (when (> len 0)
      (put (<string> elements) str (gc/allocate-opaque <data> len)))
    str))

(define-function new-<string>-from-cstring (cstr)
  (let* ((len (libc/strlen cstr))
         (obj (string len)))
    (libc/memcpy (get (<string> elements) obj) cstr len)
    obj))

(define-function new-<symbol> (cstr)
  (let ((len (libc/strlen cstr)))    ; +1 is for the zero termination
    (gc/let* ((obj  (new-record-instance <symbol>))
              (bits (gc/allocate-opaque <data> (+ len 1))))
      (libc/memcpy bits cstr (+ len 1))
      (put (<symbol> _bits) obj bits)
      obj)))

(define-function array (capacity)
  (gc/let* ((arr (new-record-instance <array>)))
    (put (<array> size) arr (new-<long> 0))
    (when (> capacity 0)
      (put (<array> elements) arr (gc/allocate <data> (words-to-bytes capacity))))
    arr))

(define-function new-<expr> (parameters body env ctx)
  (let ((obj (new-record-instance <expr>)))
    (put (<expr> parameters)	obj parameters)
    (put (<expr> body)		obj body)
    (put (<expr> env)		obj env)
    (put (<expr> ctx)		obj ctx)
    (when-at-expand feature/profiler
      (put (<expr> profiler-counter) obj (new-<long> 0)))
    obj))

(define-function new-<form> (fn sym)
  (let ((obj (new-record-instance <form>)))
    (put (<form> function)	obj fn)
    (put (<form> symbol)	obj sym)
    obj))

(define-function new-<fixed> (fn)
  (let ((obj (new-record-instance <fixed>)))
    (put (<fixed> function)	obj fn)
    obj))

(define-function new-<primitive-function> (_imp _name)
  (let ((obj (new-record-instance/opaque <primitive-function>)))
    (put (<primitive-function> _imp)		obj _imp)
    (put (<primitive-function> _name)		obj _name)
    (when-at-expand feature/profiler
      (put (<primitive-function> profiler-counter) obj 0))
    obj))

(define-function new-<variable> (name value env index)
  (gc/let* ((obj (new-record-instance <variable>)))
    (put (<variable> name)	obj name)
    (put (<variable> value)	obj value)
    (put (<variable> env)	obj env)
    (put (<variable> index)	obj (new-<long> index))
    obj))

(define-function new-<env> (parent level offset)
  (gc/let* ((obj (new-record-instance <env>)))
    (put (<env> parent)		obj parent)
    (put (<env> level)		obj (new-<long> (if parent (+ (get/long (get (<env> level) parent)) level) 0)))
    (put (<env> offset)		obj (new-<long> offset))
    (put (<env> bindings)	obj (array 0))
    obj))

(define-function new-base-<context> (home caller env)
  (gc/let* ((obj (new-record-instance <context>)))
    (put (<context> home)	obj home)
    (put (<context> env)	obj env)
    (put (<context> bindings)	obj (array 0))
    obj))

;; (define-function new-<context> (home caller env)
;;   (let ((obj (new-record-instance <env>)))
;;     (gc/protect (obj)
;;       (set (<context>-home     obj) home)
;;       (set (<context>-env      obj) env)
;;       (set (<context>-bindings obj) (array 0))
;;       obj)))

(define-function new-<context> (home caller env)
  (let ((obj ()))
    (if (and caller
             (set obj (get (<context> callee) caller)))
        (let ()
          (put (<context> home) obj home)
          (put (<context> env)  obj env))
      (set obj (new-base-<context> home caller env))
      (when caller
        (put (<context> callee) caller obj)))
    obj))

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

(load "source/evaluator/arrays.l")
(load "source/evaluator/buffer.l")

;;;
;;; env
;;; ----------------------------------------------------------------

(define-function set-current-module (module)
  (debug (libc/printf "set-current-module {%p}\n" module))
  (set *module* module)
  (capture-well-known-module-values))

(define-form with-current-module (module . body)
  `(gc/let* ((__previous-module__ *module*)
             __result__)
     (set-current-module ,module)
     (set __result__ (let () ,@body))
     (set-current-module __previous-module__)
     __result__))

(define-function find-variable (env name)
  (safety 2 (assert (is <env> env)     "find-variable: env is not an <env>: "env))
  (safety 2 (assert (symbol? name) "find-variable: name is not a <symbol>: "name))
  (let* ((bindings (get (<env> bindings) env))
         (index    (array-length bindings))
         (vars     (get (<array> elements) bindings))) ; KLUDGE an early optimization that will bite us somewhere down the road...
    (while (<= 0 (decr index))
      (let ((var (oop-at vars index)))
        (when (= name (get (<variable> name) var))
          (return var))))))

(define-function defined? (name env)
  (safety 1 (assert (is <env> env) "defined?: env is not an <env>: "env))
  (safety 1 (assert (symbol? name) "defined?: name is not a <symbol>: "name))
  (while env
    (awhen (find-variable env name)
      (return it))
    (set env (get (<env> parent) env))))

(define-function variable-value (env name)
  (aif (defined? name env)
      (get (<variable> value) it)
    (fatal1 "undefined variable in variable-value: %s" (get/symbol name))))

(define-function ensure-variable (env name)
  (safety 1 (assert (is <env> env)		"ensure-variable: env arg is not of type <env>: "env))
  (safety 1 (assert (symbol? name)	"ensure-variable: name arg is not of type <symbol>: "name))
  (awhen (find-variable env name)
    (return it))
  (let ((offset (get/long (get (<env> offset) env))))
    (gc/let* ((var (new-<variable> name () env offset)))
      (put (<env> offset) env (new-<long> (+ offset 1)))
      (array-append (get (<env> bindings) env) var))))

(define-function environment-define (env name value)
  (safety 1 (assert (is <env> env) "environment-define: env is not of type <env>: "env))
  (safety 1 (assert (symbol? name) "environment-define: name is not of type <symbol>: "name))
  (debug (libc/printf "environment-define called, name is %s\n" (get/symbol name)))
  (let ((var (ensure-variable env name)))
    (put (<variable> value) var value)
    var))

(define-function string->symbol (cstr)
  (array-binary-search *symbols*
                       cstr
                       (lambda (item candidate)
                         (libc/strcmp item (get/symbol candidate)))
                       (lambda (array index item)
                         (debug (libc/printf "interning %s\n" item))
                         (gc/let* ((sym (new-<symbol> item)))
                           (array-insert array index sym)
                           sym))))

(define-function maybe-object-in-variable (var type)
  (let ((tmp var))
    (and tmp
         (is <variable> tmp)
         (set tmp (get (<variable> value) tmp))
         (or (not type)
             (= type (type-of tmp)))
         tmp)))

(define-function maybe-object-in-env (env name type)
  (when (symbol? name)
    (maybe-object-in-variable (defined? name env) type)))

(load "source/env-min.l")

;; TODO move this is also into env-min.l, but for that we need smart accessors in the level-shifted code that automatically do the unboxing
(define-function global-variable? (var)
  (let ((env (get (<variable> env) var)))
    (= 0 (get/long (get (<env> level) env)))))

(load "source/evaluator/reader.l")
(load "source/evaluator/printer.l")

;;;
;;; backtrace
;;; ----------------------------------------------------------------

(define-record <call-frame> () (callee-designator callee arguments))

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
       ;;(debug (libc/printf "with-new-call-frame returning with result: ") (dumpln __result__))
       __result__)))

(when-at-expand feature/backtrace
  (define-function %new-call-frame (callee-designator callee args)
    (safety 3 (unless (or (not callee-designator)	(gc/valid-maru-value? callee-designator))	(fatal1 "new-call-frame: encountered an untagged callee-designator: %p" callee-designator)))
    (safety 3 (unless (or (not callee)			(gc/valid-maru-value? callee))			(fatal1 "new-call-frame: encountered an untagged callee %p" callee)))
    (let ((frame (array-at *call-stack* *call-stack-index*)))
      (if frame
          (safety 1 (assert (is <call-frame> frame) "new-call-frame: found a non-<call-frame> in the *call-stack*, type: " (type-of frame)))
        (gc/let* ((new-frame (new-record-instance <call-frame>)))
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
      (let ((i *call-stack-index*))
        (while (<= 0 (decr i))
          (let ((call-frame (array-at *call-stack* i)))
            (libc/printf "%3ld: " i)
	    (dumpln (<call-frame>-callee-designator call-frame))
            (awhen (<call-frame>-callee call-frame)
              (libc/printf "\tcallee: ")
	      (dumpln it))
            (awhen (<call-frame>-arguments call-frame)
              (libc/printf "\targs: ")
	      (dumpln it))
            (libc/flush-streams))))
    (libc/fprintf libc/stderr "print-backtrace: call-frame tracking is disabled in this build. current call depth is %ld\n" *call-stack-index*)))

;;;
;;; apply
;;; TODO move this into the expand-encode-eval-apply order
;;; ----------------------------------------------------------------

(define-function apply/expr (fun arguments parent-ctx)
  (verbosity 3 (libc/printf "  A  ") (dump fun)  (libc/printf " ")  (dump arguments) (libc/printf " ") (dumpln parent-ctx) (libc/flush-streams))
  (let ((env	(get (<expr> env) fun))
        (params	(get (<expr> parameters) fun)))
    (gc/let* ((new-ctx (new-<context> (get (<expr> ctx) fun) parent-ctx env)))
      (let ((locals (get (<context> bindings) new-ctx))
            (args   arguments))
        (while (pair? params)
          (or (pair? args) (error "too few arguments for "fun": "arguments))
          (set (array-at locals (get/long (get (<variable> index) (get/head params))))
               (get/head args))
          (set params	(get/tail params))
          (set args	(get/tail args)))
        (when (is <variable> params)
          (set (array-at locals (get/long (get (<variable> index) params))) args)
          (set args ()))
        (when args
          (error "too many arguments for "fun": "arguments)))
      (let ((prg (get (<expr> body) fun))
            (result ()))
        (list-do exp prg
          (set result (eval exp new-ctx)))
        (when (get (<env> stable) env)
          (put (<context> callee) new-ctx ()))
        result))))

(define-function apply (fun arguments ctx)
  (debug (libc/printf "apply, function ") (dump fun) (libc/printf ", arguments: ") (dump arguments) (libc/printf "\n"))
  (safety 1 (assert fun "apply: fun is null"))
  (with-new-call-frame (symbol/apply fun arguments)
    (let ((type (type-of fun)))
      (cond
        ((= type <expr>)
         (apply/expr fun arguments ctx))

        ((= type <primitive-function>)
         ((get (<primitive-function> _imp) fun) arguments ctx))

        (else
         (aif (and *applicators*
                   (set it (maybe-object-in-variable *applicators* <array>))
                   (array-at it (type-of fun)))
             (gc/let* ((args arguments))
               (set args (cons fun args))
               (apply it args ctx))
           (error "cannot apply: " fun)))))))

;;;
;;; expand
;;; ----------------------------------------------------------------

(define-function maybe-form-in-env/function (env name)
  (awhen (maybe-object-in-env env name <form>)
    (get (<form> function) it)))

(define-function maybe-form-in-env/symbol (env name)
  (awhen (maybe-object-in-env env name <form>)
    (get (<form> symbol) it)))

(define-function expand-all (list env)
  (if (pair? list)
      (gc/let* ((head (expand		(get/head list) env))
                (tail (expand-all	(get/tail list) env)))
        (cons head tail))
    (expand list env)))

(define-function expand/pair (exp env -call-frame-)
  (gc/let* ((head (expand (get/head exp) env)))
    (debug (libc/printf "expand/pair on head ") (dumpln head))
    (when-at-expand feature/backtrace
      (set (<call-frame>-callee-designator	-call-frame-) (get/head exp))
      (set (<call-frame>-callee			-call-frame-) head)
      (set (<call-frame>-arguments		-call-frame-) (get/tail exp)))
    (let (expander)
      (cond
        ((= head symbol/let)
         ;; TODO use a collecting macro to simplify this
         (gc/let* ((new-bindings ()))
           (let ((bindings (cadr exp))
                 new-bindings-last)
             (list-do entry bindings
               (let (var-name)
                 (gc/let* (var-init-prog)
                   (if (pair? entry)
                       (let ()
                         (set var-name		(get/head entry))
                         (set var-init-prog	(expand-all (get/tail entry) env)))
                     (set var-name	entry)
                     (set var-init-prog	(cons () ())))
                   (gc/let* ((new-entry (cons var-name var-init-prog)))
                     (set new-bindings-last (if new-bindings
                                                (put/tail new-bindings-last (cons new-entry ()))
                                              (set new-bindings (cons new-entry ())))))))))
           (gc/let* ((tmp (expand-all (cddr exp) env))) ; the body
             (set tmp (cons new-bindings tmp))
             (set tmp (cons symbol/let tmp))
             tmp)))

        ((= head symbol/quote)
         (cons symbol/quote (get/tail exp)))

        ((= head symbol/set)
         (assert (and (cddr exp) (not (cdddr exp))) "illegal set form: " exp)
         (debug (libc/printf "expand/set on form ") (dumpln exp))
         (gc/let* ((body (expand-all (get/tail exp) env)))
           (let (fn-name)
             (if (and (pair? body)
                      (pair? (get/head body))
                      (set fn-name (get/head (get/head body)))
                      (symbol? fn-name))
                 ;; convert set forms: (set (foo a b c) new-value) -> (set-foo a b c new-value)
                 (gc/let* ((buf (new-<buffer>)))
                   (buffer-append-string buf "set-")
                   (buffer-append-string buf (get/symbol fn-name))
                   (gc/let* ((args (concat-list (get/tail (get/head body)) (get/tail body))))
                     (cons (string->symbol (buffer-contents buf))
                                 args)))
               (cons symbol/set body)))))

        ((= head symbol/define)
         (assert (not (cdddr exp)) "illegal define form: " exp)
         (let ((name	(cadr exp))
               (value	(caddr exp)))
           (list3 symbol/define name (expand value env))))

        ((= head symbol/lambda)
         (let ((params	(cadr exp))
               (body	(cddr exp)))
           (gc/let* ((tmp (expand-all body env)))
             (set tmp (cons params tmp))
             (cons symbol/lambda tmp))))

        ((set expander (maybe-form-in-env/function env head))
         ;; head is a <form> found in *env* (which may hold lexically scoped forms, and i think delegates all the way up to the module's env)
         (gc/let* ((args (cons env (get/tail exp)))
                   (expansion (apply expander args ())))
           (debug (libc/printf "expand/pair, found in local env, expanded to ") (dumpln expansion))
           (expand expansion env)))

        (else
         ;; head is not a <form> nor a fixed special form
         (gc/let* ((tail (expand-all (get/tail exp) env)))
           (cons head tail)))))))

(define-function expand/symbol (exp env)
  (debug (libc/printf "expand/symbol, exp ") (dump exp) (libc/printf ", env ") (dumpln env))
  (let (expander)
    (cond
      ((set expander (maybe-form-in-env/symbol env exp))
       ;; head is a <form> found in *env* (which may hold lexically scoped forms, and i think delegates all the way up to the module's env)
       (gc/let* ((args (list2 env exp))
                 (expansion (apply expander args ())))
         (debug (libc/printf "expand/symbol, found in local env, expanded to ") (dumpln expansion))
         (expand expansion env)))

      (else
       exp))))

(define-function expand (exp env)
  (debug (libc/printf "expand, exp ") (dump exp) (libc/printf ", env ") (dumpln env))
  (with-new-call-frame (symbol/expand () exp)
    (cond
      ((pair? exp)	(expand/pair	exp env -call-frame-))
      ((symbol? exp)	(expand/symbol	exp env))
      (else
       ;; consult the *expanders* array to see if there's any custom expander for this type
       (aif (and *expanders*
                 (set it (maybe-object-in-variable *expanders* <array>))
                 (array-at it (type-of exp)))
           (gc/let* ((args (cons exp ())))
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
    (debug (libc/printf "encode/pair of head ") (dump head) (libc/printf ", in env ") (dumpln env))
    ;; TODO FIXME this injects the env, but also returns a list with the same head => encode is not idempotent
    ;; because of that emit requires the introduction of the eval-encoded primitive-function
    (cond
      ((= head fixed-primitive-function/let)
       (gc/let* ((vars		())
                 (new-env	(new-<env> env 0 (get/long (get (<env> offset) env)))))
         ;; phase 1: first define the let variables into new-env
         (let (vars/last)
           (list-do entry (second exp)
             (debug (libc/printf "encode/let visiting entry ") (dumpln entry))
             (let* ((var-name	(first entry))
                    (var-obj	(environment-define new-env var-name ())))
               (set vars/last (if vars
                                  (put/tail vars/last (cons var-obj ()))
                                (set vars (cons var-obj ())))))))
         ;; update the offset of the parent env to "skip" the indices of our let variables
         (put (<env> offset) env
              (get (<env> offset) new-env))
         ;; phase 2: encode-all the init-progs and build the new bindings list
         (gc/let* (var
                   new-bindings)
           (let (new-bindings/last)
             (list-do entry (second exp)
               (gc/let* ((init-prog	(encode-all (get/tail entry) env))
                         (new-entry	(cons (pop vars) init-prog)))
                 (set new-bindings/last (if new-bindings
                                            (put/tail new-bindings/last (cons new-entry ()))
                                          (set new-bindings (cons new-entry ())))))))
           (set tail (encode-all (cddr exp) new-env)) ; encode the body
           (set tail (cons new-bindings tail))
           (set tail (cons new-env tail)))))

      ((= head fixed-primitive-function/lambda)
       (let ((args (cadr exp)))
         (gc/let* ((new-env (new-<env> env 1 0)))
           (while (pair? args)
             (environment-define new-env (get/head args) ())
             (set args (get/tail args)))
           (when args
             (environment-define new-env args ()))
           (set tail (encode-all tail new-env))
           (set tail (cons new-env tail)))))

      ((= head fixed-primitive-function/define)
       (let ((var (ensure-variable (module-env *module*) (car tail))))
         (set tail (encode-all (cdr tail) env))
         (set tail (cons var tail))))

      ((= head fixed-primitive-function/set)
       (let ((var (defined? (car tail) env)))
         (or var (fatal1 "set: undefined variable: %s" (get/symbol (car tail))))
         (and (or (not (car tail)) (cddr tail)) (error "encode: malformed SET expression " exp))
         (set tail (encode-all (cdr tail) env))
         (set tail (cons var tail))))

      ((!= head fixed-primitive-function/quote)
       (set tail (encode-all tail env))))
    ;; return value
    (cons head tail)))

(define-function encode/symbol (exp env)
  (debug (libc/printf "encode/symbol of %s" (get/symbol exp)) (libc/printf ", in env ") (dumpln env))
  (let ((var (or (defined? exp env)
                 (error "encode/symbol: failed for "exp", current module "*module*", env "env))))
    (if (global-variable? var)
        (let ((val (get (<variable> value) var)))
          (when (or (is <form> val)
                    (is <fixed> val))
            (return val)))
      (let ((venv (get (<variable> env) var)))
        (unless (= (get/long (get (<env> level) venv))
                   (get/long (get (<env> level) env)))
          (put (<env> stable) venv symbol/true))))
    var))

(define-function encode (exp env)
  (debug (libc/printf "encode of exp ") (dump exp) (libc/printf ", in env ") (dumpln env))
  (with-new-call-frame (symbol/encode () exp)
    (debug (libc/printf "encode is dispatching on type %ld\n" (type-of exp)))
    (cond
      ((pair? exp)		(encode/pair	exp env))
      ((symbol? exp)	(encode/symbol	exp env))
      (else
       (aif (and *encoders*
                 (set it (maybe-object-in-variable *encoders* <array>))
                 (array-at it (type-of exp)))
           (gc/let* ((args (cons env ())))
             (set args (cons exp args))
             (debug (libc/printf "encode/other: applying fn: ") (println it) (libc/printf " ") (print args) (libc/printf " ") (println env))
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
         (debug (libc/printf "eval of pair, head eval'ed to ") (dumpln evaled-head))
         (when-at-expand feature/backtrace
           (set (<call-frame>-callee -call-frame-) evaled-head))
	 (if (is <fixed> evaled-head)
	     (apply (get (<fixed> function) evaled-head) (get/tail exp) ctx)
	   (gc/let* ((args (eval-all (get/tail exp) ctx)))
             (when-at-expand feature/backtrace
               (set (<call-frame>-arguments -call-frame-) args))
             (apply evaled-head args ctx)))))
      (else
       (when-at-expand feature/backtrace
         (set (<call-frame>-callee-designator -call-frame-) exp))
       (aif (and *evaluators*
                 (set it (maybe-object-in-variable *evaluators* <array>))
                 (array-at it type))
	   (gc/let* ((args (cons exp ())))
	     (when-at-expand feature/backtrace
               (set (<call-frame>-callee -call-frame-) it))
	     (apply it args ctx))
         exp)))))

(define-function eval (exp ctx)
  (verbosity 3 (libc/printf "  E  ") (dump exp) (libc/printf " ") (dumpln ctx) (libc/flush-streams))
  (let ((type (type-of exp)))
    (cond
      ((= type <undefined>)	exp)
      ((= type <long>)		exp)
      ((= type <string>)	exp)
      ((= type <variable>)	(if (global-variable? exp)
				    (let ()
                                      (debug (libc/printf "eval is reading global var ") (dumpln exp))
                                      (get (<variable> value) exp))
				  (let ((delta (- (get/long (get (<env> level) (get (<context>  env) ctx)))
					      (get/long (get (<env> level) (get (<variable> env) exp))))))
				    (debug (libc/printf "eval is reading local var ") (dump exp) (libc/printf " with delta %ld\n" delta))
				    (while (< 0 delta)
				      (set ctx (get (<context> home) ctx))
				      (decr delta))
                                    (let* ((index (get/long (get (<variable> index) exp)))
                                           (value (array-at (get (<context> bindings) ctx) index)))
                                      (debug (libc/printf "eval is reading local var from context ") (dump ctx) (libc/printf " at index %ld, holding value " index) (dumpln value))
				      value))))
      ((= type <symbol>)	(error "encountered a <symbol> in eval. this shouldn't happen!"))
      (else			(eval/with-call-frame type exp ctx)))))


(define-function expand-encode-eval (form env)
  (debug (libc/printf "expand-encode-eval for form ") (println form))
  (gc/let* ((x form)
            (ctx (new-base-<context> () () env)))
					(verbosity 2 (libc/printf ";;; ? ")		(dumpln x))
    (set x (expand x env))		(verbosity 2 (libc/printf ";;; expd--> ")	(dumpln x))
    (set x (encode x env))		(verbosity 2 (libc/printf ";;; encd--> ")	(dumpln x))
    (set x (eval   x ctx))
					(verbosity 2 (libc/printf ";;; => ")		(dumpln x))
    (debug (libc/printf "expand-encode-eval for form ") (dump form) (libc/printf " is returning with ") (dumpln x))
    x))

(define-function repl-stream (stream)
  ;;(put/variable-value *input* (new-<long> stream))
  (unless (= libc/stdin stream)
    (libc/fscanf stream "#!%*[^\012\015]")) ; drop the possible #!./eval first line of the file
  (gc/let* ((res ()))
    (while (let ()
             (when (= libc/stdin stream)
               (libc/printf ".")
               (libc/flush-streams))
             (!= k/+end+ (set res (read stream))))
      (gc/let* ((env (new-<env> (module-env *module*) 1 0)))
        (set res (expand-encode-eval res env))
        (when (= libc/stdin stream)
          (gc/let* ((printer (cons res 0)))
            (set printer (cons (cons symbol/quote printer) 0))
            (set printer (cons (string->symbol "print") printer))
            (expand-encode-eval printer env))
          (libc/flush-streams))))
    (and (= libc/stdin stream)
         (libc/printf "\nmorituri te salutant\n"))
    res))

(define-function new-<module> (name)
  (debug (libc/printf "new-<module>\n"))
  (gc/let* ((module (new-record-instance <module>))
            (env    (new-<env> () 0 0))
            tmp)
    (set (<module>-globals module)	(environment-define env symbol/*globals* env))
    (when-at-expand feature/debug-info
      (set (<module>-name module)	(new-<string>-from-cstring (or name ""))))

    (when *maru-module*
      (copy-module-bindings *maru-module* module (lambda (name value) (not (= name symbol/*globals*)))))

    ;; we always overwrite these with empty arrays in the new module
    (set tmp (array 0))		(environment-define env (string->symbol "*expanders*")		tmp)
    (set tmp (array 0))		(environment-define env (string->symbol "*encoders*")		tmp)
    (set tmp (array 0))		(environment-define env (string->symbol "*evaluators*")		tmp)
    (set tmp (array 0))		(environment-define env (string->symbol "*applicators*")	tmp)

    (debug (libc/printf "new-<module> returning with ") (println module))
    module))

(when-at-expand feature/profiler
  ;; these are coming from profiler.c
  (define-foreign-function install_profiler_handler void install_profiler_handler (*))
  (define-foreign-function set_profiler_interval void set_profiler_interval (int))

  (define profiler/sample-counter 0)

  (define-function profiler/take-sample (_)
    (incr profiler/sample-counter)
    (let ((frame (current-call-frame)))
      (when frame
        (let* ((callee		(<call-frame>-callee frame))
               (callee-type	(type-of callee)))
          (with-forms ((incr-boxed ((place) `(set ,place (new-<long> (+ 1 (get/long ,place)))))))
            (cond
              ((= callee-type <expr>)
               (incr-boxed (<expr>-profiler-counter callee)))

              ((= callee-type <primitive-function>)
               (incr (<primitive-function>-profiler-counter callee)))))))))

  (define-function profiler/disable ()
    (set_profiler_interval 0)
    (when (< 0 profiler/sample-counter)
      (libc/fprintf libc/stderr "Profiler took %ld samples:\n" profiler/sample-counter)
      (let ((obj (gc/first-object)))
        (while obj
          (let ((type (type-of obj))
                (name ())
                (counter ()))
            (cond
              ((and (= type <expr>)
                    (< 0 (set counter (get/long (<expr>-profiler-counter obj)))))
               (set name (<expr>-name obj))
               (when name
                 (set name (get/symbol name))))

              ((and (= type <primitive-function>)
                    (< 0 (set counter (<primitive-function>-profiler-counter obj))))
               (set name (<primitive-function>-_name obj))))
            (when counter
              (libc/fprintf libc/stderr "%ld\t%s\n" counter (or name "n/a"))))
          (set obj (gc/next-object obj)))))))

;;;
;;; the primitive-functions
;;;
;;; ----------------------------------------------------------------

(load "source/evaluator/primitive-functions.l")

(define-function populate-module-with-maru-primitives (module)
  (debug (libc/printf "populate-module-with-maru-primitives for module {%p}\n" module))
  (let ((env (module-env module)))
    (gc/let* ((tmp))
      (set tmp (new-<long> *verbosity*))	(environment-define env (string->symbol "*verbosity*")		tmp)
      (set tmp (new-<long> *optimised*))	(environment-define env (string->symbol "*optimised*")		tmp)
      ;; an uninterned singleton symbol, i.e. a unique identity that cannot be recreated any other way
      (set k/+end+ (or k/+end+ (set tmp (new-<symbol> "+end+"))))
      (environment-define env (string->symbol "+end+") k/+end+))

    ;; make sure the symbol true evaluates to itself
    (environment-define env symbol/true symbol/true)

    (environment-define env (string->symbol "*maru-module*") *maru-module*)

    (instantiate-primitive-functions module)

    (set fixed-primitive-function/quote		(variable-value env symbol/quote))
    (set fixed-primitive-function/lambda	(variable-value env symbol/lambda))
    (set fixed-primitive-function/let		(variable-value env symbol/let))
    (set fixed-primitive-function/define	(variable-value env symbol/define))
    (set fixed-primitive-function/set		(variable-value env symbol/set))

    (assert (and (is <fixed> fixed-primitive-function/quote) (is <fixed> fixed-primitive-function/lambda) (is <fixed> fixed-primitive-function/let) (is <fixed> fixed-primitive-function/define) (is <fixed> fixed-primitive-function/set)) "populate-module-with-maru-primitives: final assert")))

(define-function capture-well-known-module-values ()
  (debug (libc/printf "capture-well-known-module-values from *module*, which is %p\n" *module*))
  ;; let's cache some values from *module* to speed up their access in tight loops
  (let ((env (module-env *module*)))
    (set *expanders*	(defined? (string->symbol "*expanders*") env))
    (set *encoders*	(defined? (string->symbol "*encoders*") env))
    (set *evaluators*	(defined? (string->symbol "*evaluators*") env))
    (set *applicators*	(defined? (string->symbol "*applicators*") env)))

  (debug (libc/printf "capture-well-known-module-values is done\n")))

(define-function main (argc argv)
  (debug (libc/printf "alive\n"))

  (set libc/stdin  (libc/fdopen 0 "r"))
  (set libc/stdout (libc/fdopen 1 "a"))
  (set libc/stderr (libc/fdopen 2 "a"))

  (libc/setbuf libc/stdout 0)
  ;; (when-at-expand (not (= target/os "darwin"))
  ;;   ;; TODO investigate: when enabled this crashes any following fprintf's to stderr on darwin
  ;;   (libc/setbuf libc/stderr 0))

  (gc/initialise)

  (safety 4 (set gc/frequency 1))

  (debug (libc/printf "gc initialized\n"))

  (assert (= <long>	(type-of (new-<long> 42))) "type-of for <long> is broken")
  (assert (= 42	(get/long (new-<long> 42))) "get/long is broken")

  (gc/push-root (address-of *module*))
  (gc/push-root (address-of *maru-module*))
  (gc/push-root (address-of *symbols*))

  (debug (libc/printf "initializing *call-stack*\n"))

  (when-at-expand feature/backtrace
    (gc/push-root (address-of *call-stack*))
    (set *call-stack* (array 32)))

  (set *symbols* (array 32))
  (initialize-symbol-cache)				(debug (libc/printf "initialized *symbols*\n"))

  (set *maru-module* (new-<module> "maru"))
  (populate-module-with-maru-primitives *maru-module*)
  (set *module* (new-<module> "maru-user"))
  (capture-well-known-module-values)			(debug (libc/printf "finished module initialization\n"))

  (debug (libc/printf "start processing argv\n"))

  ;; *command-line-arguments*
  (let ((cla-var (environment-define (module-env *module*) (string->symbol "*command-line-arguments*") ())))
    ;; initialize *cla*
    (gc/let* ((tmp ()))
      (let ((idx argc))
        (while (< 0 (decr idx))
          (debug (libc/printf "processing argv %ld = %s\n" idx (oop-at argv idx)))
          (set tmp (cons () tmp))
          (put/head tmp (new-<string>-from-cstring (oop-at argv idx)))))
      (put (<variable> value) cla-var tmp))

    (debug (libc/printf "*command-line-arguments* is initialized\n"))

    ;; process *cla*
    (let (cla tmp)
      (while (pair? (set cla (get (<variable> value) cla-var)))
        (let* ((arg-string	(get/head cla))
               (arg		(get/string arg-string)))
          (gc/protect (arg-string tmp)
            (put (<variable> value) cla-var (set cla (get/tail cla))) ; (pop *command-line-arguments*)
            (cond
              ;; -v
              ((not (libc/strcmp arg "-v"))
               (incr *verbosity*)
               (set tmp (new-<long> *verbosity*))
               (put/variable-value "*verbosity*" tmp))

              ;; -O
              ((not (libc/strcmp arg "-O"))
               (incr *optimised*)
               (set tmp (new-<long> *optimised*))
               (put/variable-value "*optimised*" tmp))

              ;; -p
              ((not (libc/strcmp arg "-p"))
               (if-at-expand feature/profiler
                   (let ((usecs 1000))
                     (install_profiler_handler profiler/take-sample)
                     (set_profiler_interval usecs)
                     (libc/fprintf libc/stderr "profiling at every %ld uSec(s)\n" usecs))
                 (libc/fprintf libc/stderr "WARNING: this build has no profiler, ignoring -p\n")))

              ;; -
              ((not (libc/strcmp arg "-"))
               (repl-stream libc/stdin))

              ;; --call to call a function
              ((not (libc/strcmp arg "--call"))
               (debug (libc/printf "processing a --call\n"))
               (unless (pair? cla)
                 (fatal "--call requires an argument"))
               (set arg-string (get/head cla))
               (set arg (get/string arg-string))
               (put (<variable> value) cla-var (set cla (get/tail cla))) ; (pop *command-line-arguments*)
               (let ((sym (string->symbol arg)))
                 (gc/let* ((form (cons sym ())))
                   (expand-encode-eval form (module-env *module*)))))

              ;; --define to define a variable
              ((not (libc/strcmp arg "--define"))
               (debug (libc/printf "processing a --define\n"))
               (unless (and (pair? cla)
                            (pair? (get/tail cla)))
                 (fatal "--define requires two arguments"))
               (let ((var (car  cla))
                     (val (cadr cla)))
                 (put (<variable> value) cla-var (set cla (get/tail (get/tail cla)))) ; (pop *command-line-arguments*) x 2
                 ;; convert to long when possible
                 (let* ((cstr	(get/string val))
                        (endptr	cstr)
                        (i	(libc/strtoul cstr (address-of endptr) 0)))
                   ;; TODO investigate: why the hell does this behave differently than the one at the other call site of strtoul?
                   ;; (when (or (not (= -1 i))
                   ;;           (= 0 (libc/strcmp cstr "-1")))
                   ;;   (set val (new-<long> i)))
                   (when (= 0 (char-at endptr 0))
                     (set val (new-<long> i))))
                 (gc/let* ((form (cons val ())))
                   (set form (cons (string->symbol (get/string var)) form))
                   (set form (cons symbol/define form))
                   (expand-encode-eval form (module-env *module*)))))

              ;; read file as a program
              (else
               (verbosity 1 (libc/fprintf libc/stderr "loading file: %s\t(as a CLA)\n" arg))
               (let ((stream (libc/fopen arg "r")))
                 (or stream (fatal1 "no such file: %s" arg))
                 (repl-stream stream)
                 (libc/fclose stream)))))))))

  (debug (libc/printf "main is on the way out\n"))

  (gc/collect)
  (libc/fprintf libc/stderr "%ld objects in %ld bytes, %ld bytes free\n" gc/objects-live gc/bytes-used gc/bytes-free)
  (when-at-expand feature/profiler
    (profiler/disable))
  (libc/flush-streams)

  (debug (libc/printf "main is returning normally\n"))
  (return 0))
