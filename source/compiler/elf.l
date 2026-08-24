;;; -*- mode: lisp; coding: us-ascii -*-

;;; Shared ELF emission helpers for the x86-64 and aarch64 backends.

;; TODO this is neither in struct nor readelf print order...
(define-function emit-program-header (type file-offset file-size mem-size flags
                                           start alignment)
  (.i32	type)                           ; p_type
  (.i32	flags)                          ; p_flags
  (.i64	file-offset)                    ; p_offset - File offset
  (.i64	start)   ; p_vaddr (virtual addr of segment) - Virtual address
  (.i64	0)       ; p_paddr - ignored
  (.i64	file-size)                      ; p_filesz - Size in file
  (.i64	mem-size)                       ; p_memsz - Size in memory
  (.i64	alignment))

(define-function emit-section-header (name-offset type flags addr
                                      offset size link info addralign entsize)

  (.i32 name-offset)	; sh_name   - offset into .shstrtab
  (.i32 type)		; sh_type   - section type (SHT_*)
  (.i64 flags)		; sh_flags  - SHF_*
  (.i64 addr)		; sh_addr   - virtual address (if mapped)
  (.i64 offset)		; sh_offset - file offset
  (.i64 size)		; sh_size   - section size in bytes
  (.i32 link)		; sh_link   - index of related section
  (.i32 info)		; sh_info   - extra section info
  (.i64 addralign)	; sh_addralign - alignment requirement
  (.i64 entsize))	; sh_entsize - size of each entry (0 if not fixed-size)
