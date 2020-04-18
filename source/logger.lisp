(in-package :maru.eval)

(locally
    #+sbcl(declare (sb-ext:muffle-conditions sb-kernel:redefinition-warning))
  (handler-bind
      ((sb-kernel:redefinition-warning #'muffle-warning))
    (hu.dwim.logger:deflogger maru () :runtime-level hu.dwim.logger:+warn+)
    (hu.dwim.logger:deflogger eval (maru))
    (hu.dwim.logger:deflogger reader (maru))
    (hu.dwim.logger:deflogger expander (maru)))
    )
