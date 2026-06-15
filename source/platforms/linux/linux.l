;;; -*- mode: lisp; coding: us-ascii -*-

(set (feature platform/linux) true)
(set (feature platform/posix) true)

(require "source/platforms/platform-c-based.l")

;; It's tempting to just include the posix cgrov values, but even
;; though they mostly overlap, there's no guaranteed that they are
;; the same.
;; (require-cgrov "source/platforms/posix/posix")

(require-cgrov "source/platforms/linux/linux")

(define main) ; forward

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

;; this is a placeholder object in the target on which we can register
;; a special-form later. theoretically, this could be any object
;; (including nil), but we leave a recognizable trace for better
;; potential error messages.
(define syscall
  (fixed (lambda args
           (print "syscall encountered in interpreted code with args " args "\n")
           (abort))))

;; NOTE: cannot be a function, because the syscall special form cannot be applied
;; NOTE: the assert wrapper must be defined later when ERROR is set up
(define-form syscall* args
  `(%syscall-rc-assert ,(first args) (syscall ,@args)))

;;;
;;; Platform API implementation when running on top of the Linux kernel.
;;;
(define-function platform/flush-streams ()
  ;; there's no need to flush fd's on linux. fsync straight out
  ;; returns an error when called on a terminal or pipe.
  ;; (syscall* linux/SYS_fsync linux/STDOUT_FILENO)
  ;; (syscall* linux/SYS_fsync linux/STDERR_FILENO)
  )

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

(define-function platform/clear-cells (from cell-count)
;; TODO this is still rather high in the profiler. maybe introduce
;; backend specific compiler macros, and then add an x86 asm
;; impelmentation?
  (for (i 0 cell-count)
    (set (oop-at from i) 0)))

(define-form platform/diag-print-string (str)
  (typecase str
    (<string> ; i.e. we can calculate the string length at expand time
     `(syscall linux/SYS_write linux/STDERR_FILENO
                     (string->C-string ,str) ,(string-length str)))
    (else
     ;; FIXME why do i need the eval?
     `(let ((cstr ,(if (eval '(feature emit-with-object-headers))
                       `(string->C-string ,str)
                     str)))
        (syscall linux/SYS_write linux/STDERR_FILENO cstr (C-string-length cstr))))))

(define-function platform/diag-print-char (char)
  ;; TODO endianness?
  (syscall linux/SYS_write linux/STDERR_FILENO (address-of char) 1)
  char)

;; needs to be a form; the compiler doesn't yet support . rest args
(define-form platform/halt args
  `(syscall linux/SYS_exit ,@(or args '(-42))))

(define *initial-break* 0)
(define *current-break* 0)

(define-function platform/acquire-memory (size)
  ;; https://gist.github.com/nikAizuddin/f4132721126257ec4345
  (unless *initial-break*
    (set *current-break* (set *initial-break* (syscall linux/SYS_brk 0)))
    ;; TODO too early, ASSERT and ERROR is not functional at this point
    ;;(assert (< 0 *current-break*))
    )
  (let ((new-break	(syscall linux/SYS_brk (+ *current-break* size)))
        (result		*current-break*))
    (when (= new-break *current-break*)
      (platform/diag-print "SYS_brk failed, aborting")
      (platform/halt))
    (set *current-break* new-break)
    ;; KLUDGE we make all allocated memory executable.
    ;; `make test-elf` generates machine code and wants to call it...
    (syscall linux/SYS_mprotect *initial-break*
             (- *current-break* *initial-break*)
             (+ (+ linux/PROT_READ linux/PROT_WRITE)
                linux/PROT_EXEC))
    result))

(eval-in-host '(load "source/platforms/linux/syscall.l"))

;; https://clang.llvm.org/docs/UsersManual.html#freestanding-builds

;; let's declare a memset function because clang -O can emit
;; references to it (and memcpy and memmove) even with `clang
;; -nostdlib -nostartfiles -ffreestanding -Wl,-Bstatic`.

;; So even if your handwritten code never mentions strlen, LLVM might:
;;   - Recognize an strlen impl in the IR and turn it to an strlen call.
;;   - Emit a call to strlen (libc function) during lowering to
;;     AArch64 assembly/object code.
(eval-in-host
 '(define *llvm-platform-specific-prelude*
   "
define weak dso_local ptr @memset(ptr %dst, i32 %val, %word %len) {
entry:
  %end = getelementptr i8, ptr %dst, %word %len
  %val8 = trunc i32 %val to i8
  br label %loop

loop:
  %cur = phi ptr [ %dst, %entry ], [ %next, %store ]
  %done = icmp eq ptr %cur, %end
  br i1 %done, label %exit, label %store

store:
  store i8 %val8, ptr %cur
  %next = getelementptr i8, ptr %cur, %word 1
  br label %loop

exit:
  ret ptr %dst
}

define weak dso_local i64 @strlen(ptr %str) {
entry:
  br label %loop

loop:
  ; %cur starts as %str, then advances by 1 each iteration
  %cur = phi ptr [ %str, %entry ], [ %next, %loop ]

  %ch = load i8, ptr %cur
  %zero = icmp eq i8 %ch, 0
  %next = getelementptr i8, ptr %cur, i64 1
  br i1 %zero, label %exit, label %loop

exit:
  %endptr = phi ptr [ %cur, %loop ]
  %start = ptrtoint ptr %str to i64
  %end   = ptrtoint ptr %endptr to i64
  %len   = sub i64 %end, %start
  ret i64 %len
}
"))

;; aka `extern char **environ` in libc land
(define %envp)

;; the API we use
(define-function posix/envp ()
  %envp)


;; https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;; http://www.dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html
;; https://0xax.gitbooks.io/linux-insides/content/Misc/linux-misc-4.html
;; https://stackoverflow.com/questions/50260855/how-get-arguments-value-using-inline-assembly-in-c-without-glibc
;; i386: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/i386/start.S;h=91035fa83fb7ee38a0ca5834ba1d215b4a7f78e8;hb=HEAD
;; x86_64: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/x86_64/start.S;h=354d2e6ec78f0eaf9ab0f8ed665c2e5499388df0;hb=HEAD
;; argc and argv position on the stack: https://briancallahan.net/blog/20200808.html
;;
;; auxv, ELF auxiliary vector: contains information about the memory page size, metadata from the ELF file, etc
;;   https://amit.prasad.me/blog/before-main
;;   How programs get run: ELF binaries
;;   https://lwn.net/Articles/631631/
(define-function _start ()
  ;; too early for this: (debug (platform/diag-print "_start is alive\n"))

  ;; Stack layout, High memory
  ;; +---------------------+
  ;; | auxv[0].a_type = 0  | ; some AT_NULL nonsense, #defined as 0
  ;; | auxv[0].a_val = 0   |
  ;; +---------------------+
  ;; | ...                 |
  ;; +---------------------+
  ;; | auxv[0].a_type      |
  ;; | auxv[0].a_val       |
  ;; +---------------------+
  ;; | NULL                |
  ;; +---------------------+
  ;; | ...                 |
  ;; +---------------------+
  ;; | envp pointers       | key=value strings
  ;; +---------------------+
  ;; | NULL                |
  ;; +---------------------+
  ;; | ... (argc times)    |
  ;; +---------------------+
  ;; | argv[0]             |
  ;; +---------------------+
  ;; | argc (int)          | <-- stack pointer points to argc
  ;; +---------------------+
  ;; Lower memory

  ;; TODO parse AT_PAGESZ (the page size)
  (let* ((sp (stack-pointer-on-entry))
         (argc (oop-at sp 0))
         (argv (+ sp (words-to-bytes 1)))
         (envp (+ argv (words-to-bytes (+ argc 1)))))
    (set %envp envp)
    (syscall linux/SYS_exit (main argc argv))))
