;;;
;;; NOTE: this is mostly obsolete, look at the single-pass version instead
;;;

;; ELF stuff:
;; stack, argc, argv, envs: https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;; https://github.com/tonyg/pi-nothing/blob/4b2b59d42babd72cfd007cb71ed295dcdbf53d4a/nothingc/elf.rkt
;; https://interrupt.memfault.com/blog/gnu-binutils
;; man elf
;; /usr/include/linux/elf.h
;; https://cirosantilli.com/elf-hello-world
;; man 8 ld-linux.so
;; https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
;; embedding user data into elf: https://www.matheusmoreira.com/articles/self-contained-lone-lisp-applications


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

(require "source/assembler/x86-traditional.l")
(require "source/c/cgrov.l")
(require-cgrov "source/platforms/linux/elf")

(define elf/page-size	0x1000)
(define base-address	0x00400000)

(assemble
  '((.base	base-address) ; typical 64-bit default base
file-start
    (.u8	0x7f)			; ident[0]
    (.ascii	"ELF")
    (.u8	2 1 1 0)		; ELFCLASS64, ELFDATA2LSB, version, ELFOSABI_NONE
    (.u8	0 0 0 0 0 0 0 0)	; EI_ABIVERSION and padding (total 16 ident bytes)
    (.u16	2)			; e_type (ET_EXEC = 2)
    (.u16	62)			; e_machine (EM_X86_64 = 62)
    (.u32	1)			; e_version
    (.u64	code-segment-start)	; e_entry (entry point)
    (.u64	(- program-headers file-start))	; e_phoff	Start of program headers (file offset)
    (.u64	0)			; e_shoff	Start of section headers
    (.u32	0)			; e_flags
    (.u16	elf-header-size)	; e_ehsize	Size of this header (ELF64_Ehdr = 64)
    (.u16	program-header-size)	; e_phentsize	Size of program header entry (ELF64_Phdr = 56)
    (.u16	3)			; e_phnum	Number of program headers
    (.u16	0)			; e_shentsize	Size of section header
    (.u16	0)			; e_shnum	Number of section headers
    (.u16	0)			; e_shstrndx	Section header string table index
    (.def	elf-header-size (- $ file-start))
program-headers
    ;; code segment (PT_LOAD)
    (.u32	elf/PT_LOAD)		; p_type
    (.u32	(+ elf/PF_R elf/PF_X))	; p_flags (read, exec)
    (.u64	0)			; p_offset (file offset)
    (.u64	base-address)		; p_vaddr (virtual addr of segment) - base
    (.u64	0)			; p_paddr
    (.u64	code-segment-size)	; p_filesz
    (.u64	code-segment-size)	; p_memsz
    (.u64	elf/page-size)		; p_align
    (.def	program-header-size (- $ program-headers))

    ;; read-only data segment
    (.u32	elf/PT_LOAD)		; p_type
    (.u32	elf/PF_R)		; p_flags (read)
    (.u64	(- ro-data-segment-start file-start))	; p_offset
    (.u64	ro-data-segment-start)	; p_vaddr
    (.u64	0)			; p_paddr
    (.u64	ro-data-segment-size)	; p_filesz
    (.u64	ro-data-segment-size)	; p_memsz
    (.u64	4)			; p_align

    ;; writable data segment
    (.u32	elf/PT_LOAD)		; p_type
    (.u32	(+ elf/PF_R elf/PF_W))	; p_flags (read, write)
    (.u64	(- data-segment-start file-start))	; p_offset
    (.u64	data-segment-start)	; p_vaddr
    (.u64	0)			; p_paddr
    (.u64	data-segment-size)	; p_filesz
    (.u64	data-segment-size)	; p_memsz
    (.u64	4)			; p_align

code-segment-start
    ;; print message (syscall write)
    ;; rax = syscall number (1), rdi = fd, rsi = buf, rdx = count
    (MOVQir	1 RAX)			; write (syscall #1)
    (MOVQir	1 RDI)			; fd, stdout
    (MOVQir	msg RSI)
    (MOVQir	msglen RDX)
    (SYSCALL)

    ;; write into the data segment: var = var - 42
    (XORQrr	RAX RAX)
    (MOVQir	exit-code RBX)
    (ADDQim	-42 0 RBX RAX 1)
    ;; (NOP)
    ;; (MOVQir -42 _RAX)
    ;; (ADDQrm _RAX exit-code 0 0 0)

    ;; exit: rax = 60, rdi = status
    (MOVQir	exit-code RDI)		; exit code into rdi
    (MOVQmr	0 RDI 0 0 RDI)
    (MOVQir	60 RAX)		; exit syscall (60)
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
    (.u64	42)
    (.def	data-segment-size (- $ data-segment-start))))

(let ((filename "./build/test-elf.x86-64.traditional"))
  (println "writing elf buffer to "filename)
  (save-assembler-buffer *assembler* filename)
  (println (concat-strings "*** You may run "filename" now for a friendly greeting")))
