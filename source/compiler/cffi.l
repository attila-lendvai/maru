;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/sequences-basic.l")

;;; Shared-object soname we depend on (DT_NEEDED), where the externals
;;; live. x86-64 linux uses glibc's libc.so.6; Android names it libc.so
;;; (future per-platform config).
(define +libc-soname+ "libc.so.6")
(define *libc-soname-offset* 0) ; byte offset of +libc-soname+ in .dynstr

;;;
;;; External C symbols imported into the generated binary
;;;
;;; Each entry is a <external-symbol> record, keyed by the foreign
;;; symbol name (a string). The loader (ld.so) resolves them at load
;;; time; we emit the matching .dynsym/.dynstr/.gnu.hash entries and
;;; R_*_GLOB_DAT relocations (see emit-relocation-tables and the FFI
;;; call-site codegen in elf-late.l).
(define-record <external-symbol> ()
  (name			; foreign symbol name, a string
   dynsym-index		; index into .dynsym (1-based: 0 is the null symbol)
   name-offset		; byte offset of name in .dynstr
   got-label		; <label> of the GOT cell (in data), filled by R_*_GLOB_DAT
   trampoline-label	; <label> of the code trampoline (functions only)
   ))

(define *external-symbols* ())

(define-function find-external-symbol (name)
  (list-find-if (lambda (e)
                  (= name (<external-symbol>-name e)))
                *external-symbols*))

(define-function register-external-symbol (name)
  (or (find-external-symbol name)
      (let ((entry (make <external-symbol> (name name))))
        (push *external-symbols* entry)
        entry)))

;;;
;;; .dynstr/.dynsym emission
;;;

(define-function emit-dynstr ()
  (label! '.dynstr)
  (.i8 0)
  (let ((offset 1))
    (list-do entry *external-symbols*
      (set (<external-symbol>-name-offset entry) offset)
      (.ascii (<external-symbol>-name entry))
      (.i8 0)
      (incr offset (+ 1 (string-length (<external-symbol>-name entry)))))
    ;; only add a DT_NEEDED entry when there are externals to resolve
    (when (pair? *external-symbols*)
      (set *libc-soname-offset* offset)
      (.ascii +libc-soname+)
      (.i8 0)))
  (label! '.dynstr-end))

(define-function emit-dynsym ()
  (.align elf/alignof-Elf64_Sym)
  (label! '.dynsym)
  (.i64 0 0 0) ; the null symbol (see elf/sizeof-Elf64_Sym)
  (let ((index 1))
    (list-do entry *external-symbols*
      (set (<external-symbol>-dynsym-index entry) index)
      ;; Elf64_Sym: st_name, st_info, st_other, st_shndx, st_value, st_size
      ;; st_info = (STB_GLOBAL << 4) | STT_FUNC
      (.i32 (<external-symbol>-name-offset entry))
      (.i8 (+ (bitwise-shift elf/STB_GLOBAL 4) elf/STT_FUNC))
      (.i8 0)
      (.i16 elf/SHN_UNDEF)
      (.i64 0 0)
      (incr index))))

;;; DT_GNU_HASH. We only ever import externals (all SHN_UNDEF) and
;;; export nothing, so no symbol ever lands in the table: the loader
;;; requires a valid, non-NULL gnu-hash for startup lookup (musl
;;; >=1.2.4 looks up "malloc" in every loaded dso; gnu_lookup derefs
;;; dso->ghashtab). An all-empty table makes such lookups fail cleanly.
(define-function emit-gnu-hash ()
  (label! 'gnu-hash)
  ;; nbuckets, symoffset, bloom_size (words), bloom_shift
  (.i32 1 1 1 0)
  (.i64 0)			; bloom filter (one 64-bit word, empty)
  (.i32 0))			; buckets (one bucket, empty -> lookup fails)

;;; FFI: emit the trampolines for the externals that got referenced
;;; through external-trampoline-label; their bytes are emitted here
;;; after the code pass. The jump through the GOT cell is
;;; backend-specific (see cffi-late.l).
