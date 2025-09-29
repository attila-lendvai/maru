;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams-min.l")

;;;
;;; files
;;;

(define-primitive-function file-open ((path <string>) (mode <string>))
  (awhen (libc/fopen (string->C-string path) (string->C-string mode))
    (box <target-pointer> it)))

(define-primitive-function file-close ((handle <target-pointer> _ nounbox))
  ;; NOUNBOX because it is called from many places from inside the
  ;; target, i.e. they all would need to box it, because the auto
  ;; unboxing is only added to the /EVALUATOR-STUB.
  (when (= 0 (libc/fclose (unbox <target-pointer> handle)))
    symbol/true))

(define-primitive-function file-read-character ((stream <target-pointer>))
  (let ((c (libc/fgetc stream)))
    (if (= libc/EOF c)
        ()
      (box <long> c))))

(define-primitive-function file-write-character ((char <long>) (stream <target-pointer>))
  (when (not (= libc/EOF (libc/fputc char stream)))
    symbol/true))

;; (define-primitive-function file-flush ((stream <target-pointer>))
;;   (unless (= 0 (libc/fflush stream))
;;     (error "file-flush: libc/fflush returned an error")))

;;;
;;; <libc-stream>
;;;

(define-record <libc-stream> <stream> (handle))

(define-primitive-function file-stream ((handle <target-pointer> _ nounbox))
  (make/opaque <libc-stream>
    (handle	(unbox <target-pointer> handle))))

(define-method $at-end? <libc-stream> ()
  (libc/feof self.handle))

(define-method $peek <libc-stream> ()
  (let ((result (libc/fgetc self.handle)))
    (if (= result libc/EOF)
        (set result +end+) ; NOTE returning () here would mean returning 0 in compiled code, which is a valid character
      (libc/ungetc result self.handle))
    result))

(define-method $next <libc-stream> ()
  (let ((result (libc/fgetc self.handle)))
    (if (= result libc/EOF)
        +end+
      result)))

(define-method $put <libc-stream> (char)
  ;; can't add an (assert (is <long> char)) because this is lowered
  ;; into the target domain where the values are not boxed/tagged.
  (let ((result (libc/fputc char self.handle)))
    (when (= result libc/EOF)
      (error "<libc-stream> $put: fputc returned with error"))
    char))

;; TODO implemenet inheritance on compiled selectors
(define-method $put-all <libc-stream> (elements)
  (typecase elements
    (<string>		(when (= libc/EOF (libc/fwrite (string->C-string elements) (string-length elements) 1 self.handle))
                          (error "<libc-stream> $put-all: libc/fputs returned with error")))
    (else		(error "<libc-stream> $put-all: unexpected elements: " elements)))
  elements)

(require "source/streams-min-late.l")
