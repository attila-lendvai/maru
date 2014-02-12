(in-package :maru.eval)

;;;
;;; infrastructure
;;;

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun fun-name-from-subr-name (name)
    (assert (is-symbol? name))
    (format-symbol :maru.eval "MARU/SUBR/~A" (string-upcase (symbol-name name)))))

(defun arity-error (operator-name expected actual)
  (error "Wrong number of arguments (~A instead of ~A) for operator ~S"
         actual expected operator-name))

(defun proper-arity-or-die (operator-name expected-count arguments)
  (check-type arguments maru/pair)
  (flet ((fail ()
           (arity-error operator-name expected-count (maru/length arguments))))
    (loop
      :for i :from 0 :to expected-count
      :for arg = arguments :then (maru/cdr arg)
      :do
      (cond
        ((< i expected-count)
         (unless (typep arg 'maru/pair)
           (fail)))
        ((= i expected-count)
         (when (typep arg 'maru/pair)
           (fail)))))))

(defmacro def-subr ((name &key expected-arg-count fixed) &body body)
  (let* ((subr-name (maru/intern (string-downcase name)))
         (fun-name (fun-name-from-subr-name subr-name)))
    `(progn
       (eval-when (:compile-toplevel :load-toplevel :execute)
         (pushnew ',subr-name ,(if fixed
                                   '*predefined-fixed-names*
                                   '*predefined-subr-names*)))
       (defun ,fun-name (-args- -env-)
         (declare (ignorable -args- -env-))
         (let ((-subr- ',subr-name))
           (declare (ignorable -subr-))
           ,@(when expected-arg-count
                   `((proper-arity-or-die -subr- ,expected-arg-count -args-)))
           ,@body)))))

;;;
;;; debug helpers
;;;

(def-subr (invoke-debugger)
  (break "Maru invoked the debugger with args ~S in env ~S" -args- -env-)
  (maru-symbol "nil"))


;;;
;;; predefined maru, fixed
;;;

(def-subr (if :fixed t)
  (if (not (eq (maru/eval (first -args-) -env-)
               (maru-symbol "nil")))
      (maru/eval (maru/second -args-) -env-)
      (let ((result (maru-symbol "nil"))
            (else (maru/cddr -args-)))
        (loop
          :while (is-pair? else)
          :do
          (setf result (maru/eval (maru/get-head else) -env-))
          (setf else (maru/cdr else)))
        result)))

(def-subr (and :fixed t)
  (let ((result (maru-symbol "t")))
    (loop
      :for cell = -args- :then (maru/rest cell)
      :while (is-pair? cell)
      :do
      (setf result (maru/eval (maru/get-head cell) -env-))
      (when (eq (maru-symbol "nil") result)
        (return)))
    result))

(def-subr (or :fixed t)
  (let ((result (maru-symbol "nil")))
    (loop
      :for cell = -args- :then (maru/rest cell)
      :while (is-pair? cell)
      :do
      (setf result (maru/eval (maru/get-head cell) -env-))
      (when (not (eq (maru-symbol "nil") result))
        (return)))
    result))

(def-subr (set :fixed t :expected-arg-count 2)
  (let* ((sym (maru/first -args-))
         (var (progn
                (unless (is-symbol? sym)
                  (error "~S can only set variables denoted by symbols, but it got ~S" -subr- sym))
                (maru/find-variable -env- sym :otherwise :error)))
         (val (maru/eval (maru/second -args-) -env-)))
    (when (and (maru/expr? val)
               (eq (maru/expr/name val)
                   (maru-symbol "nil")))
      (setf (maru/expr/name val) sym))
    (maru/set-tail var val)
    val))

(def-subr (let :fixed t)
  (eval.dribble "LET with bindings ~S" (maru/first -args-))
  (let* ((bound (maru/cons (maru-symbol "nil")
                           (maru-symbol "nil")))
         (ptr bound))
    (loop
      :for cell = (maru/first -args-) :then (maru/get-tail cell)
      :while (is-pair? cell)
      :for binding = (maru/get-head cell)
      :do
      (let ((name (maru-symbol "nil"))
            (value (maru-symbol "nil")))
        (if (is-pair? binding)
            (progn
              (setf name (maru/first binding))
              (setf value (if (eq (maru-symbol "nil")
                                  (maru/second binding))
                              (maru-symbol "nil")
                              (maru/eval (maru/second binding) -env-))))
            (progn
              (unless (is-symbol? binding)
                (error "~S as a binding is illegal in ~S" binding -subr-))
              (setf name binding)))
        (setf ptr (maru/set-tail ptr (maru/cons (maru-symbol "nil")
                                                (maru-symbol "nil"))))
        (maru/set-head ptr (maru/cons name value))))
    (maru/set-tail ptr -env-)
    (if (locals-are-namespace? *eval-context*)
        (maru/set-head bound (maru/cons (maru-symbol "*locals*")
                                        bound))
        (setf bound (maru/get-tail bound)))
    (let ((result (maru-symbol "nil")))
      (loop
        :for cell = (maru/cdr -args-) :then (maru/cdr cell)
        :while (is-pair? cell)
        :do (setf result (maru/eval (maru/get-head cell) bound)))
      result)))

(def-subr (while :fixed t)
  (let ((test (maru/first -args-)))
    (loop
      :until (eq (maru-symbol "nil") (maru/eval test -env-))
      :do
      (loop
        :for cell = (maru/cdr -args-) :then (maru/cdr cell)
        :while (is-pair? cell)
        :do (maru/eval (maru/get-head cell) -env-))))
  (maru-symbol "nil"))

(def-subr (quote :fixed t :expected-arg-count 1)
  (maru/car -args-))

(def-subr (lambda :fixed t)
  (make-maru/expr -args- -env-))

(def-subr (define :fixed t)
  (let* ((name (maru/car -args-))
         (value (maru/eval (maru/car (maru/cdr -args-)) -env-))
         (var (maru/find-namespace-variable -env- name)))
    (if var
        (maru/set-tail var value)
        (setf var (maru/define -env- name value)))
    (when (maru/form? value)
      (setf value (maru/form/function value)))
    (when (and (maru/expr? value)
               (null (maru/expr/name value)))
      (setf (maru/expr/name value) name))
    value))

;;;
;;; predefined maru, simple subr
;;;

(def-subr (defined?)
  (let* ((name (maru/car -args-))
         (env (maru/car (maru/cdr -args-))))
    (when (eq (maru-symbol "nil")
              env)
      (setf env (maru/get-var (globals-of *eval-context*))))
    (if (maru/find-variable env name :otherwise nil)
        (maru-symbol "t")
        (maru-symbol "nil"))))

(defmacro def-binary-arithmetic-subr (operator &optional (lisp-operator operator))
  `(def-subr (,operator :expected-arg-count 2)
    (let ((lhs (maru/get-head -args-))
          (rhs (maru/get-head (maru/get-tail -args-))))
      (cond
        ((typep lhs 'maru/long)
         (cond
           ((typep rhs 'maru/long)
            (coerce (,lisp-operator lhs rhs) 'maru/long))
           ((typep rhs 'maru/double)
            (coerce (,lisp-operator lhs rhs) 'maru/double))))
        ((typep lhs 'maru/double)
         (cond
           ((typep rhs 'maru/double)
            (coerce (,lisp-operator lhs rhs) 'maru/double))
           ((typep rhs 'maru/long)
            (coerce (,lisp-operator lhs rhs) 'maru/long))))
        (t (error "Non-numeric arguments for (~S ~S ~S)" ',operator lhs rhs))))))

(def-binary-arithmetic-subr +)

(def-binary-arithmetic-subr *)
(def-binary-arithmetic-subr /)
(def-binary-arithmetic-subr % mod)
(def-subr (-)
  (unless (is-pair? -args-)
    (arity-error -subr- "at least 1" (maru/length -args-)))
  (let ((lhs (maru/get-head -args-))
        (args (maru/rest -args-)))
    (if (is-pair? args)
        (let ((rhs (maru/get-head -args-)))
          (when (is-pair? (maru/rest -args-))
            (arity-error -subr- "at most 2" (maru/length -args-)))
          (cond
            ((typep lhs 'maru/long)
             (cond
               ((typep rhs 'maru/long) (coerce (- lhs rhs) 'maru/long))
               ((typep rhs 'maru/double) (coerce (- lhs rhs) 'maru/double))))
            ((typep lhs 'maru/double)
             (cond
               ((typep rhs 'maru/double) (coerce (- lhs rhs) 'maru/double))
               ((typep rhs 'maru/long) (coerce (- lhs rhs) 'maru/long))))
            (t (error "Non-numeric arguments for (~S ~S ~S)" -subr- lhs rhs))))
        (cond
          ((typep lhs 'maru/long)
           (coerce (- lhs) 'maru/long))
          ((typep lhs 'maru/double)
           (coerce (- lhs) 'maru/double))
          (t (error "Non-numeric arguments for (~S ~S)" -subr- lhs))))))

(defmacro def-comparator-subr (operator)
  `(def-subr (,operator :expected-arg-count 2)
    (let ((lhs (maru/get-head -args-))
          (rhs (maru/get-head (maru/get-tail -args-))))
      (maru/bool (,operator lhs rhs)))))

(def-comparator-subr <)

(def-comparator-subr <=)
(def-comparator-subr >=)
(def-comparator-subr >)

(defun %equal (args)
  (let ((lhs (maru/get-head args))
        (rhs (maru/get-head (maru/get-tail args))))
    (typecase lhs
      ((or maru/long
           maru/double)
       (= lhs rhs))
      (maru/string
       (and (typep rhs 'maru/string)
            (string= lhs rhs)))
      (t
       (eq lhs rhs)))))

(def-subr (= :expected-arg-count 2)
  (maru/bool (%equal -args-)))

(def-subr (!= :expected-arg-count 2)
  (maru/bool (not (%equal -args-))))

(def-subr (exit)
  (error "exit subr was called"))

(def-subr (abort)
  (error "abort subr was called"))

(def-subr (open)
  (not-yet-implemented))

(def-subr (close)
  (not-yet-implemented))

(def-subr (getc)
  (not-yet-implemented))

(def-subr (putc)
  (not-yet-implemented))

(def-subr (read)
  (not-yet-implemented))

(def-subr (expand)
  (let ((expr (maru/car -args-))
        (env (maru/car (maru/cdr -args-))))
    (when (eq env (maru-symbol "nil"))
      (setf env -env-))
    (maru/expand expr env)))

(def-subr (eval)
  (let ((expr (maru/car -args-))
        (env (maru/car (maru/cdr -args-))))
    (when (eq env (maru-symbol "nil"))
      (setf env (globals-of *eval-context*)))
    (let ((expanded (maru/expand expr env)))
      (maru/eval expanded env))))

(def-subr (apply)
  (unless (is-pair? -args-)
    (arity-error -subr- "2+" (maru/length -args-)))
  (let* ((fun (maru/first -args-))
         (a -args-)
         (b (maru/get-tail a))
         (c (maru/cdr b)))
    (loop
      :while (is-pair? c)
      :do
      (setf a b)
      (setf c (maru/cdr (setf b c))))
    ;; FIXME sideffecting the args list? is it a problem?
    (maru/set-tail a (maru/car b))
    (maru/apply fun (maru/rest -args-) -env-)))

(def-subr (current-environment)
  -env-)

(def-subr (type-of)
  (proper-arity-or-die -subr- 1 -args-)
  (not-yet-implemented)
  (maru-symbol "nil"))

(def-subr (print)
  (loop
    :for cell = -args- :then (maru/cdr -args-)
    :while (is-pair? cell)
    :do (print (maru/car cell)))
  (maru-symbol "nil"))

(def-subr (dump)
  (loop
    :for cell = -args- :then (maru/cdr -args-)
    :while (is-pair? cell)
    :do (print (maru/car cell)))
  (maru-symbol "nil"))

(def-subr (format)
  (not-yet-implemented)
  (maru-symbol "nil"))

(def-subr (form)
  (make-maru/form (maru/car -args-) (maru/car (maru/cdr -args-))))

(def-subr (cons :expected-arg-count 2)
  (maru/cons (maru/first -args-) (maru/second -args-)))

(def-subr (pair? :expected-arg-count 1)
  (maru/bool (is-pair? (maru/first -args-))))

(def-subr (car :expected-arg-count 1)
  (maru/car (maru/first -args-)))

(def-subr (set-car :expected-arg-count 2)
  (maru/set-head (maru/first -args-) (maru/second -args-)))

(def-subr (cdr :expected-arg-count 1)
  (maru/cdr (maru/first -args-)))

(def-subr (set-cdr :expected-arg-count 2)
  (maru/set-tail (maru/first -args-) (maru/second -args-)))

(def-subr (symbol? :expected-arg-count 1)
  (maru/bool (is-symbol? (maru/first -args-))))

(def-subr (string? :expected-arg-count 1)
  (maru/bool (typep (maru/first -args-) 'string)))

(def-subr (string :expected-arg-count 1)
  (let ((length (maru/first -args-)))
    (check-type length maru/long)
    (make-string length)))

(def-subr (string-length :expected-arg-count 1)
  (let ((object (maru/first -args-)))
    (etypecase object
      (maru/string
       (length object))
      (maru/symbol
       (length (symbol-name object))))))

(def-subr (string-at :expected-arg-count 2)
  (let ((object (maru/first -args-))
        (index (maru/second -args-)))
    (check-type index maru/long)
    (etypecase object
      (maru/string
       (elt object index))
      (maru/symbol
       (elt (symbol-name object) index)))))

(def-subr (set-string-at :expected-arg-count 3)
  (let ((object (maru/first -args-))
        (value (maru/second -args-))
        (index (maru/third -args-)))
    (check-type object maru/string)
    (check-type index maru/long)
    (check-type value maru/character)
    (setf (elt object index) value)))

(def-subr (string-copy)
  (not-yet-implemented))

(def-subr (string-compare)
  (not-yet-implemented))

(def-subr (symbol-compare)
  (not-yet-implemented))

(def-subr (string->symbol)
  (not-yet-implemented))

(def-subr (symbol->string)
  (not-yet-implemented))

(def-subr (long->double)
  (not-yet-implemented))

(def-subr (double->long)
  (not-yet-implemented))

(def-subr (string->long)
  (not-yet-implemented))

(def-subr (string->double)
  (not-yet-implemented))

(def-subr (array)
  (not-yet-implemented))

(def-subr (array?)
  (not-yet-implemented))

(def-subr (array-length)
  (not-yet-implemented))

(def-subr (array-at)
  (not-yet-implemented))

(def-subr (set-array-at)
  (not-yet-implemented))

(def-subr (insert-array-at)
  (not-yet-implemented))

(def-subr (data)
  (not-yet-implemented))

(def-subr (data-length)
  (not-yet-implemented))
