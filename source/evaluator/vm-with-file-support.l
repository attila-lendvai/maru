;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO FIXME file-stream returns an instance of a type that is not
;; available at runtime in the interpreter, yet, we bind its value to
;; *standard-output* & co... it's and extra complexity that this type
;; id will have quite a gap in the type id's (4-5). without fixing
;; this situation the streams will be an object of an unknown type in
;; the evaluator, or even worse: a different type gets loaded and
;; assigned the same type id. need to think more about the compilation
;; of types, because the current setup is clearly inadequate.

(define-form initialize-stream (target-name our-name)
  (assert (symbol? our-name)) ; symbol macros should be expanded after the call form macros
  `(gc/let* (tmp)
     (debug (platform/print-diag "initializing " ,(symbol->string our-name)))
     (set tmp (box <target-pointer> ,target-name))
     (set tmp (file-stream tmp))
     (set ,our-name tmp)
     ;; the maru-user module was create earlier, let's set it there, too.
     (set (global-variable-value *maru-user-module* ,(concat-symbol 'symbol/ our-name))
          tmp)))

(define-function initialize-streams (in-handle out-handle err-handle)
  ;; NOTE a WITH-FORMS is tempting here, but the body of WITH-FORMS'
  ;; are not executed in the syntax module.
  ;; TODO rename to *input*?
  (initialize-stream in-handle	*standard-input*)
  (initialize-stream out-handle	*standard-output*)
  (initialize-stream err-handle	*error-output*)
  (initialize-stream err-handle	*debug-output*))

(define-function repl-stream (stream)
  ;;(set (global-variable-value *input* <target-pointer>) stream)
  (safety 1 (assert (gc/valid-maru-value? stream)))
  (let ((stdin?	(= *standard-input* stream)))
    ;; (unless stdin?
    ;;   (let ((libc-handle (unbox <target-pointer> (<libc-stream>-handle stream))))
    ;;     (libc/fscanf libc-handle "#!%*[^\x0a\x0d]"))) ; drop the possible #!./eval first line of the file
    (gc/let* ((res ()))
      (while (let ()
               (when stdin?
                 ($put *standard-output* ?.)
                 (platform/flush-streams))
               (and (not (= +end+ (set res (read stream))))
                    (not ($at-end? stream))))
        (unless (= +end+ res)
          (gc/let* ((env (environment (module-env *module*) 1 0)))
            (set res (expand-encode-eval res env))
            (when stdin?
              (do-print *standard-output* res false)
              (platform/flush-streams)))))
      (when stdin?
        ($put-all *standard-output* "\nmorituri te salutant\n"))
      res)))

(define-form with-input-from-file (args . body)
  (let ((var		(first args))
        (file-name	(second args)))
    `(gc/let* ((__file-name	,file-name)
               (__file-handle	(or (file-open __file-name "r")
                                    (error "with-input-from-file: file-open failed for: " __file-name)))
               (,var		(file-stream __file-handle))
               (__result	,@body))
       (file-close __file-handle)
       __result)))

(define-primitive-function (load ()) ((path <string>))
  (with-input-from-file (stream path)
    (expand-encode-eval-stream stream)))

(define-function process-command-line-arguments (argc argv)
  (debug-print "start processing argv")

  ;; *command-line-arguments*
  (let ((cla-var (environment-define (module-env *module*) (string->symbol "*command-line-arguments*") ())))
    ;; initialize *cla*
    (gc/let* ((tmp ()))
      (let ((idx argc))
        (while (< 0 (decr idx)) ; skip the first, which is the name of the executable
          (set tmp (cons () tmp))
          (put/head tmp (C-string->string (oop-at argv idx)))
          (debug-print "processing argv "(box <long> idx)" = "(get/head tmp))))
      (set (<variable>-value cla-var) tmp))

    (debug-print "*command-line-arguments* is initialized to: " (<variable>-value cla-var))

    ;; process *cla*
    (let (cla)
      (gc/let* (arg
                tmp)
        (with-forms ((pop-cla (_ '(set (<variable>-value cla-var) (set cla (get/tail cla))))))
          (while (pair? (set cla (<variable>-value cla-var)))
            (set arg (get/head cla))
            (pop-cla)
            (cond
              ;; -v
              ((string= "-v" arg)
               (incr *verbosity*)
               ;; KLUDGE propagate the value by hand into the evaluator
               (set tmp (box <long> *verbosity*))
               (set (global-variable-value *maru-module* symbol/*verbosity*) tmp)
               (set (global-variable-value *maru-user-module* symbol/*verbosity*) tmp))

              ;; -O
              ((string= "-O" arg)
               (incr *optimised*)
               ;; KLUDGE propagate the value by hand into the evaluator
               (set tmp (box <long> *optimised*))
               (set (global-variable-value *maru-module* symbol/*optimised*) tmp)
               (set (global-variable-value *maru-user-module* symbol/*optimised*) tmp))

              ;; -p
              ((string= "-p" arg)
               (if-at-expand feature/profiler
                   (let ((usecs 1000))
                     (install_profiler_handler profiler/take-sample)
                     (set_profiler_interval usecs)
                     (platform/print-diag-fmt "profiling at every %ld uSec(s)" usecs))
                 (platform/print-diag "WARNING: this build has no profiler, ignoring -p")))

              ;; -
              ((string= "-" arg)
               (repl-stream *standard-input*))

              ;; --call to call a function
              ((string= "--call" arg)
               (debug-print "processing a --call")
               (unless (pair? cla)
                 (fatal "--call requires an argument"))
               (set arg (get/head cla))
               (pop-cla)
               (let ((sym (string->symbol arg)))
                 (gc/let* ((form (cons sym ())))
                   (expand-encode-eval form (module-env *module*)))))

              ;; --define to define a variable
              ((string= "--define" arg)
               (debug-print "processing a --define")
               (unless (and (pair? cla)
                            (pair? (get/tail cla)))
                 (fatal "--define requires two arguments"))
               (gc/let* ((name	(first  cla))
                         (value	(second cla)))
                 (pop-cla)
                 (pop-cla)
                 ;; convert to long when possible
                 (let ((i (string->long* value 10)))
                   (unless (= +end+ i)
                     (set value (box <long> i))))
                 (environment-define (module-env *module*)
                                     (string->symbol name)
                                     value)))

              ;; read file as a program
              (else
               (verbosity 1 (print-all *debug-output* "loading file: "arg"\t(as a CLA)\n"))
               (with-input-from-file (stream arg)
                 (repl-stream stream))))))))))
