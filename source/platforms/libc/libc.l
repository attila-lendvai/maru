;;; -*- mode: lisp; coding: us-ascii -*-

(set (feature platform/libc) true)

(require "source/platforms/platform-c-based.l")

(require-cgrov "source/platforms/libc/libc")

;;;
;;; The libc FFI
;;;

(define-C-functions libc/
  (void abort ()) (void exit (int))
  (* malloc (size_t)) (void free (*)) (* realloc (* size_t)) (* memset (* int size_t)) (* memcpy (* * size_t)) (* memmove (* * size_t)) (int memcmp (* * size_t))
  (int printf (* ...)) (int fprintf (* * ...)) (int sprintf (* * ...)) (int snprintf (* size_t * ...))
  (int puts (*)) (int fputs (* *)) (int fputc (* *)) (int fgetc (*)) (int ungetc (int *)) (* fopen (* *))
  (int fclose (*)) (int fflush (*)) (int fscanf (* * ...)) (int feof (*)) (void setbuf (* *))
  (size_t fwrite (* size_t size_t *)) (size_t fread (* size_t size_t *))
  (size_t strlen (*)) (* strcpy (* *)) (* strncpy (* * size_t)) (int strcmp (* *)) (int strncmp (* * size_t)) (* strdup (*)) (unsigned-long strtoul (* * int)) (long strtol (* * int))
  )

;; the compat wrappers we export from the C side
(define-C-functions (libc/ maru_)
  (int chdir (*))
  ;; TODO extend the cgrov to deal with such wrappings automatically
  (* get_stdin ()) (* get_stdout ()) (* get_stderr ())
  (int get_errno ())
  )

;; the only correct way to grovel some global variables like stdin and
;; errno is to wrap them into a C function and call it from the lisp
;; side.
;;
;; reasons:
;;   - stdin and friends can be macros (darwin) and be written using freopen
;;   - errno is thread local (requires special flags handled by the c
;;     compiler)
(define-symbol-form libc/stdin  '(libc/get_stdin))
(define-symbol-form libc/stdout '(libc/get_stdout))
(define-symbol-form libc/stderr '(libc/get_stderr))
(define-symbol-form libc/errno  '(libc/get_errno))

;;;
;;; Platform API implementation when running on libc.
;;;

;; NOTE OPTIMIZATION redefine the generic implementation with the one from libc
;; another solution, but only works with the x86 backend: (set C-string-length libc/strlen)
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

(define-form platform/diag-print (str)
  `(libc/fputs (string->C-string ,str) libc/stderr))

(define-function platform/diag-print-char (char)
  ;; TODO endianness?
  ;; NOTE this is lowlevel diag, we can't really do much if printing fails
  (libc/fputc char libc/stderr)
  char)

;; TODO delme
(define-form platform/print-diag-fmt (format . args)
  `(let ()
     (libc/fprintf libc/stderr (string->C-string ,format) ,@args)
     (libc/fputc ?\n libc/stderr)))

(define-form platform/halt args
  ;;(libc/abort) don't use libc/abort because the stdout is not properly finished when it's redirected into a file
  `(libc/exit ,@(or args '(-42))))

(define-form platform/acquire-memory (size)
  `(libc/malloc ,size))
