;;; -*- mode: lisp; coding: us-ascii -*-

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
;;     (string-from-cstring buf)))

;; TODO possible #optimization
;; (define-function string->long (str radix)
;;   ;; TODO handle radix
;;   (let* ((cstr		(get/string str))
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
;;       ((= typ <string>)		(set arg (get/string oarg)))
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
;;                 (set result (string-from-cstring buf))
;;               (set size (* size 2))))))
;;       result)))

(load "source/platforms/libc/streams.l")

;; TODO eventually we could do something like this... note that this would access the current module!
;; NOTE binding this into the interpreter's env is only useful/meaningful if its LIBC-STREAM type is also
;; properly initialized in the interpreter's env. otherwise it would be there an object of an unknown type.
;; TODO add compilation of symbols and drop the string->symbol call
;; (define-symbol-form *standard-input*  (global-variable-value (string->symbol "*standard-input*")))
;; (define-symbol-form *standard-output* (global-variable-value (string->symbol "*standard-output*")))
;; (define-symbol-form *standard-error*  (global-variable-value (string->symbol "*standard-error*")))

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

(define-form with-input-from-file (args . body)
  (let ((var		(first args))
        (file-name	(second args)))
    `(let* ((__file-name	,file-name)
            (__file-handle	(file-open (get/string __file-name) "r")))
       (or __file-handle (error "with-input-from-file: file-open failed for: " __file-name))
       (gc/let* ((,var (libc-stream __file-handle)))
         (let ((__result ,@body))
           (file-close (unbox <target-vm-pointer> __file-handle))
           __result)))))

(define-primitive-function (load ()) (path)
  (with-input-from-file (stream path)
    (expand-encode-eval-stream stream)))

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
                 (platform/flush-streams))
               (and (not (= +end+ (set res (read stream))))
                    (not (libc/feof libc-handle))))
        (unless (= +end+ res)
          (gc/let* ((env (environment (module-env *module*) 1 0)))
            (set res (expand-encode-eval res env))
            (when stdin?
              (gc/let* ((printer (list2 symbol/quote res)))
                (set printer (list2 (string->symbol "print") printer))
                (expand-encode-eval printer env))
              (platform/flush-streams)))))
      (when stdin?
        (libc/printf "\nmorituri te salutant\n"))
      res)))

(load "source/evaluator/vm-late.l")

(define-function main (argc argv)
  (initialize-vm)
  (initialize-streams)

  (process-command-line-arguments argc argv)

  (debug (libc/printf "main is on the way out\n"))

  (verbosity 1 (gc/collect) (libc/fprintf libc/stderr "%ld objects in %ld bytes, %ld bytes free\n" gc/objects-live gc/bytes-used gc/bytes-free))
  (when-at-expand feature/profiler
    (profiler/disable))
  (platform/flush-streams)

  (debug (libc/printf "main is returning normally\n"))
  (return 0))
