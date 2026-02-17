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

(require "source/assembler/x86-single-pass.l")

;; ELF flags
(define elf/PF_R	0x4)
(define elf/PF_W	0x2)
(define elf/PF_X	0x1)
(define elf/page-size	0x1000)
(define base-address	0x00400000)

;; its role is to encode the intention when an upcoming flabel will fill this hole
(define hole 0)

(define-function write-elf-file ()
  (begin-assembling)

  (.base	base-address)             ; typical 64-bit default base
  (label!	'file-start)
  (.i8		0x7f)			; ident[0]
  (.ascii	"ELF")
  (.i8		2 1 1 0) ; ELFCLASS64, ELFDATA2LSB, version, ELFOSABI_NONE
  (.i8		0 0 0 0 0 0 0 0) ; EI_ABIVERSION and padding (total 16 ident bytes)
  (.i16		2)               ; e_type (ET_EXEC = 2)
  (.i16		62)              ; e_machine (EM_X86_64 = 62)
  (.i32		1)               ; e_version
  (flabel .i64	'code-segment-start)                  ; e_entry (entry point)
  (flabel .i64	'program-headers (- self (label 'file-start))) ; e_phoff	Start of program headers (file offset)
  (.i64		0)                ; e_shoff	Start of section headers
  (.i32		0)                ; e_flags
  (flabel .i16	'elf-header-end (- self (label 'file-start))) ; e_ehsize	Size of this header (ELF64_Ehdr = 64)
  (flabel .i16	'program-header-end (- self (label 'program-headers))) ; e_phentsize	Size of program header entry (ELF64_Phdr = 56)
  (.i16		3)           ; e_phnum	Number of program headers
  (.i16		0)           ; e_shentsize	Size of section header
  (.i16		0)           ; e_shnum	Number of section headers
  (.i16		0) ; e_shstrndx	Section header string table index
  (flabel!	'elf-header-end)
  (flabel!	'program-headers)

  ;; code segment (PT_LOAD)
  (.i32		1)			; p_type (PT_LOAD)
  (.i32		(+ elf/PF_R elf/PF_X))	; p_flags (read, exec)
  (.i64		0)			; p_offset (file offset)
  (.i64		base-address) ; p_vaddr (virtual addr of segment) - base
  (.i64		0)          ; p_paddr
  (flabel .i64	'code-segment-end (- self (label 'file-start)))	; p_filesz
  (flabel .i64	'code-segment-end (- self (label 'file-start)))	; p_memsz
  (.i64		elf/page-size)		; p_align
  (flabel!	'program-header-end)

  ;; read-only data segment
  (.i32		1)			; p_type (PT_LOAD)
  (.i32		elf/PF_R)		; p_flags (read)
  (flabel .i64	'ro-data-segment-start (- self (label 'file-start))) ; p_offset
  (flabel .i64	'ro-data-segment-start)                ; p_vaddr
  (.i64		0)                                    ; p_paddr
  (flabel .i64	'ro-data-segment-end (- self (label 'ro-data-segment-start))) ; p_filesz
  (flabel .i64	'ro-data-segment-end (- self (label 'ro-data-segment-start))) ; p_memsz
  (.i64		4)                                    ; p_align

  ;; writable data segment
  (.i32		1)			; p_type (PT_LOAD)
  (.i32		(+ elf/PF_R elf/PF_W))	; p_flags (read, write)
  (flabel .i64	'data-segment-start (- self (label 'file-start))) ; p_offset
  (flabel .i64	'data-segment-start)                ; p_vaddr
  (.i64		0)                                 ; p_paddr
  (flabel .i64	'data-segment-end (- self (label 'data-segment-start))) ; p_filesz
  (flabel .i64	'data-segment-end (- self (label 'data-segment-start))) ; p_memsz
  (.i64		4)                                 ; p_align

  (flabel!	'code-segment-start)

  ;; print message (syscall write)
  ;; rax = syscall number (1), rdi = fd, rsi = buf, rdx = count
  (MOVQir	1 _RAX)			; write (syscall #1)
  (MOVQir	1 _RDI)			; fd, stdout
  (MOVQir	hole _RSI)
  (flabel .i64	'msg -8)  ; i.e. put msg into $ - 8 when its defined
  (MOVQir	hole _RDX)
  (flabel .i64	'msg-end -8 (- self (label 'msg)))
  (SYSCALL)

  ;; write into the data segment: var = var - 42
  (XORQrr	_RAX _RAX)
  (MOVQir	hole _RBX)
  (flabel .i64	'exit-code -8)
  (ADDQim	-42 0 _RBX _RAX 1)

  ;; exit: rax = 60, rdi = status
  (MOVQir	hole _RDI)		; exit code into rdi
  (flabel .i64	'exit-code -8)
  (MOVQmr	0 _RDI 0 0 _RDI)
  (MOVQir	60 _RAX)		; exit syscall (60)
  (SYSCALL)

  (.align elf/page-size) ; 64 bit elf loader is more strict: it won't set the X bit if it's not aligned

  (flabel!	'code-segment-end)

  (flabel!	'ro-data-segment-start)
  (flabel!	'msg)
  (.ascii	"Hello, world! From an ELF64 binary!\n")
  (flabel!	'msg-end)
  (flabel!	'ro-data-segment-end)

  (flabel!	'data-segment-start)
  (flabel!	'exit-code)
  (.i64		42)
  (flabel!	'data-segment-end)

  (let ((filename "./build/test-elf.x86-64-single-pass"))
    (println "writing elf buffer to "filename)
    (save-assembler-buffer *assembler* filename)))

(write-elf-file)

(define-function memory-buffer1 ()
  (begin-assembling)

  (MOVQir	1 _RAX)         ; write (syscall #1)
  (MOVQir	2 _RDI)         ; stderr (fd 2)
  (MOVQir	hole _RSI)       ; buffer
  (flabel .i64	'msg -8)
  (MOVQir	hole _RDX)    ; strlen(buffer)
  (flabel .i64	'msg-end -8 (- self (label 'msg)))
  (SYSCALL)
  (RET)

  (flabel!	'msg)
  (.ascii	"*** Test output from running the dynamically compiled asm code\n")
  (flabel!	'msg-end)

  (let ((filename "./build/runtime-buffer.x86-64-single-pass"))
    (println "writing runtime buffer to "filename)
    (save-assembler-buffer *assembler* filename))

  (println "calling memory buffer, output should follow")

  (call-x86-64-machine-code (assembler->function *assembler*)))

(memory-buffer1)

(define-function memory-buffer2 ()
  (begin-assembling)

  (MOVQir	1 _RAX)         ; write
  (MOVQir	1 _RDI)         ; stdout
  (MOVQir	hole _RSI)       ; buffer
  (flabel .i64	'msg -8)
  (MOVQir	hole _RDX)    ; strlen(buffer)
  (flabel .i64	'msg-end -8 (- self (label 'msg)))
  (SYSCALL)

  (MOVQir	60 _RAX)        ; exit
  (MOVQir	0 _RDI)         ; status
  (SYSCALL)

  (flabel!	'msg)
  (.ascii	"*** You may run ./build/test-elf.x86-64-single-pass now for a friendly greeting\n")
  (flabel!	'msg-end)

  (println "calling it, output should follow")

  (call-x86-64-machine-code (assembler->function *assembler*)))

(memory-buffer2)

(println "BUG: it shouldn't have returned!!!")
