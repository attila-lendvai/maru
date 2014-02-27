(in-package :maru.eval)

;;;
;;; from hu.dwim.util
;;;
(defun not-yet-implemented (&optional (datum "Not yet implemented." datum?) &rest args)
  (when datum?
    (setf datum (concatenate 'string "Not yet implemented: " datum)))
  (apply #'cerror "Ignore and continue" datum args))

(defun not-yet-implemented/crucial-api (name)
  (warn "~S is not implemented on your platform! This may lead to runtime errors later..." name)
  `(error "~S is not implemented on your platform, sorry..." ',name))

(defun if-symbol-exists (package name)
  (if (and (find-package (string package))
           (find-symbol (string name) (string package)))
      '(:and)
      '(:or)))

(defun handle-otherwise/value (otherwise &key default-message)
  (setf default-message (ensure-list default-message))
  (case otherwise
    (:error  (apply #'error (or default-message (list "Otherwise assertion failed"))))
    (:cerror (apply #'cerror "Continue" (or default-message (list "Otherwise assertion failed"))))
    (:warn   (apply #'warn (or default-message (list "Otherwise assertion failed"))))
    (t (cond
         ((and (consp otherwise)
               (member (first otherwise) '(:error error :cerror cerror :warn warn) :test #'eq))
          (assert (not (null (rest otherwise))))
          (ecase (first otherwise)
            ((error :error)   (apply #'error  (rest otherwise)))
            ((cerror :cerror) (apply #'cerror (list* "Continue by returning (VALUES)" (rest otherwise))))
            ((warn :warn)     (apply #'warn   (rest otherwise))))
          (values))
         ((functionp otherwise)
          (funcall otherwise))
         (t
          otherwise)))))

;; from hu.dwim.def
(defmacro def-print-object (&whole whole class-name* &body body)
  "Define a PRINT-OBJECT method using PRINT-UNREADABLE-OBJECT.
  An example:
  (def print-object parenscript-dispatcher ; could be (parenscript-dispatcher :identity nil)
    (when (cachep self)
      (princ \"cached\")
      (princ \" \"))
    (princ (parenscript-file self)))"
  (with-unique-names (stream printing)
    (let ((args (ensure-list class-name*)))
      (destructuring-bind (class-name &key (identity t) (type t) with-package (muffle-errors t)) args
          (multiple-value-bind
                (body declarations documentation)
              (parse-body body :documentation t :whole whole)
            `(defmethod print-object ((-self- ,class-name) ,stream)
               ,@(when documentation
                       (list documentation))
               ,@declarations
               (print-unreadable-object (-self- ,stream :type ,type :identity ,identity)
                 (let ((*standard-output* ,stream))
                   (block ,printing
                     (,@(if muffle-errors
                            `(handler-bind ((error (lambda (error)
                                                     (declare (ignore error))
                                                     (write-string "<<error printing object>>")
                                                     (return-from ,printing)))))
                            `(progn))
                        (let (,@(when with-package `((*package* ,(find-package with-package)))))
                          ,@body)))))
               ;; primary PRINT-OBJECT methods are supposed to return the object
               -self-))))))
