(in-package :maru.test)

(defsuite (test :in root-suite))

(defmacro deftest (name args &body body)
  `(hu.dwim.stefil:deftest ,name ,args
     (let ((*print-circle* t))
       (with-new-maru-state
         ,@body))))

(defun read-and-run (expr)
  (maru/eval (maru/expand (maru/read-expression expr))))
