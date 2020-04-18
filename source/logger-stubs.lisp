(in-package :maru.eval)

;; minimalistic hu.dwim.logger API emulation
(macrolet
    ((frob (name)
       `(progn
          ,@(loop
                  :for postfix :in '(#:fatal #:error #:warn #:info #:debug #:dribble)
                  :collect
                  `(defmacro ,(symbolicate name "." postfix) (message &rest args)
                     (declare (ignorable message args))
                     (if nil
                         `(with-standard-io-syntax
                            (let ((*print-circle* t)
                                  (*print-readably* nil))
                              (format *debug-io* ,(concatenate 'string message "~%") ,@args)))
                         `(values)))))))
  (frob maru)
  (frob eval)
  (frob reader)
  (frob expander)
  )
