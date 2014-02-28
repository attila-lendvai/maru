(in-package :maru.test)

(defsuite (test :in root-suite))

(defun ensure-cwd-is-right ()
  (setf *default-pathname-defaults* (asdf/system:system-relative-pathname (asdf:find-system :maru) "../../")))

(defmacro deftest (name args &body body)
  `(hu.dwim.stefil:deftest ,name ,args
     (let ((*print-circle* t))
       (ensure-cwd-is-right)
       (with-new-maru-state
         ,@body))))

(defun read-and-run (expr)
  (maru/eval (maru/expand (maru/read-expression expr))))
