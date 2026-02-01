;;; -*- mode: lisp; coding: us-ascii -*-

(define-constant +linux/syscall/argument-registers/IA-32+
    `(quote ,(map symbol->string '(eax ebx ecx edx esi edi ebp))))

(define-constant +linux/syscall/clobbered-registers/IA-32+
    `(quote ,(map symbol->string '(ebx ecx edx esi edi ebp))))

(define-constant +linux/syscall/argument-registers/x86_64+
    `(quote ,(map symbol->string '(rax rdi rsi rdx r10 r8 r9))))
(define-constant +linux/syscall/clobbered-registers/x86_64+
    `(quote ,(map symbol->string '(rdi rsi rdx r10 r8 r9 rcx r11))))

(define-constant +linux/syscall/argument-registers/aarch64+
    `(quote ,(map symbol->string '(x8 x0 x1 x2 x3 x4 x5))))
;; AArch64 syscall number goes into x8, args in x0-x7, return in x0, x1 (?)
;; x6 x7 are not clobbered according to man 2 syscall
(define-constant +linux/syscall/clobbered-registers/aarch64+
    `(quote ,(map symbol->string '(x1 x2 x3 x4 x5 x8 x16 x17))))

;; TODO these should be groveled automatically
(eval-in-slave
 '(let ()
   (define-constant linux/O_RDONLY		0)
   (define-constant linux/O_WRONLY		1)
   (define-constant linux/O_RDWR		2)
   (define-constant linux/O_CREAT		64)
   (define-constant linux/PROT_READ		1)
   (define-constant linux/PROT_WRITE		2)
   (define-constant linux/PROT_EXEC		4)
   (define-constant linux/SEEK_SET		0)
   (define-constant linux/SEEK_CUR		1)
   (define-constant linux/SEEK_END		2)
   (define-constant linux/AT_FDCWD		-100)
   (define-constant linux/stdin			0)
   (define-constant linux/stdout		1)
   (define-constant linux/stderr		2)
   (cond
     ((= +architecture+ 'IA-32)
      ;; less $(guix build linux-libre-headers)/include/asm/unistd_32.h
      (define-constant linux/exit		1)
      (define-constant linux/read		3)
      (define-constant linux/write		4)
      ;; (define-constant linux/open		5)
      (define-constant linux/openat		295)
      (define-constant linux/close		6)
      (define-constant linux/chdir		12)
      (define-constant linux/lseek		19)
      (define-constant linux/brk		45)
      (define-constant linux/fsync		118)
      (define-constant linux/mprotect		125)
      )
     ((= +architecture+ 'x86-64)
      ;; less $(guix build linux-libre-headers)/include/asm/unistd_64.h
      (define-constant linux/exit		60)
      (define-constant linux/read		0)
      (define-constant linux/write		1)
      ;; (define-constant linux/open		2)
      (define-constant linux/openat		257)
      (define-constant linux/close		3)
      (define-constant linux/chdir		80)
      (define-constant linux/lseek		8)
      (define-constant linux/brk		12)
      (define-constant linux/fsync		74)
      (define-constant linux/mprotect		10)
      )
     ((= +architecture+ 'aarch64)
      ;; less $(guix build --target=aarch64-linux-gnu linux-libre-headers)/include/asm/unistd_64.h
      (define-constant linux/exit		93)
      (define-constant linux/read		63)
      (define-constant linux/write		64)
      (define-constant linux/openat		56)
      (define-constant linux/close		57)
      (define-constant linux/chdir		49)
      (define-constant linux/lseek		62)
      (define-constant linux/brk		214)
      (define-constant linux/fsync		82)
      (define-constant linux/mprotect		226)
      )

     (true (error "TODO: missing syscall constants for arch "+architecture+)))))

(load (concat-strings "source/platforms/linux/syscall-" *compiler-backend* ".l"))
