;;; -*- mode: lisp; coding: us-ascii -*-

;; NOTE this hides the one in source/types.l with a specialized
;; version for the target code.

(define-form make (type-name . inits)
  (let ((type (eval type-name *env*)))
    `(gc/let* ((self (allocate-object ,(<type>-slave-id type)
                                      ,(type/slot-count-of-instances type))))
       (with-instance-accessors self ,type-name
         ,@(%make-make-inits *env* 'self. inits))
       self)))

(define-form make/heap (type-name . inits)
  (let ((type (eval type-name *env*)))
    `(gc/let* ((self (allocate-object/heap ,(<type>-slave-id type)
                                           ,(type/slot-count-of-instances type))))
       (with-instance-accessors self ,type-name
         ,@(%make-make-inits *env* 'self. inits))
       self)))

;; TODO this should be done cleaner/nicer than a single-use macro
(define-form define-type-of ()
  (let ((conds-early	())
        (conds-late	()))
    (types-do type
      (when (is <immediate-type> type)
        (let* ((tag-value	(<immediate-type>-tag-value type))
               (tag-width	(<immediate-type>-tag-width type)))
          (if tag-width
              (let ((tag-mask (bitwise-not (- (bitwise-shift 1 tag-width)))))
                (push conds-late `((= ,tag-value (bitwise-and ptr ,tag-mask)) ,(<type>-name type))))
            (push conds-early `((= ,tag-value ptr) ,(<type>-name type)))))))
    `(define-function type-of (ptr)
       (cond
         ,@conds-early
         ;; strictly speaking, this should be a full OOP? call, but
         ;; that would include an unnecessary nil check
         ((aligned-to-oop? ptr)
	  (let ((header (gc/header-of ptr)))
            (safety 3 (or (gc/valid-header-canary? header) (fatal "type-of: encountered an untagged pointer: " (pointer ptr))))
            (safety 2 (or (gc/live-chunk? header) (fatal "type-of: attempt to access dead object: " (pointer ptr))))
            (<header>-type header)))
         ,@conds-late
         (else (fatal "type-of: encountered something unidentifiable: " (pointer ptr)))))))

(define-type-of)

(when-at-expand (feature optimize-speed)
  (define-form is (type-name obj)
    (let ((type (eval type-name *env*)))
      (cond
        ((is <record> type) ; NOTE: IS in the form bodies will resolve to the one in *slave-env*, regardless of our new definition of IS in the target module
         ;; TODO this ignores inheritance
         `(let ((__obj__ ,obj))
            (and (oop? __obj__)
                 (= ,(<type>-slave-id type)
                    (<header>-type (gc/header-of __obj__))))))
        ((is <immediate-type> type)
         (let* ((tag-value	(<immediate-type>-tag-value type))
                (tag-width	(<immediate-type>-tag-width type)))
           (if tag-width
               (let ((tag-mask (bitwise-not (- (bitwise-shift 1 tag-width)))))
                 `(= ,tag-value (bitwise-and ,obj ,tag-mask)))
             `(= ,tag-value ,obj))))
        (else
         `(= ,type-name (type-of ,obj)))))))

(define-function %allocate-boxed-cells (type-id cell-count payload)
  (let ((obj (gc/allocate type-id (words-to-bytes cell-count) true)))
    (cond
      ((= 1 cell-count)
       (set (oop-at obj 0) payload))
      ((is <array> payload)
       ;; NOTE avoid ARRAY-AT: this file is compiled before the array
       ;; vm-functions exist in the target, so a call would resolve to
       ;; the host's <target-function> and fail to compile.
       (let ((elements	(<array>-elements payload))
             (index	0))
         (while (< index cell-count)
           (set (oop-at obj index) (oop-at elements index))
           (incr index))))
      (else
       (error "%allocate-boxed-cells: a multi-cell payload must be an <array>, got "
              (type-of payload))))
    obj))

;; A two-cell boxed word, used by the interpreter for <u64> on a 32-bit
;; image. The payload is raw; the low half goes into cell 0.
(define-function %allocate-two-cell-word (type-id lo hi)
  (let ((obj (gc/allocate type-id (words-to-bytes 2) true)))
    (set (oop-at obj 0) lo)
    (set (oop-at obj 1) hi)
    obj))

(define-form box (type-name payload)
  (let ((type (eval type-name)))
    (cond
      ((is <boxed-type> type)
       (let ((cell-count (<boxed-type>-payload-cell-count type)))
         (if (long? cell-count)
             `(%allocate-boxed-cells ,type-name ,cell-count ,payload)
           (error "box: " type-name " has a variable payload; allocate and fill it directly"))))
      ((is <immediate-type> type)
       ;; TODO error when overflow
       `(bitwise-or (bitwise-shift ,payload ,(<immediate-type>-tag-width type))
                    ,(<immediate-type>-tag-value type)))
      (else
       (error "box: don't know how to deal with "type)))))

(define-form unbox (type-name obj)
  (let ((type (eval type-name)))
    (cond
      ((is <boxed-type> type)
       (if (single-cell-boxed-type? type)
           `(oop-at ,(if (feature typecheck-slot-access)
                         `(%accessor-typecheck ,(<type>-slave-id type) ,obj)
                       obj)
                    0)
         (error "unbox: " type-name " does not have a single-cell payload; use its accessors")))

      ((is <immediate-type> type)
       (if (< *safety* 2)
           `(bitwise-shift ,obj ,(- (<immediate-type>-tag-width <long>)))
         `(let ((__obj__ ,obj))
            (assert (is ,type-name __obj__))
            (bitwise-shift __obj__ ,(- (<immediate-type>-tag-width <long>))))))

      (else
       (error "unbox: don't know how to deal with "type)))))

(eval-in-slave
 ;; "export" these up into the syntax level, because the compiler
 ;; wants to call them for e.g. dumping strings, and eval-in-target
 ;; wouldn't work from there, because the target has non-evaluatable
 ;; definitions for stuff like bitwise-shift and <long>.
 `(let ()
    (define box		,box)
    (define unbox	,unbox)))

;; shorthands (and optimizations)
(if-at-expand (feature optimize-space)
    (let ()
      (define-function long?	(obj)	(is <long>	obj))
      (define-function pair?	(obj)	(is <pair>	obj))
      (define-function string?	(obj)	(is <string>	obj))
      (define-function symbol?	(obj)	(is <symbol>	obj))
      (define-function array?	(obj)	(is <array>	obj)))
  (define-form long?		(obj)	`(is <long>	,obj))
  (define-form pair?		(obj)	`(is <pair>	,obj))
  (define-form string?		(obj)	`(is <string>	,obj))
  (define-form symbol?		(obj)	`(is <symbol>	,obj))
  (define-form array?		(obj)	`(is <array>	,obj)))

;; TODO explain why these are needed, and how they are faster than the
;; accessor... or just get rid of them.
(define-form get/head		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'head))	`(<pair>-head ,obj)))
(define-form put/head		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'head) ,val)	`(set (<pair>-head ,obj) ,val)))
(define-form get/tail		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'tail))	`(<pair>-tail ,obj)))
(define-form put/tail		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'tail) ,val)	`(set (<pair>-tail ,obj) ,val)))

;; KLUDGE u32 mask written as 0xffffffff on a 32-bit host reads that
;; literal as -1. this way it's identical on every host.
(define-function %u32-mask ()
  (- (bitwise-shift 1 32) 1))

;; TODO these could work, but let's do this after the type cleanup.
;; then we could eliminate a whole lot of genesis/cell->host
;; conversions. when this land, then the DEFINE-VM-FUNCTION
;; counterparts should just call these.

;; (define-function <u64>-lo (value)
;;   (if-at-expand (single-cell-boxed-type? <u64>)
;;       (box <u32> (bitwise-and (unbox <u64> value) (%u32-mask)))
;;     (box <u32> (oop-at value 0))))

;; (define-function <u64>-hi (value)
;;   (if-at-expand (single-cell-boxed-type? <u64>)
;;       (box <u32> (bitwise-and (arithmethic-shift-right (unbox <u64> value) 32)
;;                               (%u32-mask)))
;;     (box <u32> (oop-at value 1))))

;; (define-function unbox-integer (value)
;;   (typecase value
;;     (<long>	(unbox <long> value))
;;     (<u32>	(unbox <u32> value))
;;     (<u64>	(if-at-expand (single-cell-boxed-type? <u64>)
;;                     (unbox <u64> value)
;;                   (let ((hi (<u64>-hi value))
;;                         (lo (<u64>-lo value)))
;;                     (unless (and (zero? hi)
;;                                  (< lo 0x7fffffff))
;;                       (error "unbox-integer: a too large <u64> cannot be represented in this 32 bit host"))
;;                     lo)))))
