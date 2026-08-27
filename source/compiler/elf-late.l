;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; Compiling lambdas
;;;

(define-function compile/expression-to-operand (expr -c-)
  (cond
    ((and (variable? expr)
          ;; TODO we should handle global variables, too.
          (let ((x (<variable>-value expr)))
            (or (is <STACK-CELL>	x)
                (is <LI64>		x)
                (is <LI32>		x))))
     ;; (let ((value (<variable>-value expr)))
     ;;   (print-all *debug-output* "*** matched: "expr"="value", type:" (type-of value) "\n")
     ;;   value)
     (<variable>-value expr))

    ((long? expr)
     (LI64 expr))

    (else
     ;; (when (variable? expr)
     ;;   (let ((value (<variable>-value expr)))
     ;;     (assert (global-variable? expr))
     ;;     (print-all *debug-output* "*** matched: "expr"="value", type:" (type-of value) "\n")
     ;;     value))
     (comp expr))))

(define-function compile/expr-into-temp-or-literal (expr -c-)
  (cond
    ((long? expr)
     (LI64 expr))
    (else
      (comp expr)
      (let ((temp (alloc-stack-temp -c-)))
        (emit STORE $ temp)
        temp))))

(define-function compile-call-to-global-function (op -c-)
  (if (feature redefinable-functions-in-target)
      (let ()
        (comp op)
        (compile-call-to-<target-function> -c-))
    (emit CALL (closure-code-label (<variable>-name op))))
  ())

(define-method compile-call-to <expr> (op -c-)
  ;; NOTE the fact that a literal <expr> is found in a variable's
  ;; value slot at compile time implies that it's a global definition.
  (compile-call-to-global-function op -c-)
  (expr-n-required-parameters self))

;; this case is handled early in compile-call
;; (define-method compile-call-to <pair> (op -c-)
;;   (comp op)
;;   (compile-call-to-<target-function> -c-))

(define-method compile-call-to (slave-value <selector>) (op -c-)
  (compile-call-to-global-function op -c-)
  ;; TODO extract and return n-params
  ())

;;;
;;; Special Forms
;;;

(define-function compile/expressions-into-temp (prog -c-)
  (assert (pair? prog) "compile/expressions-into-temp: prog is empty or not a list") ; this is against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  ;; NOTE it's tempting here to check for single-element prog's, and
  ;; turning them into a compile/expression, but our single caller,
  ;; namely compile/let, requires a temp location, even when
  ;; initialized to literal values.
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-stack-temp -c-)))
    (emit STORE $ temp)
    temp))

(define-function compile/let-binding (binding comp)
  ;; we unconditionally initialize empty bindings to () to avoid hidden bugs,
  ;; at a small cost of initializing temp locations even when it wouldn't be necessary.
  ;; TODO cleanup! expand now brings let bindings to a normal form (to ease encode's job). think this through...
  (unless (pair? binding)
    (set binding (list binding ())))
  (unless (cdr binding)
    (set binding (list (car binding) ())))
  (let ((var (car binding))
        (tmp (compile/expressions-into-temp (cdr binding) comp)))
    (assert (= (type-of var) <variable>) "compile/let-binding: encountered a non-variable: " var)
    (set (<variable>-value var) tmp)))

(define-function compile/let (expr -c-)
  (let ((temps (map-with compile/let-binding (caddr expr) -c-)))
    (list-do stmt (cdddr expr)
      (comp stmt))
    (free-temps temps)))

(define-function compile/set (expr -c-)
  (let* ((var	(second expr))
         (value	(<variable>-value var)))
    (accessible-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ((or (is <STACK-CELL> value)
           (is <R64> value))
       (emit STORE $ value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (error "TODO <C-variable>")
       ;; (emit STORE $ ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
       ;;             (EXTERNAL-LABEL (<C-variable>-name value))))
       )
      (else
       (emit STORE $ (GLOBAL-CELL (label (<variable>-name var))))))))

(define-function compile/address-of (expr -c-)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (cond
        ((global-variable? var)
         (emit ADDR (GLOBAL-CELL (label (<variable>-name var)))))
        ((is <STACK-CELL> val)
         (emit ADDR val))
        ;; ((is <R64> val)
        ;;  (maybe-spill-params -c-)
        ;;  (emit ADDR (<variable>-value var)))
        (else
         (error "address-of: don't know how to compile for variable " var ", holding the value " val))))))

;;;
;;; Special Operators
;;;

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  ;; FIXME we shouldn't need to instantiate the instructions here...
  (let ((instr (op ())))
    (if (<instruction>-has-input? instr)
        (emit op $)
      (emit op))))

;; FIXME? these implement a right-to-left evaluation order, while
;; function calls implement the opposite. note that this is entangled
;; with e.g. the LOAD/STORE instructions above, as they expect arg0 to
;; be loaded in %rax.
(define-function compile/binary-operator (op args -c-)
  (let ((tmp (compile/expr-into-temp-or-literal (cadr args) -c-)))
    (comp (car args))
    (free-temp tmp)
    (let ((instr (op ())))
      (if (<instruction>-has-input? instr)
          (emit op $ tmp)
        (emit op tmp)))))

(define-function compile/ternary-operator (op args -c-)
  (let ((tmp2 (compile/expr-into-temp-or-literal (third  args) -c-))
        (tmp1 (compile/expr-into-temp-or-literal (second args) -c-)))
    (comp (car args))
    (free-temp tmp1)
    (free-temp tmp2)
    (let ((instr (op ())))
      (if (<instruction>-has-input? instr)
          (emit op $ tmp1 tmp2)
        (emit op tmp1 tmp2)))))

(define +operator-compilers+ (list->array (list () compile/unary-operator compile/binary-operator compile/ternary-operator)))

(define-method compile <pair> (-c-)
  (let* ((op		(first self))
         (op-is-a-var?	(variable? op))
         (op-value	(if op-is-a-var?
                            (or (<variable>-value op)
                                (error "error: calling undefined function: "op))
                          op))
         (args		(rest self))
         (arity		(list-length args))
         (handler	()))
    (emit-comment 2 "call of op: "op", op-is-a-var? "op-is-a-var?", args: " args)
    ;; TODO add compiler-macros. use them to optimize stuff on the lisp semantic level
    (cond
      ((set handler (second (assq op-value (array-at *special-operators* arity))))
       (emit-comment 3 "found op "op" in *special-operators*, handler: "handler)
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((is <fixed> op)
       (let ((handler (cdr (assq op *special-forms*))))
         (emit-comment 3 "op is a <fixed>: "op", handler: "handler)
         (or handler (error "No handler for fixed form: " self))
         (handler self -c-)))
      (else
       (compile-call-form op args -c-)))))

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (is <R64> value)
           (is <LI64> value)
           (is <STACK-CELL> value)
           (is <STACK-PARAM> value))
       (emit LOAD value))
      ((global-variable? self)
       (cond
         ((= 'true self.name)
          (emit LOAD (LI64 (target-value true))))
         ((subtype? (type-of value) <type>)
          (emit LOAD (LI64 (eval-in-slave `(<type>-slave-id ,value)))))
         ((is <C-function> value) ; handles the situation when e.g. libc/strcmp is passed as a comparator fn for array-binary-search
          (error "TODO <C-function>")
          ;;(emit LOAD (EXTERNAL-LABEL (<C-function>-name value)))
          )
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (error "TODO <C-variable>")
          ;; (emit LOAD ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
          ;;            (EXTERNAL-LABEL (<C-variable>-name value))))
          )
         ((and (not (feature redefinable-functions-in-target))
               (is <expr> value))
          (emit LOAD (GLOBAL-ADDR (label self.name))))
         (else
          (emit LOAD (GLOBAL-CELL (label self.name))))))
      (else
       (error "don't know how to compile <variable>: " self ", holding the value: "value", type: "(type-of value))))))

(define-method compile <long> (-c-)
  ;; FIXME: We can't call COMPILE-OBJECT here, because that would box
  ;; the value. But then why the lack of symmetry with <string> and
  ;; other literals in the code (they are emitted as full heap objects)?
  (emit LOAD (LI64 self)))

;;;
;;; COMPILE-DEFINITION
;;;

;; TODO a lot of this is the same in the 32 bits
(define-method compile-definition <type>		(name -c-)	) ; we don't need (target-value <type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition (target-value false) name -c-))
(define-method compile-definition <C-function>		(name -c-)	) ; it will be handled at the call site
(define-method compile-definition <C-variable>		(name -c-)	) ; it will be handled at the site of reference

(define-method compile-definition <long> (name -c-)
  (with-current-segment (if (= 0 self) 'bss 'data)
    (label! name)
    (emit-symtab-entry/variable name
                                (if (= 0 self) +.bss-section-index+ +.data-section-index+)
                                (current-laddress)
                                +word-size-in-bytes+)
    (emit CELL self)))

;; kinda KLUDGE
;; this is used when emitting the literal dispatch tables of <selectors>
;; FIXME merge this somehow into the compile-object protocol?
;; this, and the whole emit-object business is kinda KLUDGEy
(define-function compile-array (self -c-)
  (let ((compiled (array (array-length self))))
    (for (i 0 (array-length self))
      (let ((obj (array-at self i)))
        (set (array-at compiled i)
             (typecase obj
               (<long>		(compile-object obj -c-))
               (<expr>		(compile-expr   obj () -c-))
               (<undefined>	(compile-object obj -c-))
               (else (error "compile-array: don't know how to compile: "obj))))))
    compiled))

(define-method compile-definition <array> (name -c-)
  (let ((compiled (compile-array self -c-)))
    (with-current-segment 'data
      (label! name)
      (emit-symtab-entry/variable name
                                  +.data-section-index+
                                  (current-laddress)
                                  +word-size-in-bytes+)
      (array-do el compiled
        (emit CELL el)))))

(define-method compile-definition <expr> (name -c-)
  (assert name)
  (let ((object-label (compile-expr self name -c-)))
    (when (feature redefinable-functions-in-target)
      (with-current-segment 'data
        (label! name)
        (emit CELL object-label)))))
