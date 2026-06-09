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

(require "source/assembler/single-pass-x86.l")
(require "source/c/cgrov.l")
(require-cgrov "source/platforms/linux/linux")
(require-cgrov "source/platforms/linux/elf")

(define elf/page-size	0x1000) ; is this the system page-size?
(define ideal-cache-line-alignment 64)

(assert (= elf/sizeof-Elf64_Ehdr 64))
(assert (= elf/sizeof-Elf64_Phdr 56))

;; its role is to encode the intention when an upcoming future label will fill this hole
(define hole 0)

(define-form syscall (sys-number . args)
  `(begin
    (MOVQi32r	,sys-number RAX)
    ,@(map (lambda (arg reg)
             ;; this being a macro opens the possibility for automatic
             ;; opcode selection based on the provided arg.
             `(MOVQir	,arg ,reg))
           args '(RDI RSI RDX R10 R8 R9))
    (SYSCALL)))		; p_align - Alignment constraint for both p_offset and p_vaddr

;; FIXME broken when enabled, the loader segfaults
(define *dynamic?* true)

(define +n-segments+ 4)
(define +n-program-headers+ (+ +n-segments+
                               (if *dynamic?* 2 0)))
(define +elf-prefix-size+ (+ elf/sizeof-Elf64_Ehdr
                             (* +n-program-headers+
                                elf/sizeof-Elf64_Phdr)))
(define +code-segment-address+		0x00400000)
(define +ro-data-segment-address+	0x00500000)
(define +data-segment-address+		0x00600000)
(define +bss-segment-address+	0x00700000)

(define-function emit-program-header (type file-offset file-size mem-size flags
                                                  start alignment)
  (.i32	type)                    ; p_type
  (.i32	flags)                          ; p_flags
  (.i64	file-offset)                    ; p_offset - File offset
  (.i64	start)   ; p_vaddr (virtual addr of segment) - Virtual address
  (.i64	0)       ; p_paddr - ignored
  (.i64	file-size)                      ; p_filesz - Size in file
  (.i64	mem-size)                       ; p_memsz - Size in memory
  (.i64	alignment))

(define-function emit-program-header/segment (file-offset file-size mem-size flags
                                                          start alignment)
  (emit-program-header elf/PT_LOAD file-offset file-size mem-size flags
                       start alignment))

(define-function write-elf-to-stream (stream)
  (println "assembling the elf header")

  (assert (and (string? +ld.so-path+) (< 0 (string-length +ld.so-path+))))

  (when *dynamic?*
    (.segment 'ro-data)
    (label! 'elf/interpreter-start)
    (.ascii +ld.so-path+)
    (.i8 0)
    (label! 'elf/interpreter-end)

    (let ((empty-string (label!)))
      (.i8 0)
      (.segment 'ro-data)
      (.align 8)
      (label! 'elf/dynamic-table-start)
      (.i64 elf/DT_STRTAB empty-string)
      (.i64 elf/DT_SYMTAB 0)
      (.i64 elf/DT_NULL 0)
      (label! 'elf/dynamic-table-end)))

  (.segment 'data)
  (.align	elf/page-size)

  (.segment 'ro-data)
  (.align	elf/page-size)

  (create-segment 'elf-prefix)
  (.segment 'elf-prefix)
  (.base 0) ; without this the laddress is random, which disrupts .align

;;;
;;; ELF header
;;;
  (label!	'elf-header-start)
  (.i8		0x7f)                   ; ident[0]
  (.ascii	"ELF")
  (.i8		elf/ELFCLASS64 elf/ELFDATA2LSB 1 elf/ELFOSABI_NONE) ; version
  (.i8		0 0 0 0 0 0 0 0) ; EI_ABIVERSION and padding (total 16 ident bytes)
  (.i16		elf/ET_EXEC)     ; e_type
  (.i16		elf/EM_X86_64)   ; e_machine
  (.i32		1)               ; e_version
  (.i64		(label 'code-segment-start)) ; e_entry (entry point)
  (.i64		(label 'program-headers (- self (laddress 'elf-header-start)))) ; e_phoff	Start of program headers (file offset)
  (.i64		0)                  ; e_shoff	Start of section headers
  (.i32		0)                  ; e_flags
  (.i16		(label 'elf-header-end (- self (laddress 'elf-header-start)))) ; e_ehsize	Size of this header
  (.i16		elf/sizeof-Elf64_Phdr) ; e_phentsize	Size of program header entry
  (.i16		+n-program-headers+)          ; e_phnum	Number of program headers
  (.i16		0)           ; e_shentsize	Size of section header
  (.i16		0)           ; e_shnum	Number of section headers
  (.i16		0)      ; e_shstrndx	Section header string table index
  (label!	'elf-header-end)

  (assert (= (- (laddress 'elf-header-end) (laddress 'elf-header-start)) elf/sizeof-Elf64_Ehdr))

;;;
;;; Program headers (segment layout)
;;;
  (label! 'program-headers)

  ;; code segment
  (let ((file-position	0))

    (let ((size (+ (segment-length 'code) +elf-prefix-size+)))
      (emit-program-header/segment file-position
                                   size size
                                   (+ elf/PF_R elf/PF_X)
                                   +code-segment-address+
                                   elf/page-size)
      (incr file-position size))

    ;; read-only data segment
    (let ((ro-data-segment-file-pos file-position))
      (let ((ro-data-size (segment-length 'ro-data)))
        (emit-program-header/segment file-position
                                     ro-data-size ro-data-size
                                     elf/PF_R
                                     +ro-data-segment-address+
                                     ideal-cache-line-alignment)
        (incr file-position ro-data-size))

     ;; writable data segment
     (let ((data-size (segment-length 'data)))
       (emit-program-header/segment file-position
                                    data-size data-size
                                    (+ elf/PF_R elf/PF_W)
                                    +data-segment-address+
                                    ideal-cache-line-alignment)
       (incr file-position data-size))

     ;; BSS, aka zero-initialized data
     (emit-program-header/segment file-position
                                  0 (segment-length 'bss)
                                  (+ elf/PF_R elf/PF_W)
                                  +bss-segment-address+
                                  ideal-cache-line-alignment)

     (when *dynamic?*
       (let ((len (- (laddress 'elf/interpreter-end)
                     (laddress 'elf/interpreter-start))))
         (emit-program-header elf/PT_INTERP
                              (+ ro-data-segment-file-pos
                                 (paddress 'elf/interpreter-start))
                              len len
                              elf/PF_R
                              (laddress 'elf/interpreter-start) 1)
         (incr file-position len))

       (let ((len (- (laddress 'elf/dynamic-table-end)
                     (laddress 'elf/dynamic-table-start))))
         ;; must point into a valid PT_LOAD area
         (emit-program-header elf/PT_DYNAMIC
                              (+ ro-data-segment-file-pos
                                 (paddress 'elf/dynamic-table-start))
                              len len
                              elf/PF_R
                              (laddress 'elf/dynamic-table-start) 1))))

    (write-segment-to-stream 'elf-prefix stream)
    (write-segment-to-stream 'code stream)
    (write-segment-to-stream 'ro-data stream)
    (write-segment-to-stream 'data stream)))

(define-function emit-print (text)
  ;; emit the text into the data segment, and emit machine code into
  ;; the code segment that prints it.
  (with-current-segment 'ro-data
    (let ((msg (label!))
          msg-end)
      (.ascii text)
      (set msg-end (label!))

      (.segment 'code)
      (syscall linux/SYS_write linux/STDOUT_FILENO
               msg (- (laddress msg-end)
                      (laddress msg))))))

(define-function emit-global-variable args
  (if args
      (with-new-label 'data
        (.i64 (first args)))
    (with-new-label 'bss
      (.i64 0))))

(define-function emit-base-lookup ()
  ;; NOTE AT_BASE is not set when it's not a dynamic elf

  ;; [argc]
  ;; [argv0] [argv1] ... [NULL]
  ;; [envp0] [envp1] ... [NULL]
  ;; [auxv0] [auxv1] ... [AT_NULL]
  (MOVQmr	0 RSP 0 0 RAX)          ; argc count
  (INCQr	RAX)                    ; skip argc itself also
  (LEAQmr	0 RSP RAX 8 RBX)        ; the null after the argv
  (MOVQmr	0 RSP RAX 8 RCX)        ; should be 0
  ;; skip through envp
  (let ((lp (label!)))
    (INCQr	RAX)
    (MOVQmr	0 RSP RAX 8 RCX)
    (TESTQrr	RCX RCX)
    (JNES	lp))
  ;; we reached at the aux vector
  (let ((lp (label!))
        (good (label)))
    (INCQr	RAX)
    (MOVQmr	0 RSP RAX 8 RCX)        ; a_type
    (TESTQrr	RCX RCX)
    (JNZS	good)

    (MOVQir	1 RDI)
    (syscall	linux/SYS_exit)

    (label!	good)
    (INCQr	RAX)                    ; skip the a_type
    (CMPQir	linux/AT_BASE RCX)
    (JNES	lp)
    (MOVQmr	0 RSP RAX 8 RCX)        ; the ld.so ELF address

    ;; TODO and now what? we would need to parse the ELF of the loader
    ;; at that address... but what for? if we're on the linux
    ;; platform, then no one should want to access C function with the
    ;; FFI. and if we are on a C based platform, then we might as well
    ;; use the C compiler to link a final ELF binary...
    ))

(define-function elf-test (filename)
  (println "assembling the code")
  (with-assembling (((code	(+ +code-segment-address+
                                   +elf-prefix-size+))
                     (ro-data	+ro-data-segment-address+)
                     (data	+data-segment-address+)
                     (bss	+bss-segment-address+)
                     interpreter))

    (label!	'code-segment-start)

    ;; TODO delme?
    (emit-base-lookup)

    (emit-print "Hello, world! From an ELF64 binary generated using multiple segments!\n")
    (emit-print "Just another emit-print entry for good measure\n")

    ;; test writing into the data segment: turn EXIT-CODE into 0
    (let ((l/exit-code (emit-global-variable 42)))
      ;;(LEAQmr	l/exit-code 0 0 0 _RBX) ; PIC version
      (MOVQir	l/exit-code RBX)       ; non-PIC version
      (ADDQim	-2 0 RBX 0 0)          ; [rbx] += -2
      (SUBQim	40 0 RBX 0 0)          ; [rbx] -= 40

      (LEAQmr	l/exit-code 0 0 0 RDI)
      ;;(MOVQir	l/exit-code _RDI)
      (MOVQmr	0 RDI 0 0 RDI) ; load exit code into %rdi (syscall arg 2)

      (let ((l/uninitialized (emit-global-variable)))
        (LEAQmr	l/uninitialized 0 0 0 RAX) ; should be a zero var
        (SUBQmr	0 RAX 0 0 RDI)) ; so, this shouldn't change rdi
      (syscall	linux/SYS_exit))

    (.align	elf/page-size)
    (label!	'code-segment-end)

    (let ((file (file-open-or-die filename "w")))
      (write-elf-to-stream (file-stream file))
      (file-close-or-die file))

    (println (concat-strings "*** You may run "filename" now for a friendly greeting"))))

(elf-test "./build/test-elf.x86-64.segments")
