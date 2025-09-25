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
  (int mprotect (* size_t int))
  (* mmap (* size_t int int int off_t))
  (long sysconf (int))
  )

(define-constant libc/EOF			-1)
(define-constant libc/MAP_FAILED		-1)
(define-constant libc/MAP_PRIVATE		2)
(define-constant libc/MAP_ANONYMOUS		0x20)

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

;; (define-form platform/acquire-memory (size)
;;   ;; KLUDGE we should call: size_t pagesize = sysconf(_SC_PAGESIZE)
;;   `(let* ((size/rounded (/ (+ ,size (- 0x1000 1)) ; round to page size
;;                            0x1000))
;;           (buf (libc/malloc size/rounded)))
;;      (when (= 0 buf)
;;        (platform/diag-print "malloc returned with NULL")
;;        (platform/halt))
;;      ;; KLUDGE we make all allocated memory executable.
;;      ;; `make test-elf` generates machine code and wants to call it...
;;      (unless (= 0 (libc/mprotect buf size/rounded
;;                                  ,(+ (+ linux/PROT_READ linux/PROT_WRITE)
;;                                      linux/PROT_EXEC)))
;;        (platform/diag-print "mprotect returned with non-zero")
;;        (platform/halt))
;;      buf))

;; (define-form platform/acquire-memory (size)
;;   ;; KLUDGE we should call: size_t pagesize = sysconf(_SC_PAGESIZE)
;;   ;; KLUDGE we make all allocated memory executable.
;;   ;; `make test-elf` generates machine code and wants to call it...
;;   `(let ((buf (libc/mmap 0 (/ (+ ,size (- 0x1000 1)) ; round to page size
;;                               0x1000)
;;                          ,(+ (+ linux/PROT_READ linux/PROT_WRITE)
;;                              linux/PROT_EXEC)
;;                          ,(+ libc/MAP_PRIVATE libc/MAP_ANONYMOUS)
;;                          -1 0)))
;;      (when (= buf libc/MAP_FAILED)
;;        (platform/diag-print "mmap returned with MAP_FAILED")
;;        (platform/halt))
;;      buf))
