;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; selector: functions that dispatch on the type of the first argument, aka single dispatch
;;;

(define-record <selector> () (name methods default))

(define-function selector? (obj) (= <selector> (type-of obj)))

(define-function <selector>-inherit (methods type)
  (when (subtype? (type-of type) <record>)
    (let ((method ())
          (probe  type))
      (while (and (set probe (<record>-super probe))
                  (not (set method (array-at methods (<type>-id probe))))))
      ;; (and method (set (array-at methods type) method))	; copy down the method for performance
      method)))

(define-apply <selector> (self . arguments)
  ;; NOTE if we wanted to be super precise while bootstrapping, then this should be
  ;; (<type>-id (type-of (car arguments))), so that type-of can map the host type to
  ;; that of the slave. this causes a major slowdown though, and it's probably not needed,
  ;; because emit.l is loaded into the host, so the type dispatches in it work as expected.
  ;; the fast version is: (type-id-of (car arguments))
  ;; same applies to generics.
  (apply (or (array-at (<selector>-methods self)
                       (if-at-expand (and bootstrapping?
                                          (= 0 *optimised*))
                           ;; more correct version that considers the type mappings while bootstrapping (i.e. pretty printing works properly while bootstrapping).
                           ;; this slows down the bootstrap by about 10% though.
                           (<type>-id (type-of (car arguments)))
                         (type-id-of (car arguments))))
             (<selector>-inherit (<selector>-methods self) (type-of (car arguments)))
             (<selector>-default self))
         arguments))

(define-function selector (name default)
  (let ((self (new <selector>)))
    (set (<selector>-name    self) name)
    (set (<selector>-methods self) (array))
    (set (<selector>-default self) default)
    self))

(define-function <selector>-add-method (self type method)
  (when-at-expand (and feature/track-expr-names
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
        (if (selector? (<variable>-value var))
            `(quote ,(<variable>-value var))
          (error name" is already defined as non-selector: " (<variable>-value var)))
      (or default (set default `(args (error "selector '"',name
                                             "' has no method for "(type-name-of (car args))
                                             ": "(cons (car args) (map type-name-of (cdr args)))))))
      `(define ,name (selector ',name (lambda ,@default))))))

(define-selector add-method)

(<selector>-add-method add-method <selector>
  (lambda (self type args body)
    (<selector>-add-method self type (eval `(lambda ,args (with-instance-accessors self ,type ,@body))))))

(define-form define-method (selector type args . body)
  (or (defined? selector) (eval `(define-selector ,selector)))
  `(add-method ,selector ,type ',(cons 'self args) ',body))
