;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams-min.l")

;;;
;;; files
;;;

(define-vm-function file-open ((path <string>) (mode <string>))
  (awhen (libc/fopen (string->C-string path) (string->C-string mode))
    (box <lower-cell> it)))

(define-vm-function file-close ((handle <lower-cell>))
  (to-upper-boolean
   (= 0 (libc/fclose handle))))

(define-vm-function file-read-byte ((stream <lower-cell>))
  (let ((c (libc/fgetc stream)))
    (if (= libc/EOF c)
        ;; TODO use false here. it should be 0, which should be the
        ;; <undefined> value in the upper. same for linux.
        ()
      (box <long> c))))

(define-vm-function file-write-byte ((char <long>) (stream <lower-cell>))
  (to-upper-boolean
   (not (= libc/EOF (libc/fputc char stream)))))

;; (define-vm-function file-flush ((stream <lower-cell>))
;;   (unless (= 0 (libc/fflush stream))
;;     (error "file-flush: libc/fflush returned an error")))

;;;
;;; <libc-stream>
;;;

(define-record <libc-stream> <stream> (handle))

(define-vm-function file-stream ((handle <lower-cell>))
  (make/opaque <libc-stream>
    (handle	handle)))

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
  (let ((result (libc/fputc char self.handle)))
    (when (= result libc/EOF)
      (error "<libc-stream> $put: fputc returned with error"))
    char))

(define-function %put-all (handle buf size)
  (unless (= 0 size)
    (let ((rc (libc/fwrite buf size 1 handle)))
      (unless (= 1 rc)
        (debug (platform/format "<libc-stream> $put-all: libc/fwrite returned with "(long rc)", ferror "(long (libc/ferror handle))"\n"))
        (error "<libc-stream> $put-all: libc/fwrite returned with "(box <long> rc)", ferror " (box <long> (libc/ferror handle)))))))

;; TODO implemenet inheritance on compiled selectors
(define-method $put-all <libc-stream> (obj)
  (typecase obj
    (<string>
     (%put-all self.handle (string->C-string obj) (string-length obj)))
    (when-at-expand (feature lower/array)
      (<lower/array>
       (%put-all self.handle (slot-value <lower/array> elements obj) (lower/array-length obj))))
    (else
     (error "<libc-stream> $put-all: unexpected value to write: " obj)))
  obj)

(require "source/streams-min-late.l")
