;;; -*- mode: lisp; coding: us-ascii -*-

;;; Machinery for emitting binaries that participate in the ELF
;;; relocation ecosystem (the relocatable-elf feature): the ET_DYN
;;; standalone image (externals resolved by ld.so at load time), and
;;; the ET_REL c-obj object file (externals and internal references
;;; resolved by the static linker; see C-obj/link-type in build.l).
;;;
;;; Dispatch between the two happens at expansion time on
;;; elf-emission-type, which load-platform.l defines before this
;;; file is loaded.

;; NOTE the reloc-type symbols are the arch-agnostic roles used by
;; the fixup emitters; the numbers come from the elf cgrov constants.
(define-function reloc-number (arch type)
  (cond
    ((= arch elf/EM_X86_64)
     (case type
       (pc32		elf/R_X86_64_PC32)
       (plt32		elf/R_X86_64_PLT32)
       (abs64		elf/R_X86_64_64)
       (symbol64	elf/R_X86_64_64)
       (else		(error "unknown x86-64 relocation type: "type))))
    ((= arch elf/EM_AARCH64)
     (case type
       (adr-prel-lo21	elf/R_AARCH64_ADR_PREL_LO21)
       (call26		elf/R_AARCH64_CALL26)
       (condbranch19	elf/R_AARCH64_CONDBR19)
       (jump26		elf/R_AARCH64_JUMP26)
       (abs64		elf/R_AARCH64_ABS64)
       (symbol64	elf/R_AARCH64_ABS64)
       (else		(error "unknown aarch64 relocation type: "type))))
    (else
     (error "relocations are not implemented for this architecture yet: "arch))))

;;;
;;; ET_DYN standalone image: relocations applied by ld.so at load time.
;;;
;;; Externals go through GOT cells filled by R_*_GLOB_DAT relocations,
;;; and internal data pointers through R_*_RELATIVE ones (the
;;; assembler-recorded abs64 holes).

(define-function emit-relocation-tables (reloc-type glob-dat-type)
  (with-current-segment 'ro-data
    (.align elf/alignof-Elf64_Rela)
    (label! '.rela.dyn)
    (let ((rela-count 0)
          (relative-count 0))
      (let ((code-segment		(get-segment 'code))
            (data-segment		(get-segment 'data))
            (ro-data-segment	(get-segment 'ro-data)))
        ;; .dynsym indices must be known before the GLOB_DAT relocs below
        (let ((index 1))
          (list-do entry *external-symbols*
            (set (<external-symbol>-dynsym-index entry) index)
            (incr index)))
        ;; the data words holding internal addresses (the CELL holes,
        ;; recorded by the assembler as abs64) are base-relative:
        ;; ld.so adds the load base to their addend. The other roles
        ;; (the pc-relative fixups) are position-independent by
        ;; encoding, they need no dynamic relocation.
        (list-do entry (list-reverse (<assembler>-relocations *assembler*))
          (let* ((segment	(first entry))
                 (paddress	(second entry))
                 (target	(third entry))
                 (type	(car (cdr (cddddr entry)))))
            (when (= type 'abs64)
              (assert (is <label> target))
              (assert (<label>-laddress target)
                      "unresolved label in a relocation: "(<label>-%name target))
              (let ((segment-base
                      ;; NOTE CASE would do something else for symbols... (they would get quoted due to self-evaluating-value?)
                      ;; FIXME clean this up
                      (cond
                        ((= segment code-segment)	+code-segment-address+)
                        ((= segment data-segment)	+data-segment-address+)
                        ((= segment ro-data-segment)	+ro-data-segment-address+)
                        (else (error "unexpected segment in .rela.dyn emission: "segment)))))
                ;; Elf64_Rela entry (3 cells):
                ;; 1. r_offset: byte offset in file where relocation applies (paddress + segment file offset)
                (.i64 (+ segment-base paddress))
                ;; 2. r_info: relocation type
                ;;    - R_AARCH64_RELATIVE = 1027 (base-relative)
                ;;    - R_X86_64_RELATIVE = 8     (base-relative)
                (.i64 reloc-type)
                ;; 3. r_addend: the addend resolves lazily, all labels
                ;; are defined by the time this table is emitted
                (.i64 (<label>-laddress target)))
              (incr rela-count)
              (incr relative-count))))
        ;; R_*_GLOB_DAT: resolve one imported symbol into its GOT cell
        (list-do entry *external-symbols*
          (.i64 (+ +data-segment-address+
                   (<label>-paddress (<external-symbol>-got-label entry))))
          ;; r_info = (dynsym-index << 32) | glob-dat-type
          (.i64 (bitwise-or (bitwise-shift (<external-symbol>-dynsym-index entry) 32)
                            glob-dat-type))
          (.i64 0)                ; r_addend
          (incr rela-count)))
      (label! '.rela.dyn-end)

      (emit-dynstr)
      (emit-dynsym)
      (emit-gnu-hash)

      ;; Dynamic Linking Metadata Table
      (label! '.dynamic)
      ;; Elf64_Dyn struct entries, which really are just (name, tag) tuples
      (when (pair? *external-symbols*)
        (.i64 elf/DT_NEEDED *libc-soname-offset*))
      (.i64 elf/DT_RELA		(laddress '.rela.dyn))
      (.i64 elf/DT_RELASZ	(* rela-count elf/sizeof-Elf64_Rela))
      (.i64 elf/DT_RELAENT	elf/sizeof-Elf64_Rela)
      ;; ld.so only fast-paths this many leading R_*_RELATIVE entries;
      ;; anything beyond must not be counted, or it asserts on GLOB_DAT
      (.i64 elf/DT_RELACOUNT	relative-count)
      (.i64 elf/DT_STRTAB	(laddress '.dynstr))
      (.i64 elf/DT_STRSZ	(- (laddress '.dynstr-end)
                                   (laddress '.dynstr)))
      (.i64 elf/DT_SYMTAB	(laddress '.dynsym))
      (.i64 elf/DT_SYMENT	elf/sizeof-Elf64_Sym)
      (.i64 elf/DT_GNU_HASH	(laddress 'gnu-hash))
      (.i64 elf/DT_NULL		0))
    (label! '.dynamic-end)))

;;;
;;; ET_REL c-obj: relocations applied by the static linker.
;;;
;;; All addresses in the sections are section-relative (the segments
;;; are assembled with a base of 0). Internal references are recorded
;;; against section symbols, external ones against UND symbols by
;;; name. The fixup holes were recorded by the assembler at emit time
;;; (see %record-relocation in single-pass.l).
;;;

(define +c-obj/.text-section-index+		1)
(define +c-obj/.rodata-section-index+		2)
(define +c-obj/.data-section-index+		3)
(define +c-obj/.bss-section-index+		4)
(define +c-obj/.rela-text-section-index+	5)
(define +c-obj/.rela-data-section-index+	6)
(define +c-obj/.rela-rodata-section-index+	7)
(define +c-obj/.symtab-section-index+		8)
(define +c-obj/.strtab-section-index+		9)
(define +c-obj/.shstrtab-section-index+		10)

;; the number of symbols that precede the locals: the null symbol and
;; the four section symbols (.text/.rodata/.data/.bss)
(define +c-obj/n-preceding-symbols+		5)

(define-function %c-obj-symbol-count ()
  (/ (segment-length '.symtab) elf/sizeof-Elf64_Sym))


(define-function %c-obj-section-index-of (segment)
  (cond
    ((= segment (get-segment 'code))	+c-obj/.text-section-index+)
    ((= segment (get-segment 'ro-data))	+c-obj/.rodata-section-index+)
    ((= segment (get-segment 'data))	+c-obj/.data-section-index+)
    ((= segment (get-segment 'bss))	+c-obj/.bss-section-index+)
    (else (error "relocation against an unexpected segment: "segment))))

;; The number of GLOBAL symbols in .symtab (the entry points and the
;; UND externals); .symtab's sh_info must point at the first of them.
(define *c-obj-n-global-symbols* 0)

;; Appends a GLOBAL UND Elf64_Sym for NAME, and returns its .symtab
;; index (0-based; the count *before* the append is the new symbol's
;; index).
(define-function %c-obj-emit-und-symbol (name)
  (let ((index (%c-obj-symbol-count)))
    (emit-symtab-entry (emit-strtab-entry name)
                       (+ (bitwise-shift elf/STB_GLOBAL 4)
                          elf/STT_FUNC)
                       0
                       elf/SHN_UNDEF
                       0
                       0)
    (incr *c-obj-n-global-symbols*)
    index))

;; Appends GLOBAL DEFINED Elf64_Sym entries for main and _start, so
;; that the C toolchain can find them (crt1.o and the linker's entry
;; point respectively).
(define-function c-obj/emit-defined-symbols names
  (list-do name names
    (awhen (%find-label (closure-code-label-desig name))
      (incr *c-obj-n-global-symbols*)
      (emit-symtab-entry (emit-strtab-entry (symbol->string name))
                         (+ (bitwise-shift elf/STB_GLOBAL 4)
                            elf/STT_FUNC)
                         0
                         (%c-obj-section-index-of (<label>-segment it))
                         (<label>-laddress it)
                         0))))

;; Appends one GLOBAL UND symbol per distinct external name recorded
;; in the fixup holes, and returns an alist of (name . symtab-index).
(define-function %c-obj-emit-und-symbols ()
  (let ((und-alist ()))
    (list-do entry (list-reverse (<assembler>-relocations *assembler*))
      (let ((target (third entry)))
        (when (is <reloc-symbol> target)
          (let ((name (<reloc-symbol>-name target)))
            (unless (list-find-if (lambda (entry)
                                    (= name (first entry)))
                                  und-alist)
              (set und-alist (cons (cons name (%c-obj-emit-und-symbol name))
                                   und-alist)))))))
    und-alist))

;; Serializes the recorded fixup holes into per-section .rela.*
;; segments. UND-ALIST maps external names to their .symtab indices.
(define-function c-obj/serialize-relocations (arch und-alist)
  (create-segment 'rela-text)
  (create-segment 'rela-data)
  (create-segment 'rela-rodata)
  (let ((code-segment		(get-segment 'code))
        (ro-data-segment	(get-segment 'ro-data))
        (data-segment		(get-segment 'data)))
    (list-do entry (list-reverse (<assembler>-relocations *assembler*))
      (let* ((hole-segment	(first entry))
             (hole-paddress	(second entry))
             (target		(third entry))
             (type		(car (cdr (cddddr entry))))
             (rela-segment	(cond
                                   ((= hole-segment code-segment)	'rela-text)
                                   ((= hole-segment data-segment)	'rela-data)
                                   ((= hole-segment ro-data-segment)	'rela-rodata)
                                   (else	(error "relocation hole in an unexpected segment: "hole-segment))))
             (symbol-index
               (typecase target
                 (<reloc-symbol>
                  (let ((entry (list-find-if (lambda (entry)
                                               (= (<reloc-symbol>-name target) (first entry)))
                                             und-alist)))
                    (or (and entry (cdr entry))
                        (error "UND symbol not found in the symbol table: "(<reloc-symbol>-name target)))))
                 (<label>
                  (assert (<label>-laddress target)
                          "unresolved label in a relocation: "(<label>-%name target))
                  (%c-obj-section-index-of (<label>-segment target)))
                 (else	(error "unexpected relocation target: "target))))
             (addend
               ;; the addend convention differs by architecture: on
               ;; x86-64 the place (P in S + A - P) is the fixup FIELD
               ;; and the cpu adds RIP = P + size, so A must carry the
               ;; -size; on aarch64 P is the instruction itself, which
               ;; cancels out of S + A - P, leaving A = the target.
               ;; Against an UND symbol S carries the address, so the
               ;; addend only holds the RIP adjustment (and zero for
               ;; the aarch64 pc-relative forms).
               (typecase target
                 (<reloc-symbol>
                  (case type
                    (plt32		-4)
                    ((adr-prel-lo21 jump26 call26 condbranch19 symbol64) 0)
                    (else		(error "unexpected relocation type against an external: "type))))
                 (<label>
                  (case type
                    (pc32		(- (<label>-laddress target) 4))
                    ((adr-prel-lo21 jump26 call26 condbranch19)
                     (<label>-laddress target))
                    ((abs64 symbol64)	(<label>-laddress target))
                    (else		(error "unexpected relocation type: "type))))
                 (else		(error "unexpected relocation target: "target)))))
        (with-current-segment rela-segment
          (.i64 hole-paddress)
          (.i64 (bitwise-or (bitwise-shift symbol-index 32)
                            (reloc-number arch type)))
          (.i64 addend))))))

;; The finalization that runs after the code pass, before the ELF
;; writer: the standalone image resolves its entry point and external
;; trampolines and emits its dynamic linking tables; the c-obj
;; exports main/_start, creates the UND symbols, and serializes its
;; relocations.
(define-function finalize-relocatable-emission (-c- arch reloc-type glob-dat-type)
  (if (= "c-obj" elf-emission-type)
      (begin
        (set *c-obj-n-global-symbols* 0)
        (c-obj/emit-defined-symbols 'main '_start)
        (c-obj/serialize-relocations arch (%c-obj-emit-und-symbols)))
    ;; the entry point wrapper needs main's label, which the
    ;; definition loop just defined, and the exit GOT cell must
    ;; exist before the reloc table
    (emit-entry-point-wrapper -c-)
    (emit-deferred-external-trampolines -c-)
    (emit-relocation-tables reloc-type glob-dat-type)))

;;;
;;; ELF writers
;;;

;;; ET_DYN standalone image. Moved here verbatim from elf-late.l when
;;; the relocatable-elf feature was split out of cffi; the section
;;; contents and the dynamic linking tables are emitted by
;;; emit-relocation-tables above.
(define-function write-standalone-elf-to-stream (stream arch)
  (.segment	'code)
  (.align	elf/page-size)

  (.segment	'data)
  (.align	elf/page-size)

  (.segment	'ro-data)
  (label!	'elf-interpreter-start)
  (.ascii	+ld.so-path+)
  (.i8		0)
  (label!	'elf-interpreter-end)

  (.align	elf/page-size)

  ;; we write this into a separate segment (instead of the code
  ;; segment), so that we can do this as the last step.
  (create-segment 'elf-prefix)
  (.segment 'elf-prefix)
  (.base 0) ; without this the laddress is random, which disrupts .align

;;;
;;; ELF header
;;;
  (emit-elf-header elf/ET_DYN arch
                   (closure-code-label '_start)
                   'program-headers
                   +n-program-headers+
                   'section-headers
                   +n-section-headers+
                   +.shstrtab-section-index+)

;;;
;;; Program headers (segment layout)
;;;
  (label! 'program-headers)

  ;; code segment
  (let* ((file-position		0)
         (file-offset/text	file-position)
         ;; the elf header is included into the code segment as per convention
         (size/text		(+ (segment-length 'code) +elf-prefix-size+))
         file-offset/ro-data
         size/ro-data
         file-offset/data
         size/data
         size/bss
         size/relocation-tables)

    ;; PT_PHDR
    (let ((size
            ;; TODO FIXME? this yields different values for the two sizes emitted. but why?
            ;; (label 'program-headers-end (- self (laddress 'program-headers)))
            ;; (label 'program-headers-end (- (laddress 'program-headers-end) (laddress 'program-headers)))
            (* +n-program-headers+
               elf/sizeof-Elf64_Phdr)))
      (emit-program-header elf/PT_PHDR
                           (paddress 'program-headers)
                           size size
                           elf/PF_R
                           8
                           (laddress 'program-headers)))

    ;; text segment
    (emit-program-header elf/PT_LOAD
                         file-offset/text
                         size/text size/text
                         (+ elf/PF_R elf/PF_X)
                         elf/page-size
                         +code-segment-address+
                         +code-segment-space+)
    (incr file-position size/text)

    ;; ro-data segment (must be last, because this will also mmap the )
    (set size/ro-data (segment-length 'ro-data))
    (set file-offset/ro-data file-position)
    (emit-program-header elf/PT_LOAD
                         file-offset/ro-data
                         size/ro-data size/ro-data
                         (+ elf/PF_R elf/PF_W)
                         elf/page-size
                         +ro-data-segment-address+
                         +ro-data-segment-space+)
    (incr file-position size/ro-data)

    ;; mark the entire ro-data segment to become read-only after
    ;; relocation is finished. note that it's possible to mark only a
    ;; subset of it using this extra PT_GNU_RELRO program header.
    (emit-program-header elf/PT_GNU_RELRO file-offset/ro-data
                         size/ro-data size/ro-data
                         elf/PF_R
                         elf/page-size
                         +ro-data-segment-address+)

    ;; data segment
    (set size/data (segment-length 'data))
    (set file-offset/data file-position)
    (emit-program-header elf/PT_LOAD
                         file-offset/data
                         size/data size/data
                         (+ elf/PF_R elf/PF_W)
                         elf/page-size
                         +data-segment-address+
                         +data-segment-space+)
    (incr file-position size/data)

    ;; BSS, aka zero-initialized data
    (set size/bss (segment-length 'bss))
    (when (= 0 size/bss)
      ;; zero is illegal, and not emitting is more trouble than just
      ;; setting it to 1.
      (set size/bss 1))
    (emit-program-header elf/PT_LOAD
                         file-position
                         0 size/bss
                         (+ elf/PF_R elf/PF_W)
                         elf/page-size
                         +bss-segment-address+
                         +bss-segment-space+)

    ;; PT_INTERP segment (dynamic linker path)
    ;; NOTE: PT_INTERP doesn't add file content - it references existing .rodata content
    (let ((interp-size (- (laddress 'elf-interpreter-end)
                          (laddress 'elf-interpreter-start))))
      (emit-program-header elf/PT_INTERP
                           (+ file-offset/ro-data
                              (paddress 'elf-interpreter-start))
                           interp-size interp-size
                           elf/PF_R
                           1
                           (laddress 'elf-interpreter-start)))

    (set size/relocation-tables (- (laddress '.dynamic-end)
                                   (laddress '.dynamic)))
    (emit-program-header elf/PT_DYNAMIC
                         (+ file-offset/ro-data
                            (paddress '.dynamic))
                         size/relocation-tables size/relocation-tables
                         elf/PF_R
                         8
                         (laddress '.dynamic))

  (label! 'program-headers-end)

  (label! 'section-headers)

;;;
;;; This is fragile for reordering, must be in sync with the
;;; +.*-section-index+ constants.
;;;

  ;; section #0 must be NULL
  (emit-section-header 0 0 0 0 0 0 0 0 0 0)

  ;; section #1
  (emit-section-header (emit-shstrtab-entry ".text")
                       elf/SHT_PROGBITS
                       (+ elf/SHF_ALLOC elf/SHF_EXECINSTR)
                       +code-segment-address+
                       file-offset/text
                       size/text
                       0 0 16 0)

  ;; section #2
  (emit-section-header (emit-shstrtab-entry ".rodata")
                       elf/SHT_PROGBITS
                       elf/SHF_ALLOC
                       +ro-data-segment-address+
                       file-offset/ro-data
                       size/ro-data
                       0 0 16 0)

  ;; section #3
  (emit-section-header (emit-shstrtab-entry ".data")
                       elf/SHT_PROGBITS
                       (+ elf/SHF_ALLOC elf/SHF_WRITE)
                       +data-segment-address+
                       file-offset/data
                       size/data
                       0 0 16 0)

  ;; section #4
  (emit-section-header (emit-shstrtab-entry ".bss")
                       elf/SHT_NOBITS
                       (+ elf/SHF_ALLOC elf/SHF_WRITE)
                       +bss-segment-address+
                       0
                       size/bss
                       0 0 16 0)

  ;; section #5: .dynamic
  (emit-section-header (emit-shstrtab-entry ".dynamic")
                       elf/SHT_DYNAMIC
                       (+ elf/SHF_ALLOC elf/SHF_WRITE)
                       (laddress '.dynamic)
                       (+ file-offset/ro-data
                          (paddress '.dynamic))
                       size/relocation-tables
                       +.dynstr-section-index+
                       0 8 elf/sizeof-Elf64_Dyn)

  ;; section #6: .rela.dyn
  (emit-section-header (emit-shstrtab-entry ".rela.dyn")
                       elf/SHT_RELA
                       (+ elf/SHF_ALLOC elf/SHF_WRITE)
                       (laddress '.rela.dyn)
                       (+ file-offset/ro-data
                          (paddress '.rela.dyn))
                       (- (laddress '.rela.dyn-end)
                          (laddress '.rela.dyn))
                       0 0 8 elf/sizeof-Elf64_Rela)

  ;; section #7: .dynstr
  (let ((name-offset		(emit-shstrtab-entry ".dynstr")))
    (emit-section-header name-offset
                         elf/SHT_STRTAB 0 0
                         (+ file-offset/ro-data
                            (paddress '.dynstr))
                         (- (laddress '.dynstr-end)
                            (laddress '.dynstr))
                         0 0 1 0))

  ;; section #8: .symtab
  (let ((size/symtab (segment-length '.symtab))
        (symtab-offset file-position))
    (emit-section-header (emit-shstrtab-entry ".symtab")
                         elf/SHT_SYMTAB
                         0 0
                         symtab-offset
                         size/symtab
                         +.strtab-section-index+
                         (/ size/symtab elf/sizeof-Elf64_Sym)
                         8
                         elf/sizeof-Elf64_Sym)
    (incr file-position size/symtab))

  ;; section #9: .strtab
  (let ((size/strtab (segment-length '.strtab)))
    (emit-section-header (emit-shstrtab-entry ".strtab")
                         elf/SHT_STRTAB 0 0
                         file-position
                         size/strtab 0 0 1 0)
    (incr file-position size/strtab))

  ;; section #10: .shstrtab
  (let* ((name-offset		(emit-shstrtab-entry ".shstrtab"))
         (size/shstrtab	(segment-length '.shstrtab)))
    (emit-section-header name-offset
                         elf/SHT_STRTAB 0 0
                         file-position
                         size/shstrtab
                         0 0 1 0))

  (assert (= (segment-length 'elf-prefix) +elf-prefix-size+))

  ;; we can start writing the file. note that the order must be in
  ;; sync with the headers above.
    (list-do name '(elf-prefix code ro-data data) ; bss data is discarded
      (write-segment-to-stream name stream))
    (list-do name '(.symtab .strtab .shstrtab)
      (write-segment-to-stream name stream))))

;;;
;;; ET_REL c-obj object file. The section contents were assembled with
;;; a base of 0, i.e. all laddresses are section-relative offsets.
;;;

(define +c-obj/sizeof-Elf64_Rela+	24)

;; The file layout in write order: (segment-name file-alignment).
;; .bss is NOBITS and carries no file content. The section header
;; table goes last.
(define +c-obj/section-layout+
  '((code		16)
    (ro-data		16)
    (data		16)
    (rela-text		8)
    (rela-data		8)
    (rela-rodata	8)
    (.symtab		8)
    (.strtab		1)
    (.shstrtab		1)))

(define-function %c-obj-register-section-names ()
  ;; pre-registers the section names in .shstrtab; must match the
  ;; names used by %c-obj-emit-section-headers exactly, so that the
  ;; layout (computed afterwards) sees the final .shstrtab size.
  ;; returns an alist of (name . shstrtab-offset)
  (let ((alist ()))
    (list-do name '(".text" ".rodata" ".data" ".bss"
                    ".rela.text" ".rela.data" ".rela.rodata"
                    ".symtab" ".strtab" ".shstrtab")
      (set alist (cons (cons name (emit-shstrtab-entry name))
                       alist)))
    alist))

(define +c-obj/shdr-table-size+		(* 11 elf/sizeof-Elf64_Shdr))

(define-function %c-obj-layout-entry (layout name)
  (list-find-if (lambda (entry)
                  (= name (first entry)))
                layout))

;; Appends zero bytes to the segments so that each section's content
;; starts exactly at its layout offset; the write loop can then write
;; the segments back to back with no padding.
(define-function %c-obj-align-segments (layout)
  (let ((cursor elf/sizeof-Elf64_Ehdr)
        (previous 'code))
    (list-do entry layout
      (let* ((name	(first entry))
             (offset	(second entry))
             (gap	(- offset cursor)))
        (when (< 0 gap)
          (with-current-segment previous
            (times-do gap
              (.i8 0))))
        (set previous name)
        (set cursor (+ offset (third entry)))))))

(define-function %c-obj-layout ()
  (let ((shstrtab-alist	(%c-obj-register-section-names))
        (layout		())
        (pos		elf/sizeof-Elf64_Ehdr))
    (list-do entry +c-obj/section-layout+
      (let* ((name	  (first entry))
             (alignment   (second entry))
             (size	  (segment-length name)))
        (set pos (align alignment pos))
        (push layout (list name pos size))
        (incr pos size)))
    ;; the shdr table goes last: push it as the final write-order entry
    (set pos (align 8 pos))
    (push layout (list 'shdr-table pos +c-obj/shdr-table-size+))
    (list (list-reverse! layout) shstrtab-alist)))

(define-function %c-obj-emit-section-headers (layout shstrtab-alist)
  ;; emits the section header table into the shdr-table segment; the
  ;; layout carries each section's file offset and size, and the
  ;; alist the .shstrtab offsets (the names were registered BEFORE
  ;; the layout was computed, so the table size is final)
  (create-segment 'shdr-table)
  (.segment 'shdr-table)
  (.base 0)

  (let ((name-offset (lambda (name)
                       (cdr (list-find-if (lambda (entry)
                                            (= name (first entry)))
                                          shstrtab-alist)))))
    (emit-section-header 0 0 0 0 0 0 0 0 0 0) ; section #0: NULL

    (emit-section-header (name-offset ".text")
                         elf/SHT_PROGBITS
                         (+ elf/SHF_ALLOC elf/SHF_EXECINSTR)
                         0 (second (%c-obj-layout-entry layout 'code)) (third (%c-obj-layout-entry layout 'code))
                         0 0 16 0)
    (emit-section-header (name-offset ".rodata")
                         elf/SHT_PROGBITS
                         elf/SHF_ALLOC
                         0 (second (%c-obj-layout-entry layout 'ro-data)) (third (%c-obj-layout-entry layout 'ro-data))
                         0 0 16 0)
    (emit-section-header (name-offset ".data")
                         elf/SHT_PROGBITS
                         (+ elf/SHF_ALLOC elf/SHF_WRITE)
                         0 (second (%c-obj-layout-entry layout 'data)) (third (%c-obj-layout-entry layout 'data))
                         0 0 16 0)
    (emit-section-header (name-offset ".bss")
                         elf/SHT_NOBITS
                         (+ elf/SHF_ALLOC elf/SHF_WRITE)
                         0 (second (%c-obj-layout-entry layout 'data)) (segment-length 'bss)
                         0 0 16 0)
    (emit-section-header (name-offset ".rela.text")
                         elf/SHT_RELA
                         elf/SHF_INFO_LINK
                         0 (second (%c-obj-layout-entry layout 'rela-text)) (third (%c-obj-layout-entry layout 'rela-text))
                         +c-obj/.symtab-section-index+
                         +c-obj/.text-section-index+
                         8 elf/sizeof-Elf64_Rela)
    (emit-section-header (name-offset ".rela.data")
                         elf/SHT_RELA
                         elf/SHF_INFO_LINK
                         0 (second (%c-obj-layout-entry layout 'rela-data)) (third (%c-obj-layout-entry layout 'rela-data))
                         +c-obj/.symtab-section-index+
                         +c-obj/.data-section-index+
                         8 elf/sizeof-Elf64_Rela)
    (emit-section-header (name-offset ".rela.rodata")
                         elf/SHT_RELA
                         elf/SHF_INFO_LINK
                         0 (second (%c-obj-layout-entry layout 'rela-rodata)) (third (%c-obj-layout-entry layout 'rela-rodata))
                         +c-obj/.symtab-section-index+
                         +c-obj/.rodata-section-index+
                         8 elf/sizeof-Elf64_Rela)
    (emit-section-header (name-offset ".symtab")
                         elf/SHT_SYMTAB
                         0 0
                         (second (%c-obj-layout-entry layout '.symtab)) (third (%c-obj-layout-entry layout '.symtab))
                         +c-obj/.strtab-section-index+
                         ;; sh_info: the index of the first GLOBAL symbol
                         (- (/ (segment-length '.symtab)
                               elf/sizeof-Elf64_Sym)
                            *c-obj-n-global-symbols*)
                         8 elf/sizeof-Elf64_Sym)
    (emit-section-header (name-offset ".strtab")
                         elf/SHT_STRTAB 0 0
                         (second (%c-obj-layout-entry layout '.strtab)) (third (%c-obj-layout-entry layout '.strtab))
                         0 0 1 0)
    (emit-section-header (name-offset ".shstrtab")
                         elf/SHT_STRTAB 0 0
                         (second (%c-obj-layout-entry layout '.shstrtab)) (third (%c-obj-layout-entry layout '.shstrtab))
                         0 0 1 0)))

(define-function write-c-obj-to-stream (stream arch)
  ;; the layout is computed first (all section contents are final at
  ;; this point), so the ELF header can use plain numbers instead of
  ;; label fixups
  (let* ((layout-and-alist (%c-obj-layout))
         (layout (first layout-and-alist))
         (shstrtab-alist (second layout-and-alist))
         (file-position elf/sizeof-Elf64_Ehdr))
    (%c-obj-emit-section-headers layout shstrtab-alist)
    (%c-obj-align-segments layout)

    (create-segment 'elf-prefix)
    (.segment 'elf-prefix)
    (.base 0)

    (emit-elf-header elf/ET_REL arch
                     0
                     0 0
                     (second (%c-obj-layout-entry layout 'shdr-table))
                     +n-section-headers+
                     +c-obj/.shstrtab-section-index+)

    (assert (= (segment-length 'elf-prefix) +elf-prefix-size+))

    ;; write the file; the layout carries the padded file offsets
    (write-segment-to-stream 'elf-prefix stream)
    (list-do entry layout
      (let* ((name	(first entry))
             (offset	(second entry))
             (size	(third entry)))
        ;; empty sections (e.g. .rela.* with no relocations) carry no
        ;; file content; writing their zero-length buffer would crash
        (unless (= 0 size)
          (write-segment-to-stream name stream))
        (incr file-position size)))))

(define-function write-relocatable-to-stream (stream arch)
  (if (= "c-obj" elf-emission-type)
      (write-c-obj-to-stream stream arch)
    (write-standalone-elf-to-stream stream arch)))
