;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Platform API when running under a Maru evaluator.
;;;
;;; This is nowhere near ready...
;;;
;;; TODO:
;;;  - find out how to deal with strings. the libc platform provides cstring (zero terminated ASCII bytes)
;;;  - how to hook into the allocate of the super's GC

(define-form move-oops (from to wordcount)
  `(copy-oops ,from ,to ,wordcount))

(define-form move-bytes (from to count)
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

(define-form platform/string-length (cstr)
  `(libc/strlen ,cstr))

(define-form platform/flush-streams ()
  `(libc/flush-streams))

(define-form platform/print cstrs
  `(let ()
     ,@(map (lambda (cstr) `(libc/fputs ,cstr libc/stdout))
            cstrs)))

(define-form platform/print-diagnostics cstrs
  `(let ()
     ,@(map (lambda (cstr) `(libc/fputs ,cstr libc/stderr))
            cstrs)))

;; TODO a possible #optimization: set things up so, that platform-libc.l can override long->string
;; with its own? or just rely on a future tree-shaker?
;; (define-primitive-function long->string ((arg <long>))
;;   (let ((buf (allocate-data 32))) ; safe up until 64 bits
;;     (libc/sprintf buf "%ld" arg)
;;     (string-from-cstring buf)))

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
;;   (safety 1 (assert (= <target-vm-pointer> (type-of libc-handle))))
;;   (make <libc-stream>
;;     (handle		libc-handle)))

(load "source/evaluator/eval.l")

(define-function repl-stream (stream)
  ;;(set (global-variable-value *input* <target-vm-pointer>) stream)
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

(define-function main (argc argv)
  (initialize-vm)

  (debug (libc/printf "start processing argv\n"))

  ;; *command-line-arguments*
  (let ((cla-var (environment-define (module-env *module*) (string->symbol "*command-line-arguments*") ())))
    ;; initialize *cla*
    (gc/let* ((tmp ()))
      (let ((idx argc))
        (while (< 0 (decr idx)) ; skip the first, which is the name of the executable
          (set tmp (cons () tmp))
          (put/head tmp (string-from-cstring (oop-at argv idx)))
          (debug (libc/printf "processing argv %ld = %s; parsed into " idx (oop-at argv idx)) (println (get/head tmp)))))
      (set (<variable>-value cla-var) tmp))

    (debug (libc/printf "*command-line-arguments* is initialized: ") (println (<variable>-value cla-var)))

    ;; process *cla*
    (let (cla
          arg)
      (gc/let* (arg-string
                tmp)
        (with-forms ((pop-cla (_ '(set (<variable>-value cla-var) (set cla (get/tail cla))))))
          (while (pair? (set cla (<variable>-value cla-var)))
            (set arg-string	(get/head cla))
            (set arg		(get/string arg-string))
            (pop-cla)
            (cond
              ;; -v
              ((libc/string= arg "-v")
               (incr *verbosity*)
               (set tmp (box <long> *verbosity*))
               (set (global-variable-value (string->symbol "*verbosity*")) tmp))

              ;; -O
              ((libc/string= arg "-O")
               (incr *optimised*)
               (set tmp (box <long> *optimised*))
               (set (global-variable-value (string->symbol "*optimised*")) tmp))

              ;; -p
              ((libc/string= arg "-p")
               (if-at-expand feature/profiler
                   (let ((usecs 1000))
                     (install_profiler_handler profiler/take-sample)
                     (set_profiler_interval usecs)
                     (libc/fprintf libc/stderr "profiling at every %ld uSec(s)\n" usecs))
                 (libc/fprintf libc/stderr "WARNING: this build has no profiler, ignoring -p\n")))

              ;; -
              ((libc/string= arg "-")
               (repl-stream libc/stdin))

              ;; --call to call a function
              ((libc/string= arg "--call")
               (debug (libc/printf "processing a --call\n"))
               (unless (pair? cla)
                 (fatal "--call requires an argument"))
               (set arg-string (get/head cla))
               (set arg (get/string arg-string))
               (pop-cla)
               (let ((sym (string->symbol arg)))
                 (gc/let* ((form (cons sym ())))
                   (expand-encode-eval form (module-env *module*)))))

              ;; --define to define a variable
              ((libc/string= arg "--define")
               (debug (libc/printf "processing a --define\n"))
               (unless (and (pair? cla)
                            (pair? (get/tail cla)))
                 (fatal "--define requires two arguments"))
               (gc/let* ((name	(first  cla))
                         (value	(second cla)))
                 (pop-cla)
                 (pop-cla)
                 ;; convert to long when possible
                 (let* ((cstr	(get/string value))
                        (endptr	cstr)
                        (i	(libc/strtoul cstr (address-of endptr) 0)))
                   ;; TODO investigate: why the hell does this behave differently than the one at the other call site of strtoul?
                   ;; (when (or (not (= -1 i))
                   ;;           (libc/string= cstr "-1"))
                   ;;   (set value (box <long> i)))
                   (when (= 0 (char-at endptr 0))
                     (set value (box <long> i))))
                 (environment-define (module-env *module*)
                                     (string->symbol (get/string name))
                                     value)))

              ;; read file as a program
              (else
               (verbosity 1 (libc/fprintf libc/stderr "loading file: %s\t(as a CLA)\n" arg))
               (let ((stream (libc/fopen arg "r")))
                 (or stream (fatal1 "no such file: %s" arg))
                 (repl-stream stream)
                 (libc/fclose stream)))))))))

  (debug (libc/printf "main is on the way out\n"))

  (verbosity 1 (gc/collect) (libc/fprintf libc/stderr "%ld objects in %ld bytes, %ld bytes free\n" gc/objects-live gc/bytes-used gc/bytes-free))
  (when-at-expand feature/profiler
    (profiler/disable))
  (libc/flush-streams)

  (debug (libc/printf "main is returning normally\n"))
  (return 0))
