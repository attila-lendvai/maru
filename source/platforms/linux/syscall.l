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

(load (concat-strings "source/platforms/linux/syscall-" *compiler-backend* ".l"))
