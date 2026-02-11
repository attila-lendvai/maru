;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/platforms/platform-c-based.l")
(require-cgrov "source/platforms/linux/linux")

;; define some llvm intrinsics as FFI calls
;; https://llvm.org/docs/LangRef.html#llvm-memcpy-intrinsic
;; (define-C-functions ()
;;   (void llvm.memcpy.p0i8.p0i8.i32 (* * int int))
;;   )
;; TODO turned off because this requires linking to something that defines memcpy. apparently llvm doesn't emit its own code for these.
;; (if (= (host-value *compiler-backend*) "llvm")
;;     (define-form copy-oops (from to wordcount)
;;       ;; TODO add align: https://llvm.org/docs/LangRef.html#attr-align
;;       `(llvm.memcpy.p0i8.p0i8.i32 ,to ,from (words-to-bytes ,wordcount) 1)))

;;;
;;; Platform API implementation when running on top of the Linux kernel.
;;;
(define-function platform/flush-streams ()
  (linux-syscall linux/SYS_fsync linux/STDOUT_FILENO)
  (linux-syscall linux/SYS_fsync linux/STDERR_FILENO))

;; NOTE copy means it may not overlap. move means they may overlap.

;; TODO these two are exported into the evaluator to provide the same api in interpreted code. how shall this be?
(define-function copy-oops (from to wordcount)
  (for (i 0 wordcount)
    (set (oop-at to   i)
         (oop-at from i))))

(define-function copy-bytes (from to count)
  (for (i 0 count)
    (set (byte-at to   i)
         (byte-at from i))))

(define-function platform/move-oops (from to wordcount)
  (cond
    ((< to from)
     (for (i 0 wordcount)
       (set (oop-at to   i)
            (oop-at from i))))
    ((< from to)
     (for (i (- wordcount 1) -1 -1)
       (set (oop-at to   i)
            (oop-at from i))))))

(define-function platform/move-bytes (from to count)
  (cond
    ((< to from)
     (for (i 0 count)
       (set (byte-at to   i)
            (byte-at from i))))
    ((< from to)
     (for (i (- count 1) -1 -1)
       (set (byte-at to   i)
            (byte-at from i))))))

(define-function platform/clear-bytes (from count)
  (for (i 0 count)
    (set (byte-at from i) 0)))

(begin-for-syntax
 (define-function string+length (str)
   (let ((len (string-length str)))
     (assert (< 0 len))
     `((string->C-string ,str) ,len))))

(define-form platform/diag-print (str)
  (if (is <string> str)
      `(linux-syscall linux/SYS_write linux/STDERR_FILENO ,@(string+length str))
    `(let ((cstr (string->C-string ,str)))
       (linux-syscall linux/SYS_write linux/STDERR_FILENO cstr (C-string-length cstr)))))

(define-function platform/diag-print-char (char)
  ;; TODO endianness?
  (linux-syscall linux/SYS_write linux/STDERR_FILENO (address-of char) 1)
  char)

;; TODO delme
(define-form platform/print-diag-fmt (format . args)
  ())

;; needs to be a form; the compiler doesn't yet support . rest args
(define-form platform/halt args
  `(linux-syscall linux/SYS_exit ,@(or args '(-42))))

(define *initial-break* 0)
(define *current-break* 0)

(define-function platform/acquire-memory (size)
  ;; https://gist.github.com/nikAizuddin/f4132721126257ec4345
  (unless *initial-break*
    (set *current-break* (set *initial-break* (linux-syscall linux/SYS_brk 0)))
    ;; TODO too early, ASSERT and ERROR is not functional at this point
    ;;(assert (< 0 *current-break*))
    )
  (let ((new-break	(linux-syscall linux/SYS_brk (+ *current-break* size)))
        (result	*current-break*))
    ;;(assert (= size (- new-break *current-break*)))
    (set *current-break* new-break)
    ;; KLUDGE we make all allocated memory executable.
    ;; `make test-elf` generates machine code and wants to call it...
    (linux-syscall linux/SYS_mprotect *initial-break*
                   (- *current-break* *initial-break*)
                   (+ (+ linux/PROT_READ linux/PROT_WRITE)
                      linux/PROT_EXEC))
    result))
