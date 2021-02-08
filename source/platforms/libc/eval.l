;;; -*- mode: lisp; coding: us-ascii -*-

(define *standard-input*)
(define *standard-output*)
(define *error-output*)
(define *debug-output*)

(require "source/platforms/libc/libc.l")

(load "source/evaluator/vm-early.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")

(define-function allocate (type slot-count)
  (gc/allocate type (words-to-bytes slot-count)))

(load "source/evaluator/eval.l")

;; TODO possible #optimization: even in the current setup, libc.l can override number->string with its own.
;; (define-function long->string (num radix)
;;   ;; TODO introduce alloca?
;;   ;; TODO handle radix
;;   (let ((buf (allocate-data 32)))       ; safe up until 64 bits
;;     (libc/sprintf buf "%ld" num)
;;     (string-from-C-string buf)))

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
;;                 (set result (string-from-C-string buf))
;;               (set size (* size 2))))))
;;       result)))

(load "source/platforms/libc/streams.l")

;; TODO eventually we could do something like this... note that this would access the current module!
;; NOTE binding this into the interpreter's env is only useful/meaningful if its LIBC-STREAM type is also
;; properly initialized in the interpreter's env. otherwise it would be there an object of an unknown type.
;; TODO add compilation of symbols and drop the string->symbol call
;; (define-symbol-form *standard-input*  (global-variable-value (string->symbol "*standard-input*")))
;; (define-symbol-form *standard-output* (global-variable-value (string->symbol "*standard-output*")))
;; (define-symbol-form *error-output*  (global-variable-value (string->symbol "*standard-error*")))

(define-function initialize-streams ()
  (gc/let* (tmp)
    (with-forms ((doit ((libc-name our-name)
                        `(let ()
                           (set tmp (file-stream (box <target-vm-pointer> ,libc-name)))
                           (set ,our-name tmp)
                           ;; TODO add support for compiling symbols
                           (set (global-variable-value (u/string->symbol ,(symbol->string our-name))) tmp)))))
      (doit libc/stdin	*standard-input*)
      (doit libc/stdout	*standard-output*)
      (doit libc/stderr	*error-output*)
      (set *debug-output* *error-output*))))

(load "source/evaluator/vm-with-file-support.l")
(load "source/evaluator/vm-late.l")

(define-function main (argc argv)
  (initialize-vm)
  (initialize-streams)

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
