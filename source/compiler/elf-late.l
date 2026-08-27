;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; Compiling lambdas
;;;

(define-function compile/expression-to-operand (expr -c-)
  (cond
    ((and (variable? expr)
          ;; TODO we should handle global variables, too.
          (let ((x (<variable>-value expr)))
            (or (is <STACK-CELL>	x)
                (is <LI64>		x)
                (is <LI32>		x))))
     ;; (let ((value (<variable>-value expr)))
     ;;   (print-all *debug-output* "*** matched: "expr"="value", type:" (type-of value) "\n")
     ;;   value)
     (<variable>-value expr))

    ((long? expr)
     (LI64 expr))

    (else
     ;; (when (variable? expr)
     ;;   (let ((value (<variable>-value expr)))
     ;;     (assert (global-variable? expr))
     ;;     (print-all *debug-output* "*** matched: "expr"="value", type:" (type-of value) "\n")
     ;;     value))
     (comp expr))))

(define-function compile/expr-into-temp-or-literal (expr -c-)
  (cond
    ((long? expr)
     (LI64 expr))
    (else
      (comp expr)
      (let ((temp (alloc-stack-temp -c-)))
        (emit STORE $ temp)
        temp))))

(define-function compile-call-to-global-function (op -c-)
  (if (feature redefinable-functions-in-target)
      (let ()
        (comp op)
        (compile-call-to-<target-function> -c-))
    (emit CALL (closure-code-label (<variable>-name op))))
  ())

(define-method compile-call-to <expr> (op -c-)
  ;; NOTE the fact that a literal <expr> is found in a variable's
  ;; value slot at compile time implies that it's a global definition.
  (compile-call-to-global-function op -c-)
  (expr-n-required-parameters self))

;; this case is handled early in compile-call
;; (define-method compile-call-to <pair> (op -c-)
;;   (comp op)
;;   (compile-call-to-<target-function> -c-))

(define-method compile-call-to (slave-value <selector>) (op -c-)
  (compile-call-to-global-function op -c-)
  ;; TODO extract and return n-params
  ())

;;;
;;; Special Forms
;;;

(define-function compile/expressions-into-temp (prog -c-)
  (assert (pair? prog) "compile/expressions-into-temp: prog is empty or not a list") ; this is against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  ;; NOTE it's tempting here to check for single-element prog's, and
  ;; turning them into a compile/expression, but our single caller,
  ;; namely sf/let, requires a temp location, even when
  ;; initialized to literal values.
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-stack-temp -c-)))
    (emit STORE $ temp)
    temp))

(define-function %let-binding (binding comp)
  ;; we unconditionally initialize empty bindings to () to avoid hidden bugs,
  ;; at a small cost of initializing temp locations even when it wouldn't be necessary.
  ;; TODO cleanup! expand now brings let bindings to a normal form (to ease encode's job). think this through...
  (unless (pair? binding)
    (set binding (list binding ())))
  (unless (cdr binding)
    (set binding (list (car binding) ())))
  (let ((var (car binding))
        (tmp (compile/expressions-into-temp (cdr binding) comp)))
    (assert (= (type-of var) <variable>) "compile/let-binding: encountered a non-variable: " var)
    (set (<variable>-value var) tmp)))

(define-function sf/let (expr -c-)
  (let ((temps (map-with %let-binding (caddr expr) -c-)))
    (list-do stmt (cdddr expr)
      (comp stmt))
    (free-temps temps)))

(define-function sf/set (expr -c-)
  (let* ((var	(second expr))
         (value	(<variable>-value var)))
    (accessible-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ((or (is <STACK-CELL> value)
           (is <R64> value))
       (emit STORE $ value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (error "TODO <C-variable>")
       ;; (emit STORE $ ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
       ;;             (EXTERNAL-LABEL (<C-variable>-name value))))
       )
      (else
       (emit STORE $ (GLOBAL-CELL (label (<variable>-name var))))))))

(define-function sf/address-of (expr -c-)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (cond
        ((global-variable? var)
         (emit ADDR (GLOBAL-CELL (label (<variable>-name var)))))
        ((is <STACK-CELL> val)
         (emit ADDR val))
        ;; ((is <R64> val)
        ;;  (maybe-spill-params -c-)
        ;;  (emit ADDR (<variable>-value var)))
        (else
         (error "address-of: don't know how to compile for variable " var ", holding the value " val))))))

(define-function sf/and (expr -c-)
  (let ((done (label)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (emit BF $ done)))
    (label! done)))

(define-function sf/or (expr -c-)
  (let ((done (label)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (emit BT $ done)))
    (label! done)))

(define-function sf/if (expr -c-)
  (let ((condition	(second expr))
        (then		(third expr))
        (else		(cdddr expr))
        (l/false	(label))
        (l/end		(label)))
    (comp condition)
    ;; the current-value from the condition is false when we jump to
    ;; the else branch, therefore we don't need to clear the
    ;; current-value when the else branch is empty.
    (emit BF $ l/false)
    (comp then)
    ;; therefore, we can just fall through with the return value of
    ;; the true branch when the else branch is empty.
    (when else
      (emit BR l/end))
    (label! l/false)
    (list-do stmt else
      (comp stmt))
    (label! l/end)))

(define-function sf/while (expr -c-)
  (let ((l/body	(label))
        (l/cond	(label))
        (body	(cddr expr)))
    (when body ; only need to skip it at first if there's any at all
      (emit BR l/cond))
    (label! l/body)
    (list-do stmt body
      (and stmt (comp stmt)))
    (label! l/cond)
    (comp (second expr))
    (emit BT $ l/body)))

(define-function sf/return (expr -c-)
  (list-do stmt (cdr expr)
    (comp stmt))
  (emit BR (or (<compiler>-fn-epilogue-label -c-)
               (set (<compiler>-fn-epilogue-label -c-) (label)))))

(define-function sf/lambda (form -c-)
  (let ((expr (eval form)))
    (emit LOAD (compile-expr expr () -c-))))

(define-function sf/C-string (expr -c-)
  (assert (= (list-length expr) 2))
  (emit LOAD (emit-object/C-string (second expr) -c-)))

(define *special-forms* (list
  (cons (target-value let)		sf/let)
  (cons (target-value and)		sf/and)
  (cons (target-value or)		sf/or)
  (cons (target-value if)		sf/if)
  (cons (target-value while)		sf/while)
  (cons (target-value set)		sf/set)
  (cons (target-value lambda)		sf/lambda)
  (cons (target-value return)		sf/return)
  (cons (target-value address-of)	sf/address-of)
  (cons (target-value C-string)		sf/C-string)
  (cons (target-value stack-pointer-on-entry) sf/stack-pointer-on-entry)
  ))

;;;
;;; Special Operators
;;;

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  ;; FIXME we shouldn't need to instantiate the instructions here...
  (let ((instr (op ())))
    (if (<instruction>-has-input? instr)
        (emit op $)
      (emit op))))

;; FIXME? these implement a right-to-left evaluation order, while
;; function calls implement the opposite. note that this is entangled
;; with e.g. the LOAD/STORE instructions above, as they expect arg0 to
;; be loaded in %rax.
(define-function compile/binary-operator (op args -c-)
  (let ((tmp (compile/expr-into-temp-or-literal (cadr args) -c-)))
    (comp (car args))
    (free-temp tmp)
    (let ((instr (op ())))
      (if (<instruction>-has-input? instr)
          (emit op $ tmp)
        (emit op tmp)))))

(define-function compile/ternary-operator (op args -c-)
  (let ((tmp2 (compile/expr-into-temp-or-literal (third  args) -c-))
        (tmp1 (compile/expr-into-temp-or-literal (second args) -c-)))
    (comp (car args))
    (free-temp tmp1)
    (free-temp tmp2)
    (let ((instr (op ())))
      (if (<instruction>-has-input? instr)
          (emit op $ tmp1 tmp2)
        (emit op tmp1 tmp2)))))

(define +operator-compilers+ (list->array (list () compile/unary-operator compile/binary-operator compile/ternary-operator)))

;; a vector of assoc lists indexed by operator arity
(define *special-operators*
    (let ((table
           `(;; nullary
             ()
             ;; unary
             ((-  ,NEGATE) (not ,LOGIC-NOT) (bitwise-not ,BITWISE-NOT))
             ;; binary
             ((+  ,ADD) (-   ,SUB) (* ,MULTIPLY) (/ ,DIVIDE)
              (bitwise-and ,AND) (bitwise-or ,OR) (bitwise-xor ,XOR)
              (<  ,LT ) (<=  ,LE ) (= ,EQ ) (>= ,GE) (> ,GT) ; (!= ,NE)
              (arithmethic-shift-left ,ASL) (arithmethic-shift-right  ,ASR)
              (char-at		,LOAD-I8)
              (byte-at		,LOAD-I8)
              ,@(when-at-expand (feature lower/array)
                  `((cell-at	,LOAD-CELL)))
              (oop-at		,LOAD-OOP)
             )
             ;; ternary
             ((set-char-at	,STORE-I8)
              (set-byte-at	,STORE-I8)
              ,@(when-at-expand (feature lower/array)
                  `((set-cell-at ,STORE-CELL)))
              (set-oop-at	,STORE-OOP)
             ))))
      (list->array
       (map (lambda (arity-line)
              (map (lambda (entry)
                     (let* ((op-name (car entry))
                            (op (eval-in-target op-name)))
                       (assert op "operator not found while building *special-operators* "op)
                       (cons op (cdr entry))))
                   arity-line))
            table))))

(define-method compile <pair> (-c-)
  (let* ((op		(first self))
         (op-is-a-var?	(variable? op))
         (op-value	(if op-is-a-var?
                            (or (<variable>-value op)
                                (error "error: calling undefined function: "op))
                          op))
         (args		(rest self))
         (arity		(list-length args))
         (handler	()))
    (emit-comment 2 "call of op: "op", op-is-a-var? "op-is-a-var?", args: " args)
    ;; TODO add compiler-macros. use them to optimize stuff on the lisp semantic level
    (cond
      ((set handler (second (assq op-value (array-at *special-operators* arity))))
       (emit-comment 3 "found op "op" in *special-operators*, handler: "handler)
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((is <fixed> op)
       (let ((handler (cdr (assq op *special-forms*))))
         (emit-comment 3 "op is a <fixed>: "op", handler: "handler)
         (or handler (error "No handler for fixed form: " self))
         (handler self -c-)))
      (else
       (compile-call-form op args -c-)))))

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (is <R64> value)
           (is <LI64> value)
           (is <STACK-CELL> value)
           (is <STACK-PARAM> value))
       (emit LOAD value))
      ((global-variable? self)
       (cond
         ((= 'true self.name)
          (emit LOAD (LI64 (target-value true))))
         ((subtype? (type-of value) <type>)
          (emit LOAD (LI64 (eval-in-slave `(<type>-slave-id ,value)))))
         ((is <C-function> value) ; handles the situation when e.g. libc/strcmp is passed as a comparator fn for array-binary-search
          (error "TODO <C-function>")
          ;;(emit LOAD (EXTERNAL-LABEL (<C-function>-name value)))
          )
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (error "TODO <C-variable>")
          ;; (emit LOAD ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
          ;;            (EXTERNAL-LABEL (<C-variable>-name value))))
          )
         ((and (not (feature redefinable-functions-in-target))
               (is <expr> value))
          (emit LOAD (GLOBAL-ADDR (label self.name))))
         (else
          (emit LOAD (GLOBAL-CELL (label self.name))))))
      (else
       (error "don't know how to compile <variable>: " self ", holding the value: "value", type: "(type-of value))))))

(define-method compile <long> (-c-)
  ;; FIXME: We can't call COMPILE-OBJECT here, because that would box
  ;; the value. But then why the lack of symmetry with <string> and
  ;; other literals in the code (they are emitted as full heap objects)?
  (emit LOAD (LI64 self)))

;;;
;;; COMPILE-DEFINITION
;;;

;; TODO a lot of this is the same in the 32 bits
(define-method compile-definition <type>		(name -c-)	) ; we don't need (target-value <type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition (target-value false) name -c-))
(define-method compile-definition <C-function>		(name -c-)	) ; it will be handled at the call site
(define-method compile-definition <C-variable>		(name -c-)	) ; it will be handled at the site of reference

(define-method compile-definition <long> (name -c-)
  (with-current-segment (if (= 0 self) 'bss 'data)
    (label! name)
    (emit-symtab-entry/variable name
                                (if (= 0 self) +.bss-section-index+ +.data-section-index+)
                                (current-laddress)
                                +word-size-in-bytes+)
    (emit CELL self)))

;; kinda KLUDGE
;; this is used when emitting the literal dispatch tables of <selectors>
;; FIXME merge this somehow into the compile-object protocol?
;; this, and the whole emit-object business is kinda KLUDGEy
(define-function compile-array (self -c-)
  (let ((compiled (array (array-length self))))
    (for (i 0 (array-length self))
      (let ((obj (array-at self i)))
        (set (array-at compiled i)
             (typecase obj
               (<long>		(compile-object obj -c-))
               (<expr>		(compile-expr   obj () -c-))
               (<undefined>	(compile-object obj -c-))
               (else (error "compile-array: don't know how to compile: "obj))))))
    compiled))

(define-method compile-definition <array> (name -c-)
  (let ((compiled (compile-array self -c-)))
    (with-current-segment 'data
      (label! name)
      (emit-symtab-entry/variable name
                                  +.data-section-index+
                                  (current-laddress)
                                  +word-size-in-bytes+)
      (array-do el compiled
        (emit CELL el)))))

(define-method compile-definition <expr> (name -c-)
  (assert name)
  (let ((object-label (compile-expr self name -c-)))
    (when (feature redefinable-functions-in-target)
      (with-current-segment 'data
        (label! name)
        (emit CELL object-label)))))

;;;
;;; Emitting Elf
;;;

(define-constant +n-program-headers+ 8)
(define-constant +n-section-headers+ 11)
(define-constant +elf-prefix-size+ (+ elf/sizeof-Elf64_Ehdr
                                      (* +n-program-headers+
                                         elf/sizeof-Elf64_Phdr)
                                      (* +n-section-headers+
                                         elf/sizeof-Elf64_Shdr)))

(define-constant +code-segment-address+		0x00000000)
(define-constant +code-segment-space+		0x00040000)

(define-constant +ro-data-segment-address+	(+ +code-segment-address+	+code-segment-space+))
(define-constant +ro-data-segment-space+	0x00020000)

(define-constant +data-segment-address+		(+ +ro-data-segment-address+	+ro-data-segment-space+))
(define-constant +data-segment-space+		0x00020000)

(define-constant +bss-segment-address+		(+ +data-segment-address+	+data-segment-space+))
(define-constant +bss-segment-space+		0xffffffff) ; there's space for plenty of nothing at the end...

(define-function write-elf-to-stream (stream arch)
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
  (.i16		elf/ET_DYN)      ; e_type
  (.i16		arch)            ; e_machine
  (.i32		1)               ; e_version
  (.i64		(closure-code-label '_start)) ; e_entry (entry point)
  (.i64		(label 'program-headers	(- self (laddress 'elf-header-start)))) ; e_phoff	Start of program headers (file offset)
  (.i64		(label 'section-headers	(- self (laddress 'elf-header-start)))) ; e_shoff	Start of section headers
  (.i32		0)               ; e_flags
  (.i16		(label 'elf-header-end	(- self (laddress 'elf-header-start)))) ; e_ehsize	Size of this header
  (.i16		elf/sizeof-Elf64_Phdr) ; e_phentsize	Size of program header entry
  (.i16		+n-program-headers+)   ; e_phnum	Number of program headers
  (.i16		elf/sizeof-Elf64_Shdr) ; e_shentsize	Size of section header
  (.i16		+n-section-headers+)   ; e_shnum	Number of section headers
  (.i16		+.shstrtab-section-index+) ; e_shstrndx	Section header string table index
  (label!	'elf-header-end)

  (assert (= (- (laddress 'elf-header-end) (laddress 'elf-header-start)) elf/sizeof-Elf64_Ehdr))

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

    ;; section #0 must be NULL
    (emit-section-header 0 0 0 0 0 0 0 0 0 0)

;;;
;;; This is fragile for reordering, must be in sync with the
;;; +.*-section-index+ constants.
;;;

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

    )

  ;; we can start writing the file. note that the order must be in
  ;; sync with the headers above.
  (list-do name '(elf-prefix code ro-data data ; bss is discarded
                  .symtab .strtab .shstrtab)
    (write-segment-to-stream name stream)))

(define-function emit-relocation-tables (reloc-type)
  (with-current-segment 'ro-data
    (.align elf/alignof-Elf64_Rela)
    (label! '.rela.dyn)
    (let ((rela-count 0))
      (let ((code-segment		(get-segment 'code))
            (data-segment		(get-segment 'data))
            (ro-data-segment	(get-segment 'ro-data)))
        (list-do entry (list-reverse *rela-entries*)
          (let* ((segment	(first entry))
                 (paddress	(second entry))
                 (addend	(third entry))
                 (segment-base
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
            ;; 3. r_addend: constant addend for relocation (0 for pure relative)
            (.i64 addend
                  ;;(+ segment-base paddress)
                  ))
          (incr rela-count)))
      (label! '.rela.dyn-end)

      (label! '.dynstr)
      (.i8 0)
      (label! '.dynstr-end)

      (.align elf/alignof-Elf64_Sym)
      (label! '.dynsym)
      (.i64 0 0 0) ; TODO better express elf/sizeof-Elf64_Sym number of zero bytes

      ;; minimal SysV hash table for the dummy symbol above (nbucket,
      ;; nchain, one empty bucket, one terminating chain entry). musl
      ;; >=1.2.4 unconditionally looks up "malloc" in every loaded dso
      ;; during startup, and its sysv_lookup derefs dso->hashtab; a
      ;; symtab without a hash table crashes the process there.
      (label! 'dt-hash)
      (.i32 1 1 0 0)

      ;; Dynamic Linking Metadata Table
      (label! '.dynamic)
      ;; Elf64_Dyn struct entries, which really are just (name, tag) tuples
      (.i64 elf/DT_RELA		(laddress '.rela.dyn))
      (.i64 elf/DT_RELASZ	(* rela-count elf/sizeof-Elf64_Rela))
      (.i64 elf/DT_RELAENT	elf/sizeof-Elf64_Rela)
      (.i64 elf/DT_RELACOUNT	rela-count)
      (.i64 elf/DT_STRTAB	(laddress '.dynstr))
      (.i64 elf/DT_STRSZ	1)
      (.i64 elf/DT_SYMTAB	(laddress '.dynsym))
      (.i64 elf/DT_SYMENT	elf/sizeof-Elf64_Sym)
      (.i64 elf/DT_HASH		(laddress 'dt-hash))
      (.i64 elf/DT_NULL		0))
    (label! '.dynamic-end)))

(define-function compile-env (env -c- output-path machine-type reloc-type)
  (verbosity 1
    (warn "begin compiling env with "(array-length (<env>-bindings env))" definitions\n\n")
    (map (lambda (sym)
           (warn (symbol->string sym)"	"(eval-in-slave sym)"\n"))
         '(+operating-system+ +architecture+ +little-endian?+
           +word-size-in-bits+
           ;;oop/alignment-in-bytes oop/align-padding
           ;;oop/payload-mask oop/tag-mask
           )))
  (comment-features)
  (emit-prelude -c-)
  ;; NOTE this array-do will not pick up any new definitions added to
  ;; the env after the iterations has begun (see e.g. the
  ;; COMPILE-DEFINITION of <selector>).
  (with-assembling (((code	(+ +code-segment-address+
                                   +elf-prefix-size+))
                     (ro-data	+ro-data-segment-address+)
                     (data	+data-segment-address+)
                     (bss	+bss-segment-address+)
                     (.shstrtab	0)
                     (.symtab	0)
                     (.strtab	0)))

    (.segment	'.shstrtab)
    (.i8	0)				; mandated by the elf standard

    (.segment	'.strtab)
    (.i8	0)				; mandated by the elf standard

    (.segment	'.symtab)
    (emit-symtab-entry 0 0 0 0 0 0)		; mandated by the elf standard

    ;; This is the default segment, and whoever changes it should make
    ;; sure changes it back by using WITH-CURRENT-SEGMENT,
    ;; WITH-NEW-LABEL, or similar constructs.
    (.segment 'code)

    (array-do var (<env>-bindings env)
      (let* ((name		(<variable>-name  var))
             (value		(<variable>-value var))
             (type-blacklist	(list <form> <fixed>))
             (name-blacklist	'()))
        (unless (or (member? (type-of value) type-blacklist)
                    (member? name name-blacklist))
          ;; (emit-comment 1 "defn "name)
          (verbosity 1 (warn name ", "))
          (compile-definition value name -c-))))

    (emit-relocation-tables reloc-type)

    (with-open-file (file output-path "w")
      (write-elf-to-stream (file-stream file) machine-type))

    (when (<= 1 *compiler-verbosity*)
      (array-do var (<env>-bindings (<assembler>-env *assembler*))
        (let ((value (<variable>-value var)))
          (when (is <label> value)
            (emit COMMENT (list "0x"(integer->string (<label>-laddress value) 16)
                                "\t" (<variable>-name var))))))))
  (verbosity 1 (warn "\n")))
