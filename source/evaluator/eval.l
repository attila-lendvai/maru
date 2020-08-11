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

;; This variable controls the amount of safety features compiled
;; into the runtime, at the cost of execution speed.
(define safety-level 1)

(define-form safety (level . prog)
  (when (<= level safety-level)
    `(let () ,@prog)))

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

(define-constant immediate-type/max-tag-width	(let ((res 0))
                                                  (types-do type
                                                    (when (immediate-type? type)
                                                      (set res (max res (<immediate-type>-tag-width type)))))
                                                  res))

(when (< target-word-size/bytes
         (<< 1 immediate-type/max-tag-width))
  (warn "immediate-type/max-tag-width ("immediate-type/max-tag-width") will force a stronger alignment for OOP's than what the target word size demands\n"))

(define-constant oop/alignment-in-bytes		(max target-word-size/bytes (<< 1 immediate-type/max-tag-width)))
(define-constant oop/align-padding		(- oop/alignment-in-bytes 1))
(define-constant oop/payload-mask		(- oop/alignment-in-bytes))
(define-constant oop/tag-mask			(^ oop/payload-mask -1))

;;(warn "oop/alignment-in-bytes is "oop/alignment-in-bytes", oop/align-padding is "oop/align-padding", oop/payload-mask is "oop/payload-mask", oop/tag-mask is "oop/tag-mask"\n")

(define-form oop/align (value)
  `(& (+ ,value ,oop/align-padding) ,oop/payload-mask))

(define-form aligned-to-oop? (ptr)
  `(= 0 (& ,ptr ,oop/tag-mask)))

(define-form oop? (word)
  `(aligned-to-oop? ,word))

(define-form immediate? (word)
  `(not (oop? ,word)))

(define-form malloc-oops (wordcount)
  `(libc/malloc (words-to-bytes ,wordcount)))

(define-form copy-oops (from to wordcount)
  `(libc/memcpy ,to ,from (words-to-bytes ,wordcount)))

(define-form move-oops (from to wordcount)
  `(libc/memmove ,to ,from (words-to-bytes ,wordcount)))

;; the header of heap objects
(eval `(define-record <header> () (,@(when (<= 3 safety-level) (list 'magic-marker)) size flags next type)))

(define-form byte-size-of (type)
  (words-to-bytes (record/effective-slot-count (eval type))))

(define-constant size-of-<header> (byte-size-of <header>))

(define-form header-of (arg)
  `(- ,arg ,size-of-<header>))

(let ((marker 233495534)) ; 0xDEADBEE, it's just an easy to recognize token without any meaning
  (define-form valid-header-magic-marker? (header)
    `(= (<header>-magic-marker ,header) ,marker))

  (define-form initialize-header-magic-marker (header)
    `(set (<header>-magic-marker ,header) ,marker)))

(define-constant <header>-flags/used	1)
(define-constant <header>-flags/opaque	2) ; the GC will not look inside opaque objects
(define-constant <header>-flags/mark	4)

(define *subr-registry* ()) ; define-subr collects them here at compile time

;; TODO get rid of this by representing the metadata of strucure fields as full objects that hold the offset
(define-function record-slot-index (type slot-name)
  (let ((i 0)
        (list (<record>-effective-slots type)))
    (while (and (pair? list)
                (not (= slot-name (car list))))
      (set list (cdr list))
      (set i (+ i 1)))
    (or (and (pair? list)
             i)
        (error "record-slot-index has failed for type "type", slot-name "slot-name))))

;; TODO FIXME this crashes the gc when inside (compile-begin)
(define-record <buffer> () (contents capacity position))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Actual artifacts that are meant to be level-shifted into the target
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(compile-begin)

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

(require "source/evaluator/buffer.l")

(define-function max (a b)
  (if (> a b) a b))

;;;
;;; global state
;;; ----------------------------------------------------------------

(define k/+done+) ; we need a unique value that k/read cannot ever read from any source file; will be initialized at startup

(define *backtrace-stack*	0)
(define *backtrace-index*	0)

(define *arg/verbose*		0)
(define *arg/optimised*		0)

;; Some of the state of the Maru VM being implemented needs to be
;; captured/known by the code implementing it in the target VM.
;; Only the first one of these is essential: *module*, the rest could
;; be looked up each time; i.e. they're just optimization or debug helpers.
(define *module*)

;; optimization: we cache these definitions from the env of the Maru VM
;; to avoid looking them up a gazillion times.
(define var/*expanders*)
(define var/*encoders*)
(define var/*evaluators*)
(define var/*applicators*)
(define var/*input*)

(define symbol/t)
(define symbol/dot)
(define symbol/define)
(define symbol/set)
(define symbol/quote)
(define symbol/quasiquote)
(define symbol/unquote)
(define symbol/unquote_splicing)

(define fixed-subr/quote)
(define fixed-subr/lambda)
(define fixed-subr/let)
(define fixed-subr/define)
(define fixed-subr/set)

;;;
;;; error handling
;;; ----------------------------------------------------------------

(define k/print) ; forward
(define print-backtrace) ; forward

(define-function die ()
  (libc/fprintf libc/stderr "\nDIE called at depth %d, printing a backtrace to stdout and exiting with exit code 1...\n" *backtrace-index*)
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
;;; types and their kernel accessors
;;;
;;; types are represented at runtime as integers upfrom 0.
;;; <undefined> doesn't necessarily need to be denoted by zero.
;;; the subr's here in eval.l encode/implement the behavior of the primitive types.
;;; ----------------------------------------------------------------

(define-form %level-shift-types type-names
  ;; (println "; Types in the host:")
  ;; (eval-in-module host '(host:let ()
  ;;                        (host:primitive/print "# " host:%types "\n") ; a KLUDGE alternative that works
  ;;                        ;; TODO FIXME investigate: this brings down the gc in the host with a stack overflow:
  ;;                        ;;(host:println "; " host:%types)
  ;;                        ;; it only started to happen after i have installed the register-type/host call that
  ;;                        ;; registers the type objects that the slave creates back into the host vm, and
  ;;                        ;; added the do-print specialization on <array>.
  ;;                        ;; it's probably a stack overflow, because after an ulimit -s 100000 it takes much
  ;;                        ;; longer to get the segfault.
  ;;                        ))
  ;; (println "\n; Slave types are as follows:\n; host id	slave id	type name")
  ;; (types-do type
  ;;   (println "; "(<type>-id type)"		"(<type>-slave-id type)"		"(<type>-name type)))
  ;; (println)
  `(let ()
     ,@(map (lambda (type-name)
              (let ((type (eval type-name)))
                ;; level-shift the maru type object to an integer in the target vm
                `(define-constant ,(concat-symbol 'k/ type-name) ,(<type>-slave-id type))))
            type-names)))

;; level-shift the ids of some types that we will need to denote in the target.
;; NOTE: <type> and <record> are not needed in the level-shifted code, they are
;; built on top of the other abstractions in boot.l.
(%level-shift-types
 <undefined>
 <target-vm-pointer>
 <data>
 <long>
 <string>
 <symbol>
 <pair>
 <array>
 <expr>
 <form>
 <fixed>
 <subr>
 <variable>
 <env>
 <context>
 <module>)

(eval-at-expand
 `(define-function get/type (ptr)
    (cond
      ((not ptr)	k/<undefined>)
      ((oop? ptr)	(let ((header (header-of ptr)))
                          (safety 3 (or (valid-header-magic-marker? header) (fatal1 "get/type: encountered an untagged pointer: %p" ptr)))
                          (safety 1 (or (& <header>-flags/used (<header>-flags header)) (fatal1 "get/type: attempt to access dead object: %p" ptr)))
                          (<header>-type header)))
      ((immediate? ptr) (cond
                          ,@(let ((conds ()))
                              (types-do type
                                (when (immediate-type? type)
                                  (let* ((tag-value	(<immediate-type>-tag-value type))
                                         (tag-width	(<immediate-type>-tag-width type))
                                         (tag-mask	(^ (- (<< 1 tag-width)) -1))) ; TODO this should use bitwise not instead of xor
                                    (push conds `((= ,tag-value (& ptr ,tag-mask)) ,(concat-symbol 'k/ (<type>-name type)))))))
                              conds)
                          (else (fatal1 "get/type: encountered an unidentifiable immediate: {%p}" ptr))))
      (else (fatal1 "get/type: encountered something unidentifiable: {%p}" ptr)))))

(define-form is (type ptr)
  `(= ,(concat-symbol 'k/ type) (get/type ,ptr)))

(define-function %type-check (obj exp-type)
  (let ((act-type (get/type obj)))
    (or (= exp-type act-type)
        (fatal2 "kernel get/put type error: expected type id %d, got %d" exp-type act-type))))

;; "one of the reasons for having all accesses to object fields go through get() and set() was to make it ridiculously easy to add read and write barriers" - Piumarta
(define-form get (type-name slot object)
  (let ((type (eval type-name)))
    `(let ((__obj__ ,object))
       (safety 2 (%type-check __obj__ ,(concat-symbol 'k/ type-name)))
       ;; we could use the accessors, too:
       ;; (,(concat-symbol (concat-symbol type-name '-) slot) __obj__)
       (oop-at __obj__ ,(record-slot-index type slot)))))

(define-form put (type-name slot object value)
  (let ((type (eval type-name)))
    `(let ((__obj__ ,object))
       (safety 2 (%type-check __obj__ ,(concat-symbol 'k/ type-name)))
       ;; we could use the accessors, too:
       ;; (set (,(concat-symbol (concat-symbol type-name '-) slot) __obj__) ,value)
       (set (oop-at __obj__ ,(record-slot-index type slot)) ,value))))

;; shorthands (and optimizations)
(define-form get/globals	()		`(get <variable> value (get <module> globals *module*)))
(define-form get/globals*	(obj)		`(get <variable> value (get <module> globals ,obj)))

(define-form is/long		(obj)		`(is <long> ,obj))
(define-form is/pair		(obj)		`(is <pair> ,obj))
(if (immediate-type? <long>)
    (define-form get/long	(obj)		`(>> ,obj ,(<immediate-type>-tag-width <long>)))
    (define-form get/long	(obj)		(if (< safety-level 3)		`(oop-at ,obj ,(record-slot-index <long> '_bits))	`(get <long> _bits ,obj))))
(define-form get/head		(obj)		(if (< safety-level 3)		`(oop-at ,obj ,(record-slot-index <pair> 'head))	`(get <pair> head ,obj)))
(define-form put/head		(obj val)	(if (< safety-level 3)	    `(set-oop-at ,obj ,(record-slot-index <pair> 'head) ,val)	`(put <pair> head ,obj ,val)))
(define-form get/tail		(obj)		(if (< safety-level 3)		`(oop-at ,obj ,(record-slot-index <pair> 'tail))	`(get <pair> tail ,obj)))
(define-form put/tail		(obj val)	(if (< safety-level 3)	    `(set-oop-at ,obj ,(record-slot-index <pair> 'tail) ,val)	`(put <pair> tail ,obj ,val)))

(define-form is/tptr		(obj)		`(is <target-vm-pointer> ,obj))
(define-form get/tptr		(obj)		`(get <target-vm-pointer> _bits ,obj))

(define-form get/string		(obj)		`(get <string> _bits ,obj))
(define-form get/symbol		(obj)		`(get <symbol> _bits ,obj))

(define-form get/variable-value	(var)		`(get <variable> value
                                                      ,(if (string? var)
                                                           `(k/env/lookup-variable (get/globals) (intern ,var))
                                                         var)))

(define-form put/variable-value	(var val)	`(put <variable> value
                                                      ,(if (string? var)
                                                           `(k/env/lookup-variable (get/globals) (intern ,var))
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
;;; GC and instantiation
;;; ----------------------------------------------------------------

(require "source/evaluator/gc.l")

(define-function %new-object (type bytesize)
  (debug (libc/printf "new-object type %d bytesize %d\n" type bytesize))
  (safety 1 (k/assert (not (= 0 type)) "new-object: called with zero type id"))
  (let* ((obj (gc/allocate bytesize))
         (header (header-of obj)))
    (k/assert (aligned-to-oop? obj) "new-object: gc/allocate returned not aligned-to-oop? {%p}\n" obj)
    (set (<header>-type header) type)
    (debug (libc/printf "new-object returning %p\n" obj))
    obj))

(define-function %new-object/opaque (type bytesize)
  (safety 1 (k/assert (not (= 0 type)) "new-object/opaque: called with zero type id"))
  (let* ((obj (gc/allocate-opaque bytesize))
         (header (header-of obj)))
    (set (<header>-type header) type)
    obj))

(define-form new-object (type wordsize)
  `(%new-object ,(<type>-slave-id (eval type)) (words-to-bytes ,wordsize)))

(define-form new-object/opaque (type wordsize)
  `(%new-object/opaque ,(<type>-slave-id (eval type)) (words-to-bytes ,wordsize)))

(define-form new-record-instance (type)
  (set type (eval type))
  (assert (subtype? (type-of type) <record>))
  `(%new-object ,(<type>-slave-id type) ,(words-to-bytes (record/effective-slot-count type))))

(define-form new-record-instance/opaque (type)
  (set type (eval type))
  (assert (subtype? (type-of type) <record>))
  `(%new-object/opaque ,(<type>-slave-id type) ,(words-to-bytes (record/effective-slot-count type))))

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
    (put <string> size  str (new-<long> len))
    (put <string> _bits str (new-object/opaque <data> (+ len 1))) ; +1 is for the terminal zero
    str))

(define-function new-<string>-from-cstring (cstr)
  (let* ((len (libc/strlen cstr))
         (obj (new-<string>-of-length len)))
    (libc/memcpy (get <string> _bits obj) cstr len)
    obj))

(define-function new-<symbol> (cstr)
  ;; TODO mimic strings, make symbols gc-able
  (let ((obj (new-record-instance/opaque <symbol>)))
    (put <symbol> _bits obj (libc/strdup cstr))
    obj))

(define-function new-<array> (size)
  (gc/let* ((arr (new-record-instance <array>)))
    (put <array> size arr   (new-<long> size))
    (put <array> _bits arr  (new-object <data> (or size 1))) ; TODO this is kinda random. why not just go with the size here?
    arr))

(define-function new-<expr> (defn ctx)
  (let ((obj (new-record-instance <expr>)))
    (put <expr> defn obj defn)
    (put <expr> ctx  obj ctx )
    obj))

(define-function new-<form> (fn sym)
  (let ((obj (new-record-instance <form>)))
    (put <form> function obj fn)
    (put <form> symbol   obj sym)
    obj))

(define-function new-<fixed> (fn)
  (let ((obj (new-record-instance <fixed>)))
    (put <fixed> function obj fn)
    obj))

(define-function new-<subr> (_imp _name)
  (let ((obj (new-record-instance/opaque <subr>)))
    (put <subr> _imp  obj _imp )
    (put <subr> _name obj _name)
    obj))

(define-function new-<variable> (name value env index)
  (gc/let* ((obj (new-record-instance <variable>)))
    (put <variable> name  obj name)
    (put <variable> value obj value)
    (put <variable> env   obj env)
    (put <variable> index obj (new-<long> index))
    obj))

(define-function new-<env> (parent level offset)
  (gc/let* ((obj (new-record-instance <env>)))
    (put <env> parent   obj parent)
    (put <env> level    obj (new-<long> (if parent (+ (get/long (get <env> level parent)) level) 0)))
    (put <env> offset   obj (new-<long> offset))
    (put <env> bindings obj (new-<array> 0))
    obj))

(define-function new-base-<context> (home caller env)
  (gc/let* ((obj (new-record-instance <context>)))
    (put <context> home     obj home)
    (put <context> env      obj env)
    (put <context> bindings obj (new-<array> 0))
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
    (if (and caller (set obj (get <context> callee caller)))
        (let ()
          (put <context> home obj home)
          (put <context> env  obj env))
      (set obj (new-base-<context> home caller env))
      (and caller (put <context> callee caller obj)))
    obj))

;;;
;;; arrays, strings, and more utils
;;; ----------------------------------------------------------------

(require "source/evaluator/arrays.l")

(define-function k/concat-list (head tail)
  (if (is/pair head)
      (gc/let* ((new-tail (k/concat-list (get/tail head) tail)))
        (new-<pair> (get/head head) new-tail))
    tail))

;;;
;;; env
;;; ----------------------------------------------------------------

(define-function global-variable? (var)
  (let ((env (get <variable> env var)))
    (and env (= 0 (get/long (get <env> level env))))))

(define-function k/env/lookup-variable (env name)
  (safety 1 (k/assert (is <env> env)     "k/env/lookup-variable: env is not an <env>: "env))
  (safety 1 (k/assert (is <symbol> name) "k/env/lookup-variable: name is not a <symbol>: "name))
  (while env
    (let* ((bindings (get <env> bindings env))
           (index    (k/array-length bindings))
           (vars     (get <array> _bits bindings))) ; KLUDGE? early optimization?
      (while (<= 0 (set index (- index 1)))
        (let ((var (oop-at vars index)))
          (and (= name (get <variable> name var))
               (return var)))))
    (set env (get <env> parent env))))

(define-function k/env/lookup-variable-or-die (env name)
  (let ((var (k/env/lookup-variable env name)))
    (or (and var (is <variable> var)) (fatal1 "k/env/lookup-variable-or-die failed for %s" (get/symbol name)))
    var))

(define-function k/env/variable-value (env name)
  (let ((var (k/env/lookup-variable env name)))
    (if var
        (get <variable> value var)
      (fatal1 "undefined variable in env/variable-value: %s" (get/symbol name)))))

(define-function k/env/ensure-variable (env name)
  (safety 1 (k/assert (is <env> env)		"k/env/ensure-variable: env arg is not of type env: "env))
  (safety 1 (k/assert (is <symbol> name)	"k/env/ensure-variable: name arg is not of type symbol: "name))
  (let* ((bindings (get <env> bindings env))
         (index (k/array-length bindings)))
    (while (<= 0 (set index (- index 1)))
      (let ((var (k/array-at bindings index)))
        (and (= name (get <variable> name var))
             (return var))))
    (let* ((off (get/long (get <env> offset env)))
           (var (new-<variable> name () env off)))
      (gc/protect (var)
        (put <env> offset env (new-<long> (+ off 1)))
        (k/array-append bindings var)))))

(define-function k/env/define (env name value)
  (safety 1 (k/assert (is <env> env) "k/env/define: env arg is not of type env: "env))
  (safety 1 (k/assert (is <symbol> name) "k/env/define: name arg is not of type symbol: "name))
  (debug (libc/printf "k/env/define called, name is %s\n" (get/symbol name)))
  (let ((var (k/env/ensure-variable env name)))
    (put <variable> value var value)
    var))

(define-function intern* (cstr module)
  (safety 1 (k/assert (is <module> module) "intern called with not a module " module))
  ;; deal with ?: syntax for denoting modules
  (let ((len (libc/strlen cstr))
        (idx 0))
    (while (< idx len)
      (when (= ?: (string-at cstr idx))
        (let ((module-name (libc/malloc (+ 1 idx))))
          (libc/memcpy module-name cstr idx)
          (set (string-at module-name idx) 0)
          (let ((submod (k/env/variable-value (get/globals* module) (intern* module-name module))))
            (unless (is <module> submod)
              (fatal2 "intern: '%s' is found, but it's not a module while interning %s" module-name cstr))
            (libc/free module-name)
            (return (intern* (+ 1 (+ cstr idx)) submod)))))
      (set idx (+ 1 idx))))
  ;; no module is denoted in cstr (anymore); it's just a symbol to be at this point
  (let ((symbols (get <module> symbols module)))
    (let ((lo 0)
          (hi (- (k/array-length symbols) 1)))
    (while (<= lo hi)
      (let* ((mid	(/ (+ lo hi) 2))
             (candidate	(k/array-at symbols mid))
             (c		(libc/strcmp cstr (get/symbol candidate))))
        (cond
          ((< c 0)	(set hi (- mid 1)))
          ((> c 0)	(set lo (+ mid 1)))
          (else		(return candidate)))))
    (debug (libc/printf "interning %s into module {%p}\n" cstr module))
    (gc/let* ((sym (new-<symbol> cstr)))
      (k/array-insert symbols lo sym)
      sym))))

(define-function intern (cstr)
  (intern* cstr *module*))

(require "source/evaluator/reader.l")

;;;
;;; printer
;;; ----------------------------------------------------------------

(require "source/evaluator/printer.l")

(set print-backtrace
  (lambda ()
    (let ((i *backtrace-index*))
      (while (<= 0 (set i (- i 1)))
        (libc/printf "%3d: " i)
        (k/dumpln (k/array-at *backtrace-stack* i))
        (libc/flush-streams)))))

;;;
;;; eval
;;; ----------------------------------------------------------------

(define k/eval) ; forward

(define-function k/apply-expr (fun arguments parent-ctx)
  (and (< 2 *arg/verbose*) (let () (libc/printf "  A  ")  (k/dump fun)  (libc/printf " ")  (k/dump arguments) (libc/printf " ")  (k/dumpln parent-ctx) (libc/flush-streams)))
  (let* ((defn    (get <expr> defn fun))
         (env     (k/car defn))
         (formals (k/cadr defn)))
    (gc/let* ((new-ctx (new-<context> (get <expr> ctx fun) parent-ctx env)))
      (let ((locals (get <context> bindings new-ctx))
            (args   arguments))
        (while (is/pair formals)
          (or (is/pair args) (k/error "too few arguments for "fun": "arguments))
          (k/set-array-at locals (get/long (get <variable> index (get/head formals))) (get/head args))
          (set formals (get/tail formals))
          (set args    (get/tail args)))
        (when (is <variable> formals)
          (k/set-array-at locals (get/long (get <variable> index formals)) args)
          (set args ()))
        (when args
          (k/error "too many arguments for "fun": "arguments)))
      (let ((prg (get/tail (get/tail defn)))
            (result ()))
        (while (is/pair prg)
          (set result (k/eval (get/head prg) new-ctx))
          (set prg (get/tail prg)))
        (when (get <env> stable env)
          (put <context> callee new-ctx ()))
        result))))

(define-function k/apply (fun arguments ctx)
  ;;(libc/printf "  %02d " *backtrace-index*) (k/dumpln fun)
  (debug (libc/printf "k/apply, function ") (k/dump fun) (libc/printf ", arguments: ") (k/dump arguments) (libc/printf "\n"))
  (k/assert fun "k/apply: fun is nil")
  (let ((type (get/type fun)))
    (cond
      ((= type k/<expr>)	(k/apply-expr fun arguments ctx))
      ((= type k/<fixed>)	(k/apply (get <fixed> function fun) arguments ctx))
      ((= type k/<subr>)
       ;; TODO FIXME it sould be this:
       ;; ((get <subr> _imp fun) arguments ctx)
       ;; but without using a local var it gets miscompiled by the x86 backend
       ;; see 8(%esp) and 12(%esp), they should be 0 and 4.
       ;; +	movl	_25type_check, %eax
       ;; +	movl	36(%esp), %ecx
       ;; +	movl	%ecx, 8(%esp)
       ;; +	movl	40(%esp), %ecx
       ;; +	movl	%ecx, 12(%esp)
       ;; +	call	*%eax
       (let ((imp (get <subr> _imp fun)))
         (imp arguments ctx)))
      (else			(let ((ap (k/array-at (get/variable-value var/*applicators*) (get/type fun))))
				  (if ap
				      (let ((args arguments))
					(gc/protect (args)
					  (set args (new-<pair> fun args))
					  (k/apply ap args ctx)))
				      (k/error "cannot apply: " fun)))))))

;;; ----------------------------------------------------------------

(define k/expand/list) ; forward

(define-function k/expand (exp env)
  (debug (libc/printf "k/expand, exp ") (k/dump exp) (libc/printf ", env ") (k/dump env) (libc/printf "\n"))
  (cond
    ((is/pair exp)
     (let ((head (k/expand (get/head exp) env)))
       (gc/push-root (address-of head))
       (when (is <symbol> head)
         (let ((val (k/env/lookup-variable env head)))
           (and (is <variable> val) (set val (get <variable> value val)))
           (and (is <form> val)
                (let ((fn (get <form> function val)))
                  (and fn
                       (let ((args (new-<pair> env (get/tail exp))))
                         (gc/protect (args)
                           (set head (k/apply fn args ()))
                           (set head (k/expand head env)))
                         (gc/pop-root (address-of head))
                         (return head)))))))
       (let ((tail (get/tail exp)))
         (gc/push-root (address-of tail))
         (or (= head symbol/quote) (set tail (k/expand/list tail env)))
         ;; convert set forms: (set (foo a b c) new-value) -> (set-foo a b c new-value)
         (and (= symbol/set head)
              (is/pair (k/car  tail))
              (is <symbol> (k/caar tail))
              (let ((buf (new_buffer)))
                (buffer_append_all buf "set-")
                (buffer_append_all buf (get/symbol (get/head (get/head tail))))
                (set head (intern (buffer_contents buf)))
                (set tail (k/concat-list (get/tail (get/head tail)) (get/tail tail)))))
         (set exp (new-<pair> head tail))
         (gc/pop-root (address-of tail))
         (gc/pop-root (address-of head)))))
    ((is <symbol> exp)
     (let ((val (k/env/lookup-variable env exp)))
          (and (is <variable> val) (set val (get <variable> value val)))
          (and (is <form> val)
               (let ((fn (get <form> symbol val)))
                 (and fn
                      (let ((args (new-<pair> exp ())))
                        (gc/protect (args)
                          (set args (new-<pair> env args))
                          (set args (k/apply fn args ()))
                          (set exp (k/expand args env)))))))))
    (else ; consult the *expanders* array to see if there's any custom expander for this type
     (let ((fn (k/array-at (get/variable-value var/*expanders*) (get/type exp))))
        (and fn
             (let ((args (new-<pair> exp ())))
               (gc/protect (args)
                 (set exp (k/apply fn args ()))))))))
  exp)

(set k/expand/list (lambda (list env)
  (if (is/pair list)
      (gc/let* ((head (k/expand		(get/head list) env))
                (tail (k/expand/list	(get/tail list) env)))
        (new-<pair> head tail))
    (k/expand list env))))

(define k/encode/list) ; forward
(define k/encode) ; forward

(define-function k/encode/pair (exp env)
  (gc/let* ((head (k/encode (get/head exp) env))
            (tail (get/tail exp)))
    (cond
      ((= head fixed-subr/let)		(let ((bindings (k/cadr exp)))
					  (gc/let* ((new-env (new-<env> env 0 (get/long (get <env> offset env)))))
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
  (let ((val (k/env/lookup-variable env exp)))
    (or val (fatal1 "undefined variable in encode: %s" (get/symbol exp)))
    (set exp val)
    (if (global-variable? exp)
        (let ((val (get <variable> value exp)))
          (when (or (is <form> val)
                    (is <fixed> val))
            (set exp val)))
      (let ((venv (get <variable> env exp)))
        (unless (= (get/long (get <env> level venv))
                   (get/long (get <env> level env)))
            (put <env> stable venv symbol/t)))))
  exp)

(define-function k/encode/other (exp env)
  (let ((fn (k/array-at (get/variable-value var/*encoders*) (get/type exp))))
    (when fn
      (gc/let* ((args (new-<pair> env ())))
        (set args (new-<pair> exp args))
        (debug (libc/printf "APPLY ENCODER\n... ") (k/print fn) (libc/printf " ") (k/print args) (libc/printf " ") (k/println env))
        (set exp (k/apply fn args ())))))
  exp)

(define-function k/encode (exp env)
  (debug (libc/printf "k/encode, exp ") (k/dump exp) (libc/printf ", env ") (k/dump env) (libc/printf "\n"))
  (cond
    ((is/pair exp)	(k/encode/pair		exp env))
    ((is <symbol> exp)	(k/encode/symbol	exp env))
    (else		(k/encode/other		exp env))))

(set k/encode/list (lambda (list env)
  (if (is/pair list)
      (gc/let* ((head (k/encode		(get/head list) env))
                (tail (k/encode/list	(get/tail list) env)))
        (new-<pair> head tail))
    (k/encode list env)))
)

(define-function k/eval/list (obj ctx)
  (if (is/pair obj)
      (gc/let* ((head (k/eval		(get/head obj) ctx))
                (tail (k/eval/list	(get/tail obj) ctx)))
        (new-<pair> head tail))
    obj))

(set k/eval (lambda (exp ctx)
  (and (< 2 *arg/verbose*) (let () (libc/printf "  E  ")  (k/dump exp)  (libc/printf " ") (k/dumpln ctx)  (libc/flush-streams)))
  (let ((type (get/type exp)))
    (cond
      ((= type k/<undefined>)	exp)
      ((= type k/<long>)	exp)
      ((= type k/<string>)	exp)
      ((= type k/<variable>)	(if (global-variable? exp)
				    (get <variable> value exp)
				  (let ((delta (- (get/long (get <env> level (get <context>  env ctx)))
					      (get/long (get <env> level (get <variable> env exp))))))
				    (while (< 0 delta)
				      (set ctx (get <context> home ctx))
				      (set delta (- delta 1)))
				    (k/array-at (get <context> bindings ctx) (get/long (get <variable> index exp))))))
      ((= type k/<pair>)	(let ((raw-head (get/head exp)))
                                  (debug (libc/printf "k/eval of pair, raw-head (of type %d) is " (get/type raw-head)) (k/dumpln raw-head))
				  (gc/let* ((head (k/eval raw-head ctx)))
                                    (debug (libc/printf "k/eval of pair, head eval'ed to ") (k/dumpln head))
				    (k/set-array-at *backtrace-stack* *backtrace-index* exp)
				    (set *backtrace-index* (+ *backtrace-index* 1))
				    (set head (if (is <fixed> head)
						  (k/apply (get <fixed> function head) (get/tail exp) ctx)
						(let ((args (k/eval/list (get/tail exp) ctx)))
						  (gc/protect (args)
						    (k/apply head args ctx)))))
				    (set *backtrace-index* (- *backtrace-index* 1))
                                    (debug (libc/printf "k/eval of pair, returning with head ") (k/dumpln head))
				    head)))
      ((= type k/<symbol>)	(k/error "symbol in eval?")) ;; TODO xxx
      (else			(let ((ev (k/array-at (get/variable-value var/*evaluators*) (get/type exp))))
				  (and ev
				       (let ((args (new-<pair> exp ())))
					 (gc/protect (args)
					   (k/set-array-at *backtrace-stack* *backtrace-index* exp)
					   (set *backtrace-index* (+ *backtrace-index* 1))
					   (set exp (k/apply ev args ctx))
					   (set *backtrace-index* (- *backtrace-index* 1)))))
				  exp)))))
     )

(define-function k/expand-encode-eval (form env)
  (gc/let* ((x form)
            (ctx (new-base-<context> () () env)))
								(when (< 0 *arg/verbose*) (libc/printf ";;; ")		(k/dumpln x))
    (set x (k/expand x env))					(when (< 2 *arg/verbose*) (libc/printf "expd--> ")	(k/dumpln x))
    (set x (k/encode x env))					(when (< 2 *arg/verbose*) (libc/printf "encd--> ")	(k/dumpln x))
    (set x (k/eval   x ctx))
								(when (< 0 *arg/verbose*) (libc/printf ";;; => ")	(k/dumpln x))
    x))

(define-function k/repl-stream (stream)
  (put/variable-value var/*input* (new-<long> stream))
  (unless (= libc/stdin stream)
    (libc/fscanf stream "#!%*[^\012\015]")) ; drop the possible #!./eval first line of the file
  (gc/let* ((res ()))
    (while (let ()
             (when (= libc/stdin stream)
               (libc/fprintf libc/stdout ".")
               (libc/flush-streams))
             (!= k/+done+ (set res (k/read stream))))
      (gc/let* ((env (new-<env> (get/globals) 1 0)))
        (set res (k/expand-encode-eval res env))
        (when (= libc/stdin stream)
          (k/dumpln res))))
    (and (= libc/stdin stream)
         (libc/printf "\nmorituri te salutant\n"))
    res))

(define-function new-<module> ()
  (debug (libc/printf "new-<module>\n"))
  (gc/let* ((module (new-record-instance <module>))
            (env    (new-<env> () 0 0)))
    (set (<module>-symbols module)	(new-<array> 0))
    (set (<module>-globals module)	(k/env/define env (intern* "*globals*" module) env))
    (debug (libc/printf "new-<module> returning with %p\n" module))
    module))

;;;
;;; the subr's
;;;
;;; ----------------------------------------------------------------

(require "source/evaluator/subrs.l")

(define-function %instantiate-subr (name imp fixed? module)
  (gc/let* ((tmp (new-<subr> imp name)))
    (when fixed?
      (set tmp (new-<fixed> tmp)))
    (k/env/define (get/globals* module) (intern* name module) tmp)))

(define-form instantiate-subrs ()
  (let ((result ()))
    (list-do entry *subr-registry*
      (let* ((name (car entry))
             (impl-name (concat-symbol 'subr/ name))
             (fixed? (caddr entry)))
        (push result `(%instantiate-subr ,(symbol->string name) ,impl-name ,(target-boolean fixed?) module))))
    `(let () ,@result)))

(set populate-module-with-primitives (lambda (module)
  (debug (libc/printf "populate-module-with-primitives on %p\n" module))
  (safety 1 (k/assert (is <module> module) "populate-module-with-primitives: called with not a <module>: "module))
  ;; the predefined primitives of the language
  (let ((env (get/globals* module))
        (tmp))
    (gc/protect (tmp)
				(k/env/define env (intern* "*input*"			module) ())
				(k/env/define env (intern* "*command-line-arguments*"	module) ())
      (set tmp (new-<long> 0))	(k/env/define env (intern* "*verbosity*"		module) tmp)
      (set tmp (new-<long> 0))	(k/env/define env (intern* "*optimised*"		module) tmp)

      (k/env/define env (intern* "+done+" module) k/+done+)

      (set tmp (new-<array> 0))	(k/env/define env (intern* "*expanders*"		module) tmp)
      (set tmp (new-<array> 0))	(k/env/define env (intern* "*encoders*"			module) tmp)
      (set tmp (new-<array> 0))	(k/env/define env (intern* "*evaluators*"		module) tmp)
      (set tmp (new-<array> 0))	(k/env/define env (intern* "*applicators*"		module) tmp))

    (instantiate-subrs))))

(set capture-well-known-vm-values (lambda ()
  (debug (libc/printf "capture-well-known-vm-values from *module*, which is %p\n" *module*))
  ;; let's cache some values from *module* to speed up their access in tight loops
  (set symbol/t                      (intern "t"))
  (set symbol/dot                    (intern "."))
  (set symbol/define                 (intern "define"))
  (set symbol/set                    (intern "set"))
  (set symbol/quote                  (intern "quote"))
  (set symbol/quasiquote             (intern "quasiquote"))
  (set symbol/unquote                (intern "unquote"))
  (set symbol/unquote_splicing       (intern "unquote-splicing"))

  (let ((global-env (get/globals)))
    (set var/*expanders*	(k/env/lookup-variable-or-die global-env (intern "*expanders*")))
    (set var/*encoders*		(k/env/lookup-variable-or-die global-env (intern "*encoders*")))
    (set var/*evaluators*	(k/env/lookup-variable-or-die global-env (intern "*evaluators*")))
    (set var/*applicators*	(k/env/lookup-variable-or-die global-env (intern "*applicators*")))
    (set var/*input*		(k/env/lookup-variable-or-die global-env (intern "*input*")))

    (set fixed-subr/quote  (k/env/variable-value global-env (intern "quote")))
    (set fixed-subr/lambda (k/env/variable-value global-env (intern "lambda")))
    (set fixed-subr/let    (k/env/variable-value global-env (intern "let")))
    (set fixed-subr/define (k/env/variable-value global-env (intern "define")))
    (set fixed-subr/set    (k/env/variable-value global-env (intern "set")))

    (k/assert (and (is <fixed> fixed-subr/quote) (is <fixed> fixed-subr/lambda) (is <fixed> fixed-subr/let) (is <fixed> fixed-subr/define) (is <fixed> fixed-subr/set)) "capture-well-known-vm-values: assert 2"))

  (debug (libc/printf "capture-well-known-vm-values is done\n"))))

(define-function main (argc argv)
  (debug (libc/printf "alive\n"))

  (set libc/stdin  (libc/fdopen 0 "r"))
  (set libc/stdout (libc/fdopen 1 "a"))
  (set libc/stderr (libc/fdopen 2 "a"))
  (libc/setbuf libc/stdout 0)
  (libc/setbuf libc/stderr 0)

  (gc/initialise)

  (safety 4 (set gc/frequency 1))

  (debug (libc/printf "gc initialized\n"))

  (k/assert (= k/<long> (get/type (new-<long> 42))) "get/type for <long> is broken")
  (k/assert (= 42       (get/long (new-<long> 42))) "get/long is broken")

  (set k/+done+ (new-<symbol> "+done+")) ; an uninterned symbol, i.e. a unique identity that cannot be recreated any other way
  (gc/push-root (address-of k/+done+))

  (gc/push-root (address-of *module*))			; the gc root for all (module-)global definitions
  (gc/push-root (address-of *backtrace-stack*))
  (gc/push-root (address-of fixed-subr/quote))		; precautionary, in case someone redefines them and they get removed from the env.
  (gc/push-root (address-of fixed-subr/lambda))
  (gc/push-root (address-of fixed-subr/let))
  (gc/push-root (address-of fixed-subr/define))

  (debug (libc/printf "initializing *module*\n"))

  (set *module* (new-<module>))

  (debug (libc/printf "*module* initialized\n"))

  (set *backtrace-stack* (new-<array> 32))

  (debug (libc/printf "populating *module*\n"))

  (populate-module-with-primitives *module*)
  (capture-well-known-vm-values)

  (debug (libc/printf "start processing argv\n"))

  ;; *command-line-arguments*
  (let ((cla-var (k/env/lookup-variable (get/globals) (intern "*command-line-arguments*"))))
    ;; initialize *cla*
    (gc/let* ((tmp ()))
      (let ((idx argc))
        (while (< 0 (set idx (- idx 1)))
          (set tmp (new-<pair> () tmp))
          (put/head tmp (new-<string>-from-cstring (oop-at argv idx)))))
      (put <variable> value cla-var tmp))

    ;; process *cla*
    (let (cla tmp)
      (while (is/pair (set cla (get <variable> value cla-var)))
        (let ((arg-string	(get/head cla))
              (arg		(get/string arg-string)))
          (gc/protect (arg-string tmp)
            (put <variable> value cla-var (set cla (get/tail cla))) ; (pop *command-line-arguments*)
            (cond
              ;; -v
              ((not (libc/strcmp arg "-v"))
               (set *arg/verbose* (+ 1 *arg/verbose*))
               (set tmp (new-<long> *arg/verbose*))
               (put/variable-value "*verbosity*" tmp))

              ;; -O
              ((not (libc/strcmp arg "-O"))
               (set *arg/optimised* (+ 1 *arg/optimised*))
               (set tmp (new-<long> *arg/optimised*))
               (put/variable-value "*optimised*" tmp))

              ;; -
              ((not (libc/strcmp arg "-"))
               (k/repl-stream libc/stdin))

              ;; --call to call a function
              ((not (libc/strcmp arg "--call"))
               (unless (is/pair cla)
                 (fatal "--call requires an argument"))
               (set arg-string (get/head cla))
               (set arg (get/string arg-string))
               (put <variable> value cla-var (set cla (get/tail cla))) ; (pop *command-line-arguments*)
               (let* ((sym (intern arg))
                      (form (new-<pair> sym ())))
                 (gc/protect (form)
                   (k/expand-encode-eval form (get/globals)))))

              ;; --define to define a variable
              ((not (libc/strcmp arg "--define"))
               (unless (and (is/pair cla)
                            (is/pair (get/tail cla)))
                 (fatal "--define requires two arguments"))
               (let ((var (k/car  cla))
                     (val (k/cadr cla)))
                 (put <variable> value cla-var (set cla (get/tail (get/tail cla)))) ; (pop *command-line-arguments*) x 2
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
                   (set form (new-<pair> (intern (get/string var)) form))
                   (set form (new-<pair> symbol/define form))
                   (k/expand-encode-eval form (get/globals)))))

              ;; read file as a program
              (else
               (let ((stream (libc/fopen arg "r")))
                 (or stream (fatal1 "no such file: %s" arg))
                 (k/repl-stream stream)
                 (libc/fclose stream)))))))))

  (libc/flush-streams)
  (and (< 0 *arg/verbose*)
       (let ()
         (gc/collect)
         (libc/printf "GC: %d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)))

  (libc/fprintf libc/stderr "%d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)
  (libc/flush-streams)
  (return 0))

(compile-end)
