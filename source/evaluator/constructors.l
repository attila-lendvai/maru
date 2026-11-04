;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; The Maru VM, written in a dialect of Maru.
;;;

(load "source/evaluator/gc.l")
(load "source/evaluator/types.l")

;;;
;;; object instantiation
;;; ----------------------------------------------------------------

;; TODO introduce type kinds (a type-of-type) so that properties like
;; opacity can be annotated on the type itself; then make/opaque can be
;; folded into make. the arena work may remove these call sites first.
(define-form make/opaque (type-name . inits)
  (let ((type (eval type-name)))
    `(gc/let* ((self (allocate-object/opaque/heap ,(<type>-slave-id type)
                                                  ,(type/slot-count-of-instances type))))
       (with-instance-accessors self ,type-name
         ,@(%make-make-inits *env* 'self. inits)
         self))))

;;; allocation
;;;
;;; the dynamic variants will consult *allocator* once arenas land; for
;;; now they are the heap variants.

(define-vm-function allocate-object ((type <long>) (slot-count <long>))
  (gc/allocate type (words-to-bytes slot-count) false))

(define-vm-function allocate-object/heap ((type <long>) (slot-count <long>))
  (gc/allocate type (words-to-bytes slot-count) false))

(define-vm-function allocate-object/opaque ((type <long>) (slot-count <long>))
  (gc/allocate type (words-to-bytes slot-count) true))

(define-vm-function allocate-object/opaque/heap ((type <long>) (slot-count <long>))
  (gc/allocate type (words-to-bytes slot-count) true))

(define-vm-function allocate-bytes ((byte-size <long>))
  (gc/allocate <data> byte-size true))

(define-vm-function allocate-bytes/heap ((byte-size <long>))
  (gc/allocate <data> byte-size true))

(define-vm-function allocate-oop-vector ((cell-count <long>))
  (gc/allocate <oop-vector> (words-to-bytes cell-count) false))

(define-vm-function allocate-oop-vector/heap ((cell-count <long>))
  (gc/allocate <oop-vector> (words-to-bytes cell-count) false))

(define-vm-function cons ((head () ()) (tail () ()))
  (make <pair>
    (head head)
    (tail tail)))

(define-vm-function cons/heap ((head () ()) (tail () ()))
  (make/heap <pair>
    (head head)
    (tail tail)))

(define-vm-function string ((capacity <long> 0))
  (make <string>
    (size	(box <long> 0))
    (elements	(when (< 0 capacity)
                  (allocate-bytes capacity)))))

(define-vm-function string/heap ((capacity <long> 0))
  (make/heap <string>
    (size	(box <long> 0))
    (elements	(when (< 0 capacity)
                  (allocate-bytes/heap capacity)))))

;; (define-function ascii-bytes->string (buf length)
;;   (let ((str (string length)))
;;     (copy-bytes buf (<string>-elements str) length)
;;     str))

(define-function symbol (name)
  (safety 1 (assert (string? name)))
  (make/heap <symbol>
    (name	name)))

(define-vm-function array ((capacity <long> 0))
  (make <array>
    (size	(box <long> 0))
    (elements	(when (> capacity 0)
                  (allocate-oop-vector capacity)))))

(define-vm-function array/heap ((capacity <long> 0))
  (make/heap <array>
    (size	(box <long> 0))
    (elements	(when (> capacity 0)
                  (allocate-oop-vector/heap capacity)))))

(define-function expr (parameters body env ctx)
  (make/heap <expr>
    (parameters	parameters)
    (body	body)
    (env	env)
    (ctx	ctx)
    (when-at-expand (feature profiler)
      (profiler-counter (box <long> 0)))))

(define-vm-function form (fn (sym () ()))
  (make/heap <form>
    (function	fn)
    (symbol	sym)))

(define-vm-function fixed (fn)
  (make/heap <fixed>
    (function fn)))

;; a vm-function is something that will be made available in the VM we
;; are implementing. a <target-function> is a heap object that points
;; to a machine code block in the lower realm; i.e. a fitting
;; instrument to represent a vm-function.
(define-function vm-function (code name)
  (safety 2 (assert (and (is <lower-cell> code) (is <string> name))))
  (make/heap <target-function>
    (program-code	code)
    (when-at-expand (feature track-expr-names)
      (name		name))
    (when-at-expand (feature profiler)
      (profiler-counter	(box <long> 0)))))

(define-vm-function variable ((name <symbol>) value (env <env>) (index <long>))
  (make/heap <variable>
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
  (make/heap <env>
    (parent	parent)
    (level	(box <long> (if (is <env> parent)
                                (+ (unbox <long> (<env>-level parent)) level)
                              0)))
    (offset	(box <long> offset))
    (bindings	(array/heap 0))
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
