;;; -*- mode: lisp; coding: us-ascii -*-

(define-form host-value (form)
  `(eval-in-host ',form))

(eval-in-host
 `(when-at-expand feature/debug-info
    (assert (= "maru-user" (<env>-name ,(host-value *globals*))))))

(switch-to-host-env)

(when-at-expand feature/debug-info
  (assert (= "slave" (<env>-name (slave-value *globals*)))))
