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
(define-function platform/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

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

(define-form platform/compare-bytes (a b count)
  `(libc/memcmp ,a ,b ,count))

(define-form libc/string= (a b)
  `(= 0 (libc/strcmp ,a ,b)))

;; TODO clean up this libc and cstring mess. if we use the same string representation in
;; our string payloads as libc, it doesn't mean that we should use libc stuff directly to
;; manipulate it.
(define-form platform/string-length (cstr)
  `(libc/strlen ,cstr))

(define-form platform/print cstrs
  `(let ()
     ,@(map (lambda (cstr) `(libc/fputs ,cstr libc/stdout))
            cstrs)))

(define-form platform/print-diag cstrs
  `(let ()
     ,@(map (lambda (cstr) `(libc/fputs ,cstr libc/stderr))
            cstrs)))

(define-form platform/print-diag-fmt (format . args)
  `(libc/fprintf libc/stderr ,format ,@args))

(define-form platform/halt args
  ;;(libc/abort) don't use libc/abort because the stdout is not properly finished when it's redirected into a file
  `(libc/exit ,@(or args '(-1))))

(define-form platform/acquire-memory (size)
  `(libc/malloc ,size))
