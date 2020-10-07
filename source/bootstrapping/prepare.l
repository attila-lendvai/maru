;;; -*- mode: lisp; coding: us-ascii -*-

(let ((host-module (current-module))
      (slave-module (create-module "slave")))
  (define *slave-module* slave-module)
  (define-function switch-to-slave-module ()
    ;;(warn "--- switching to the slave module\n")
    (set (current-module) *slave-module*))
  (switch-to-slave-module)
  ;; in the slave, set the global variable called 'host' to hold the host-module
  (eval-in-module *slave-module* `(define *host-module* ,host-module)))

;; NOTE: we are in the slave module now, and the following forms will be read/interned into the slave.
;; NOTE: the slave module doesn't have boot.l loaded at this point, we only have the primitives.

;; The variable bootstrapping? denotes that the process is underway in which a host loads a slave into an isolated module,
;; and then compiles the definitions to the target (does the level-shift).
(define bootstrapping? true)

;; The variable evolving? denotes that the host running the bootstrapping process is
;; the previous stage, i.e. an earlier version of us. It will be set in host-extras.l
;; if it gets loaded.
(define evolving? ())

(define switch-to-host-module
    (lambda ()
      ;;(warn "--- switching to the host  module\n")
      (set (current-module) *host-module*)))

(define eval-in-host (lambda (form)
                       (eval-in-module *host-module* form)))

(switch-to-host-module)

(define-function eval-in-slave (form)
  (eval-in-module *slave-module* form))

(define-form slave-value (form)
  `(eval-in-slave ',form))
