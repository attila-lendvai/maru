(require "source/assembler/x86-single-pass.l")
(require "tests/infra.l")

(require "source/c/cgrov.l")
(require "source/c/cffi.l")

(define +fputs-msg+ "*** dlsym lookup of fputs(char *, FILE *) seems to be able to emit this ***\n\000")

(define-function call-asm-buf ()
  (call-x86-64-machine-code (assembler->function *assembler*)))

(define-function call (lower-fn)
  (MOVQir	lower-fn RAX)
  (CALLQr	RAX))

(when-at-expand (feature platform/posix)
  (require-cgrov "source/platforms/posix/posix"))

(define-form define-jit-test (name . body)
  `(define-test ,name ()
     (with-assembling ((code))
       ;; let's test that the generated code is position independent
       (.base	0xdeadbeef)

       ,@body

       (let ((filename ,(concat-string "./build/jit/" (symbol->string name))))
         ;; (println "\nwriting jit buffer to "filename)
         (save-current-segment-to-file filename))

       (test-assert
        (= 0 (call-asm-buf))))))

(when-at-expand (and (feature platform/posix)
                     (defined? 'posix/dlsym *globals*))

  (define-jit-test jit-posix-1
    (let ((fputs	(posix/dlsym posix/RTLD_DEFAULT "fputs"))
          (fflush	(posix/dlsym posix/RTLD_DEFAULT "fflush"))
          (stderr	(posix/dlsym posix/RTLD_DEFAULT "stderr")))

      (let ((l/code (label)))
        (JMPSm	l/code 0 0 0)

        (let ((l/msg (label!)))
          (.ascii	+fputs-msg+)

          (.align	16 0x90) ; NOP's to help the disassemler resync after the data

          (label!	l/code)
          (LEAQmr	l/msg 0 0 0 RDI)
          (MOVQir	stderr RSI)
          (MOVQmr	0 RSI 0 0 RSI)
          (call		fputs)

          (MOVQir	stderr RDI)
          (MOVQmr	0 RDI 0 0 RDI)
          (call		fflush)

          ;; NOTE libc only picks up EAX, not the entire RAX as return
          ;; value, so this doesn't test an actual bug where NEGQ was
          ;; wrongly emitting a NEGL.
          (MOVQir	-42 RAX)
          (NEGQr		RAX)
          (let ((future-value (label)))
            (SUBQi8r	future-value RAX)
            (NOP)
            (label!	future-value 42))

          (RET)))))

  (define-jit-test jit-posix-2
    (let ((fputs	(posix/dlsym posix/RTLD_DEFAULT "fputs"))
          (stderr	(posix/dlsym posix/RTLD_DEFAULT "stderr")))

      (let ((l/code (label)))
        (JMPSm	l/code 0 0 0)

        (LEAQmr	'msg 0 0 0 RDI) ; a forward reference
        (NOP)
        (NOP)
        (NOP)

        (let ((l/msg (label! 'msg))) ; test mixed name/local-var referencing
          (.ascii	+fputs-msg+)

          (.align	16 0x90) ; NOP's to help the disassemler resync after the data

          (label!	l/code)
          (LEAQmr	l/msg 0 0 0 RDI)

          ;; NOP; just to test using high R64 regs
          (MOVQir	stderr R15)
          (MOVQmr	0 R15 0 0 R15)

          (MOVQir	stderr RSI)
          (MOVQmr	0 RSI 0 0 RSI)
          (call		fputs)

          (LEAQmr	'msg 0 0 0 RAX)  ; both should work and
          (LEAQmr	l/msg 0 0 0 RBX) ; load the same address.
          (SUBQrr	RBX RAX) ; therefore it should return 0 in RAX
          (RET)))))
) ; posix and dlsym

(when-at-expand (feature platform/posix)

  (define-jit-test jit-posix-3
    (let ()

      (JMPSm	'skip-1 0 0 0)

      (label!	'data-1)
      (.i64	'skip-1) ; future label reference

      (label!	'skip-1)
      (JMPSm	'skip-2 0 0 0)

      (label!	'data-2)
      (.i64	'skip-1) ; realized label reference
      (NOP)
      (NOP)
      (NOP)
      (NOP)
      (NOP)

      ;; some unexecuted instructions to test the instruction emitters
      (ADDBrr	AL BL)
      (ADDBmr	8 0 0 0 BL)
      (ADDQir	8 RAX)
      (ADDQir	9 RBX)
      (ADDQir	0x11223344 RCX)
      (LEAQmr	3 RAX RBX 8 RCX)
      (NOP)

      (label!	'skip-2)
      (LEAQmr	'data-1 0 0 0 RAX)
      (MOVQmr	0 RAX 0 0 RAX)        ; data-1 in rax
      (LEAQmr	'data-2 0 0 0 RBX)
      (MOVQmr	0 RBX 0 0 RBX)        ; data-2 in rbx
      (SUBQrr	RBX RAX)              ; should be zero
      (RET)))

  (define-jit-test jit-posix-4

    ;; (LEAQmr 0 RAX RCX 1 RCX)
    ;; (MOVBmr 0 ECX 0 1 AL)
    ;; (MOVBmr 0 RCX 0 1 AL)
    (MOVQir	21 RAX)
    (MOVQir	2  RBX)
    (MULQrr	RBX RAX)
    (MOVQir	42  RBX)
    (DIVQrr	RBX RAX)
    (SUBQrm	RAX 'exit-code 0 0 0)
    (MOVQmr	'exit-code 0 0 0 RAX)
    ;; de facto NOPs to test the instruction emitters
    (ANDQir	0xff RAX)
    (ORQir	0 RAX)
    (XORQir	0 RAX)
    (ADDQir	3 RAX)
    (SUBQi32r	3 RAX)
    (RET)
    (label! 'exit-code)
    (.i64	1))

(define-jit-test jit-posix-5 ()

  (MOVQir	0x1122334455667788 RAX)
  (ANDQir	0x7fffffff RAX)
  (SUBQir	0x55667788 RAX)
  (RET))

) ; (feature platform/posix)

;; TODO investigate why this must be a separate toplevel form
(when-at-expand (feature platform/linux)
  (require-cgrov "source/platforms/linux/linux"))

(when-at-expand (feature platform/linux)
  (define-jit-test jit-linux-1 ()

    ;; print using forward labels
    (MOVQi32r	linux/SYS_write RAX)
    (MOVQi32r	linux/STDERR_FILENO RDI)
    (LEAQmr	'msg 0 0 0 RSI)                    ; buffer
    (MOVQi32r	(label 'msg-end (- self (laddress 'msg))) RDX) ; strlen(buffer)
    (SYSCALL)

    ;; only to test the instruction emitter
    (MOVQir	0x12345678 RAX)
    ;;(MOVQir	0x123456789abcdef0 RAX)
    (JMPSm	'skip-text 0 0 0)

    (label!	'msg)
    (.ascii	"*** linux syscall test output from the dynamically compiled code ***\n")
    ;;(.ascii	"alma")
    (label!	'msg-end)

    ;; print using the already assigned values of the forward labels
    (.align	16)
    (label!	'skip-text)

    (MOVQi32r	linux/SYS_write RAX)
    (MOVQi32r	linux/STDERR_FILENO RDI)
    (LEAQmr	'msg 0 0 0 RSI)
    (MOVQi32r	(- (laddress 'msg-end) (laddress 'msg)) RDX)
    (SYSCALL)

    (MOVQi32r	0 RAX)
    (RET))

) ; (feature platform/linux)

(run-tests)
