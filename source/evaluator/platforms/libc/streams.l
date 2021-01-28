;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams-min.l")

;;;
;;; files
;;;

(define-primitive-function file-open ((path <string>) (mode <string>))
  (awhen (libc/fopen path mode)
    (box <target-vm-pointer> it)))

(define-primitive-function file-close ((stream <target-vm-pointer>))
  (box <long> (libc/fclose stream)))

(define-primitive-function file-read-character ((stream <target-vm-pointer>))
  (let ((c (libc/fgetc stream)))
    (if (= libc/EOF c)
        ()
      (box <long> c))))

(define-primitive-function file-write-character ((char <long>) (stream <target-vm-pointer>))
  (when (= libc/EOF (libc/fputc char stream))
    (error "file-write-char: libc/fputc returned an error")))

;;;
;;; <libc-stream>
;;;

(define-record <libc-stream> <stream> (handle))

(define-function libc-stream (handle)
  (assert (is <target-vm-pointer> handle))
  (make <libc-stream>
    (handle handle)))

;; (define-function libc-stream-for-file (name mode)
;;   (let ((handle (libc/fopen name mode)))
;;     (unless handle
;;       (error "libc-stream-for-file: failed to open file "
;;              (string-from-cstring name)" in mode "
;;              (string-from-cstring mode)))
;;     (libc-stream (box <target-vm-pointer> handle))))

(define-method $at-end? <libc-stream> ()
  ;; TODO make the FFI smarter to do this unboxing automatically. then we will be able to load this file as is into the interpreter
  (libc/feof (unbox <target-vm-pointer> self.handle)))

(define-method $peek <libc-stream> ()
  (let* ((handle (unbox <target-vm-pointer> self.handle))
         (result (libc/fgetc handle)))
    (if (= result libc/EOF)
        (set result +end+) ; NOTE returning () here would mean returning 0 in compiled code, which is a valid character
      (libc/ungetc result handle))
    result))

(define-method $next <libc-stream> ()
  (let* ((handle (unbox <target-vm-pointer> self.handle))
         (result (libc/fgetc handle)))
    (if (= result libc/EOF)
        +end+
      result)))
