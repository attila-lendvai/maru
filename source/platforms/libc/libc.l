;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/platforms/platform-c-based.l")

;;;
;;; The libc FFI
;;;
(if-at-expand (= 'darwin +operating-system+)
    ;; %m_libc-FILE is an opaque type that we define in the prelude of
    ;; the llvm backend.
    (let ()
      (define-C-variable libc/stdin  __stdinp  (* "%m_libc-FILE"))
      (define-C-variable libc/stdout __stdoutp (* "%m_libc-FILE"))
      (define-C-variable libc/stderr __stderrp (* "%m_libc-FILE")))
  (define-C-variable libc/stdin  stdin  (* "%m_libc-FILE")) ; an opaque type that we define in the prelude of the llvm backend
  (define-C-variable libc/stdout stdout (* "%m_libc-FILE"))
  (define-C-variable libc/stderr stderr (* "%m_libc-FILE")))

;; this works on linux, but it's probably not too portable.
;;(define-C-variable libc/errno  errno  int "thread_local")

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
(define-constant libc/PROT_READ			1)
(define-constant libc/PROT_WRITE		2)
(define-constant libc/PROT_EXEC			4)
(define-constant libc/_SC_PAGESIZE		30)

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

;; (define-form platform/acquire-memory (size)
;;   `(libc/malloc ,size))

;; malloc doesn't return page-aligned memory, so we round down the
;; returned address, and round up the end address. this should work,
;; but using mmap would probably be the right way.
(define-form platform/acquire-memory (size)
  `(let* ((page-size	(libc/sysconf libc/_SC_PAGESIZE))
          (buf		(libc/malloc size))
          ;; the page-size-alined boundaries encompassing the returned block
          (addr-start	(align-address-down buf page-size))
          (addr-size	(- (align-address-up (+ buf size) page-size)
                           addr-start)))
     (when (= 0 buf)
       (platform/diag-print "malloc returned with NULL")
       (platform/halt))
     ;; KLUDGE we make all allocated memory executable.
     ;; `make test-elf` generates machine code and wants to call it...
     (unless (= 0 (libc/mprotect addr-start addr-size
                                 ,(+ (+ libc/PROT_READ libc/PROT_WRITE)
                                     libc/PROT_EXEC)))
       (platform/format "mprotect failed")
       ;;(platform/format "mprotect returned with "(long libc/errno))
       (platform/halt))
     buf))

;; TODO this is subtly broken: bootstrap goes quite far ahead, but
;; then it misbehaves (endless loop, or unable to apply undefined).
;; ideally the API should be extended to be able to allocate/extend a
;; continuous block of memory that the GC may take advantage of. for
;; that we would need to receive the current range.

;; (define-form platform/acquire-memory (size)
;;   ;; KLUDGE we make all allocated memory executable.
;;   ;; `make test-elf` generates machine code and wants to call it...
;;   `(let* ((page-size (libc/sysconf libc/_SC_PAGESIZE))
;;           (buf (libc/mmap 0 (align-address-up ,size page-size)
;;                           ,(+ (+ libc/PROT_READ libc/PROT_WRITE)
;;                               libc/PROT_EXEC)
;;                           ,(+ libc/MAP_PRIVATE libc/MAP_ANONYMOUS)
;;                           -1 0)))
;;      ;;(platform/format "mmap returned with "(pointer buf)"\n")
;;      (when (= buf libc/MAP_FAILED)
;;        (platform/diag-print "mmap returned with MAP_FAILED")
;;        (platform/halt))
;;      buf))
