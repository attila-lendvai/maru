;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; The Maru VM, written in a dialect of Maru.
;;;

(load "source/evaluator/gc.l")
(load "source/evaluator/types.l")

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

;; TODO ? rename to allocate-object/heap
;; TODO introduce allocate-object/stack
(define-vm-function allocate ((type <long>) (slot-count <long>))
  (gc/allocate type (words-to-bytes slot-count)))

;; TODO rename to allocate-opaque-data or something else; ? allocate-memory/opaque
(define-vm-function allocate-data ((byte-size <long>))
  (gc/allocate-opaque <data> byte-size))

(define-vm-function cons ((head () ()) (tail () ()))
  (make <pair>
    (head head)
    (tail tail)))

(define-vm-function string ((capacity <long> 0))
  (make <string>
    (size	(box <long> 0))
    (elements	(when (< 0 capacity)
                  (allocate-data capacity)))))

;; (define-function ascii-bytes->string (buf length)
;;   (let ((str (string length)))
;;     (copy-bytes buf (<string>-elements str) length)
;;     str))

(define-function symbol (name)
  (safety 1 (assert (string? name)))
  (make <symbol>
    (name	name)))

(define-vm-function array ((capacity <long> 0))
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
    (when-at-expand (feature profiler)
      (profiler-counter (box <long> 0)))))

(define-vm-function form (fn (sym () ()))
  (make <form>
    (function	fn)
    (symbol	sym)))

(define-vm-function fixed (fn)
  (make <fixed>
    (function fn)))

;; a vm-function is something that will be made available in the VM we
;; are implementing. a <target-function> is a heap object that points
;; to a machine code block in the lower realm; i.e. a fitting
;; instrument to represent a vm-function.
(define-function vm-function (code name)
  (safety 2 (assert (and (is <lower-cell> code) (is <string> name))))
  (make <target-function>
    (program-code	code)
    (when-at-expand (feature track-expr-names)
      (name		name))
    (when-at-expand (feature profiler)
      (profiler-counter	(box <long> 0)))))

(define-vm-function variable ((name <symbol>) value (env <env>) (index <long>))
  (make <variable>
    (name	name)
    (value	value)
    (env	env)
    (index	(box <long> index))))

(define-vm-function environment
    ((parent () ())
     (level <long> 0)
     (offset <long> (if (is <env> parent)
                        (unbox <long> (<env>-offset parent))
                      0)))
  (safety 2 (assert (or (is <env> parent) (is <undefined> parent))))
  (make <env>
    (parent	parent)
    (level	(box <long> (if (is <env> parent)
                                (+ (unbox <long> (<env>-level parent)) level)
                              0)))
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
