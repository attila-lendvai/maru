;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/platforms/platform-c-based.l")

;;;
;;; The libc FFI
;;;
(define-C-variable libc/stdin  stdin  (* "%m_libc-FILE")) ; an opaque type that we define in the prelude of the llvm backend
(define-C-variable libc/stdout stdout (* "%m_libc-FILE"))
(define-C-variable libc/stderr stderr (* "%m_libc-FILE"))

(define-C-functions libc/
  (void abort ()) (void exit (int))
  (* malloc (size_t)) (void free (*)) (* realloc (* size_t)) (* memset (* int size_t)) (* memcpy (* * size_t)) (* memmove (* * size_t)) (int memcmp (* * size_t))
  (int printf (* ...)) (int fprintf (* * ...)) (int sprintf (* * ...)) (int snprintf (* size_t * ...))
  (int puts (*)) (int fputs (* *)) (int fputc (* *)) (int fgetc (*)) (int ungetc (int *)) (* fopen (* *)) (* fdopen (int *))
  (int fclose (*)) (int fflush (*)) (int fscanf (* * ...)) (int feof (*)) (void setbuf (* *))
  (size_t fwrite (* size_t size_t *)) (size_t fread (* size_t size_t *))
  (int chdir (*)) ;(* getcwd (* size_t))
  (size_t strlen (*)) (* strcpy (* *)) (* strncpy (* * size_t)) (int strcmp (* *)) (int strncmp (* * size_t)) (* strdup (*)) (unsigned-long strtoul (* * int)) (long strtol (* * int))
  )

(define-constant libc/EOF -1)

;;;
;;; Platform API implementation when running under libc.
;;;

;; NOTE OPTIMIZATION redefine the generic implementation with the one from libc
;; this only works with the x86 backend: (set C-string-length libc/strlen)
(define-form C-string-length (cstr)
  `(libc/strlen ,cstr))

(define-function platform/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

;; NOTE copy means it may not overlap. move means they may overlap.

;; TODO these two are exported into the evaluator to provide the same api in interpreted code. how shall this be?
(define-form copy-oops (from to wordcount)
  `(libc/memcpy ,to ,from (words-to-bytes ,wordcount)))

(define-form copy-bytes (from to count)
  `(libc/memcpy ,to ,from ,count))

(define-form platform/move-oops (from to wordcount)
  `(libc/memmove ,to ,from (words-to-bytes ,wordcount)))

(define-form platform/move-bytes (from to count)
  `(libc/memmove ,to ,from ,count))

(define-form platform/clear-bytes (from count)
  `(libc/memset ,from 0 ,count))

(define-form platform/print strs
  `(let ()
     ,@(map (lambda (str) `(libc/fputs (string->C-string ,str) libc/stdout))
            strs)
     (libc/fputc ?\n libc/stderr)))

(define-form platform/print-diag strs
  `(let ()
     ,@(map (lambda (str) `(libc/fputs (string->C-string ,str) libc/stderr))
            strs)
     (libc/fputc ?\n libc/stderr)))

(define-form platform/print-diag-fmt (format . args)
  `(let ()
     (libc/fprintf libc/stderr (string->C-string ,format) ,@args)
     (libc/fputc ?\n libc/stderr)))

(define-form platform/halt args
  ;;(libc/abort) don't use libc/abort because the stdout is not properly finished when it's redirected into a file
  `(libc/exit ,@(or args '(-1))))

(define-form platform/acquire-memory (size)
  `(libc/malloc ,size))
