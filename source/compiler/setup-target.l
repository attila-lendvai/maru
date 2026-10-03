;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; target env setup
;;;

(let (arch word-size)
  ;; normalize arch into a symbol
  (case target/arch
    ("x86_64"
     (set arch		'x86-64)
     (set word-size	64))

    (("i686" "i386")
     (set arch		'IA-32)
     (set word-size	32))

    (("aarch64")
     (set arch		'aarch64)
     (set word-size	64))

    (else
     (error "Couldn't identify architecture and word size from target/arch: "target/arch)))

  ;; define in the host to be able to load cgrov.l
  (define-constant target/triple		(concat-strings target/arch "-" target/vendor "-" target/os
                                                                (if (equal "" target/abi)
                                                                    ""
                                                                  (concat-string "-" target/abi))))

  (eval-in-slave
   `(let ()
      (define-constant target/arch		'',arch)
      (define-constant target/os		'',(string->symbol target/os))
      (define-constant target/little-endian?	true) ; this is needed by the compiler tests
      ;; we need the eval here because constants are <form> objects,
      ;; and without the eval we would pass a form object between the
      ;; host and the slave, but we want to pass the value.
      (define-constant target/triple		,(eval 'target/triple))
      (define-constant target/cell-size/bits	,word-size)
      (define-constant target/cell-size/bytes	,(/ word-size 8)))))

(switch-to-slave-env)

(set (feature redefinable-functions-in-target) false) ; costs about 20-30% time increase in the bootstrap process
(set (feature strict-semantics-for-compiled-set) true) ; compiled set-oop-at & co. also returns the value that was just set
(set (feature backtrace)		(or true (feature profiler) (< 0 *safety*)))
(set (feature object-canary)		(or () (<= 3 *safety*)))
(set (feature emit-with-object-headers)	false)
(set (feature platform/libc)		false)
(set (feature platform/posix)		false)
(set (feature platform/linux)		false)
(set (feature memory-block)		true)

;; TODO set up proper framework for optimization control, merge with *optimised*
(set (feature optimize-space)		true)
(set (feature optimize-speed)		(and (not (feature optimize-space)) (<= *safety* 2)))

;; FIXME these would be too much trouble to define above because nested quasiquote doesn't work
(define-form bytes-to-words (value)
  (if (long? value)
      (/  value target/cell-size/bytes)
    `(/ ,value ,target/cell-size/bytes)))

(define-form words-to-bytes (value)
  (if (long? value)
      (* value  target/cell-size/bytes)
    `(* ,value ,target/cell-size/bytes)))

;; we rebind these to point to the actual definitions (as opposed to the symbols naming them),
;; so that CONS can be redefined in the target and the expansion of quasiquotes still work as expected
(define qq-concat-list	concat-list)
(define qq-cons		cons)

;; make these also available in the slave module
(define *slave-env*   (host-value *slave-env*))
(define eval-in-slave (host-value eval-in-slave))

(safety 1
  (eval-in-host
   `(let ()
      (assert (is <env> ,*slave-env*))
      (assert (is <expr> ,eval-in-slave)))))

;; TODO what about this? if it's retained, then audit the code for
;; every usage of EVAL-IN-SLAVE...
(define-form begin-for-syntax forms
  `(eval-in-slave '(let () ,@forms)))

;;;
;;; create an empty env (stored in *target-env*) to hold the
;;; definitions that will be level-shifted to the target.
;;;

;; *target-env* will hold the definitions that need to be
;; level-shifted (compiled). *slave-env* will be the parent of
;; *target-env*, therefore all <form>'s that are defined in
;; *slave-env* are available "in" the *target-env*.
(assert (= *slave-env* *globals*))
(define *target-env* (environment *slave-env*))

(when-at-expand (feature debug-info)
  (eval-in-host `(set (<env>-name ,*target-env*) "target")))

(eval-in-host `(define *target-env* ,*target-env*))

(define-function switch-to-target-env ()
  (verbosity 2 (warn "---> target env\n"))
  (set *globals* *target-env*))

(eval-in-host `(define switch-to-target-env ,switch-to-target-env))

(switch-to-host-env)

;; the *globals* of the slave-module is the env that holds the target's definitions
(define-function eval-in-target (form)
  (eval form *target-env*))

(define-form target-value (form)
  `(eval-in-target ',form))
