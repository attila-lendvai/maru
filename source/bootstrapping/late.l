;;; -*- mode: lisp; coding: us-ascii -*-

(define-form host-value (form)
  `(eval-in-host ',form))

(switch-to-host-env)

(when-at-expand feature/debug-info
  (assert (= "maru-user" (<env>-name *globals*)))
  (assert (= "slave" (<env>-name (slave-value *globals*)))))
