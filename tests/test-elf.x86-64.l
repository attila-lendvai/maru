(require "source/buffer.l")

;; ELF stuff:
;; stack, argc, argv, envs: https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;; https://github.com/tonyg/pi-nothing/blob/4b2b59d42babd72cfd007cb71ed295dcdbf53d4a/nothingc/elf.rkt
;; https://interrupt.memfault.com/blog/gnu-binutils
;; man elf
;; /usr/include/linux/elf.h
;; https://cirosantilli.com/elf-hello-world
;; man 8 ld-linux.so
;; https://en.wikipedia.org/wiki/Executable_and_Linkable_Format

;; lots of docs on writing a kernel module to add a new binary format
;; https://www.muppetlabs.com/~breadbox/txt/mopb.html
;; https://www.muppetlabs.com/~breadbox/txt/mopb-app.html

;; memory layout, linux loader, malloc, brk:
;; https://gist.github.com/CMCDragonkai/10ab53654b2aa6ce55c11cfc5b2432a4
;; ASLR: https://sysctl-explorer.net/kernel/randomize_va_space/
;; brk: https://gist.github.com/nikAizuddin/f4132721126257ec4345

;; readelf -a ./build/test-elf

;; Notes:
;;  - ELFCLASS64 (EI_CLASS = 2), EM_X86_64 = 62
;;  - ELF64 header size = 64, program header size = 56
;;  - Program header layout for ELF64: p_type(4), p_flags(4), p_offset(8),
;;    p_vaddr(8), p_paddr(8), p_filesz(8), p_memsz(8), p_align(8)
;;  - Use syscall (0x0f 0x05). Syscall numbers: write=1, exit=60.
;;  - Syscall args in rdi, rsi, rdx, r10, r8, r9 (we use rdi/rsi/rdx here).

(define asm-buffer (buffer 4096))	;; binary
(define phased 1)		;; non-nil if something changed this pass
(define $$ 0)			;; last .base address
(define $ 0)			;; current address

(define-function _B  (value)	(buffer-append asm-buffer value) (incr $))
(define-function _W  (value)	(_B (bitwise-and 0xff value))   (_B (bitwise-and 0xff   (bitwise-shift value -8))))
(define-function _L  (value)	(_W (bitwise-and 0xffff value)) (_W (bitwise-and 0xffff (bitwise-shift value -16))))
(define-function _Q  (value)
  (_L (bitwise-and 0xffffffff value))
  (_L (bitwise-and 0xffffffff (bitwise-shift value -32))))

;; TODO these should encode RIP relative addresses
(define-function _D1 (value)	(_B value))
(define-function _D4 (value)	(_L value))

(require "source/assembler/assembler.x86.l")

(define-function define-label (name value)
  (unless (= (eval name) value)
    (eval (list 'set name value))
    (set phased 1)))

;; address helpers
(define-function .base (addr)		(set $$ (set $ (eval addr))))
(define-form	 .def (name expr)	(define-label name (eval expr)) ())
(define-function .i8 bytes		(list-do byte bytes (_B (eval byte))))
(define-function .i16 halfs		(list-do half halfs (_W (eval half))))
(define-function .i32 longs		(list-do long longs (_L (eval long))))
(define-function .i64 quads		(list-do quad quads (_Q (eval quad))))
(define-function .ascii strings		(list-do string strings (string-do char string (_B char))))
(define-function .asciiz strings	(apply .ascii strings) (_B 0))
(define-function .align (bytes)		(let ((remainder (bitwise-and $ (- bytes 1))))
                                          (when (< 0 remainder)
                                            (times-do (- bytes remainder)
                                              (_B 0)))))

(define-function assemble (program)
  (list-do insn program
           (cond
             ((symbol? insn)		(eval (list 'define insn 0)))
             ((= '.def (car insn))	(eval (list 'define (cadr insn) 0)))))
  (set phased 1)
  (while phased
    (set phased ())
    (buffer-reset asm-buffer)
    (set $$ (set $ (address-of (<buffer>-elements asm-buffer))))
    (list-do insn program
             (cond
	       ((symbol? insn)		(define-label insn $))
	       ((pair? insn)		(eval insn))
	       (else			(error "huh? "insn)))))
  (println "assembled "(buffer-length asm-buffer)" bytes")
  )

;; ELF flags
(define elf/PF_R	0x4)
(define elf/PF_W	0x2)
(define elf/PF_X	0x1)
(define elf/page-size	0x1000)

(assemble
  '((.base	0x00400000) ; typical 64-bit default base
file-start
    (.i8	0x7f)			; ident[0]
    (.ascii	"ELF")
    (.i8	2 1 1 0)		; ELFCLASS64, ELFDATA2LSB, version, ELFOSABI_NONE
    (.i8	0 0 0 0 0 0 0 0)	; EI_ABIVERSION and padding (total 16 ident bytes)
    (.i16	2)			; e_type (ET_EXEC = 2)
    (.i16	62)			; e_machine (EM_X86_64 = 62)
    (.i32	1)			; e_version
    (.i64	code-segment-start)	; e_entry (entry point)
    (.i64	(- program-headers file-start))	; e_phoff	Start of program headers (file offset)
    (.i64	0)			; e_shoff	Start of section headers
    (.i32	0)			; e_flags
    (.i16	elf-header-size)	; e_ehsize	Size of this header (ELF64_Ehdr = 64)
    (.i16	program-header-size)	; e_phentsize	Size of program header entry (ELF64_Phdr = 56)
    (.i16	3)			; e_phnum	Number of program headers
    (.i16	0)			; e_shentsize	Size of section header
    (.i16	0)			; e_shnum	Number of section headers
    (.i16	0)			; e_shstrndx	Section header string table index
    (.def	elf-header-size (- $ file-start))
program-headers
    ;; code segment (PT_LOAD)
    (.i32	1)			; p_type (PT_LOAD)
    (.i32	(+ elf/PF_R elf/PF_X))	; p_flags (read, exec)
    (.i64	0)			; p_offset (file offset)
    (.i64	0x00400000)		; p_vaddr (virtual addr of segment) - base
    (.i64	0)			; p_paddr
    (.i64	code-segment-size)	; p_filesz
    (.i64	code-segment-size)	; p_memsz
    (.i64	elf/page-size)		; p_align
    (.def	program-header-size (- $ program-headers))

    ;; read-only data segment
    (.i32	1)			; p_type (PT_LOAD)
    (.i32	elf/PF_R)		; p_flags (read)
    (.i64	(- ro-data-segment-start file-start))	; p_offset
    (.i64	ro-data-segment-start)	; p_vaddr
    (.i64	0)			; p_paddr
    (.i64	ro-data-segment-size)	; p_filesz
    (.i64	ro-data-segment-size)	; p_memsz
    (.i64	4)			; p_align

    ;; writable data segment
    (.i32	1)			; p_type (PT_LOAD)
    (.i32	(+ elf/PF_R elf/PF_W))	; p_flags (read, write)
    (.i64	(- data-segment-start file-start))	; p_offset
    (.i64	data-segment-start)	; p_vaddr
    (.i64	0)			; p_paddr
    (.i64	data-segment-size)	; p_filesz
    (.i64	data-segment-size)	; p_memsz
    (.i64	4)			; p_align

code-segment-start
    ;; print message (syscall write)
    ;; rax = syscall number (1), rdi = fd, rsi = buf, rdx = count
    (MOVQir	1 _RAX)			; write (syscall #1)
    (MOVQir	1 _RDI)			; fd, stdout
    (MOVQir	msg _RSI)
    (MOVQir	msglen _RDX)
    (SYSCALL)

    ;; write into the data segment: var = var - 42
    (XORQrr	_RAX _RAX)
    (MOVQir	exit-code _RBX)
    (ADDQim	-42 0 _RBX _RAX 1)
    ;; (NOP)
    ;; (MOVQir -42 _RAX)
    ;; (ADDQrm _RAX exit-code 0 0 0)

    ;; exit: rax = 60, rdi = status
    (MOVQir	exit-code _RDI)		; exit code into rdi
    (MOVQmr	0 _RDI 0 0 _RDI)
    (MOVQir	60 _RAX)		; exit syscall (60)
    (SYSCALL)

    (.align elf/page-size)		; 64 bit elf loader is more strict: it won't set the X bit if it's not aligned
    (.def	code-segment-size (- $ file-start))

ro-data-segment-start
msg
    (.ascii	"Hello, world! From an ELF64 binary!\n")
    (.def	msglen (- $ msg))
    (.def	ro-data-segment-size (- $ ro-data-segment-start))

data-segment-start
exit-code
    (.i64	42)
    (.def	data-segment-size (- $ data-segment-start))))

(print "writing elf buffer to ")

(buffer-save asm-buffer (println "./build/test-elf.x86-64"))

(assemble '(
	(MOVQir	1 _RAX)				; write (syscall #1)
	(MOVQir	2 _RDI)				; stderr (fd 2)
	(MOVQir	msg _RSI)			; buffer
	(MOVQir	msglen _RDX)			; strlen(buffer)
	(SYSCALL)
	(RET)
msg	(.ascii	"*** Test output from running the dynamically compiled asm code\n")
	(.def	msglen (- $ msg))))

(print "writing runtime buffer to ")

(buffer-save asm-buffer (println "./build/runtime-buffer.x86-64"))

(println "calling memory buffer, output should follow")

(define-function buffer->function (buf)
  (make <target-function>
    (program-code	(<buffer>-elements buf))))

(call-x86-64-machine-code (buffer->function asm-buffer))

(assemble '(
	(MOVQir	1 _RAX)				; write
	(MOVQir	1 _RDI)				; stdout
	(MOVQir	msg _RSI)			; buffer
	(MOVQir	msglen _RDX)			; strlen(buffer)
	(SYSCALL)
	(MOVQir	60 _RAX)			; exit
	(MOVQir	0 _RDI)				; status
	(SYSCALL)
msg	(.ascii	"*** You may run ./build/test-elf.x86-64 now for a friendly greeting\n")
	(.def	msglen (- $ msg))))

(println "calling it, output should follow")

(call-x86-64-machine-code (buffer->function asm-buffer))

(println "it shouldn't have returned!!!")
