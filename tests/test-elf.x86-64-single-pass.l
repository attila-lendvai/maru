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
;;  - ELF64 header size = 64, program header size = 56
;;  - Syscall args in rdi, rsi, rdx, r10, r8, r9 (we use rdi/rsi/rdx here).

(require "source/assembler/x86-single-pass.l")
(require "source/c/cgrov.l")
(require-cgrov "source/platforms/linux/linux")
(require-cgrov "source/platforms/linux/elf")

(define elf/page-size	0x1000) ; is this the system page-size?
(define ideal-cache-line-alignment 64)

(assert (= elf/sizeof-Elf64_Ehdr 64))
(assert (= elf/sizeof-Elf64_Phdr 56))

;; its role is to encode the intention when an upcoming flabel will fill this hole
(define hole 0)

(define-function emit-program-header (flags start end alignment)
  (.i32		1)				; p_type (PT_LOAD)
  (.i32		flags)				; p_flags (read, exec)
  (.i64		(flabel start (- pself (plabel 'file-start))))	; p_offset (file offset)
  (.i64		(flabel start))			; p_vaddr (virtual addr of segment) - base
  (.i64		0)				; p_paddr
  (.i64		(flabel end (- pself (plabel start))))	; p_filesz
  (.i64		(flabel end (- pself (plabel start))))	; p_memsz
  (.i64		alignment))			; p_align

(define-form syscall (sys-number . args)
  `(begin
    (MOVQir32	,sys-number _RAX)
    ,@(map (lambda (arg reg)
             ;; this being a macro opens the possibility for automatic
             ;; opcode selection based on the provided arg.
             `(MOVQir	,arg ,reg))
           args '(_RDI _RSI _RDX _R10 _R8 _R9))
    (SYSCALL)))

(define-function write-elf-file (filename)
  (begin-assembling)

  (.base	0x00400000)             ; typical 64-bit default base
  (label!	'file-start)

  ;;;
  ;;; ELF header
  ;;;
  (.i8		0x7f)			; ident[0]
  (.ascii	"ELF")
  (.i8		elf/ELFCLASS64 elf/ELFDATA2LSB 1 elf/ELFOSABI_NONE) ; version
  (.i8		0 0 0 0 0 0 0 0) ; EI_ABIVERSION and padding (total 16 ident bytes)
  (.i16		elf/ET_EXEC)     ; e_type
  (.i16		elf/EM_X86_64)   ; e_machine
  (.i32		1)               ; e_version
  (.i64		(flabel 'code-segment-start))                  ; e_entry (entry point)
  (.i64		(flabel	'program-headers (- self (label 'file-start)))) ; e_phoff	Start of program headers (file offset)
  (.i64		0)                ; e_shoff	Start of section headers
  (.i32		0)                ; e_flags
  (.i16		(flabel 'elf-header-end (- self (label 'file-start)))) ; e_ehsize	Size of this header
  (.i16		elf/sizeof-Elf64_Phdr) ; e_phentsize	Size of program header entry
  (.i16		3)           ; e_phnum	Number of program headers
  (.i16		0)           ; e_shentsize	Size of section header
  (.i16		0)           ; e_shnum	Number of section headers
  (.i16		0)           ; e_shstrndx	Section header string table index
  (flabel!	'elf-header-end)

  ;;;
  ;;; Program headers (segment layout)
  ;;;
  (flabel!	'program-headers)

  ;; code segment
  (emit-program-header (+ elf/PF_R elf/PF_X)
                       'code-segment-start 'code-segment-end
                       elf/page-size)

  ;; read-only data segment
  (emit-program-header elf/PF_R
                       'ro-data-segment-start 'ro-data-segment-end
                       ideal-cache-line-alignment)

  ;; writable data segment
  (emit-program-header (+ elf/PF_R elf/PF_W)
                       'data-segment-start 'data-segment-end
                       ideal-cache-line-alignment)

  ;;;
  ;;; Code Segment
  ;;;
  (when false
    ;; It's also possible to set a new .base, but then we must ensure
    ;; that this ELF invariant holds: `p_offset % p_align == p_vaddr %
    ;; p_align`, i.e. that mmap can be used to map from the file to
    ;; the memory.
    (.align	elf/page-size)
    (.base	0x00500000))

  (flabel!	'code-segment-start)

  ;; print message
  (syscall linux/SYS_write linux/STDOUT_FILENO
           (flabel 'msg) (flabel 'msg-end (- self (label 'msg))))

  ;; test writing into the data segment: turn EXIT-CODE into 0
  ;;(LEAQmr	(flabelr 'exit-code) 0 0 0 _RBX)
  (MOVQir	(flabel 'exit-code) _RBX)
  (ADDQim	-2 0 _RBX 0 0) ; [rbx] += -2
  (SUBQim	40 0 _RBX 0 0) ; [rbx] -= 40

  (LEAQmr	(flabelr 'exit-code) 0 0 0 _RDI) ; exit code address
  ;;(MOVQir	(flabel 'exit-code) _RDI) ; exit code address
  (MOVQmr	0 _RDI 0 0 _RDI)          ; exit code into %rdi (syscall arg 2)
  (syscall	linux/SYS_exit)

  (.align	elf/page-size) ; 64 bit elf loader is more strict: it won't set the X bit if it's not aligned

  (flabel!	'code-segment-end)

  ;;;
  ;;; Data Segment -- Read Only
  ;;;
  (flabel!	'ro-data-segment-start)
  (flabel!	'msg)
  (.ascii	"Hello, world! From an ELF64 binary generated in a single pass!\n")
  (flabel!	'msg-end)
  (flabel!	'ro-data-segment-end)

  ;;;
  ;;; Data Segment
  ;;;
  (flabel!	'data-segment-start)
  (flabel!	'exit-code)
  (.i64		42)
  (flabel!	'data-segment-end)

  (println "writing elf buffer to "filename)
  (save-assembler-buffer *assembler* filename)
  (println (concat-strings "*** You may run "filename" now for a friendly greeting")))

(write-elf-file "./build/test-elf.x86-64-single-pass")
