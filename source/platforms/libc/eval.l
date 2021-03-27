;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/platforms/libc/libc.l")

(load "source/evaluator/vm-early.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")
(load "source/evaluator/eval.l")

;; TODO possible #optimization: even in the current setup, libc.l can override number->string with its own.
;; (define-function long->string (num radix)
;;   ;; TODO introduce alloca?
;;   ;; TODO handle radix
;;   (let ((buf (allocate-data 32)))       ; safe up until 64 bits
;;     (libc/sprintf buf "%ld" num)
;;     (C-string->string buf)))

;; TODO possible #optimization
;; (define-function string->long (str radix)
;;   ;; TODO handle radix
;;   (let* ((cstr		(string->C-string str))
;;          (endptr	cstr)
;;          (result	(libc/strtol cstr (address-of endptr) 10)))
;;     (if (= (char-at endptr 0) ?\x00)
;;         (box <long> result)
;;       (error "invalid number in string->long, libc/strtol has failed for string " str))))

;; (define-primitive-function (libc/format ()) ((fmt <string>) oarg)
;;   (let ((typ (type-of oarg))
;;         (arg ()))
;;     ;; TODO use typecase
;;     (cond
;;       ((= typ <undefined>))
;;       ((= typ <long>)		(set arg (unbox <long> oarg)))
;;       ((= typ <string>)		(set arg (string->C-string oarg)))
;;       ((= typ <symbol>)		(set arg (unbox <symbol> oarg)))
;;       (else			(set arg oarg)))
;;     (let ((size 100)
;;           (result ()))
;;       (gc/let* ((buf ()))
;;         (while (not result)
;;           (set buf (allocate-data size))
;;           (let ((n (libc/snprintf buf size fmt arg)))
;;             (if (and (<= 0 n)
;;                      (< n size))
;;                 (set result (C-string->string buf))
;;               (set size (* size 2))))))
;;       result)))

(define-primitive-function set-working-directory ((path <string>))
  (verbosity 1 (print-all *debug-output* "changing working directory to: "path"\n"))
  (unless (= 0 (libc/chdir (string->C-string path)))
    (error "set-working-directory: libc/chdir failed for "path)))

(load "source/platforms/libc/streams.l")
(load "source/evaluator/vm-with-file-support.l")
(load "source/evaluator/vm-late.l")

(define-function main (argc argv)
  (initialize-vm)
  (initialize-streams libc/stdin libc/stdout libc/stderr)

  (process-command-line-arguments argc argv)

  (debug-print "main is on the way out")

  (verbosity 1
    (gc/collect)
    (libc/fprintf libc/stderr "%ld objects in %ld bytes, %ld bytes free\n" gc/objects-live gc/bytes-used gc/bytes-free))
  (when-at-expand feature/profiler
    (profiler/disable))
  (platform/flush-streams)

  (debug-print "main is returning normally")
  0)
