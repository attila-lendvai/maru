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
       ;; let's test that the generated code is position independent
       (.base	0xdeadbeef)

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

         (MOVQir	42 RAX)
         (let ((future-value (label)))
           (SUBQir	42 RAX)
           ;; TODO add support for this to the instruction emitters
           ;; _s1P and _Os (and others in general) need to handle
           ;; non-integer values and safely fall back.
           ;; TODO split the implementation of SUBQim to SUBQim8
           ;; and SUBQim32 so that it's possible to pick one when
           ;; using such future-value setups
           ;; (SUBQir	future-value RAX)
           ;; (label!	future-value 42)
           )

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
          (MOVQir	stderr RSI)
          (MOVQmr	0 RSI 0 0 RSI)
          (call		fputs)

          (LEAQmr	'msg 0 0 0 RAX)  ; both should work and
          (LEAQmr	l/msg 0 0 0 RBX) ; load the same address.
          (SUBQrr	RBX RAX) ; therefore it should return 0 in RAX
          (RET)))))

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
    (RET)
    (label! 'exit-code)
    (.i64	1)))

;; TODO investigate why this must be a separate toplevel form
(when-at-expand (feature platform/linux)
  (require-cgrov "source/platforms/linux/linux"))

(when-at-expand (feature platform/linux)
  (define-jit-test jit-linux-1 ()

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
