;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; The libc FFI
;;;
(define-C-variable libc/stdin  stdin  (* "%struct._IO_FILE")) ; KLUDGE ideally we should grovel this type, but that would be more complex than this entire project
(define-C-variable libc/stdout stdout (* "%struct._IO_FILE"))
(define-C-variable libc/stderr stderr (* "%struct._IO_FILE"))

(define-C-functions libc/
  (void abort ()) (void exit (int))
  (* malloc (size_t)) (void free (*)) (* realloc (* size_t)) (* memset (* int size_t)) (* memcpy (* * size_t)) (* memmove (* * size_t)) (int memcmp (* * size_t))
  (int printf (* ...)) (int fprintf (* * ...)) (int sprintf (* * ...)) (int snprintf (* size_t * ...))
  (int puts (*)) (int fputs (* *)) (int fputc (* *)) (int fgetc (*)) (int ungetc (int *)) (* fopen (* *)) (* fdopen (int *))
  (int fclose (*)) (int fflush (*)) (int fscanf (* * ...)) (int feof (*)) (void setbuf (* *))
  (size_t strlen (*)) (* strcpy (* *)) (* strncpy (* * size_t)) (int strcmp (* *)) (int strncmp (* * size_t)) (* strdup (*)) (unsigned-long strtoul (* * int)) (long strtol (* * int))
  )

(define-constant libc/EOF -1)

;;;
;;; Platform API implementation when running under libc.
;;;
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

(define-form compare-bytes (a b count)
  `(libc/memcmp ,a ,b ,count))

(define-form libc/string= (a b)
  `(= 0 (libc/strcmp ,a ,b)))

;; TODO clean up this libc and cstring mess. if we use the same string representation in
;; our string payloads as libc, it doesn't mean that we should use libc stuff directly to
;; manipulate it.
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

(load "source/evaluator/vm-early.l")

(define-primitive-function abort _
  (libc/printf "ABORTED\n")
  (print-backtrace)
  (libc/flush-streams)
  ;;(libc/abort) don't use libc/abort because the stdout is not properly finished when it's redirected into a file
  (libc/exit -1))

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")

(define-function allocate (type slot-count)
  (gc/allocate type (words-to-bytes slot-count)))

(require "source/streams.l")

(load "source/evaluator/eval.l")

;; TODO possible #optimization: even in the current setup, libc.l can override number->string with its own.
;; (define-function long->string (num)
;;   ;; TODO introduce alloca?
;;   (let ((buf (allocate-data 32)))       ; safe up until 64 bits
;;     (libc/sprintf buf "%ld" num)
;;     (string-from-cstring buf)))

;; TODO possible #optimization
;; (define-function string->long (str)
;;   (let* ((cstr		(get/string str))
;;          (endptr	cstr)
;;          (result	(libc/strtol cstr (address-of endptr) 10)))
;;     (if (= (char-at endptr 0) ?\x00)
;;         (box <long> result)
;;       (error "invalid number in string->long, libc/strtol has failed for string " str))))

(define-primitive-function (libc/fopen ()) ((path <string>) (mode <string>))
  (let ((stream (libc/fopen path mode)))
    (and stream (box <target-vm-pointer> stream))))

(define-primitive-function (libc/fclose ()) ((stream <target-vm-pointer>))
  (libc/fclose stream))

(define-primitive-function (libc/fgetc ()) ((stream <target-vm-pointer>))
  (let ((c (libc/fgetc stream)))
    (and (>= c 0)
         (box <long> c))))

(define-primitive-function (libc/fputc ()) ((char <long>) (stream <target-vm-pointer>))
  (box <long> (libc/fputc char stream)))

(define-primitive-function (libc/format ()) ((fmt <string>) oarg)
  (let ((typ (type-of oarg))
        (arg ()))
    ;; TODO use typecase
    (cond
      ((= typ <undefined>))
      ((= typ <long>)		(set arg (unbox <long> oarg)))
      ((= typ <string>)		(set arg (get/string oarg)))
      ((= typ <symbol>)		(set arg (unbox <symbol> oarg)))
      (else			(set arg oarg)))
    (let ((size 100)
          (result ()))
      (gc/let* ((buf ()))
        (while (not result)
          (set buf (allocate-data size))
          (let ((n (libc/snprintf buf size fmt arg)))
            (if (and (<= 0 n)
                     (< n size))
                (set result (string-from-cstring buf))
              (set size (* size 2))))))
      result)))

(load "source/evaluator/platforms/libc/streams.l")

;; TODO eventually we could do something like this... but this would access the current module!
;; (define-symbol-form *standard-output* (global-variable-value (string->symbol "*standard-output*")))
(define *standard-input*)
(define *standard-output*)
(define *standard-error*)

(define-function initialize-streams ()
  (gc/let* (tmp)
    (with-forms ((doit ((libc-name our-name)
                        `(let ()
                           (set tmp (libc-stream (box <target-vm-pointer> ,libc-name)))
                           ;; TODO add support for compiling symbols
                           (set (global-variable-value (string->symbol ,(symbol->string our-name))) tmp)
                           (set ,our-name tmp)))))
      (doit libc/stdin	*standard-input*)
      (doit libc/stdout	*standard-output*)
      (doit libc/stderr	*standard-error*))))

(define-form with-input-from-file (var file-name . body)
  `(let* ((__file-name ,file-name)
          (__file-handle (libc/fopen __file-name "r")))
     (or __file-handle (error "no such file: " __file-name))
     (gc/let* ((,var (libc-stream (box <target-vm-pointer> __file-handle))))
       (let ((__result ,@body))
         (libc/fclose __file-handle)
         __result))))

;; TODO which one is the actual primitive that we want to publish? maybe just a read-form?
(define-primitive-function (read ()) _
  (if (= () -args-)
      (let ((obj (read *standard-input*)))
        (when (= +end+ obj)
          (set obj ()))
        obj)
    (with-input-from-file stream (get/string (car -args-))
      (gc/let* ((head (cons () ()))
                obj)
        (let ((tail head))              ; TODO use collecting macro
          (while (!= +end+ (set obj (read stream)))
            (set tail (put/tail tail (cons obj ()))))
          (get/tail head))))))

;; TODO put it where?
;; TODO rename to expand-encode-eval-stream?
(define-function eval-stream (stream)
  (gc/let* (form
            res
            env)
    (while (!= +end+ (set form (read stream)))
      (set env (environment (module-env *module*) 1 0))
      (set res (expand-encode-eval form env)))
    res))

(define-primitive-function (load ()) (path)
  (with-input-from-file stream (get/string path)
    (eval-stream stream)))

(load "source/evaluator/vm-late.l")

(define-function repl-stream (stream)
  ;;(set (global-variable-value *input* <target-vm-pointer>) stream)
  (let ((stdin?		(= *standard-input* stream))
        (libc-handle	(unbox <target-vm-pointer> (<libc-stream>-handle stream))))
    (unless stdin?
      (libc/fscanf libc-handle "#!%*[^\x0a\x0d]")) ; drop the possible #!./eval first line of the file
    (gc/let* ((res ()))
      (while (let ()
               (when stdin?
                 (libc/printf ".")
                 (libc/flush-streams))
               (and (not (= +end+ (set res (read stream))))
                    (not (libc/feof libc-handle))))
        (unless (= +end+ res)
          (gc/let* ((env (environment (module-env *module*) 1 0)))
            (set res (expand-encode-eval res env))
            (when stdin?
              (gc/let* ((printer (list2 symbol/quote res)))
                (set printer (list2 (string->symbol "print") printer))
                (expand-encode-eval printer env))
              (libc/flush-streams)))))
      (when stdin?
        (libc/printf "\nmorituri te salutant\n"))
      res)))

(define-function main (argc argv)
  (initialize-vm)
  (initialize-streams)

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
               (repl-stream *standard-input*))

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
               (let ((file-handle (libc/fopen arg "r")))
                 (or file-handle (fatal1 "no such file: %s" arg))
                 (gc/let* ((stream (libc-stream (box <target-vm-pointer> file-handle))))
                   (repl-stream stream)
                   (libc/fclose file-handle))))))))))

  (debug (libc/printf "main is on the way out\n"))

  (verbosity 1 (gc/collect) (libc/fprintf libc/stderr "%ld objects in %ld bytes, %ld bytes free\n" gc/objects-live gc/bytes-used gc/bytes-free))
  (when-at-expand feature/profiler
    (profiler/disable))
  (libc/flush-streams)

  (debug (libc/printf "main is returning normally\n"))
  (return 0))
