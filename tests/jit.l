(require "source/assembler/x86-single-pass.l")
(require "tests/infra.l")

(define-test jit/1 ()
  (begin-assembling)

  (MOVQir	1 _RAX)         ; write (syscall #1)
  (MOVQir	2 _RDI)         ; stderr (fd 2)
  (MOVQir	(flabel 'msg) _RSI)       ; buffer
  (MOVQir	(flabel 'msg-end (- self (label 'msg))) _RDX)    ; strlen(buffer)
  (SYSCALL)

  (MOVQir	42 _RAX)
  (RET)
  (flabel!	'msg)
  (.ascii	"*** Test output from running the dynamically compiled asm code ***\n")
  (flabel!	'msg-end)

  ;; (let ((filename "./build/jit"))
  ;;   (println "writing runtime buffer to "filename)
  ;;   (save-assembler-buffer *assembler* filename))

  (test-assert
   (= 42 (call-x86-64-machine-code (assembler->function *assembler*)))))

;; (assemble '(
;; 	(MOVQir	60 _RAX)                ; exit
;; 	(MOVQir	0 _RDI)                 ; status
;; 	(SYSCALL)))

(run-tests)
