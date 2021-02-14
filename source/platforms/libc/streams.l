;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams-min.l")

;;;
;;; files
;;;

(define-primitive-function file-open ((path <string>) (mode <string>))
  (awhen (libc/fopen (string->C-string path) (string->C-string mode))
    (box <target-pointer> it)))

(define-primitive-function file-close ((stream <target-pointer> _ nounbox))
  ;; NOTE it is NOUNBOX because a lot of kernel code calls file-close
  (box <long> (libc/fclose (unbox <target-pointer> stream))))

(define-primitive-function file-read-character ((stream <target-pointer>))
  (let ((c (libc/fgetc stream)))
    (if (= libc/EOF c)
        ()
      (box <long> c))))

(define-primitive-function file-write-character ((char <long>) (stream <target-pointer>))
  (when (= libc/EOF (libc/fputc char stream))
    (error "file-write-character: libc/fputc returned an error")))

;;;
;;; <libc-stream>
;;;

(define-record <libc-stream> <stream> (handle))

(define-primitive-function file-stream ((handle <target-pointer> _ nounbox))
  (assert (is <target-pointer> handle))
  (make/opaque <libc-stream>
    (handle	(unbox <target-pointer> handle))))

(define-method $at-end? <libc-stream> ()
  ;; TODO make the FFI smarter to do this unboxing automatically. then we will be able to load this file as is into the interpreter
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

(define-method $put <libc-stream> (u/char)
  (let ((result (libc/fputc u/char self.handle)))
    (when (= result libc/EOF)
      (error "<libc-stream> $put: fputc returned with error"))
    u/char))

;; TODO implemenet inheritance on compiled selectors
(define-method $put-all <libc-stream> (elements)
  (typecase elements
    (<string>		(when (= libc/EOF (libc/fwrite (string->C-string elements) (string-length elements) 1 self.handle))
                          (error "<libc-stream> $put-all: libc/fputs returned with error")))
    (else		(error "<libc-stream> $put-all: unexpected elements: " elements)))
  elements)
