(in-package :maru.eval)

;; if you change anything here, then make sure that the assumptions in boot.l are in sync (e.g. predefined type indexes)

(declaim (inline is-pair? is-symbol? is-nil? is-long?
                 maru/intern))

(defun maru/intern (symbol-name)
  (check-type symbol-name string)
  (values (intern symbol-name :maru)))

(define-compiler-macro maru/intern (&whole form name)
  (if (stringp name)
      `(load-time-value (intern ,name :maru) t)
      form))

;; map some maru types to cl types, foo -> maru/foo
;; when changing don't forget to update the type-of subr!
(macrolet ((frob (&rest entries)
             `(progn
                ,@(loop
                    :for entry :in entries
                    :collect `(deftype ,(symbolicate '#:maru/ (first entry)) ()
                                ,(second entry))))))
  (frob
   ;; (undefined 'null)
   (double    'double-float)
   (long      '(signed-byte 64))
   (string    'string)
   ;; (character 'character)
   (pair      'cons)
   (symbol    'symbol)
   (array     'array)))

;; define CL constants for type indexes of the predefined types
(macrolet
    ((frob (&rest types)
       `(progn
          ,@(loop
              :for type :in types
              :for index :upfrom 0
              :collect `(defconstant ,(symbolicate "+MARU/TYPE-INDEX/" type "+") ,index)))))
  (frob #:undefined #:data #:long #:double #:string #:symbol #:pair #:_array #:array #:expr #:form #:fixed #:subr))

(defun maru/type-index-of (object)
  (cond
    ((is-nil? object)
     +maru/type-index/undefined+)
    (t
     (etypecase object
       (maru/data   +maru/type-index/data+)
       (maru/long   +maru/type-index/long+)
       (maru/double +maru/type-index/double+)
       (maru/string +maru/type-index/string+)
       (maru/symbol +maru/type-index/symbol+)
       (maru/pair   +maru/type-index/pair+)
       (maru/array  +maru/type-index/array+)
       (maru/oops   (maru/oops/type object))))))

(defun maru/allocate (type size)
  (case type
    (+maru/type-index/data+
     (make-maru/data size))
    (+maru/type-index/long+
     (not-yet-implemented))
    (+maru/type-index/double+
     (not-yet-implemented))
    (+maru/type-index/string+
     (make-string size))
    (+maru/type-index/symbol+
     (not-yet-implemented))
    (+maru/type-index/pair+
     (not-yet-implemented))
    (+maru/type-index/array+
     (make-array size))
    (t
     (make-maru/oops type size))))

(defun is-pair? (thing)
  (typep thing 'maru/pair))

(defun is-symbol? (thing)
  (and (symbolp thing)
       (progn
         (assert (eq (symbol-package thing) (find-package :maru)))
         t)))

(defun is-nil? (thing)
  (eq thing (maru/intern "nil")))

(defun is-long? (thing)
  (typep thing 'maru/long))

(defstruct (maru/data (:constructor %make-maru/data)
                      (:conc-name #:maru/data/)
                      (:predicate maru/data?))
  (bits #() :type vector))

(defun make-maru/data (size)
  (let ((object (%make-maru/data)))
    (setf (maru/data/bits object) (make-array size))
    object))

(defstruct (maru/oops (:constructor %make-maru/oops)
                      (:conc-name #:maru/oops/)
                      (:predicate maru/oops?))
  (type +maru/type-index/undefined+ :type maru/long)
  (bits #() :type vector))

(defun make-maru/oops (type size)
  (let ((object (%make-maru/oops)))
    (setf (maru/oops/type object) type)
    (setf (maru/oops/bits object) (make-array size))
    object))

(defun oop-at (object index)
  (let ((bits (maru/oops/bits object)))
    (aref bits index)))

(defun set-oop-at (object index value)
  (let ((bits (maru/oops/bits object)))
    (setf (aref bits index) value)))

(defmacro define-maru-struct ((name type-code &key (constructor-name (symbolicate '#:make-maru/ name)))
                              &body fields)
  (let* ((type-checker-name (symbolicate '#:maru/ name '#:?))
         (inlined-function-names (list type-checker-name constructor-name)))
    `(progn
       (defun ,constructor-name (,@fields)
         (let ((object (make-maru/oops ,type-code ,(length fields))))
           ,@(loop
               :for field :in fields
               :for index :upfrom 0
               :collect `(set-oop-at object ,index ,field))
           object))

       (defun ,type-checker-name (object)
         (and (maru/oops? object)
              (= (maru/oops/type object) ,type-code)))

       ,@(loop
           :for field :in fields
           :for index :upfrom 0
           :collect (let ((fn-name (symbolicate '#:maru/ name '#:/ field)))
                      (push fn-name inlined-function-names)
                      `(defun ,fn-name (object)
                         (assert (,type-checker-name object))
                         (oop-at object ,index)))
           :collect (let ((fn-name `(setf ,(symbolicate '#:maru/ name '#:/ field))))
                      (push fn-name inlined-function-names)
                      `(defun ,fn-name (value object)
                         (assert (,type-checker-name object))
                         (set-oop-at object ,index value))))

       (declaim (inline ,@inlined-function-names)))))

(define-maru-struct (fixed +maru/type-index/fixed+)
  function)

(define-maru-struct (expr +maru/type-index/expr+
                     :constructor-name %make-maru/expr)
  name
  definition
  environment)

(defun make-maru/expr (definition environment)
  (%make-maru/expr nil definition environment))

(define-maru-struct (form +maru/type-index/form+)
  function
  symbol)

(define-maru-struct (subr +maru/type-index/subr+)
  name
  impl)
