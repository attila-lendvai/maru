;;; -*- mode: lisp; coding: us-ascii -*-

;; https://clang.llvm.org/docs/UsersManual.html#freestanding-builds

;; let's declare a memset function because clang -O can emit
;; references to it (and memcpy and memmove) even with `clang
;; -nostdlib -nostartfiles -ffreestanding -Wl,-Bstatic`.

;; So even if your handwritten code never mentions strlen, LLVM might:
;;   - Recognize a simple string length loop in IR.
;;   - Emit a call to strlen (libc function) during lowering to
;;     AArch64 assembly/object code.
(define *llvm-platform-specific-prelude*
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

define weak dso_local i64 @strlen(ptr %0) {
  br label %2

2:                                                ; preds = %2, %1
  %3 = phi ptr [ %0, %1 ], [ %6, %2 ]
  %4 = load i8, ptr %3
  %5 = icmp eq i8 %4, 0
  %6 = getelementptr i8, ptr %3, i64 1
  br i1 %5, label %7, label %2

7:                                                ; preds = %2
  %8 = ptrtoint ptr %3 to i64
  %9 = ptrtoint ptr %0 to i64
  %10 = sub i64 %8, %9
  ret i64 %10
}
")

(load (concat-strings "source/emit-" *compiler-backend* ".l"))

;; this is a placeholder object in the target on which we can register
;; a special-form. theoretically this could be any objcect, but we
;; leave a recognizable trace should something go off track somewhere.
(eval-in-target
 '(define linux-syscall
   (fixed (lambda args
            (print "linux-syscall encountered in interpreted code with args " args "\n")
            (abort)))))

(load (concat-strings "source/platforms/linux/syscall.l"))

(switch-to-target-env)

(load "source/evaluator/vm-early.l")
(load "source/platforms/linux/linux.l")
(load "source/debug-min.l")
(load "source/evaluator/vm.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")
(load "source/evaluator/eval.l")

(define-primitive-function set-working-directory ((path <string>))
  (verbosity 1 (print-all *debug-output* "changing working directory to: "path"\n"))
  (unless (= 0 (linux-syscall linux/chdir (string->C-string path)))
    (error "set-working-directory: linux/chdir failed for "path)))

(load "source/platforms/linux/streams.l")
(load "source/evaluator/vm-with-file-support.l")
(load "source/evaluator/vm-late.l")

;; https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;; http://www.dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html
;; https://0xax.gitbooks.io/linux-insides/content/Misc/linux-misc-4.html
;; https://stackoverflow.com/questions/50260855/how-get-arguments-value-using-inline-assembly-in-c-without-glibc
;; i386: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/i386/start.S;h=91035fa83fb7ee38a0ca5834ba1d215b4a7f78e8;hb=HEAD
;; x86_64: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/x86_64/start.S;h=354d2e6ec78f0eaf9ab0f8ed665c2e5499388df0;hb=HEAD
;; argc and argv position on the stack: https://briancallahan.net/blog/20200808.html
(define-function _start ()
  (debug (platform/diag-print "_start is alive\n"))

  (let ((argc (oop-at (stack-pointer-on-entry) 0))
        (argv (+ (stack-pointer-on-entry)
                 (words-to-bytes 1))))
    (linux-syscall linux/exit
     (main/common argc argv linux/stdin linux/stdout linux/stderr))))
