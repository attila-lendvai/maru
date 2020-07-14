;;; -*- mode: lisp; coding: us-ascii -*-

(warn "--- boostrapping: early\n")

(switch-to-slave-module)

;; use the host vm's type machinery to be able to instantiate stuff while we are being bootstrapped
(define allocate-type-id
    (if evolving?
        (lambda ()
          (eval-in-module host '(host:%allocate-type (host:quote <dummy-bootstrap-type-name>))))
      (lambda ()
        (eval-in-module host '(host:allocate-type-id)))))

(define register-type/host
    (lambda (type)
      (if (not evolving?) ; types in the previous stage are simpler and it's not needed when we are evolving from it
          (eval-in-module host (cons 'host:register-type (cons (cons 'host:quote (cons type))))))))

(warn "--- boostrapping: boot.l\n")
