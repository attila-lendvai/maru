;;; -*- mode: lisp; coding: us-ascii -*-

(define-form host-value (form)
  `(eval-in-host ',form))

(define-form slave-repl ()
  '(eval-in-slave
    '(repl-stream *standard-input* *debug-output*)))

(switch-to-host-env)

(when-at-expand (feature debug-info)
  (assert (= "maru-user" (<env>-name *globals*)))
  (assert (= "slave" (<env>-name (slave-value *globals*)))))

;; TODO delme when the compiler is loaded into the slave
(eval-in-slave '(set (feature emit-with-object-headers) true))
(define-form feature (name)
  ;; we deliberately avoid calling DEFINED? for now to trigger explicit errors
  `(eval-in-slave ',(concat-symbol 'feature/ name)))
