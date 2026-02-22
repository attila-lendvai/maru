(require "source/assembler/x86-single-pass.l")
(require "tests/infra.l")

(require "source/c/cgrov.l")
(require "source/c/cffi.l")

(define-function call-asm-buf ()
  (call-x86-64-machine-code (assembler->function *assembler*)))

(define-function call (lower-fn)
  (MOVQir	lower-fn _RAX)
  (CALLQr	_RAX))

(when-at-expand (feature platform/posix)
  (require-cgrov "source/platforms/posix/posix"))

(when-at-expand (feature platform/posix)

  (define-test jit/posix/1 ()
    (begin-assembling)

    (let ((fputs (posix/dlsym posix/RTLD_DEFAULT "fputs"))
          (fflush (posix/dlsym posix/RTLD_DEFAULT "fflush"))
          (stderr (posix/dlsym posix/RTLD_DEFAULT "stderr")))
      ;; let's test that the generated code is position independent
      (.base	0xffff)

      (JMPSm	(flabelr 'code) 0 0 0)

      (label! 'msg)
      (.ascii	"*** dlsym lookup of fputs(char *, FILE *) seems to be able to emit this ***\n\000")

      (.align	16 0x90) ; NOP's to help the disassemler resync after the data
      (flabel! 'code)
      (LEAQmr	(labelr 'msg) 0 0 0 _RDI)
      (MOVQir	stderr _RSI)
      (MOVQmr	0 _RSI 0 0 _RSI)
      (call	fputs)

      (MOVQir	stderr _RDI)
      (MOVQmr	0 _RDI 0 0 _RDI)
      (call	fflush)

      (XORQrr	_RAX _RAX)
      (RET))

    (let ((filename "./build/jit"))
      (println "\nwriting runtime buffer to "filename)
      (save-assembler-buffer *assembler* filename))

    (test-assert
     (= 0 (call-asm-buf)))))

;; TODO investigate why this must be a separate toplevel form
(when-at-expand (feature platform/linux)
  (require-cgrov "source/platforms/linux/linux"))

(when-at-expand (feature platform/linux)
  (define-test jit/linux/1 ()
    (begin-assembling)

    ;; let's test that the generated code is position independent
    (.base 10000)

    ;; print using forward labels
    (MOVQir32	linux/SYS_write _RAX)
    (MOVQir32	linux/STDERR_FILENO _RDI)
    (LEAQmr	(flabelr 'msg) 0 0 0 _RSI)                    ; buffer
    (MOVQir32	(flabel 'msg-end (- self (label 'msg))) _RDX) ; strlen(buffer)
    (SYSCALL)

    ;; only to test the instruction emitter
    (MOVQir	0x01234567 _RAX)
    ;;(MOVQir	0x0123456789abcdef _RAX)
    (JMPSm	(flabelr 'skip-text) 0 0 0)

    (flabel!	'msg)
    (.ascii	"*** linux syscall test output from the dynamically compiled code ***\n")
    ;;(.ascii	"alma")
    (flabel!	'msg-end)

    ;; print using the already assigned values of the forward labels
    (.align	16)
    (flabel!	'skip-text)

    (MOVQir32	linux/SYS_write _RAX)
    (MOVQir32	linux/STDERR_FILENO _RDI)
    (LEAQmr	(labelr 'msg) 0 0 0 _RSI)
    (MOVQir32	(- (label 'msg-end) (label 'msg)) _RDX)
    (SYSCALL)

    (MOVQir32	42 _RAX)
    (RET)

    (let ((filename "./build/jit"))
      (println "writing runtime buffer to "filename)
      (save-assembler-buffer *assembler* filename))

    (test-assert
     (= 42 (call-asm-buf)))))

(run-tests)
