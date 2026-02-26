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
     (debug (platform/format "initializing " (string ,(symbol->string our-name)) "\n"))
     (set tmp (box <lower-cell> ,target-name))
     (set tmp (file-stream tmp))
     (set ,our-name tmp)
     ;; the maru-user env was create earlier, let's set it there, too.
     ;; TODO clarify: why in maru-user?
     (set (global-variable-value *maru* ,(concat-symbol 'symbol/ our-name))
          tmp)))

(define-function initialize-streams (in-handle out-handle err-handle)
  ;; NOTE: a WITH-FORMS is tempting here, but the body of WITH-FORMS'
  ;; is not executed in the right env. years later: not sure what that
  ;; means, but a WITH-FORMS indeed seems to lead to a backtrace.
  ;; TODO rename to *input*?
  ;; TODO do we need a *debug-input*?
  (initialize-stream in-handle	*standard-input*)
  (initialize-stream out-handle	*standard-output*)
  (initialize-stream err-handle	*error-output*)
  (initialize-stream err-handle	*debug-output*))

(define-vm-function repl-stream ((input _ *standard-input*)
                                        (output _ *standard-output*)
                                        (interactive? _ true))
  (safety 1 (assert (gc/valid-maru-value? input) (gc/valid-maru-value? output)))
  ;; This won't work as-is now that we have a linux platform where
  ;; there's no fscanf and the streams are not of type <libc-stream>...
  ;; (unless interactive?
  ;;   (let ((libc-handle (unbox <lower-cell> (<libc-stream>-handle input))))
  ;;     (libc/fscanf libc-handle "#!%*[^\x0a\x0d]"))) ; drop the possible #!./eval first line of the file
  (gc/let* (res)
    (while (let ()
             (when interactive?
               ($put-all output "maru> ")
               (platform/flush-streams))
             (not (= +end+ (set res (read input)))))
      (unless (= +end+ res)
        (set res (expand-encode-eval res))
        (when interactive?
          (do-print output res false)
          ($put output ?\n)             ; newline
          (platform/flush-streams))))
    (when interactive?
      ($put-all output "\nmorituri te salutant\n"))
    res))

(when-at-expand (feature lower/array)
  (define-vm-function lower/array-save ((array <lower/array>) (path <string>))
    (let ((fd (unbox <lower-cell> (file-open-or-die path "w")))
          (elements (slot-value <lower/array> elements array)))
      (debug (platform/format "lower/array-save will write " (long (lower/array-length array)) " bytes into file " (long fd) "\n"))
      (for (i 0 (lower/array-length array))
        (debug (platform/format "writing byte " (long (byte-at elements i)) "\n"))
        ;; TODO file-write-byte?
        (file-write-character-or-die (byte-at elements i) fd))
      (debug (platform/format "lower/array-save is closing the file " (long fd) "\n"))
      (file-close-or-die fd))))

(define-form with-input-from-file (args . body)
  (let ((var		(first args))
        (file-name	(second args)))
    `(gc/let* ((__file-name	,file-name)
               (__file-handle	(file-open-or-die __file-name "r"))
               (,var		(file-stream __file-handle))
               (__result	,@body))
       (file-close (unbox <lower-cell> __file-handle))
       __result)))

(define-vm-function (load ()) ((path <string>))
  (with-input-from-file (stream path)
    (expand-encode-eval-stream stream)))

(define-function process-command-line-arguments (argc argv)
  (debug-print "start processing argv")

  ;; *command-line-arguments*
  ;; TODO maybe *cla* should go into maru-user instead of *maru*?
  (let ((cla-var (environment-define *maru* (string->symbol "*command-line-arguments*") ())))
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
               ;; KLUDGE propagate the value from the target up into
               ;; the evaluator by hand. ideally this should be done
               ;; automatically.
               (set tmp (box <long> *verbosity*))
               (set (global-variable-value *maru* symbol/*verbosity*) tmp))

              ((string= "-d" arg)
               (if-at-expand (feature debug-output)
                   (set *debug-output-enabled?* true)
                 (platform/diag-print "WARNING: (feature debug-output) was not enabled while compiling this build, ignoring -d\n")))

              ;; -O
              ((string= "-O" arg)
               (incr *optimised*)
               ;; KLUDGE propagate the value from the target up into
               ;; the evaluator by hand. ideally this should be done
               ;; automatically.
               (set tmp (box <long> *optimised*))
               (set (global-variable-value *maru* symbol/*optimised*) tmp))

              ;; -p
              ((string= "-p" arg)
               (if-at-expand (feature profiler)
                   (let ((usecs 1000))
                     (install_profiler_handler
                      (<target-function>-program-code profiler/take-sample))
                     (set_profiler_interval usecs)
                     (platform/format "enabled profiling at every "usecs" uSec(s)"))
                 (platform/diag-print "WARNING: this build has no profiler, ignoring -p\n")))

              ;; -
              ((string= "-" arg)
               (repl-stream *standard-input* *standard-output* true))

              ;; --call to call a function
              ((string= "--call" arg)
               (debug-print "processing a --call")
               (unless (pair? cla)
                 (fatal "--call requires an argument"))
               (set arg (get/head cla))
               (pop-cla)
               (let ((sym (string->symbol arg)))
                 (gc/let* ((form (cons sym ())))
                   (expand-encode-eval form))))

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
                 (cond
                   ((string= value "true")
                    (set value symbol/true))
                   ((string= value "false")
                    (set value ()))
                   (else
                    (let ((i (string->long* value 10)))
                      (unless (= +end+ i)
                        (set value (box <long> i))))))
                 (environment-define *globals*
                                     (string->symbol name)
                                     value)))

              ;; read file as a program
              (else
               (verbosity 1 (print-all *debug-output* "loading file: "arg"\t(as a CLA)\n"))
               (with-input-from-file (stream arg)
                 (repl-stream stream *standard-output* false))))))))))
