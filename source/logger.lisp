(in-package :maru.eval)

;; KLUDGE this will break if we are compiled with :hu.dwim.logger in the image, and then we are loaded from fasl's without it.
;; the price of making logger an optional dependency...
#+#.(maru.eval::if-symbol-exists :hu.dwim.logger '#:deflogger)
(progn
  ;; if we are loaded after :hu.dwim.logger, then use a full-featured logger
  (hu.dwim.logger:deflogger maru ())
  (hu.dwim.logger:deflogger eval (maru))
  (hu.dwim.logger:deflogger reader (maru))
  (hu.dwim.logger:deflogger expander (maru))
  )

#-#.(maru.eval::if-symbol-exists :hu.dwim.logger '#:deflogger)
(progn
  ;; otherwise only a fake minimalistic hu.dwim.logger API emulation
  (macrolet ((frob (name)
               `(progn
                  ,@(loop
                      :for postfix :in '(#:fatal #:error #:warn #:info #:debug #:dribble)
                      :collect
                      `(defmacro ,(symbolicate name "." postfix) (message &rest args)
                         (declare (ignore message args))
                         ;; `(format *debug-io* ,(string+ message "~%") ,@args)
                         `(values))))))
    (frob eval)
    (frob reader)
    (frob expander)
    ))
