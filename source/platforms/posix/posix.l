;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; The posix platform is some extras on top of libc, so we load it,
;;; and then define and redefine some more.
;;;

(require "source/platforms/libc/libc.l")

(require-cgrov "source/platforms/posix/posix")

(define-C-functions posix/
  ;;(* getcwd (* size_t))
  ;; (int chdir (*)) we handle chdir in a libc wrapper; too precious to skip there
  (* fdopen (int *))
  (int mprotect (* size_t int))
  (* mmap (* size_t int int int off_t))
  (long sysconf (int))
  (pid_t fork ())
  (pid_t execve (* * *))
  (pid_t waitpid (pid_t * int))
  )

;; malloc doesn't return page-aligned memory, so we round down the
;; returned address, and round up the end address. this should work,
;; but using mmap would probably be the right way.
;; TODO move this to posix
(define-form platform/acquire-memory (size)
  `(let* ((page-size	(posix/sysconf posix/_SC_PAGESIZE))
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
     (unless (= 0 (posix/mprotect addr-start addr-size
                                  ,(+ (+ posix/PROT_READ posix/PROT_WRITE)
                                      posix/PROT_EXEC)))
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
;;   `(let* ((page-size (posix/sysconf posix/_SC_PAGESIZE))
;;           (buf (posix/mmap 0 (align-address-up ,size page-size)
;;                           ,(+ (+ posix/PROT_READ posix/PROT_WRITE)
;;                               posix/PROT_EXEC)
;;                           ,(+ posix/MAP_PRIVATE posix/MAP_ANONYMOUS)
;;                           -1 0)))
;;      ;;(platform/format "mmap returned with "(pointer buf)"\n")
;;      (when (= buf posix/MAP_FAILED)
;;        (platform/diag-print "mmap returned with MAP_FAILED")
;;        (platform/halt))
;;      buf))
