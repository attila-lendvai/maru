;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams.l")

(define-record <libc-stream> <stream> (handle))

(define-function libc-stream (handle)
  (assert (is <target-vm-pointer> handle))
  (assert (unbox <target-vm-pointer> handle))
  (make <libc-stream>
    (handle handle)))

(define-function libc-stream-for-file (name mode)
  (let ((handle (libc/fopen name mode)))
    (unless handle
      (error "libc-stream-for-file: failed to open file "
             (string-from-cstring name)" in mode "
             (string-from-cstring mode)))
    (libc-stream (box <target-vm-pointer> handle))))

(define-method at-end? <libc-stream> ()
  ;; TODO make the FFI smarter to do this unboxing automatically. then we will be able to load this file as is into the interpreter
  (libc/feof (unbox <target-vm-pointer> self.handle)))

(define-method peek <libc-stream> ()
  (let* ((handle (unbox <target-vm-pointer> self.handle))
         (result (libc/fgetc handle)))
    (if (= result libc/EOF)
        (set result ())
      (libc/ungetc result handle))
    result))

(define-method next <libc-stream> ()
  (let* ((handle (unbox <target-vm-pointer> self.handle))
         (result (libc/fgetc handle)))
    (if (= result libc/EOF)
        ()
      result)))
