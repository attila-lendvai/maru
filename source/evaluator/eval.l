;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; The Maru VM, written in a dialect of Maru.
;;;

(define-form k/assert		prog ())
(define-form debug		prog ())
(define-form debug/identities	prog ())
(define-form gc/debug		prog ())

;;
;; you can enable safety and debugging features here
;;
;; TODO use print-to-string eventually to generate the default assertion message, or add support for list literals in the compiler
(define-form k/assert		(test . args)	`(or ,test (k/error ,@(or args (list "kernel assertion failed")))))
;(define-form debug		prog		`(let () ,@prog))
;(define-form debug/identities	prog		`(let () ,@prog))
;(define-form gc/debug		prog		`(let () ,@prog))

(define-constant feature/backtrace		(or true  feature/profiler (< 0 *safety*)))
(define-constant feature/object-canary		(or false (and (<= 3 *safety*) true))) ; TODO evolving? artifact

;; to detect infinite recursion before a sigsegv tells us so.
(define-constant +maximum-call-stack-depth+ 10000)

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

(define-constant oop/alignment-in-bytes		target/word-size-in-bytes)
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

(define *subr-registry* ()) ; define-subr collects them here at compile time

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Actual artifacts that are meant to be level-shifted into the target
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(compile-begin)

;; override the slot-accessor choke-point. any accessor expanded after this point
;; will expand to a simple oop-at form that the compiler can directly deal with.
(define-form slot-value (type-name slot-name object)
  ;; TODO either get rid of the get/put accessors, or expand this to them, but see note below
  (let* ((type (eval type-name))
         (slot-index (record/slot-index type slot-name)))
    (list 'oop-at
          ;; TODO to enable some type-checking, we need to somehow differentiate here between
          ;; the object level (simple define-function's that are meant to be level-shifted),
          ;; and the meta level (e.g. define-forms and other meta-level code that runs
          ;; while expanding the object-level stuff), because they need different typecheck forms.
          ;; this publication may be relevant for the solution:
          ;; Submodules in Racket https://www.cs.utah.edu/plt/publications/gpce13-f-color.pdf
          (if (and false feature/typecheck-slot-access)
              `(k/%accessor-typecheck ,(<type>-id type) ,object)
            object)
          slot-index)))

;;;
;;; some forward definitions to relax the error handler
;;; ----------------------------------------------------------------
(define print-backtrace)
(define populate-module-with-primitives)
(define capture-well-known-vm-values)
(define k/print)
(define k/read)
(define k/encode/list)
(define k/encode)
(define k/expand/list)
(define k/eval)

;;;
;;; libc
;;; ----------------------------------------------------------------

(define libc/stdin)
(define libc/stdout)
(define libc/stderr)

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
;;; ----------------------------------------------------------------

(define k/+end+) ; a unique value that cannot ever be read from any source file; will be initialized at startup to an uninterned symbol

(define *call-stack-index*	0)
(when-at-expand feature/backtrace
  (define *call-stack*		0))

;; these are deliberately named the same as the binding in the evaluator, so that e.g. the verbosity macro works as expected also in the level-shifted code
(define *verbosity*		(or (debug 1) 0))
(define *optimised*		0)

;; Some of the state of the Maru VM being implemented needs to be
;; captured/known by the code implementing it in the target VM.
;; Only the first one of these is essential: *module*, the rest could
;; be looked up each time; i.e. they're just optimization or debug helpers.
(define *module*)
(define *symbols*)

;; optimization: we cache these definitions from the env of the Maru VM
;; to avoid looking them up a gazillion times.
(define var/*expanders*)
(define var/*encoders*)
(define var/*evaluators*)
(define var/*applicators*)
(define var/*input*)

(define symbol/true)
(define symbol/dot)
(define symbol/define)
(define symbol/set)
(define symbol/quote)
(define symbol/quasiquote)
(define symbol/unquote)
(define symbol/unquote_splicing)
(define symbol/expand)
(define symbol/encode)
(define symbol/apply)

(define fixed-subr/quote)
(define fixed-subr/lambda)
(define fixed-subr/let)
(define fixed-subr/define)
(define fixed-subr/set)

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
;; K/ERROR goes through the maru printing facility (i.e. must not be called with an .asciz).
(define-function fatal  (fmt)           (libc/fprintf libc/stderr fmt)           (libc/fprintf libc/stderr "\n") (die))
(define-function fatal1 (fmt arg)       (libc/fprintf libc/stderr fmt arg)       (libc/fprintf libc/stderr "\n") (die))
(define-function fatal2 (fmt arg1 arg2) (libc/fprintf libc/stderr fmt arg1 arg2) (libc/fprintf libc/stderr "\n") (die))

;; FIXME it would be nice for K/ERROR to be a function (or at least expand to a breakpoint'able function call),
;; but that would need the compiler to support variable nr of args, or literal lists
(define-form k/error args
  `(let ()
     (libc/printf "\nerror: ")
     ,@(map (lambda (arg)
              ;; string literals are turned into pointers to .asciz, therefore
              ;; we need to print them using libc/printf (or instantiate
              ;; them into Maru objects using new-<string>-from-cstring).
              (if (string? arg)
                  `(libc/printf ,arg)
                  `(k/print ,arg)))
            args)
     (libc/printf "\n")
     (die)))

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(require "source/evaluator/gc.l")

;;;
;;; types and their kernel accessors (get, put, is)
;;;
;;; unsurprisingly, types are represented in the target as integers.
;;; <undefined> doesn't necessarily need to be denoted by zero.
;;; the subr's encode/implement the behavior of the primitive types.
;;; ----------------------------------------------------------------

(eval-at-expand
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
   `(define-function get/type (ptr)
      (cond
        ,@conds-early
        ((oop? ptr)	(let ((header (gc/header-of ptr)))
                          (safety 3 (or (gc/valid-header-canary? header) (fatal1 "get/type: encountered an untagged pointer: %p" ptr)))
                          (safety 1 (or (bitwise-and <header>-flags/used (<header>-flags header)) (fatal1 "get/type: attempt to access dead object: %p" ptr)))
                          (<header>-type header)))
        ,@conds-late
        (else (fatal1 "get/type: encountered something unidentifiable: {%p}" ptr))))))

(define-form is (type ptr)
  `(= ,type (get/type ,ptr)))

(define-function k/%accessor-typecheck (expected-type-id object)
  (let ((type (get/type object)))
    (or (= type expected-type-id)
        (fatal2 "kernel get/put type error: expected type id %ld, got %ld" expected-type-id type)))
  (return object))

;; "one of the reasons for having all accesses to object fields go through get() and set() was to make it ridiculously easy to add read and write barriers" - Piumarta
(define-form get (designator object)
  (let ((type-name	(first designator))
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
(define-form get/globals	()		`(get (<variable> value) (get (<module> globals) *module*)))
(define-form get/globals*	(obj)		`(get (<variable> value) (get (<module> globals) ,obj)))

(define-form is/long		(obj)		`(is <long> ,obj))
(define-form is/pair		(obj)		`(is <pair> ,obj))
(if (immediate-type? <long>)
    (define-form get/long	(obj)		(if (< *safety* 2)
                                                    `(>> ,obj ,(<immediate-type>-tag-width <long>))
                                                  `(let ((__obj__ ,obj))
                                                     (k/assert (is/long __obj__))
                                                     (>> __obj__ ,(<immediate-type>-tag-width <long>)))))
    (define-form get/long	(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <long> '_bits))	`(get (<long> _bits) ,obj))))
(define-form get/head		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'head))	`(get (<pair> head) ,obj)))
(define-form put/head		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'head) ,val)	`(put (<pair> head) ,obj ,val)))
(define-form get/tail		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'tail))	`(get (<pair> tail) ,obj)))
(define-form put/tail		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'tail) ,val)	`(put (<pair> tail) ,obj ,val)))

;;(define-form is/tvmptr	(obj)		`(is <target-vm-pointer> ,obj))
(define-form get/tvmptr		(obj)		`(get (<target-vm-pointer> _bits) ,obj))

(define-form get/string		(obj)		`(get (<string> elements) (k/string-ensure-zero-terminated ,obj)))
(define-form get/symbol		(obj)		`(get (<symbol> _bits) ,obj))

(define-form get/variable-value	(var)		`(get (<variable> value)
                                                      ,(if (string? var)
                                                           `(k/env/lookup-variable (get/globals) (k/intern ,var))
                                                         var)))

(define-form put/variable-value	(var val)	`(put (<variable> value)
                                                      ,(if (string? var)
                                                           `(k/env/lookup-variable (get/globals) (k/intern ,var))
                                                         var)
                                                      ,val))

(define-function k/car (list)
  (when list
    (k/assert (is/pair list) "k/car called on non-list: " list)
    (get/head list)))

(define-function k/cdr (list)
  (when list
    (k/assert (is/pair list) "k/cdr called on non-list: " list)
    (get/tail list)))

(define-function k/caar		(list)		(k/car (k/car list)))
(define-function k/cadr		(list)		(k/car (k/cdr list)))
(define-function k/cddr		(list)		(k/cdr (k/cdr list)))
(define-function k/caddr	(list)		(k/car (k/cdr (k/cdr list))))
(define-function k/cadddr	(list)		(k/car (k/cdr (k/cdr (k/cdr list)))))

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

(define-function new-<pair> (head tail)
  (let ((obj (new-record-instance <pair>)))
    (set (<pair>-head obj) head)
    (set (<pair>-tail obj) tail)
    obj))

(define-function new-<string>-of-length (len)
  (gc/let* ((str (new-record-instance <string>)))
    (put (<string> size) str (new-<long> len))
    (when (> len 0)
      (put (<string> elements) str (gc/allocate-opaque <data> len)))
    str))

(define-function new-<string>-from-cstring (cstr)
  (let* ((len (libc/strlen cstr))
         (obj (new-<string>-of-length len)))
    (libc/memcpy (get (<string> elements) obj) cstr len)
    obj))

(define-function new-<symbol> (cstr)
  (let ((len (libc/strlen cstr)))    ; +1 is for the zero termination
    (gc/let* ((obj  (new-record-instance <symbol>))
              (bits (gc/allocate-opaque <data> (+ len 1))))
      (libc/memcpy bits cstr (+ len 1))
      (put (<symbol> _bits) obj bits)
      obj)))

(define-function new-<array> (capacity)
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

(define-function new-<subr> (_imp _name)
  (let ((obj (new-record-instance/opaque <subr>)))
    (put (<subr> _imp)		obj _imp)
    (put (<subr> _name)		obj _name)
    (when-at-expand feature/profiler
      (put (<subr> profiler-counter) obj 0))
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
    (put (<env> bindings)	obj (new-<array> 0))
    obj))

(define-function new-base-<context> (home caller env)
  (gc/let* ((obj (new-record-instance <context>)))
    (put (<context> home)	obj home)
    (put (<context> env)	obj env)
    (put (<context> bindings)	obj (new-<array> 0))
    obj))

;; (define-function new-<context> (home caller env)
;;   (let ((obj (new-record-instance <env>)))
;;     (gc/protect (obj)
;;       (set (<context>-home     obj) home)
;;       (set (<context>-env      obj) env)
;;       (set (<context>-bindings obj) (new-<array> 0))
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
;;;
;;; ----------------------------------------------------------------

(define-function k/concat-list (head tail)
  (if (is/pair head)
      (gc/let* ((new-tail (k/concat-list (get/tail head) tail)))
        (new-<pair> (get/head head) new-tail))
    tail))

(require "source/evaluator/arrays.l")
(require "source/evaluator/buffer.l")
(require "source/evaluator/printer.l")

;;;
;;; env
;;; ----------------------------------------------------------------

(define-function global-variable? (var)
  (let ((env (get (<variable> env) var)))
    (and env (= 0 (get/long (get (<env> level) env))))))

(define-function k/env/lookup-variable (env name)
  (safety 1 (k/assert (is <env> env)     "k/env/lookup-variable: env is not an <env>: "env))
  (safety 1 (k/assert (is <symbol> name) "k/env/lookup-variable: name is not a <symbol>: "name))
  (while env
    (let* ((bindings (get (<env> bindings) env))
           (index    (k/array-length bindings))
           (vars     (get (<array> elements) bindings))) ; KLUDGE an early optimization that will bite us somewhere down the road...
      (while (<= 0 (decr index))
        (let ((var (oop-at vars index)))
          (and (= name (get (<variable> name) var))
               (return var)))))
    (set env (get (<env> parent) env))))

(define-function k/env/lookup-variable-or-die (env name)
  (let ((var (k/env/lookup-variable env name)))
    (or (and var (is <variable> var)) (fatal1 "k/env/lookup-variable-or-die failed for %s" (get/symbol name)))
    var))

(define-function k/env/variable-value (env name)
  (let ((var (k/env/lookup-variable env name)))
    (if var
        (get (<variable> value) var)
      (fatal1 "undefined variable in env/variable-value: %s" (get/symbol name)))))

(define-function k/env/ensure-variable (env name)
  (safety 1 (k/assert (is <env> env)		"k/env/ensure-variable: env arg is not of type env: "env))
  (safety 1 (k/assert (is <symbol> name)	"k/env/ensure-variable: name arg is not of type symbol: "name))
  (let* ((bindings (get (<env> bindings) env))
         (index (k/array-length bindings)))
    (while (<= 0 (set index (- index 1)))
      (let ((var (k/array-at bindings index)))
        (and (= name (get (<variable> name) var))
             (return var))))
    (let* ((off (get/long (get (<env> offset) env)))
           (var (new-<variable> name () env off)))
      (gc/protect (var)
        (put (<env> offset) env (new-<long> (+ off 1)))
        (k/array-append bindings var)))))

(define-function k/env/define (env name value)
  (safety 1 (k/assert (is <env> env) "k/env/define: env arg is not of type env: "env))
  (safety 1 (k/assert (is <symbol> name) "k/env/define: name arg is not of type symbol: "name))
  (debug (libc/printf "k/env/define called, name is %s\n" (get/symbol name)))
  (let ((var (k/env/ensure-variable env name)))
    (put (<variable> value) var value)
    var))

(define-function k/intern (cstr)
  ;; deal with ?: syntax for denoting modules
  ;; evolving?
  (let ((len (libc/strlen cstr))
        (submod ()))
    (for (i 0 len)
      (when (= ?: (string-at cstr i))
        (return (k/intern (+ 1 (+ cstr i)))))))
  ;; no module is denoted in cstr (anymore); it's just a symbol to be interned at this point
  (array-binary-search *symbols*
                       cstr
                       (lambda (item candidate)
                         (libc/strcmp item (get/symbol candidate)))
                       (lambda (array index item)
                         (debug (libc/printf "interning %s into module {%p}\n" cstr module))
                         (gc/let* ((sym (new-<symbol> item)))
                           (k/array-insert array index sym)
                           sym))))

(require "source/evaluator/reader.l")

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
            (let ((frame (k/array-at *call-stack* *call-stack-index*)))
              (with-instance-accessors frame <call-frame>
                (set frame.callee-designator	())
                (set frame.callee		())
                (set frame.arguments		())))))
       (debug (libc/printf "with-new-call-frame returning with result: ") (k/dumpln __result__))
       __result__)))

(when-at-expand feature/backtrace
  (define-function %new-call-frame (callee-designator callee args)
    (safety 3 (unless (or (not callee-designator)	(gc/valid-maru-value? callee-designator))	(fatal1 "new-call-frame: encountered an untagged callee-designator: %p" callee-designator)))
    (safety 3 (unless (or (not callee)			(gc/valid-maru-value? callee))			(fatal1 "new-call-frame: encountered an untagged callee %p" callee)))
    (let ((frame (k/array-at *call-stack* *call-stack-index*)))
      (if frame
          (safety 1 (k/assert (is <call-frame> frame) "new-call-frame: found a non-<call-frame> in the *call-stack*, type: " (get/type frame)))
        (gc/let* ((new-frame (new-record-instance <call-frame>)))
          (set (k/array-at *call-stack* *call-stack-index*) new-frame)
          (set frame new-frame)))
      (with-instance-accessors frame <call-frame>
        (set frame.callee-designator	callee-designator)
        (set frame.callee		callee)
        (set frame.arguments		args))
      frame))

  (define-function current-call-frame ()
    (when (< 0 *call-stack-index*)
      (k/array-at *call-stack* (- *call-stack-index* 1)))))

(define-function print-backtrace ()
  (if-at-expand feature/backtrace
      (let ((i *call-stack-index*))
        (while (<= 0 (decr i))
          (let ((call-frame (k/array-at *call-stack* i)))
            (libc/printf "%3ld: " i)
	    (k/dumpln (<call-frame>-callee-designator call-frame))
            (awhen (<call-frame>-callee call-frame)
              (libc/printf "\tcallee: ")
	      (k/dumpln it))
            (awhen (<call-frame>-arguments call-frame)
              (libc/printf "\targs: ")
	      (k/dumpln it))
            (libc/flush-streams))))
    (libc/fprintf libc/stderr "print-backtrace: call-frame tracking is disabled in this build. current call depth is %ld\n" *call-stack-index*)))

;;;
;;; eval
;;; ----------------------------------------------------------------

(define-function k/apply-expr (fun arguments parent-ctx)
  (verbosity 2 (libc/printf "  A  ") (k/dump fun)  (libc/printf " ")  (k/dump arguments) (libc/printf " ") (k/dumpln parent-ctx) (libc/flush-streams))
  (let ((env	(get (<expr> env) fun))
        (params	(get (<expr> parameters) fun)))
    (gc/let* ((new-ctx (new-<context> (get (<expr> ctx) fun) parent-ctx env)))
      (let ((locals (get (<context> bindings) new-ctx))
            (args   arguments))
        (while (is/pair params)
          (or (is/pair args) (k/error "too few arguments for "fun": "arguments))
          (set (k/array-at locals (get/long (get (<variable> index) (get/head params)))) (get/head args))
          (set params (get/tail params))
          (set args    (get/tail args)))
        (when (is <variable> params)
          (set (k/array-at locals (get/long (get (<variable> index) params))) args)
          (set args ()))
        (when args
          (k/error "too many arguments for "fun": "arguments)))
      (let ((prg (get (<expr> body) fun))
            (result ()))
        (while (is/pair prg)
          (set result (k/eval (get/head prg) new-ctx))
          (set prg (get/tail prg)))
        (when (get (<env> stable) env)
          (put (<context> callee) new-ctx ()))
        result))))

(define-function k/apply (fun arguments ctx)
  (debug (libc/printf "k/apply, function ") (k/dump fun) (libc/printf ", arguments: ") (k/dump arguments) (libc/printf "\n"))
  (safety 1 (k/assert fun "k/apply: fun is nil"))
  (with-new-call-frame (symbol/apply fun arguments)
    (let ((type (get/type fun)))
      (cond
        ((= type <expr>)	(k/apply-expr fun arguments ctx))
        ((= type <fixed>)	(k/apply (get (<fixed> function) fun) arguments ctx))
        ((= type <subr>)	((get (<subr> _imp) fun) arguments ctx))
        (else
         (let ((ap (k/array-at (get/variable-value var/*applicators*) (get/type fun))))
           (if ap
               (let ((args arguments))
                 (gc/protect (args)
                   (set args (new-<pair> fun args))
                   (k/apply ap args ctx)))
             (k/error "cannot apply: " fun))))))))

;;; ----------------------------------------------------------------

(define-function k/expand (exp env)
  (debug (libc/printf "k/expand, exp ") (k/dump exp) (libc/printf ", env ") (k/dump env) (libc/printf "\n"))
  (let ((result exp))
    (with-new-call-frame (symbol/expand () exp)
      (cond
        ((is/pair exp)
         (gc/let* ((head (k/expand (get/head exp) env)))
           (when-at-expand feature/backtrace
             (set (<call-frame>-callee-designator	-call-frame-) (get/head exp))
             (set (<call-frame>-callee			-call-frame-) head)
             (set (<call-frame>-arguments		-call-frame-) (get/tail exp)))
           (let (val fn)
             (if (and (is <symbol> head)
                      (set val (k/env/lookup-variable env head))
                      (is <variable> val)
                      (set val (get (<variable> value) val))
                      (is <form> val)
                      (set fn (get (<form> function) val)))
                 ;; head is a <form>
                 (gc/let* ((args (new-<pair> env (get/tail exp))))
                   (set result (k/apply fn args ()))
                   (set result (k/expand result env)))
               ;; head is not a <form>
               (gc/let* ((tail (get/tail exp)))
                 (unless (= head symbol/quote)
                   (set tail (k/expand/list tail env)))
                 ;; convert set forms: (set (foo a b c) new-value) -> (set-foo a b c new-value)
                 (when (and (= symbol/set head)
                            (is/pair (k/car tail))
                            (is <symbol> (k/caar tail)))
                   (gc/let* ((buf (new-<buffer>)))
                     (buffer-append-string buf "set-")
                     (buffer-append-string buf (get/symbol (get/head (get/head tail))))
                     (set head (k/intern (buffer-contents buf)))
                     (set tail (k/concat-list (get/tail (get/head tail)) (get/tail tail)))))
                 (set result (new-<pair> head tail)))))))
        ((is <symbol> exp)
         (let (val fn)
           (when (and (set val (k/env/lookup-variable env exp))
                      (is <variable> val)
                      (set val (get (<variable> value) val))
                      (is <form> val)
                      (set fn (get (<form> symbol) val)))
             ;; head is a <form>
             (gc/let* ((args (new-<pair> exp ())))
               (set args (new-<pair> env args))
               (set args (k/apply fn args ()))
               (set result (k/expand args env))))))
        (else
         ;; consult the *expanders* array to see if there's any custom expander for this type
         (let ((fn (k/array-at (get/variable-value var/*expanders*) (get/type exp))))
           (when fn
             (gc/let* ((args (new-<pair> exp ())))
               (set result (k/apply fn args ()))))))))
    result))

(define-function k/expand/list (list env)
  (if (is/pair list)
      (gc/let* ((head (k/expand		(get/head list) env))
                (tail (k/expand/list	(get/tail list) env)))
        (new-<pair> head tail))
    (k/expand list env)))

(define-function k/encode/pair (exp env)
  (gc/let* ((head (k/encode (get/head exp) env))
            (tail (get/tail exp)))
    (cond
      ((= head fixed-subr/let)		(let ((bindings (k/cadr exp)))
					  (gc/let* ((new-env (new-<env> env 0 (get/long (get (<env> offset) env)))))
					    (while (is/pair bindings)
					      (let ((var-name (get/head bindings)))
					        (and (is/pair var-name) (set var-name (get/head var-name)))
					        (k/env/define new-env var-name ())
					        (set bindings (get/tail bindings))))
					    (set tail (k/encode/list tail new-env))
					    (set tail (new-<pair> new-env tail)))))
      ((= head fixed-subr/lambda)	(let ((args (k/cadr exp)))
					  (gc/let* ((new-env (new-<env> env 1 0)))
					    (while (is/pair args)
					      (k/env/define new-env (get/head args) ())
					      (set args (get/tail args)))
					    (and args (k/env/define new-env args ()))
					    (set tail (k/encode/list tail new-env))
					    (set tail (new-<pair> new-env tail)))))
      ;; TODO this defines the variable in the encode phase, even if the code doesn't get executed in the end.
      ;; i doubt it's the intended behavior... investigate!
      ((= head fixed-subr/define)	(let ((var (k/env/ensure-variable (get/globals) (k/car tail))))
					  (set tail (k/encode/list (k/cdr tail) env))
					  (set tail (new-<pair> var tail))))
      ;; TODO and then this errors while expand'ing an if branch that is _not_ taken at the end at runtime
      ((= head fixed-subr/set)		(let ((var (k/env/lookup-variable env (k/car tail))))
					  (or var (fatal1 "set: undefined variable: %s" (get/symbol (k/car tail))))
					  (and (or (not (k/car tail)) (k/cddr tail)) (k/error "encode: malformed SET expression " exp))
					  (set tail (k/encode/list (k/cdr tail) env))
					  (set tail (new-<pair> var tail))))
      ((!= head fixed-subr/quote)	(set tail (k/encode/list tail env))))
    ;; return value
    (new-<pair> head tail)))

(define-function k/encode/symbol (exp env)
  (let ((var (k/env/lookup-variable env exp)))
    (or var (fatal1 "undefined variable in encode: '%s'" (get/symbol exp)))
    (set exp var)
    (if (global-variable? exp)
        (let ((val (get (<variable> value) exp)))
          (when (or (is <form> val)
                    (is <fixed> val))
            (set exp val)))
      (let ((venv (get (<variable> env) exp)))
        (unless (= (get/long (get (<env> level) venv))
                   (get/long (get (<env> level) env)))
          (put (<env> stable) venv symbol/true)))))
  exp)

(define-function k/encode/other (exp env)
  (let ((fn (k/array-at (get/variable-value var/*encoders*) (get/type exp))))
    (debug (libc/printf "k/encode/other looked up fn: ") (k/println fn))
    (when fn
      (gc/let* ((args (new-<pair> env ())))
        (set args (new-<pair> exp args))
        (debug (libc/printf "APPLY ENCODER\n... ") (k/print fn) (libc/printf " ") (k/print args) (libc/printf " ") (k/println env))
        (set exp (k/apply fn args ())))))
  exp)

(define-function k/encode (exp env)
  (debug (libc/printf "k/encode, exp ") (k/dump exp) (libc/printf ", env ") (k/dump env) (libc/printf "\n"))
  (with-new-call-frame (symbol/encode () exp)
    (debug (libc/printf "k/encode is dispatching on type %ld\n" (get/type exp)))
    (cond
      ((is/pair exp)		(k/encode/pair		exp env))
      ((is <symbol> exp)	(k/encode/symbol	exp env))
      (else			(k/encode/other		exp env)))))

(define-function k/encode/list (list env)
  (if (is/pair list)
      (gc/let* ((head (k/encode		(get/head list) env))
                (tail (k/encode/list	(get/tail list) env)))
        (new-<pair> head tail))
    (k/encode list env)))

(define-function k/eval/list (obj ctx)
  (if (is/pair obj)
      (gc/let* ((head (k/eval		(get/head obj) ctx))
                (tail (k/eval/list	(get/tail obj) ctx)))
        (new-<pair> head tail))
    obj))

(define-function k/eval/with-backtrace (type exp ctx)
  (with-new-call-frame (() () ())
    (cond
      ((= type <pair>)
       (when-at-expand feature/backtrace
         (set (<call-frame>-callee-designator	-call-frame-) (get/head exp))
         (set (<call-frame>-arguments		-call-frame-) (get/tail exp)))
       (gc/let* ((evaled-head (k/eval (get/head exp) ctx)))
         (debug (libc/printf "k/eval of pair, head eval'ed to ") (k/dumpln evaled-head))
         (when-at-expand feature/backtrace
           (set (<call-frame>-callee -call-frame-) evaled-head))
	 (if (is <fixed> evaled-head)
	     (k/apply (get (<fixed> function) evaled-head) (get/tail exp) ctx)
	   (gc/let* ((args (k/eval/list (get/tail exp) ctx)))
             (when-at-expand feature/backtrace
               (set (<call-frame>-arguments -call-frame-) args))
             (k/apply evaled-head args ctx)))))
      (else
       (when-at-expand feature/backtrace
         (set (<call-frame>-callee-designator -call-frame-) exp))
       (let ((evaluator (k/array-at (get/variable-value var/*evaluators*) type)))
	 (if evaluator
	     (gc/let* ((args (new-<pair> exp ())))
	       (when-at-expand feature/backtrace
                 (set (<call-frame>-callee -call-frame-) evaluator))
	       (k/apply evaluator args ctx))
           exp))))))

(define-function k/eval (exp ctx)
  (verbosity 2 (libc/printf "  E  ") (k/dump exp) (libc/printf " ") (k/dumpln ctx) (libc/flush-streams))
  (let ((type (get/type exp)))
    (cond
      ((= type <undefined>)	exp)
      ((= type <long>)		exp)
      ((= type <string>)	exp)
      ((= type <variable>)	(if (global-variable? exp)
				    (get (<variable> value) exp)
				  (let ((delta (- (get/long (get (<env> level) (get (<context>  env) ctx)))
					      (get/long (get (<env> level) (get (<variable> env) exp))))))
				    (while (< 0 delta)
				      (set ctx (get (<context> home) ctx))
				      (set delta (- delta 1)))
				    (k/array-at (get (<context> bindings) ctx) (get/long (get (<variable> index) exp))))))
      ((= type <symbol>)	(k/error "encountered a <symbol> in eval. this shouldn't happen!"))
      (else			(k/eval/with-backtrace type exp ctx)))))


(define-function k/expand-encode-eval (form env)
  (gc/let* ((x form)
            (ctx (new-base-<context> () () env)))
								(verbosity 2 (libc/printf ";;; ")	(k/dumpln x))
    (set x (k/expand x env))					(verbosity 3 (libc/printf "expd--> ")	(k/dumpln x))
    (set x (k/encode x env))					(verbosity 3 (libc/printf "encd--> ")	(k/dumpln x))
    (set x (k/eval   x ctx))
								(verbosity 2 (libc/printf ";;; => ")	(k/dumpln x))
    x))

(define-function k/repl-stream (stream)
  (put/variable-value var/*input* (new-<long> stream))
  (unless (= libc/stdin stream)
    (libc/fscanf stream "#!%*[^\012\015]")) ; drop the possible #!./eval first line of the file
  (gc/let* ((res ()))
    (while (let ()
             (when (= libc/stdin stream)
               (libc/printf ".")
               (libc/flush-streams))
             (!= k/+end+ (set res (k/read stream))))
      (gc/let* ((env (new-<env> (get/globals) 1 0)))
        (set res (k/expand-encode-eval res env))
        (when (= libc/stdin stream)
          (gc/let* ((printer (new-<pair> res 0)))
            (set printer (new-<pair> (new-<pair> symbol/quote printer) 0))
            (set printer (new-<pair> (k/intern "print") printer))
            (k/expand-encode-eval printer env))
          (libc/flush-streams))))
    (and (= libc/stdin stream)
         (libc/printf "\nmorituri te salutant\n"))
    res))

(define-function new-<module> ()
  (debug (libc/printf "new-<module>\n"))
  (gc/let* ((module (new-record-instance <module>))
            (env    (new-<env> () 0 0)))
    (set (<module>-symbols module)	(new-<array> 0))
    (set (<module>-globals module)	(k/env/define env (k/intern "*globals*") env))

    (populate-module-with-primitives module)

    (debug (libc/printf "new-<module> returning with %p\n" module))
    module))

(define-function k/set-current-module (module)
  (debug (libc/printf "k/set-current-module {%p}\n" module))
  (set *module* module)
  (capture-well-known-vm-values))

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
               (callee-type	(get/type callee)))
          (with-forms ((incr-boxed ((place) `(set ,place (new-<long> (+ 1 (get/long ,place)))))))
            (cond
              ((= callee-type <expr>)		(incr-boxed	(<expr>-profiler-counter callee)))
              ((= callee-type <subr>)		(incr		(<subr>-profiler-counter callee)))))))))

  (define-function profiler/disable ()
    (set_profiler_interval 0)
    (when (< 0 profiler/sample-counter)
      (libc/fprintf libc/stderr "Profiler took %ld samples:\n" profiler/sample-counter)
      (let ((obj (gc/first-object)))
        (while obj
          (let ((type (get/type obj))
                (name ())
                (counter ()))
            (cond
              ((and (= type <expr>)
                    (< 0 (set counter (get/long (<expr>-profiler-counter obj)))))
               (set name (<expr>-name obj))
               (when name
                 (set name (get/symbol name))))
              ((and (= type <subr>)
                    (< 0 (set counter (<subr>-profiler-counter obj))))
               (set name (<subr>-_name obj))))
            (when name
              (libc/fprintf libc/stderr "%ld\t%s\n" counter name)))
          (set obj (gc/next-object obj)))))))

;;;
;;; the subr's
;;;
;;; ----------------------------------------------------------------

(require "source/evaluator/subrs.l")

(define-function %instantiate-subr (name imp fixed? module)
  (gc/let* ((tmp (new-<subr> imp name)))
    (when fixed?
      (set tmp (new-<fixed> tmp)))
    (k/env/define (get/globals* module) (k/intern name) tmp)))

(define-form instantiate-subrs ()
  (let ((result ()))
    (list-do entry *subr-registry*
      (let* ((name (car entry))
             (impl-name (concat-symbol 'subr/ name))
             (fixed? (caddr entry)))
        (push result `(%instantiate-subr ,(symbol->string name) ,impl-name ,(target-boolean fixed?) module))))
    `(let () ,@result)))

(define-function populate-module-with-primitives (module)
  (debug (libc/printf "populate-module-with-primitives on %p\n" module))
  (safety 1 (k/assert (is <module> module) "populate-module-with-primitives: called with not a <module>: "module))
  ;; the predefined primitives of the language
  (let ((env (get/globals* module)))
    (gc/let* ((tmp))
				(k/env/define env (k/intern "*input*")			())
				(k/env/define env (k/intern "*command-line-arguments*")	())
      (set tmp (new-<long> *verbosity*))	(k/env/define env (k/intern "*verbosity*")		tmp)
      (set tmp (new-<long> 0))	(k/env/define env (k/intern "*optimised*")		tmp)

      (set tmp (new-<array> 0))	(k/env/define env (k/intern "*expanders*")		tmp)
      (set tmp (new-<array> 0))	(k/env/define env (k/intern "*encoders*")		tmp)
      (set tmp (new-<array> 0))	(k/env/define env (k/intern "*evaluators*")		tmp)
      (set tmp (new-<array> 0))	(k/env/define env (k/intern "*applicators*")		tmp)

      ;; an uninterned symbol, i.e. a unique identity that cannot be recreated any other way
      (set tmp (new-<symbol> "+end+")) (k/env/define env (k/intern "+end+") tmp))

    (let ((symbol/true (k/intern "true")))
      ;; make sure the symbol true evaluates to itself
      (k/env/define env symbol/true symbol/true))

    (instantiate-subrs)))

(define-function capture-well-known-vm-values ()
  (debug (libc/printf "capture-well-known-vm-values from *module*, which is %p\n" *module*))
  ;; let's cache some values from *module* to speed up their access in tight loops
  (set symbol/true                   (k/intern "true"))
  (set symbol/dot                    (k/intern "."))
  (set symbol/define                 (k/intern "define"))
  (set symbol/set                    (k/intern "set"))
  (set symbol/quote                  (k/intern "quote"))
  (set symbol/quasiquote             (k/intern "quasiquote"))
  (set symbol/unquote                (k/intern "unquote"))
  (set symbol/unquote_splicing       (k/intern "unquote-splicing"))
  (set symbol/expand                 (k/intern "expand"))
  (set symbol/encode                 (k/intern "encode"))
  (set symbol/apply                  (k/intern "apply"))

  (let ((global-env (get/globals)))
    (set k/+end+ (k/env/lookup-variable-or-die global-env (k/intern "+end+")))

    (set var/*expanders*	(k/env/lookup-variable-or-die global-env (k/intern "*expanders*")))
    (set var/*encoders*		(k/env/lookup-variable-or-die global-env (k/intern "*encoders*")))
    (set var/*evaluators*	(k/env/lookup-variable-or-die global-env (k/intern "*evaluators*")))
    (set var/*applicators*	(k/env/lookup-variable-or-die global-env (k/intern "*applicators*")))
    (set var/*input*		(k/env/lookup-variable-or-die global-env (k/intern "*input*")))

    (set fixed-subr/quote  (k/env/variable-value global-env (k/intern "quote")))
    (set fixed-subr/lambda (k/env/variable-value global-env (k/intern "lambda")))
    (set fixed-subr/let    (k/env/variable-value global-env (k/intern "let")))
    (set fixed-subr/define (k/env/variable-value global-env (k/intern "define")))
    (set fixed-subr/set    (k/env/variable-value global-env (k/intern "set")))

    (k/assert (and (is <fixed> fixed-subr/quote) (is <fixed> fixed-subr/lambda) (is <fixed> fixed-subr/let) (is <fixed> fixed-subr/define) (is <fixed> fixed-subr/set)) "capture-well-known-vm-values: assert 2"))

  (debug (libc/printf "capture-well-known-vm-values is done\n")))

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

  (k/assert (= <long>	(get/type (new-<long> 42))) "get/type for <long> is broken")
  (k/assert (= 42	(get/long (new-<long> 42))) "get/long is broken")

  (gc/push-root (address-of *module*))			; the gc root for all (module-)global definitions
  (gc/push-root (address-of *symbols*))
  (gc/push-root (address-of fixed-subr/quote))		; precautionary, in case someone redefines them and they get removed from the env.
  (gc/push-root (address-of fixed-subr/lambda))
  (gc/push-root (address-of fixed-subr/let))
  (gc/push-root (address-of fixed-subr/define))

  (debug (libc/printf "initializing *call-stack*\n"))

  (when-at-expand feature/backtrace
    (gc/push-root (address-of *call-stack*))
    (set *call-stack* (new-<array> 32)))

  (set *symbols* (new-<array> 32))			(debug (libc/printf "initialized *symbols*\n"))
  (set *module*  (new-<module>))			(debug (libc/printf "initialized *module*\n"))

  (capture-well-known-vm-values)

  (debug (libc/printf "start processing argv\n"))

  ;; *command-line-arguments*
  (let ((cla-var (k/env/lookup-variable (get/globals) (k/intern "*command-line-arguments*"))))
    ;; initialize *cla*
    (gc/let* ((tmp ()))
      (let ((idx argc))
        (while (< 0 (decr idx))
          (debug (libc/printf "processing argv %ld = %s\n" idx (oop-at argv idx)))
          (set tmp (new-<pair> () tmp))
          (put/head tmp (new-<string>-from-cstring (oop-at argv idx)))))
      (put (<variable> value) cla-var tmp))

    (debug (libc/printf "*command-line-arguments* is initialized\n"))

    ;; process *cla*
    (let (cla tmp)
      (while (is/pair (set cla (get (<variable> value) cla-var)))
        (let ((arg-string	(get/head cla))
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
               (k/repl-stream libc/stdin))

              ;; --call to call a function
              ((not (libc/strcmp arg "--call"))
               (debug (libc/printf "processing a --call\n"))
               (unless (is/pair cla)
                 (fatal "--call requires an argument"))
               (set arg-string (get/head cla))
               (set arg (get/string arg-string))
               (put (<variable> value) cla-var (set cla (get/tail cla))) ; (pop *command-line-arguments*)
               (let* ((sym (k/intern arg))
                      (form (new-<pair> sym ())))
                 (gc/protect (form)
                   (k/expand-encode-eval form (get/globals)))))

              ;; --define to define a variable
              ((not (libc/strcmp arg "--define"))
               (debug (libc/printf "processing a --define\n"))
               (unless (and (is/pair cla)
                            (is/pair (get/tail cla)))
                 (fatal "--define requires two arguments"))
               (let ((var (k/car  cla))
                     (val (k/cadr cla)))
                 (put (<variable> value) cla-var (set cla (get/tail (get/tail cla)))) ; (pop *command-line-arguments*) x 2
                 ;; convert to long when possible
                 (let* ((cstr	(get/string val))
                        (endptr	cstr)
                        (i	(libc/strtoul cstr (address-of endptr) 0)))
                   ;; TODO investigate: why the hell does this behave differently than the at the other call site of strtoul?
                   ;; (when (or (not (= -1 i))
                   ;;           (= 0 (libc/strcmp cstr "-1")))
                   ;;   (set val (new-<long> i)))
                   (when (= 0 (string-at endptr 0))
                     (set val (new-<long> i))))
                 (gc/let* ((form (new-<pair> val ())))
                   (set form (new-<pair> (k/intern (get/string var)) form))
                   (set form (new-<pair> symbol/define form))
                   (k/expand-encode-eval form (get/globals)))))

              ;; read file as a program
              (else
               (verbosity 1 (libc/fprintf libc/stderr "loading file: %s\t(as a CLA)\n" arg))
               (let ((stream (libc/fopen arg "r")))
                 (or stream (fatal1 "no such file: %s" arg))
                 (k/repl-stream stream)
                 (libc/fclose stream)))))))))

  (debug (libc/printf "main is on the way out\n"))

  (gc/collect)
  (libc/fprintf libc/stderr "%ld objects in %ld bytes, %ld bytes free\n" gc/objects-live gc/bytes-used gc/bytes-free)
  (when-at-expand feature/profiler
    (profiler/disable))
  (libc/flush-streams)

  (debug (libc/printf "main is returning normally\n"))
  (return 0))

(compile-end)
