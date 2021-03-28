;;; -*- mode: lisp; coding: us-ascii -*-

(set-working-directory *slave-directory*)

(define *host-env* *globals*)

;; *slave-env* will be the direct parent of *target-env* (i.e. lookup is delegated to it).
;; you can think of *slave-env* as the syntax-module of the target: all macros,
;; constants, and any meta-level stuff are evaluated in that environment.
;; *target-env* will be set up later in emit-early.l.
(let ((slave-env (environment (if-at-expand (defined? '*maru-module*)
                                  (<module>-globals *maru-module*)
                                *maru*))))
  (assert (= 0 (<env>-level slave-env)))
  ;; NOTE this can only come in once we have evolved; evolving?
  (when-at-expand feature/debug-info
    (set (<env>-name slave-env) "slave"))
  (define *slave-env* slave-env)
  (environment-define *slave-env* 'switch-to-host-env
                      (lambda ()
                        (set *globals* *host-env*)))
  (set *globals* *slave-env*)
  ;; NOTE this toplevel form is encoded into the host env. the previous
  ;; switch-to-slave-env happens at runtime, i.e. it has no effect on the
  ;; encode phase. hence the seemingly superfluous use of eval below.
  (eval `(define *host-env* ,*host-env*) *slave-env*))

;; NOTE: we are in the slave module now, and the following forms will be read/interned into the slave.
;; NOTE: the slave module doesn't have boot.l loaded at this point, we only have the primitives.

;; The variable bootstrapping? denotes that the process is underway in which a host loads a slave into an isolated module,
;; and then compiles the definitions to the target (does the level-shift).
(define bootstrapping? true)

;; The variable evolving? denotes that the host running the bootstrapping process is
;; the previous stage, i.e. an earlier version of us. It will be set in host-extras.l
;; if it gets loaded.
(define evolving? ())

(define eval-in-host (lambda (form)
                       (eval form *host-env*)))

(eval-in-host ((lambda args args) 'assert ((lambda args args) 'is '<target-function> load)))

(switch-to-host-env)

(assert (= *host-env* (eval '*host-env* *slave-env*)))

(assert (= (eval '*host-env* *host-env*) (eval '*host-env* *slave-env*)))

(define-function switch-to-slave-env ()
  (set *globals* *slave-env*))

(define-function eval-in-slave (form)
  (eval form *slave-env*))

(define-form slave-value (form)
  `(eval-in-slave ',form))

(when-at-expand feature/debug-info
  ;; maru-user is the host
  (assert (= "maru-user" (<env>-name *globals*))))
