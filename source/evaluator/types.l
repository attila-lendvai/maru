;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; types
;;; ----------------------------------------------------------------

(define-form level-shift-types names
  `(let ()
     ,@(map (lambda (name)
              `(define ,name (eval-in-slave ',name)))
            names)))

(level-shift-types
 ;; make these types visible to the target code
 ;; TODO FIXME what about reinstating them when the exe starts up?
 <type> <record>
 <data> <undefined> <long> <array> <string> <expr> <form> <fixed> <target-function>
 <variable> <env> <context> <module> <target-pointer> <symbol> <pair>)

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
         ;; strictly speaking, this should be OOP?, but that would add an extra non-nil check
         ((aligned-to-oop? ptr)
	  (let ((header (gc/header-of ptr)))
            (safety 3 (or (gc/valid-header-canary? header) (fatal1 "type-of: encountered an untagged pointer: %p" ptr)))
            (safety 2 (or (gc/live-chunk? header) (fatal1 "type-of: attempt to access dead object: %p" ptr)))
            (<header>-type header)))
         ,@conds-late
         (else (fatal1 "type-of: encountered something unidentifiable: {%p}" ptr))))))

(define-type-of)

(when-at-expand feature/optimize-speed
  (define-form is (type-name obj)
    (let ((type (eval type-name)))
      (cond
        ((is <record> type) ; NOTE: IS in the form bodies will resolve to the one in slave-module, regardless of our new definition of IS in the target module
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

(define-function %allocate-boxed (type-id payload)
  (let ((obj (gc/allocate-opaque type-id (words-to-bytes 1))))
    (set (oop-at obj 0) payload)
    obj))

(define-form box (type-name payload)
  (let ((type (eval type-name)))
    (cond
      ((is <boxed-type> type)
       (assert (<boxed-type>-one-word? (eval type-name)) "cannot know how to allocate a boxed type that is not one-word?")
       `(%allocate-boxed ,type-name ,payload))
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
       (if (<boxed-type>-one-word? type)
           `(oop-at ,(if feature/typecheck-slot-access
                         `(%accessor-typecheck ,type-name ,obj)
                       obj)
                    0)
         ;; then we just return its address, the payload is right there inlined
         (if feature/typecheck-slot-access
             `(%accessor-typecheck ,type-name ,obj)
           obj)))

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

;; NOTE this is not exactly the same as the one in the user-land, it lacks the slot-name
;; parameter (because the compiler cannot deal with symbol literals yet).
(define-function %accessor-typecheck (expected-type-id object)
  (let ((type (type-of object)))
    (or (= type expected-type-id)
        (fatal2 "kernel accessor type error: expected type id %ld, got %ld" expected-type-id type)))
  object)

;; shorthands (and optimizations)
(if-at-expand feature/optimize-space
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

(define-form get/head		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'head))	`(<pair>-head ,obj)))
(define-form put/head		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'head) ,val)	`(set (<pair>-head ,obj) ,val)))
(define-form get/tail		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'tail))	`(<pair>-tail ,obj)))
(define-form put/tail		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'tail) ,val)	`(set (<pair>-tail ,obj) ,val)))
