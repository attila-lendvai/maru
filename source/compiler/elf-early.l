;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/compiler/emit-early.l")
(require "source/ansiterm.l")
(require "source/sequences-basic.l")
(require "source/files.l")

(require "source/c/cgrov.l")
(require-cgrov "source/platforms/linux/linux")
(require-cgrov "source/platforms/linux/elf")

(when-feature cffi
  (require "source/compiler/cffi.l"))

;;;
;;; Utils
;;;

(define-function align (alignment value)
  (bitwise-and (+ value (- alignment 1))
               (- alignment)))

;; TODO this is kludgey. why only this one, etc...
(define-constant target/cell-size/bytes (target-value target/cell-size/bytes))

;;;
;;; Operands
;;;

(define-function define-operand/make-setters (type-name fields)
  (when (pair? fields)
    (cons `(set (slot-value ,type-name ,(car fields) self) ,(car fields))
          (define-operand/make-setters type-name (cdr fields)))))

(define-form define-operand (name super . rest)
  (let* ((direct-slots	(pop rest))
         (type-name	(symbol->type-name name))
         (type		(eval `(define-record ,type-name ,(when super (symbol->type-name super))
                                 ,direct-slots)))
         (effective-slots (<record>-effective-slots type)))
    (assert (is <record> type))
    (eval `(define-function ,name ,effective-slots
             (let ((self (new ,type-name)))
               ,@(define-operand/make-setters type-name effective-slots)
               self)))
    (when rest
      `(define-print-method ,type-name (print-all -stream- ,@rest)))))

(define-operand REGISTER ()	(name index))
(define-operand LITERAL ()	(value)		"$"self.value)
;; we must be able to differenciate when a pointer points to a CELL to
;; be read (called GLOBAL-CELL), or when we need the pointer itself
;; (called GLOBAL-ADDR).
(define-operand GLOBAL-CELL ()	(address))
(define-operand GLOBAL-ADDR ()	(address))
(define-operand STACK-CELL ()	(offset))

(define-operand LI32 LITERAL)
(define-operand R32 REGISTER)

(define-operand GOT64 GLOBAL-CELL)     ; GOT = Global Offset Table (darwin)
(define-operand LI64 LITERAL)
(define-operand R64 REGISTER)

(define-operand STACK-PARAM STACK-CELL	()	self.offset"(bp)")

;;;
;;; Instruction infra
;;;

(define-generic emit-instruction)

(define-record <instruction> ()
  ;; TODO some of these slots are the same for all instances; they should reside on the type
  (regs
   has-input?
   n-regs
   produces-output?
   ))

(define-function %emit-form/mm-params (index types)
  (when (pair? types)
    (let ((param-name (string->symbol (concat-string "$" (number->string index)))))
      (cons (list (awhen (and (not (= (first types) '_))
                              (first types))
                    (symbol->type-name it))
                  param-name)
            (%emit-form/mm-params (+ index 1) (cdr types))))))

(define-function %emit-form/reg-accessor (index)
  (let ((var-name (string->symbol (concat-string "$reg" (number->string (+ index 1)))))
        (body `(array-at __regs__ ,index)))
    (list var-name () `((_) ',body))))

(define-function %emit-form/reg-accessors (index)
  (when (<= 0 index)
    (cons (%emit-form/reg-accessor index)
          (%emit-form/reg-accessors (- index 1)))))

(define-function %define-instruction/emit-forms (instr-name n-regs type-name emit-forms)
  (when (pair? emit-forms)
    (let* ((emit-form (first emit-forms))
           (args (first emit-form))
           (body (rest emit-form)))
      (cons `(define-multimethod emit-instruction (-c- (,type-name self) ,@(%emit-form/mm-params 1 args))
               ;;(println "; emitting " self)
               (let ((__regs__ (<instruction>-regs self)))
                 (with-forms (,@(%emit-form/reg-accessors (- n-regs 1)))
                   ,@body)))
            (%define-instruction/emit-forms instr-name n-regs type-name (rest emit-forms))))))

;; FIXME n-regs should be extracted from the definition
(define-form define-instruction/emit-forms (instr-name n-regs . emit-forms)
  `(let ()
     ,@(%define-instruction/emit-forms instr-name n-regs (symbol->type-name instr-name) emit-forms)))

;; (define-instruction name (has-input? n-regs produces-output?) emit-forms)
(define-form define-instruction (instr-name reg-spec . emit-forms)
  (let ((has-input?		(first reg-spec))
        (n-regs			(or (second reg-spec) 0))
        (produces-output?	(third reg-spec))
        (type-name		(symbol->type-name instr-name))
        (singleton-name		(concat-symbol instr-name '-instance)))
    `(let ()
       (define-record ,type-name <instruction> ())
       ;;(define-print-method ,type-name (print-all -stream- ,(symbol->string name)))
       (define ,singleton-name (make ,type-name
                                 (has-input?		,has-input?)
                                 (n-regs		',n-regs)
                                 (produces-output?	,produces-output?)))
       (define-function ,instr-name (regs)
         (if regs
             (make ,type-name
               (regs			regs)
               (has-input?		,has-input?)
               (n-regs			',n-regs)
               (produces-output?	,produces-output?))
           ,singleton-name))

       ,@(%define-instruction/emit-forms instr-name n-regs type-name emit-forms))))

;;;
;;; Instructions
;;;

(define-instruction COMMENT	()
  ((pair)			(apply print-all (concat-list
                                                  (list *debug-output* "; ")
                                                  $1))
                                ;; TODO this needs either an append
                                ;; with n args, or a smarter apply
                                (print-all *debug-output* "\n")))

;; The natural pointer/word size of the target.
(define-instruction CELL	()
  ((LI64)			(.i64 (<LITERAL>-value $1)))
  ;; the address is a <label>; emit-i64 records the abs64 hole for
  ;; the elf writers (R_*_RELATIVE standalone, R_*_64 in the c-obj)
  ((GLOBAL-ADDR)		(.i64 (<GLOBAL-ADDR>-address $1)))
  ((long)			(.i64 $1))
  )

;;;
;;; Elf emission
;;;

(define-constant +.text-section-index+		1)
;;(define-constant +.rodata-section-index+	2)
(define-constant +.data-section-index+		3)
(define-constant +.bss-section-index+		4)
;;(define-constant +.dynamic-section-index+	5)
;;(define-constant +.rela.dyn-section-index+	6)
(define-constant +.dynstr-section-index+	7)
;;(define-constant +.symtab-section-index+	8)
(define-constant +.strtab-section-index+	9)
(define-constant +.shstrtab-section-index+	10)

(define elf/page-size	0x1000) ; FIXME should this be the system page-size?
(define ideal-cache-line-alignment 64)

(assert (= elf/sizeof-Elf64_Ehdr 64))
(assert (= elf/sizeof-Elf64_Phdr 56))

;; TODO this is neither in struct nor readelf print order...
(define-function emit-program-header (type file-offset file-size mem-size flags
                                           alignment start . rest)
  (when rest
    (assert (<= file-size (first rest)) "emit-program-header: ran out of space"))
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

(define-function %emit-strtab-entry (segment-name str)
  (let (result)
    (with-current-segment segment-name
      (set result (current-paddress))
      (.ascii	(symbol->string str)) ; symbol->string is also ok for strings
      (.i8 0))
    result))

(define-function emit-shstrtab-entry (str)
  (%emit-strtab-entry '.shstrtab str))

(define-function emit-strtab-entry (str)
  (%emit-strtab-entry '.strtab str))

(define-function emit-symtab-entry (name-offset info other section-index
                                                value size)
  (with-current-segment '.symtab
    (.i32 name-offset)		; st_name: offset into .strtab
    ;; upper 4 bits: binding (STB_*)
    ;; lower 4 bits: type (STT_*)
    (.i8  info)			; st_info: bind/type (e.g. STT_FUNC, STB_GLOBAL)
    (.i8  other)		; st_other: visibility (usually 0)
    (.i16 section-index)	; st_shndx: section index (.text, etc.)
    (.i64 value)		; st_value: address of symbol
    (.i64 size)))		; st_size: size of symbol in bytes

(define-function emit-symtab-entry/variable (name section-index value size)
  ;; LOCAL: module-internal names must not collide at c-obj link time
  ;; (the env may hold shadowed bindings); only main/_start and the
  ;; UND externals are global (see relocatable-elf.l)
  (emit-symtab-entry (emit-strtab-entry name)
                     (+ (bitwise-shift elf/STB_LOCAL 4)
                        elf/STT_OBJECT)
                     0
                     section-index
                     value
                     target/cell-size/bytes))

(define-function emit-symtab-entry/function (name value size)
  ;; see the LOCAL note in emit-symtab-entry/variable
  (emit-symtab-entry (emit-strtab-entry name)
                     (+ (bitwise-shift elf/STB_LOCAL 4)
                        elf/STT_FUNC)
                     0
                     +.text-section-index+
                     value
                     size))
