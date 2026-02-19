;;; -*- mode: lisp; coding: us-ascii -*-

(define-form host-value (form)
  `(eval-in-host ',form))

(define-form slave-repl ()
  '(eval-in-slave
    '(repl-stream *standard-input* *debug-output*)))

;; replace FEATURE with a strict version that doesn't fall back to
;; false on undefined features. this is to get early errors in case of
;; loading issues.
(define-form feature (name)
  (concat-symbol 'feature/ name))

(switch-to-host-env)

(when-at-expand (feature debug-info)
  (assert (= "maru-user" (<env>-name *globals*)))
  (assert (= "slave" (<env>-name (slave-value *globals*)))))

;; redirect to the slave env, and also be intolerant; see above
(define-form feature (name)
  `(eval-in-slave ',(concat-symbol 'feature/ name)))
