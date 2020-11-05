;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Platform hooks when running under libc.

(define-libc-ffi)

(define-function libc/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

(define-form copy-oops (from to wordcount)
  `(libc/memcpy ,to ,from (words-to-bytes ,wordcount)))

(define-form move-oops (from to wordcount)
  `(libc/memmove ,to ,from (words-to-bytes ,wordcount)))

(define-form copy-bytes (from to count)
  `(libc/memcpy ,to ,from ,count))

(define-form move-bytes (from to count)
  `(libc/memmove ,to ,from ,count))

;; for sorting
(define-form cstring-compare (a b)
  `(libc/strcmp ,a ,b))

(define-form cstring= (a b)
  `(= 0 (libc/strcmp ,a ,b)))

(define-form cstring-length (cstr)
  `(libc/strlen ,cstr))

(load "source/evaluator/eval.l")

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
          (put/head tmp (new-<string>-from-cstring (oop-at argv idx)))
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
              ((cstring= arg "-v")
               (incr *verbosity*)
               (set tmp (box <long> *verbosity*))
               (set (global-variable-value (string->symbol "*verbosity*")) tmp))

              ;; -O
              ((cstring= arg "-O")
               (incr *optimised*)
               (set tmp (box <long> *optimised*))
               (set (global-variable-value (string->symbol "*optimised*")) tmp))

              ;; -p
              ((cstring= arg "-p")
               (if-at-expand feature/profiler
                   (let ((usecs 1000))
                     (install_profiler_handler profiler/take-sample)
                     (set_profiler_interval usecs)
                     (libc/fprintf libc/stderr "profiling at every %ld uSec(s)\n" usecs))
                 (libc/fprintf libc/stderr "WARNING: this build has no profiler, ignoring -p\n")))

              ;; -
              ((cstring= arg "-")
               (repl-stream libc/stdin))

              ;; --call to call a function
              ((cstring= arg "--call")
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
              ((cstring= arg "--define")
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
                   ;;           (cstring= cstr "-1"))
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
