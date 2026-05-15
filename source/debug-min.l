;;; -*- mode: lisp; coding: us-ascii -*-

(define-form debug		prog ())
(define-form debug/identities	prog ())
(define-form gc/debug		prog ())

(when-at-expand (feature debug-output)
  (define *debug-output-enabled?* false)

  (define-form debug		prog	`(when *debug-output-enabled?* ,@prog))
  ;;(define-form debug/identities	prog	`(when *debug-output-enabled?* ,@prog))
  ;;(define-form gc/debug		prog	`(when *debug-output-enabled?* ,@prog))
  )

(define-form debug-print objs
  `(debug
    ;; only works after streams and printing are initialized. prior to
    ;; that we must use the platform primitives directly.
    ;; TODO add some trick to switch to the smart printer when it becomes available in the init process
    (when *debug-output*
      (print-all *debug-output* ,@objs)
      ;; TODO? use $put
      (do-print *debug-output* "\n" false))))

;;
;; FATAL is a low-level facility that directly uses the target
;; platform's (libc, linux) primitives. it works very early in the
;; init, but it has its limitations:
;;  - it cannot print maru heap objects (will print them as )
;;  - its arugments must either be a literal <string>
;;    - or it must evaluate to a target <long> (i.e. untagged) (?)
;;

;; NOTE: FATAL needs to be a form so that the platform primitive
;; expands to a C-string compiler special form; i.e. it works without
;; any advanced facility, e.g. while we are early in the init.

(define-function fatal-prologue ()
  (platform/flush-streams)
  (platform/diag-print "\nFATAL: "))

;; TODO consider somehow replacing the lame early FATAL with a proper
;; ERROR later in the init
(define-form fatal forms
  ;; format (fatal form1 (string form2) (pointer form3) (long form4) ...)
  ;; but it defaults to long, and recognizes string literals.
  `(let ()
     (fatal-prologue)
     (platform/diag-print ,@forms "\n")
     (platform/halt)))
