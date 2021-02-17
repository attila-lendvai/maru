(require "source/buffer.l")

;; https://github.com/tonyg/pi-nothing/blob/4b2b59d42babd72cfd007cb71ed295dcdbf53d4a/nothingc/elf.rkt
;; https://interrupt.memfault.com/blog/gnu-binutils

(define code (buffer 4096))	;; binary
(define phased 1)		;; non-nil if something changed this pass
;;(define $% 0)			;; file offset
(define $$ 0)			;; last .base address
(define $ 0)			;; current address

(define-function _B  (out value)	(buffer-append code value) (incr $))
(define-function _W  (out value)	(_B out (bitwise-and 0xff value))   (_B out (bitwise-and 0xff   (bitwise-shift value -8))))
(define-function _L  (out value)	(_W out (bitwise-and 0xffff value)) (_W out (bitwise-and 0xffff (bitwise-shift value -16))))
(define-function _D1 (out value)	(_B out value))
(define-function _D4 (out value)	(_L out value))

(require "source/assembler/asm-x86.l")

(define-function define-label (name value)
  (unless (= (eval name) value)
    (eval (list 'set name value))
    (set phased 1)))

;; TODO clean up namespace issue, and only use .foo naming convention
;; for stuff that doesn't actually emit anything.
(define-function .base (addr)		(set $$ (set $ (eval addr))))
(define-form	 .def (name expr)	(define-label name (eval expr)) ())
(define-function .i8 bytes		(list-do byte bytes (_B () (eval byte))))
(define-function .i16 halfs		(list-do half halfs (_W () (eval half))))
(define-function .i32 longs		(list-do long longs (_L () (eval long))))
(define-function .ascii strings		(list-do string strings (string-do char string (_B () char))))
(define-function .asciiz strings	(apply .ascii strings) (_B () 0))
(define-function .align (bytes)		(let ((remainder (bitwise-and $ (- bytes 1))))
                                          (when (< 0 remainder)
                                            (times-do (- bytes remainder)
                                              (_B () 0)))))

(define-function movlIR (src dst)	(MOVLir src dst ()))
(define-function movlRM (src dst)	(MOVLrm src dst 0 0 0 ()))
(define-function movlMR (src dst)	(MOVLmr src 0 0 0 dst ()))
(define-function movlRR (src dst)	(MOVLrr src dst ()))
(define-function inclR (dst)		(INCLr dst ()))
(define-function pushlI (src)		(PUSHLi src ()))
(define-function addlIR (src dst)	(ADDLir src dst ()))
(define-function addlRM (src dst)	(ADDLrm src dst 0 0 0 ()))
(define-function sublIR (src dst)	(SUBLir src dst ()))
(define-function int (n)		(_B () 0xCD) (_B () n))

(define-function assemble (program)
  (list-do insn program
    (cond
      ((symbol? insn)		(eval (list 'define insn 0)))
      ((= '.def (car insn))	(eval (list 'define (cadr insn) 0)))))
  (set phased 1)
  (while phased
    (set phased ())
    (buffer-reset code)
    (set $$ (set $ (address-of (<buffer>-elements code))))
    (list-do insn program
      (cond
	((symbol? insn)		(define-label insn $))
	((pair? insn)		(eval insn))
	(else			(error "huh? "insn)))))
  (println "assembled "(buffer-length code)" bytes")
  )

;; man elf
;; /usr/include/linux/elf.h
;; https://cirosantilli.com/elf-hello-world
;; man 8 ld-linux.so
;; https://en.wikipedia.org/wiki/Executable_and_Linkable_Format

(define elf/PF_R	0x4)
(define elf/PF_W	0x2)
(define elf/PF_X	0x1)

(assemble
  '((.base	0x08048000) ; with ASLR disabled, programs for x86 architecture are based at 0x8048000 by the linker: https://stackoverflow.com/questions/18296276/base-address-of-elf
file-start
    (.i8	0x7f)			; ident
    (.ascii	"ELF")
    (.i8	1 1 1 0)		; ELFCLASS32, ELFDATA2LSB, version, ELFOSABI_NONE
    (.i8	0 0 0 0 0 0 0 0)	; EI_ABIVERSION and padding
    (.i16	2)			; Type (ET_EXEC = 2)
    (.i16	3)			; Machine (EM_386 = 3)
    (.i32	1)			; Version
    (.i32	code-segment-start)	; Entry point address
    (.i32	(- program-headers file-start))	; phoff		Start of program headers
    (.i32	0)			; shoff		Start of section headers
    (.i32	0)			; Flags
    (.i16	elf-header-size)	; ehsize	Size of this header
    (.i16	program-header-size)	; phentsize	Size of program headers (of *one* section header, the rest are the same).
    (.i16	3)			; phnum		Number of program headers
    (.i16	0)			; shentsize	Size of section headers
    (.i16	0)			; shnum		Number of section headers
    (.i16	0)			; shstrndx	Section header string table index
    (.def	elf-header-size (- $ file-start))
program-headers
    ;; code segment
    (.i32	1)			; type (1 = PT_LOAD)
    (.i32	0)			; file offset
    (.i32	0x08048000)		; vaddr		Virtual Addr
    (.i32	0)			; paddr		Physical Addr
    (.i32	code-segment-size)	; filesz	Size in file (?)
    (.i32	code-segment-size)	; memsz		Size in memory (?)
    (.i32	(+ elf/PF_R elf/PF_X))	; flags: read, execute
    (.i32	0x1000)			; alignment
    (.def	program-header-size (- $ program-headers)) ; of *one* section header
    ;; read only data segment
    (.i32	1)			; type (1 = PT_LOAD)
    (.i32	(- ro-data-segment-start file-start))	; file offset
    (.i32	ro-data-segment-start)	; vaddr		Virtual Addr
    (.i32	0)			; paddr		Physical Addr
    (.i32	ro-data-segment-size)	; filesz	Size in file (?)
    (.i32	ro-data-segment-size)	; memsz		Size in memory (?)
    (.i32	elf/PF_R)		; flags: read
    (.i32	4)			; alignment
    ;; writable data segment
    (.i32	1)			; type (1 = PT_LOAD)
    (.i32	(- data-segment-start file-start))	; file offset
    (.i32	data-segment-start)	; vaddr		Virtual Addr
    (.i32	0)			; paddr		Physical Addr
    (.i32	data-segment-size)	; filesz	Size in file (?)
    (.i32	data-segment-size)	; memsz		Size in memory (?)
    (.i32	(+ elf/PF_R elf/PF_W))	; flags: read, write
    (.i32	4)			; alignment
code-segment-start
    ;; print message
    (movlIR	4 _EAX)			; write
    (movlIR	1 _EBX)			; fd, stdout
    (movlIR	msg _ECX)
    (movlIR	msglen _EDX)
    (int	0x80)
    ;; write into the data segment: var = var - 42
    (movlIR	-42 _EAX)
    (addlRM	_EAX var)
    ;; exit
    (movlMR	var _EBX)		; exit code, should be 0
    (movlIR	1 _EAX)			; exit
    (int	0x80)			; linux syscall
    (.def	code-segment-size (- $ file-start))

    ;; (.align 1234) ; to test that it still works with a random offset added
ro-data-segment-start
msg
    (.ascii	"Hello, world! From an elf binary!\n")
    (.def	msglen (- $ msg))
    (.def	ro-data-segment-size (- $ ro-data-segment-start))

data-segment-start
var
    (.i32	42)
    (.def	data-segment-size (- $ data-segment-start))))

(print "writing buffer to ")

(buffer-save code (println "./build/test-elf"))

;; for details on int 0x80 and syscall see:
;; https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux
;; /usr/include/asm/unistd_32.h

;; TODO the next two doesn't print anything for me, even though the asm looks good in gdb
;; when i uncomment the crashing line to enter gdb.

;; TODO this started to sigsegv for me. due to stricter ASLR on a new kernel?

(assemble '(
	(movlIR	4 _EAX)				; write
	(movlIR	2 _EBX)				; stderr
	(movlIR	msg _ECX)			; buffer
	(movlIR	msglen _EDX)			; strlen(buffer)
	(int	0x80)
	;;(movlRM	_EAX 0)				; crash! for testing...
	(RET	0)
msg	(.ascii	"*** Test output from running the dynamically compiled asm code\n")
	(.def	msglen (- $ msg))))

(println "calling it, output should follow")

(define-function buffer->fn (buf)
  (make <target-function>
    (program-code	(<buffer>-elements buf))))

(call-IA-32-machine-code (buffer->fn code))

(assemble '(
	(movlIR	4 _EAX)				; write
	(movlIR	1 _EBX)				; stdout
	(movlIR	msg _ECX)			; buffer
	(movlIR	msglen _EDX)			; strlen(buffer)
	(int	0x80)
	(movlIR	1 _EAX)				; exit
	(movlIR	0 _EBX)				; status
	(int	0x80)
msg	(.ascii	"*** Now run ./a.out for a friendly greeting\n")
	(.def	msglen (- $ msg))))

(println "calling it, output should follow")

(call-IA-32-machine-code (buffer->fn code))

(println "it shouldn't have returned!!!")
