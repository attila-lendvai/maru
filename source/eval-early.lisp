(in-package :maru.eval)

(defvar *eval-context*)

(defparameter *predefined-subr-names* (list))
(defparameter *predefined-fixed-names* (list))

(declaim (inline maru/get-var maru/set-var maru/lookup))

#+nil
(hu.dwim.defclass-star:defclass* eval-context ()
  (;;(current-line 0)
   ;;(current-path)
   ;;(current-source)
   (locals-are-namespace? nil :type boolean)
   (global-namespace)
   (globals)
   (expanders)
   (evaluators)
   (applicators)))

;; macroexpansion of the above to lower dependencies
(defclass eval-context ()
  (;;(current-line :initform 0 :accessor current-line-of :initarg :current-line)
   ;;(current-path :accessor current-path-of :initarg :current-path)
   ;;(current-source :accessor current-source-of :initarg :current-source)
   (locals-are-namespace? :initform nil :accessor locals-are-namespace? :initarg :locals-are-namespace? :type boolean)
   (global-namespace :accessor global-namespace-of :initarg :global-namespace)
   (globals :accessor globals-of :initarg :globals)
   (expanders :accessor expanders-of :initarg :expanders)
   (evaluators :accessor evaluators-of :initarg :evaluators)
   (applicators :accessor applicators-of :initarg :applicators)))

(defun make-eval-context ()
  (make-instance 'eval-context))

;; FIXME rename to what? find-environment-entry?
(defun maru/find-environment (env &key otherwise)
  ;; TODO rewrite to something lispy
  (loop
    :with entry = env
    :while (typep entry 'maru/pair)
    :for ass = (maru/get-head entry)
    :do (if (and (typep ass 'maru/pair)
                 (eq (maru/get-tail ass) entry))
            (return-from maru/find-environment entry)
            (setf entry (maru/get-tail entry))))
  (handle-otherwise/value otherwise :default-message `("Failed to find environment ~S" ,env)))

(defun maru/find-variable-2 (env name)
  (eval.dribble "MARU/FIND-VARIABLE-2 for ~S in ~S" name env)
  (loop
    :until (maru/nil? env)
    :do
    ;; (eval.dribble "MARU/FIND-VARIABLE-2 looking at env ~S" env)
    (let ((ass (maru/get-head env)))
      (if (eq name (maru/car ass))
          (progn
            (eval.dribble "MARU/FIND-VARIABLE-2 is returning with ~S" ass)
            (return-from maru/find-variable-2 ass))
          (setf env (maru/get-tail env)))))
  (eval.dribble "MARU/FIND-VARIABLE-2 is returning without a match")
  nil)

(defun maru/find-variable (env name &key otherwise)
  (loop
    :until (maru/nil? env)
    :do (if (eq env (global-namespace-of *eval-context*))
            (let ((ass (maru/find-variable-2 env name)))
              (return-from maru/find-variable
                (or ass
                    (handle-otherwise/value otherwise :default-message `("Failed to find variable ~S" ,name)))))
            (let ((ass (maru/get-head env)))
              (if (eq name (maru/car ass))
                  (return-from maru/find-variable ass)
                  (setf env (maru/get-tail env))))))
  (handle-otherwise/value otherwise :default-message `("Failed to find variable ~S" ,name)))

(defun maru/find-namespace-variable (env name)
  (let ((beg (maru/find-environment env :otherwise :error))
        (end (maru/find-environment (maru/cdr env) :otherwise (maru/intern "nil"))))
    ;;(eval.dribble "MARU/FIND-NAMESPACE-VARIABLE beg ~S end ~S" beg end)
    (loop
      :until (eq beg end)
      :for ass = (maru/car beg)
      :do (if (eq name (maru/car ass))
              (return-from maru/find-namespace-variable ass)
              (setf beg (maru/get-tail beg)))))
  nil)

(defun maru/lookup (env name)
  (maru/cdr (maru/find-variable env name)))

(defun maru/get-var (var)
  (maru/get-tail var))

(defun maru/set-var (var value)
  (maru/set-tail var value))

(defun maru/define (env name value)
  (let* ((env (maru/find-environment env :otherwise :error))
         (binding (maru/cons nil (maru/get-tail env))))
    (maru/set-tail env binding)
    (setf binding (maru/set-head binding (maru/cons name value)))
    (eval.dribble "Defined new binding, name ~S, value ~S, in env ~S" name value env)
    binding))
