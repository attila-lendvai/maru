;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Platform API when running under a Maru evaluator.
;;;
;;; This is nowhere near ready...
;;;
;;; TODO:
;;;  - find out how to deal with strings. the libc platform provides cstring (zero terminated ASCII bytes)
;;;  - how to hook into the allocate of the super's GC

(define-form platform/move-oops (from to wordcount)
  `(copy-oops ,from ,to ,wordcount))

(define-form platform/move-bytes (from to count)
  `(copy-bytes ,to ,from ,count))

;; for compare-bytes
;; (let ((i		0)
;;       (limit	(min len-a len-b)))
;;   (while (< i limit)
;;     (let ((diff (- (byte-at buf-a)
;;                    (byte-at buf-b))))
;;       (when (not (= 0 diff))
;;         (return diff)))
;;     (incr i)))

(define-form libc/string= (a b)
  `(= 0 (libc/strcmp ,a ,b)))

(define-form platform/flush-streams ()
  `(libc/flush-streams))

(define-form platform/print cstrs
  `(let ()
     ,@(map (lambda (cstr) `(libc/fputs ,cstr libc/stdout))
            cstrs)))

(define-form platform/print-diag cstrs
  `(let ()
     ,@(map (lambda (cstr) `(libc/fputs ,cstr libc/stderr))
            cstrs)))

;; TODO a possible #optimization: set things up so, that platform-libc.l can override long->string
;; with its own? or just rely on a future tree-shaker?
;; (define-primitive-function long->string ((arg <long>))
;;   (let ((buf (allocate-data 32))) ; safe up until 64 bits
;;     (libc/sprintf buf "%ld" arg)
;;     (C-string->string buf)))

(load "source/evaluator/platform.l")

(define-primitive-function abort _
  (libc/printf "ABORTED\n")
  (print-backtrace)
  (libc/flush-streams)
  ;;(libc/abort) don't use libc/abort because the stdout is not properly finished when it's redirected into a file
  (libc/exit -1))

(load "source/streams.l")

;; (define-record <libc-stream> <stream> (handle))

;; (define-function libc-stream (libc-handle)
;;   (safety 1 (assert (= <target-pointer> (type-of libc-handle))))
;;   (make <libc-stream>
;;     (handle		libc-handle)))

(load "source/evaluator/eval.l")

(define-function repl-stream (stream)
  ;;(set (global-variable-value *input* <target-pointer>) stream)
  (unless (= libc/stdin stream)
    (libc/fscanf stream "#!%*[^\x0a\x0d]")) ; drop the possible #!./eval first line of the file
  (gc/let* ((res ()))
    (while (let ()
             (when (= libc/stdin stream)
               (libc/printf ".")
               (libc/flush-streams))
             (!= +end+ (set res (read stream))))
      (gc/let* ((env (environment (module-env *module*) 1 0)))
        (set res (expand-encode-eval res env))
        (when (= libc/stdin stream)
          (gc/let* ((printer (list2 symbol/quote res)))
            (set printer (list2 (string->symbol "print") printer))
            (expand-encode-eval printer env))
          (libc/flush-streams))))
    (and (= libc/stdin stream)
         (libc/printf "\nmorituri te salutant\n"))
    res))
