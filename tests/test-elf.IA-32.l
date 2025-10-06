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

(require "source/assembler/x86.l")

;; Define simplified variants that pass () as buffer for each
;; generated instruction emitter, and writes directly into our global
;; variable (asm-buffer) in the _B function above.
(define-function movlIR (src dst)	(MOVLir src dst))
(define-function movlRM (src dst)	(MOVLrm src dst 0 0 0))
(define-function movlMR (src dst)	(MOVLmr src 0 0 0 dst))
(define-function movlRR (src dst)	(MOVLrr src dst))
(define-function inclR (dst)		(INCLr dst))
(define-function pushlI (src)		(PUSHLi src))
(define-function addlIR (src dst)	(ADDLir src dst))
(define-function addlRM (src dst)	(ADDLrm src dst 0 0 0))
(define-function sublIR (src dst)	(SUBLir src dst))
(define-function int (n)		(_B 0xCD) (_B n))

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
    (.ascii	"Hello, world! From an ELF32 binary!\n")
    (.def	msglen (- $ msg))
    (.def	ro-data-segment-size (- $ ro-data-segment-start))

data-segment-start
var
    (.i32	42)
    (.def	data-segment-size (- $ data-segment-start))))

(let ((filename "./build/test-elf.IA-32"))
  (println "writing elf buffer to "filename)
  (save-assembler-buffer *assembler* filename))

;; for details on int 0x80 and syscall see:
;; https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux
;; /usr/include/asm/unistd_32.h

;; TODO the next two doesn't print anything for me, even though the asm looks good in gdb
;; when i uncomment the crashing line to enter gdb.

;; NOTE stricter ASLR on newer kernels will make this sigsegv, unless disabled

(assemble '(
	(movlIR	4 _EAX)				; write
	(movlIR	2 _EBX)				; stderr
	(movlIR	msg _ECX)			; buffer
	(movlIR	msglen _EDX)			; strlen(buffer)
	(int	0x80)
	;;(movlRM	_EAX 0)				; crash! for testing...
	(RET)
msg	(.ascii	"*** Test output from running the dynamically compiled asm code\n")
	(.def	msglen (- $ msg))))

(let ((filename "./build/runtime-buffer.IA-32"))
  (println "writing runtime buffer to "filename)
  (save-assembler-buffer *assembler* filename))

(println "calling memory buffer, output should follow")

(call-IA-32-machine-code (assembler->function *assembler*))

(assemble '(
	(movlIR	4 _EAX)				; write
	(movlIR	1 _EBX)				; stdout
	(movlIR	msg _ECX)			; buffer
	(movlIR	msglen _EDX)			; strlen(buffer)
	(int	0x80)
	(movlIR	1 _EAX)				; exit
	(movlIR	0 _EBX)				; status
	(int	0x80)
msg	(.ascii	"*** You may run ./build/test-elf.IA-32 now for a friendly greeting\n")
	(.def	msglen (- $ msg))))

(println "calling it, output should follow")

(call-IA-32-machine-code (assembler->function *assembler*))

(println "BUG: it shouldn't have returned!!!")
