(require "source/assembler/x86-single-pass.l")
(require "tests/infra.l")

(require "source/c/cgrov.l")
(require "source/c/cffi.l")

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
       ,@body

       (let ((filename ,(concat-string "./build/jit/" (symbol->string name))))
         ;; (println "\nwriting jit buffer to "filename)
         (save-current-segment-to-file filename))

       (test-assert
        (= 0 (call-asm-buf))))))

(when-at-expand (feature platform/posix)

  (define +fputs-msg+ "*** dlsym lookup of fputs(char *, FILE *) seems to be able to emit this ***\n\000")

  (define-jit-test jit-posix-1
    (let ((fputs	(posix/dlsym posix/RTLD_DEFAULT "fputs"))
          (fflush	(posix/dlsym posix/RTLD_DEFAULT "fflush"))
          (stderr	(posix/dlsym posix/RTLD_DEFAULT "stderr")))
      ;; let's test that the generated code is position independent
      (.base	0xdeadbeef)

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

         (XORQrr	RAX RAX)
         (RET)))))

  (define-jit-test jit-posix-2
    (let ((fputs	(posix/dlsym posix/RTLD_DEFAULT "fputs"))
          (stderr	(posix/dlsym posix/RTLD_DEFAULT "stderr")))
      ;; let's test that the generated code is position independent
      (.base	0xdeadbeef)

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
          (MOVQir	stderr RSI)
          (MOVQmr	0 RSI 0 0 RSI)
          (call		fputs)

          (LEAQmr	'msg 0 0 0 RAX)  ; both should work and
          (LEAQmr	l/msg 0 0 0 RBX) ; load the same address.
          (SUBQrr	RBX RAX) ; therefore it should return 0 in RAX
          (RET)))))

  (define-jit-test jit-posix-3
    (let ()
      ;; let's test that the generated code is position independent
      (.base	0xdeadbeef)

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

      (label!	'skip-2)
      (LEAQmr	'data-1 0 0 0 RAX)
      (MOVQmr	0 RAX 0 0 RAX)        ; data-1 in rax
      (LEAQmr	'data-2 0 0 0 RBX)
      (MOVQmr	0 RBX 0 0 RBX)        ; data-2 in rbx
      (SUBQrr	RBX RAX)              ; should be zero
      (RET))))

;; TODO investigate why this must be a separate toplevel form
(when-at-expand (feature platform/linux)
  (require-cgrov "source/platforms/linux/linux"))

(when-at-expand (feature platform/linux)
  (define-jit-test jit-linux-1 ()
    ;; let's test that the generated code is position independent
    (.base	0xdeadbeef)

    ;; print using forward labels
    (MOVQir32	linux/SYS_write RAX)
    (MOVQir32	linux/STDERR_FILENO RDI)
    (LEAQmr	'msg 0 0 0 RSI)                    ; buffer
    (MOVQir32	(label 'msg-end (- self (laddress 'msg))) RDX) ; strlen(buffer)
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

    (MOVQir32	linux/SYS_write RAX)
    (MOVQir32	linux/STDERR_FILENO RDI)
    (LEAQmr	'msg 0 0 0 RSI)
    (MOVQir32	(- (laddress 'msg-end) (laddress 'msg)) RDX)
    (SYSCALL)

    (MOVQir32	0 RAX)
    (RET)))

(run-tests)
