;;; -*- mode: lisp; coding: us-ascii -*-

(warn "--- boostrapping: early\n")

(switch-to-slave-module)

;; integrate with the host vm's type machinery to instantiate slave objects
;; in the framework of the host's type machinery while we are being bootstrapped.
(define allocate-type-id
    (lambda ()
      (eval-in-module host '(host:allocate-type-id))))

(define register-type/host
    (lambda (type)
      (eval-in-module host (cons 'host:register-type (cons (cons 'host:quote (cons type)))))))

(warn "--- boostrapping: boot.l\n")
