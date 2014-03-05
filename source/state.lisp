(in-package :maru.eval)

;;;
;;; the eval state
;;;

(defun define-predefined ()
  (dolist (name *predefined-subr-names*)
    (maru/define (global-namespace-of *eval-context*)
                 name
                 (make-maru/subr name (fun-name-from-subr-name name))))
  (dolist (name *predefined-fixed-names*)
    (maru/define (global-namespace-of *eval-context*)
                 name
                 (make-maru/fixed (make-maru/subr name (fun-name-from-subr-name name))))))

(defun make-global-namespace ()
  ;; this fn is used by the tests
  (let ((ref (maru/cons (maru/intern "*global-namespace*") +maru/nil+)))
    (maru/set-tail ref (maru/cons ref +maru/nil+))))

(defun initialize-maru-state ()
  (check-type *eval-context* eval-context)

  (setf (global-namespace-of *eval-context*) (make-global-namespace))

  (flet ((maru/define-in-global-namespace (name &optional value)
           (maru/define (global-namespace-of *eval-context*) (maru/intern name) value)))
    (setf (globals-of *eval-context*)     (maru/define-in-global-namespace "*globals*" (global-namespace-of *eval-context*)))
    (setf (expanders-of *eval-context*)   (maru/define-in-global-namespace "*expanders*"))
    (setf (evaluators-of *eval-context*)  (maru/define-in-global-namespace "*evaluators*"))
    (setf (applicators-of *eval-context*) (maru/define-in-global-namespace "*applicators*")))

  (define-predefined))

(defmacro with-new-maru-state (&body body)
  `(let ((*eval-context* (make-eval-context)))
     (initialize-maru-state)
     ,@body))
