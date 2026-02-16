;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; selector: functions that dispatch on the type of the first argument, aka single dispatch
;;;

;; FIXME the slave's slectors cannot be applied in the host while
;; bootstrapping. this leads to e.g. ASSERT not working properly in
;; macros, because the host cannot apply the slave's DO-PRINT.

(define-record <selector> () (name methods default))

;; TODO the printing subsystem requires <selector>
;; (define-print-method <selector>
;;   (print-all -stream- "<selector:"self.name">"))

(define-function selector/lookup-effective-method (methods type)
  (when (subtype? (type-of type) <record>)
    (let ((method ())
          (probe  type))
      (while (and (set probe (and (is <record> probe)
                                  (<record>-super probe)))
                  (not (set method (array-at methods (<type>-id probe))))))
      ;; (and method (set (array-at methods type) method))	; copy down the method for performance
      method)))

(define-apply <selector> (self . arguments)
  (apply
   (or (array-at (<selector>-methods self)
                 ;; TODO implement the same for generics
                 (if-at-expand (and bootstrapping?
                                    (= 0 *optimised*))
                     ;; the more correct version that considers the type mappings while bootstrapping (e.g. pretty printing works properly while bootstrapping).
                     ;; this slows down the bootstrap by about 10% though.
                     (<type>-id (type-of (car arguments)))
                   (type-id-of (car arguments))))
       (selector/lookup-effective-method (<selector>-methods self)
                                         (type-of (car arguments)))
       (<selector>-default self))
   arguments))

(define-function selector (name default)
  (make <selector>
    (name      name)
    (methods   (array))
    (default   default)))

(define-function selector/add-method (self type method)
  (when-at-expand (and (feature track-expr-names)
                       (not bootstrapping?))
    ;; expr's (lambdas) are instantiated by the host, so let's not assume anything about their object layout.
    (when (and (expr? method)
               (not (<expr>-name method)))
      (set (<expr>-name method)
           (concat-symbols (name-of-type type) '. (<selector>-name self)))))
  (set-array-at (<selector>-methods self) (<type>-id type) method))

(define-form define-selector (name . default)
  (assert (symbol? name) "define-selector: name is not a symbol")
  (let ((var (defined? name)))
    (if var
        (if (is <selector> (<variable>-value var))
            `(quote ,(<variable>-value var))
          (error name" is already defined as non-selector: " (<variable>-value var)))
      (unless default
        (set default `(args (error "selector '"',name
                                   "' has no method for "(type-name-of (car args))
                                   ": "(cons (car args) (map type-name-of (cdr args)))))))
      `(define ,name (selector ',name (lambda ,@default))))))

(define-selector add-method)

(selector/add-method add-method <selector>
  (lambda (self type body)
    (selector/add-method self type body)))

(define-form define-method (selector type args . body)
  (or (defined? selector) (eval `(define-selector ,selector) *env*))
  `(add-method ,selector ,type
               (lambda (self ,@args)
                 (with-instance-accessors self ,type
                   ,@body))))
