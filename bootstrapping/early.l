;;; -*- mode: lisp; coding: us-ascii -*-

(warn "--- boostrapping: early\n")

(switch-to-slave-module)

;; use the host vm's type machinery to be able to instantiate stuff while we are being bootstrapped
(define allocate-type-id
    (lambda ()
      (eval-in-module host '(host:allocate-type-id))))

(define register-type/host
    (lambda (type)
      (eval-in-module host (cons 'host:register-type (cons (cons 'host:quote (cons type)))))))

(warn "--- boostrapping: boot.l\n")
