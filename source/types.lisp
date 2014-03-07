(in-package :maru.eval)

;; if you change anything here, then make sure that the assumptions in boot.l are in sync (e.g. predefined type indexes)

(declaim (inline maru/oops? maru/array-at maru/set-array-at))

;; (define-function name-of-type (type)	(array-at %type-names type))
(defun maru/name-of-type (type-index)
  (let ((type-names (maru/get-var (maru/find-variable (global-namespace-of *eval-context*) (maru/intern "%type-names")))))
    (maru/array-at type-names type-index)))

;;(define-function type-name-of (obj)	(name-of-type (type-of obj)))
(defun maru/type-name-of (object)
  (maru/name-of-type (maru/type-of object)))

;;;
;;; data
;;;
(defstruct (maru/data (:constructor %make-maru/data)
                      (:conc-name #:maru/data/)
                      (:predicate maru/data?))
  (bits #() :type vector))

(defun make-maru/data (size)
  (let ((object (%make-maru/data)))
    (setf (maru/data/bits object) (make-array size :initial-element +maru/nil+))
    object))

;;;
;;; general oops, the "base class" of other maru impl structures
;;;
(defclass maru/oops ()
  ((type :initform +maru/type-index/undefined+
         :type maru/long
         :accessor maru/oops/type
         :initarg :type)
   (bits :initform #()
         :type vector
         :accessor maru/oops/bits
         :initarg :bits)))

(defun maru/oops? (thing)
  (typep thing 'maru/oops))

(defun make-maru/oops (type size)
  (make-instance 'maru/oops
                 :type type
                 :bits (make-array size :initial-element +maru/nil+)))

(defun oop-at (object index)
  (let ((bits (maru/oops/bits object)))
    (aref bits index)))

(defun set-oop-at (object index value)
  (let ((bits (maru/oops/bits object)))
    (setf (aref bits index) value)))

(def-print-object (maru/oops :identity nil :type nil)
  (let ((*print-right-margin* most-positive-fixnum)
        (type (maru/type-of -self-)))
    (write-string (or (ignore-errors
                        (symbol-name (maru/name-of-type type)))
                      (princ-to-string type)))
    (case type
      (#.+maru/type-index/subr+
       (write-string " ")
       (write-string (symbol-name (maru/subr/name -self-))))
      (#.+maru/type-index/expr+
       (write-string " ")
       (write-string (symbol-name (maru/expr/name -self-))))
      (#.+maru/type-index/fixed+
       (write-string " ")
       (prin1 (maru/fixed/function -self-)))
      (#.+maru/type-index/array+
       (write-string " ")
       (prin1 (maru/array/size -self-)))
      (t
       (write-string " :size ")
       (princ (array-dimension (maru/oops/bits -self-) 0))))))

(defmacro define-maru-struct ((name type-code &key (constructor-name (symbolicate '#:make-maru/ name)))
                              &body fields)
  (let* ((type-checker-name (symbolicate '#:maru/ name '#:?))
         (inlined-function-names (list type-checker-name constructor-name))
         (definitions (list*
                       `(defun ,constructor-name (,@fields)
                          (let ((object (make-maru/oops ,type-code ,(length fields))))
                            ,@(loop
                                :for field :in fields
                                :for index :upfrom 0
                                :collect `(set-oop-at object ,index ,field))
                            object))
                       `(defun ,type-checker-name (object)
                          (and (maru/oops? object)
                               (= (maru/oops/type object) ,type-code)))
                       (loop
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
                                       (set-oop-at object ,index value)))))))
    `(progn
       (declaim (inline ,@inlined-function-names))
       ,@definitions)))

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

;;;
;;; array
;;;
(define-maru-struct (array +maru/type-index/array+
                     :constructor-name %make-maru/array)
  elements
  size)

(defun make-maru/array (size)
  (check-type size (integer 0))
  (%make-maru/array (make-array (max 4 size) :initial-element +maru/nil+)
                    size))

(defun maru/array-length (array)
  (assert (maru/array? array))
  (maru/array/size array))

(defun maru/array-at (array index)
  (assert (maru/array? array))
  (check-type index (integer 0))
  (let ((elements (maru/array/elements array))
        (size (maru/array/size array)))
    (if (< index size)
        (aref elements index)
        ;; TODO signalling an error seems better, but would break eval.c compatibility
        ;; (error "array-at ~S out of bounds ~S on array ~S" index size array)
        +maru/nil+)))

(defun maru/set-array-at (array index value)
  (assert (maru/array? array))
  (check-type index (integer 0))
  (let ((elements (maru/array/elements array))
        (size (maru/array/size array)))
    (when (>= index size) ; maru semantic size
      (let ((capacity (array-dimension elements 0)))
        (when (>= index capacity) ; underlying CL array size
          (let ((new-capacity (max 2 capacity)))
            (loop
              :while (>= index
                         new-capacity)
              :do (setf new-capacity (* new-capacity 2)))
            ;; CLHS is unclear about the identity, so let's just setf it back
            (setf elements (adjust-array elements
                                         new-capacity
                                         :initial-element +maru/nil+))
            (setf (maru/array/elements array) elements))))
      ;; update maru semantic size
      (setf (maru/array/size array) (1+ index)))
   (setf (aref elements index) value)))

(defun maru/type-of (object)
  (cond
    ((maru/nil? object)
     +maru/type-index/undefined+)
    (t
     (etypecase object
       (maru/data   +maru/type-index/data+)
       (maru/long   +maru/type-index/long+)
       (maru/double +maru/type-index/double+)
       (maru/string +maru/type-index/string+)
       (maru/symbol +maru/type-index/symbol+)
       (maru/pair   +maru/type-index/pair+)
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
     (make-array size :initial-element +maru/nil+))
    (t
     (make-maru/oops type size))))

(defun maru/print (object &key (stream *standard-output*))
  (with-standard-io-syntax
    (let ((*print-circle* t)
          (*print-readably* nil))
      (prin1 object stream))))
