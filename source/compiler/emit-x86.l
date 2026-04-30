;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits IA-32 text, aka x86 assembly, that
;;; needs to be fed to the gcc toolchain.
;;;
;;; Status: it should successfully compile eval.l into eval.s,
;;; that in turn can be compiled by the gcc toolchain into an executable eval binary.
;;;

;;; TODO
;;;  - factor out the C ffi stuff into a separate file

;;; It can compile a subset of Maru.
;;;
;;; Limitations and peculiarities:
;;;   - no closures
;;;   - no variable number of args for functions
;;;   - some literal objects are emitted as valid objects that can participate
;;;     in the heap; see the EMIT-OBJECT methods for an up-to-date list.
;;;   - probaby more
;;;   - see *special-operators* and *special-forms* for the list of specially
;;;     handled constructs
;;;
;;; Naming:
;;;   - EMIT: emit instructions into the output stream
;;;   - GEN:  like EMIT, but collect instructions into a buffer for later emission
;;;   - -foo- is an implicit var in the lexenv
;;;   - +foo+ is a constant
;;;   - *foo* is a global

;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")
(require "source/c/cffi.l")
(require "source/ansiterm.l")
(require "source/assembler/x86-single-pass.l")

(require "source/c/cgrov.l")
(require-cgrov "source/platforms/linux/linux")
(require-cgrov "source/platforms/linux/elf")

(define *compiler-verbosity* 0)

;; TODO this is kludgey. why only this one, etc...
(define-constant +word-size-in-bytes+ (target-value +word-size-in-bytes+))

(define-constant +maru-label-prefix+ "m_")

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

;; forwards
(define compile-expr)
(define compile-env)
(define new-stack-cell)
(define %free-temp)

;;;
;;; Utils
;;;
(let ((counter 0))
  (define-function unique-name (prefix)
    (concat-string prefix (number->string (incr counter)))))

(define-function align (alignment value)
  (bitwise-and (+ value (- alignment 1))
               (- alignment)))

;; TODO this is naive, should also deal with varargs explicitly instead of just returning nil
(define-function expr-n-required-parameters (op)
  (let ((params		(<expr>-parameters op))
        (n-params	()))
    (cond
      ((not params))                   ; (lambda () ...)
      ((symbol? params))               ; (lambda args ...)
      ((pair? params)
       (set n-params 1)
       (while (pair? (set params (rest params)))
         (incr n-params))
       (when (symbol? params)          ; (lambda (arg1 . rest) ...)
         (set n-params ())))
      (else
       (error "expr-n-required-parameters: error parsing <expr> " op ", parameters " params)))
    n-params))

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

;;;
;;; compiler infrastructure
;;;

(define-record <compiler> ()
  (level
   temp-counter
   temp-limit
   free-stack-cells
   gen-buffer
   current-value              ; the output of the previous-instruction
   ))

(define-function new-temp-index (c)
  (with-instance-accessors c <compiler>
    (let ((i c.temp-counter))
      (incr c.temp-counter)
      (when (< c.temp-limit c.temp-counter)
        (set c.temp-limit c.temp-counter))
      i)))

(define-function alloc-stack-temp (-c-)
  (or (pop (<compiler>-free-stack-cells -c-))
      (new-stack-cell -c-)))

(define-function %free-temps (-c- temps)	(list-do temp temps (%free-temp -c- temp)))
(define-form free-temp (temp)			`(%free-temp -c- ,temp))
(define-form free-temps (temp)			`(%free-temps -c- ,temp))

(define-function accessible-variable-or-die (var -c-)
  (or (global-variable? var)
      (let ((comp-level	(<compiler>-level -c-))
            (var-level	(<env>-level (<variable>-env var))))
        (when (< var-level comp-level)
          (error "cannot access variable "var", closures are not yet supported by the compiler.")))))

;;;
;;; Early ELF stuff
;;;
(define-constant +.text-section-index+		1)
(define-constant +.data-section-index+		3)
(define-constant +.bss-section-index+		4)
(define-constant +.strtab-section-index+	6)
(define-constant +.shstrtab-section-index+	7)

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
  (emit-symtab-entry (emit-strtab-entry name)
                     (+ (bitwise-shift elf/STB_GLOBAL 4)
                        elf/STT_OBJECT)
                     0
                     section-index
                     value
                     +word-size-in-bytes+))

(define-function emit-symtab-entry/function (name value size)
  (emit-symtab-entry (emit-strtab-entry name)
                     (+ (bitwise-shift elf/STB_GLOBAL 4)
                        elf/STT_FUNC)
                     0
                     +.text-section-index+
                     value
                     size))

;;;
;;; Instructions
;;;

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
      ;; TODO what about dispatching on -c-?
      ;; (cons `(define-multimethod emit-instruction ((<llvm-compiler> -c-) (,type-name self) ,@(%emit-form/mm-params 1 args))
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
;;; Emission
;;;

(define-generic emit-instruction)

(define-form emit (instr-name . args)
  `(%emit -c- ,instr-name (list ,@(map (lambda (arg)
                                         (if (= '$ arg)
                                             '(<compiler>-current-value -c-)
                                           arg))
                                       args))))

(define-instruction COMMENT	()
  ;; just a default that can be redefined
  ((pair)			(print "; ") (apply println $1)))

;; this is faster than (emit COMMENT ...) by skipping the evaluation early
(define-form emit-comment (level . args)
  `(when (<= ,level *compiler-verbosity*)
     (emit COMMENT (list ,@args))))

(define-function %emit (-c- factory args)
  (let* ((instr (factory ())))
    (when (and (<= 3 *compiler-verbosity*)
               (not (is <COMMENT> instr)))
      ;; TODO move this into emit-instruction?
      (print-all *debug-output* "; EMIT of "instr", args: "args"\n"))
    (apply emit-instruction (cons -c- (cons instr args)))))

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit-comment 2 "COMPILE of "__obj__)
     ;;(assert (= (get-segment 'code) (current-segment)))
     (compile __obj__ -c-)
     (<compiler>-current-value -c-)))

;; only to accommodate for a vanilla emit-objects.l
(define gen emit)

(define-selector compile-object)
(define LOAD) ; forward
(define-selector compile (self -c-)
  (emit LOAD (compile-object self -c-)))
(define-selector compile-definition)
(define-selector compile-call-to)
(define-selector emit-prelude _) ; default is NOP

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

(define *special-forms*) ; forward
(define compile-call-form) ; forward

;; TODO ? introduce abstraction for ABIs...
(define-constant +call-frame-alignmet+
    (case (target-value +word-size-in-bits+)
      (32 (case (target-value +operating-system+)
            (darwin	16)
            (else	4)))
      (64 16)))

(define-constant +function-alignmet+ 16)

;; TODO use the grovelled __USER_LABEL_PREFIX__
;; (define-constant +external-label-prefix+
;;     (case (target-value +operating-system+)
;;       (darwin	"_")
;;       (else	"")))

(define-record <c-function-entry> ()
  (ptr-label
   stub-label))

(define-record <x86-compiler> <compiler>
  (param-offset
   arg-offset
   arg-limit
   asm-cell-type
   fn-epilogue-label
   c-function-entries
   ))

;;;
;;; OPERANDS
;;;

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

(define-operand STACK-PARAM STACK-CELL	()	self.offset"(%rbp)")

(with-forms
    ((x ((ctor . registers)
         (let ((index -1))
           `(begin
             ,@(map (lambda (reg)
                      (incr index)
                      ;; the op/ prefix stands for operand
                      `(define ,(concat-symbol 'op/ reg)
                         (,ctor ,reg ,index)))
                    registers))))))
  (x R32 EAX EBX ECX EDX ESP EBP ESI EDI)
  (x R64 RAX RBX RCX RDX RSP RBP RSI RDI R8 R9 R10 R11 R12 R13 R14 R15))

;;;
;;; INSTRUCTIONS
;;;

(define-instruction/emit-forms COMMENT 0
  ((pair)			(apply print-all (concat-list
                                                  (list *debug-output* "; ")
                                                  $1))
                                ;; TODO this needs either and append with n args or
                                ;; a smarter apply
                                (print-all *debug-output* "\n")))

;; The natural pointer/word size of the target.
(define-instruction CELL	()
  ((LITERAL)			(.i64 (<LITERAL>-value $1)))
  ((GLOBAL-ADDR)		(.i64 (<GLOBAL-ADDR>-address $1)))
  ((long)			(.i64 $1))
  )

(define-instruction BR		()
  ((label)			(JMPm $1 0 0 0)))

(define-instruction BF		(true 0 false)
  ((REGISTER label)		(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JE $2)))

(define-instruction BT		(true 0 false)
  ((REGISTER label)		(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JNE $2)))

(define-instruction CALL	(false 0 true)
  ((label)			(CALLQm $1 0 0 0)))

;; TODO merge into CALL?
(define-instruction CALLPTR	(true 0 false)
  ((REGISTER)			(CALLQr (<REGISTER>-name $1))))

(define-instruction ADD		(true 0 true)
  ((R32 STACK-CELL)		(ADDLmr (<STACK-CELL>-offset $2) ESP 0 0 (<REGISTER>-name $1)))
  ((R32 LI32)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= lit 0)
				    (ADDLir lit (<REGISTER>-name $1)))))
  ((R64 STACK-CELL)		(ADDQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= lit 0)
				    (ADDQir lit (<REGISTER>-name $1))))))

(define-instruction SUB		(true 0 true)
  ((R32 STACK-CELL)		(SUBLmr (<STACK-CELL>-offset $2) ESP 0 0 (<REGISTER>-name $1)))
  ;; TODO wtf? the order...
  ((R32 LI32)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= lit 0)
				    (SUBLir lit (<REGISTER>-name $1)))))
  ((R64 STACK-CELL)		(SUBQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ;; TODO wtf? the order...
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= lit 0)
				    (SUBQir lit (<REGISTER>-name $1))))))

;; TODO x86 mul operates on eax, which somehow needs to be encoded
;; into the instruction. same applies to div.
(define-instruction MUL		()
  ((STACK-CELL)			(MULQmr (<STACK-CELL>-offset $1) RBP 0 0 RAX))
  ((LI64)			(cond
                                  ((= 1 (<LITERAL>-value $1))) ; nothing to do
                                  ;; TODO emit shifts when possible
                                  (else
                                   (MOVQir (<LITERAL>-value $1) RCX)
                                   (MULQrr RCX RAX)))))

;; the x86 div instruction is unsigned division
(define-instruction DIV		()
  ((STACK-CELL)			(XORQrr RDX RDX)
                                (DIVQmr (<STACK-CELL>-offset $1) RBP 0 0 RAX))
  ((LI64)			(cond
                                  ((= 1 (<LITERAL>-value $1))
                                   ;; remainder is zero, %rax is unchanged
                                   (XORQrr RDX RDX))
                                  ;; TODO emit shifts when possible
                                  (else
                                   (XORQrr RDX RDX) ; the upper side of 64 bit operand
                                   (MOVQir (<LITERAL>-value $1) RCX) ; divisor
                                   (DIVQrr RCX RAX)))))

(define-instruction AND		(true 0 true)
  ((R64 STACK-CELL)		(ANDQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= -1 lit)
                                    (ANDQir lit (<REGISTER>-name $1))))))

(define-instruction OR		(true 0 true)
  ((R64 STACK-CELL)		(ORQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (ORQir lit (<REGISTER>-name $1))))))

;; TODO could be simplified with LI and TI base classes
(define-instruction XOR		(true 0 true)
  ((R64 STACK-CELL)		(XORQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (XORQir lit (<REGISTER>-name $1))))))

(define-instruction BITWISE-NOT	(true 0 true)
  ((REGISTER)			(NOTQr (<REGISTER>-name $1))))

(define-instruction LOGIC-NOT	(true 0 true)
  ((REGISTER)			(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (SETEr AL)
                                (MOVZBQrr AL (<REGISTER>-name $1))))

(define-instruction NEG		(true 0 true)
  ((REGISTER)			(NEGQr (<REGISTER>-name $1))))

(define-instruction ASL		(true 0 true)
  ((R64 STACK-CELL)		(MOVQmr (<STACK-CELL>-offset $2) RBP 0 0 RCX)
                                (SALQrr CL (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (SALQir lit (<REGISTER>-name $1))))))

(define-instruction ASR		(true 0 true)
  ((R64 STACK-CELL)		(MOVQmr (<STACK-CELL>-offset $2) RBP 0 0 RCX)
                                (SARQrr CL (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (SARQir lit (<REGISTER>-name $1))))))

(define-instruction ADDR	(false 0 true)
  ((GLOBAL-CELL)		(LEAQmr	(<GLOBAL-CELL>-address $1) 0 0 0 RAX))
  ;;((label)			(LEAQmr	$1 0 0 0 RAX))
  ((STACK-CELL)			(LEAQmr	(<STACK-CELL>-offset $1) RBP 0 0 RAX)))

(define-instruction MOVE	()
  ((LI64 STACK-CELL)		(MOVQim (<LITERAL>-value $1) (<STACK-CELL>-offset $2) RBP 0 0))
  ((LI64 R64)			(MOVQir (<LITERAL>-value $1) (<REGISTER>-name $2)))
  ((STACK-CELL STACK-CELL)	(MOVQmr (<STACK-CELL>-offset $1) RBP 0 0 RCX)
                                (MOVQrm RCX (<STACK-CELL>-offset $2) RBP 0 0))
  ((R64 STACK-CELL)		(MOVQrm (<REGISTER>-name $1) (<STACK-CELL>-offset $2) RBP 0 0))
  ((STACK-CELL R64)		(MOVQmr (<STACK-CELL>-offset $1) RBP 0 0 (<REGISTER>-name $2)))
  ((R64 R64)			(MOVQrr (<REGISTER>-name $1) (<REGISTER>-name $2))))

(define-instruction LOAD	(false 0 true)
  ((LI64)			(if (= 0 (<LITERAL>-value $1))
                                    (XORQrr RAX RAX)
                                  (MOVQir (<LITERAL>-value $1) RAX)))
  ((STACK-CELL)			(MOVQmr (<STACK-CELL>-offset $1) RBP 0 0 RAX))
  ((R64)			(MOVQrr (<REGISTER>-name $1) RAX))
  ((GLOBAL-CELL)		(LEAQmr	(<GLOBAL-CELL>-address $1) 0 0 0 RAX)
                                (MOVQmr 0 RAX 0 0 RAX))
  ((GLOBAL-ADDR)		(LEAQmr	(<GLOBAL-ADDR>-address $1) 0 0 0 RAX))
  ;; ((GOT64)			(println "	mov	"$1"@GOTPCREL(%rip), %rax")
  ;;       			(println "	mov	(%rax), %rax"))
  )
;; $1 what, $2 where
(define-instruction STORE	(true 0 false)
  ((R64 GLOBAL-CELL)		(LEAQmr	(<GLOBAL-CELL>-address $2) 0 0 0 RBX)
                                (MOVQrm (<REGISTER>-name $1) 0 RBX 0 1))
  ;; ((R64 GOT64)			(println "	mov	"$2"@GOTPCREL(%rip), %rbx")
  ;;                               (println "	mov	"$1", (%rbx)"))
  ((R64 R64)			(MOVQrm (<REGISTER>-name $1) 0 (<REGISTER>-name $2) 0 1))
  ((R64 STACK-CELL)		(MOVQrm (<REGISTER>-name $1) (<STACK-CELL>-offset $2) RBP 0 1)))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; in haskell the signed ones are called integer, and the unsigned one are called word.
;; for now these are all unsigned, i.e. not sign extended.
(define-instruction LOAD-I8	(false 0 true)
  ((STACK-CELL)			(MOVQmr (<STACK-CELL>-offset $1) RBP 0 1 RCX)
                                (LEAQmr 0 RAX RCX 1 RCX)
                                (XORQrr RAX RAX)
                                (MOVBmr 0 RCX 0 1 AL))
  ((LI64)			(let ((offset (<LITERAL>-value $1)))
                                  (if (= 0 offset)
                                      (MOVQrr RAX RCX)
                                    (LEAQmr offset RAX 0 1 RCX)))
                                (XORQrr RAX RAX)
                                (MOVBmr 0 RCX 0 1 AL)))

(define-instruction STORE-I8	(false 0 true)
  ((STACK-CELL STACK-CELL)	(when-at-expand (feature strict-semantics-for-compiled-set)
                                  (XORQrr	RBX RBX))
                                (MOVBmr	(<STACK-CELL>-offset $2) RBP 0 1 BL)
                                (MOVQmr	(<STACK-CELL>-offset $1) RBP 0 1 RCX)
                                (MOVBrm	BL 0 RAX RCX 1)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RBX RAX)))
  ((STACK-CELL LI64)		(MOVQmr	(<STACK-CELL>-offset $1) RBP 0 1 RCX)
                                (if-at-expand (feature strict-semantics-for-compiled-set)
                                    (begin
                                     (XORQrr	RBX RBX)
                                     (MOVBir	(<LITERAL>-value $2) BL)
                                     (MOVBrm	BL 0 RAX RCX 1)
                                     (MOVQrr	RBX RAX))
                                  (MOVBim	(<LITERAL>-value $2) 0 RAX RCX 1))))

(when-at-expand (feature lower/array)
  ;; TODO these two are the same as the -OOP versions, except the lea's multiplier
  (define-instruction LOAD-CELL	(false 0 true)
    ((STACK-CELL)		(MOVQmr	(<STACK-CELL>-offset $1) RBP 0 1 RCX) ; index
				(MOVQmr 0 RAX RCX 1 RAX)))

  (define-instruction STORE-CELL	(false 0 true)
    ((STACK-CELL STACK-CELL)	(MOVQmr	(<STACK-CELL>-offset $1) RBP 0 1 RCX) ; index
				(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RBX) ; value
				(MOVQrm	RBX 0 RAX RCX 1))))

(define-instruction LOAD-OOP	(false 0 true)
  ((STACK-CELL)			(MOVQmr	(<STACK-CELL>-offset $1) RBP 0 1 RCX) ; index
				(MOVQmr 0 RAX RCX 8 RAX))
  ((LI64)			(let ((offset (<LITERAL>-value $1)))
                                  (if (= 0 offset)
                                      (MOVQmr 0 RAX 0 0 RAX)
                                    (LEAQmr (* offset 8) RAX 0 0 RCX)
                                    (MOVQmr 0 RCX 0 0 RAX)))))

;; object is in RAX; args: offset, value
(define-instruction STORE-OOP	(false 0 true)
  ((STACK-CELL STACK-CELL)	(MOVQmr	(<STACK-CELL>-offset $1) RBP 0 1 RCX)
                                (MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RDX)
                                (MOVQrm	RDX 0 RAX RCX 8)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RDX RAX)))
  ((LI64 LI64)			(MOVQir	(<LITERAL>-value $2) RDX) ; value
                                (MOVQrm	RDX (* (<LITERAL>-value $1) 8) RAX 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RDX RAX)))
  ((STACK-CELL LI64)		(MOVQmr	(<STACK-CELL>-offset $1) RBP 0 1 RCX)
                                (MOVQir	(<LITERAL>-value $2) RDX)
                                (MOVQrm	RDX 0 RAX RCX 8)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RDX RAX)))
  ((LI64 STACK-CELL)		(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RDX) ; value
                                (MOVQrm	RDX (* (<LITERAL>-value $1) 8) RAX 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RDX RAX))))

(define-instruction PUSH	()
  ((LI64)			(PUSHQi (<LITERAL>-value $1)))
  ((R64)			(PUSHQr (<REGISTER>-name $1))))

(define-instruction POP		()
  ((R64)			(POPQr (<REGISTER>-name $1))))

(define-form define-instruction/comparator (maru-name x86-name)
  `(define-instruction ,maru-name (true 0 true)
     ((R64 STACK-CELL)
      ;; TODO order?!
      (CMPQmr (<STACK-CELL>-offset $2) RBP 0 1 (<REGISTER>-name $1))
      (,x86-name AL)
      (MOVZBQrr AL (<REGISTER>-name $1)))
     ((R64 LI64)
      (let ((lit (<LITERAL>-value $2)))
        (if (= 0 lit)
            (TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
          (CMPQir lit (<REGISTER>-name $1))))
      (,x86-name AL)
      (MOVZBQrr AL (<REGISTER>-name $1)))))

(define-instruction/comparator LT SETLr)
(define-instruction/comparator LE SETLEr)
(define-instruction/comparator EQ SETEr)
(define-instruction/comparator GE SETGEr)
(define-instruction/comparator GT SETGr)
;;(define-instruction/comparator NE "setne")

;; a vector of assoc lists indexed by operator arity
(define *special-operators*
    (let ((table
           `(;; nullary
             ()
             ;; unary
             ((-  ,NEG) (not ,LOGIC-NOT) (bitwise-not ,BITWISE-NOT))
             ;; binary
             ((+  ,ADD) (-   ,SUB) (* ,MUL) (/ ,DIV)
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
     (LITERAL expr))

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
     (LITERAL expr))
    (else
      (comp expr)
      (let ((temp (alloc-stack-temp -c-)))
        (emit STORE $ temp)
        temp))))

(let ((program-code-offset (slave-value (record/slot-index <target-function> 'program-code))))
  (define-function compile-call-to-<target-function> (-c-)
    ;; TODO assert the type to be <target-function>
    ;; TODO assert nr of args = params
    (when (feature emit-with-object-headers)
      ;; i.e. this is a full <target-function> object. when the
      ;; feature is disabled then it's just a raw function pointer to
      ;; be called.
      (gen LOAD-OOP (LITERAL program-code-offset)))
    (gen CALLPTR $)
    ()))

(define-function closure-code-label (name)
  (label (if (feature emit-with-object-headers)
             (concat-symbol name '.code)
           name)))

(define-function compile-call-to-global-function (op -c-)
  (if (feature redefinable-functions-in-target)
      (let ()
        (comp op)
        (compile-call-to-<target-function> -c-))
    (emit CALL (closure-code-label (<variable>-name op))))
  ())

(define-method compile-call-to (slave-value <target-function>) (op -c-)
  (comp op)
  (compile-call-to-<target-function> -c-))

;; this case is handled early in compile-call
;; (define-method compile-call-to <pair> (op -c-)
;;   (comp op)
;;   (compile-call-to-<target-function> -c-))

(define-method compile-call-to <expr> (op -c-)
  ;; NOTE the fact that a literal <expr> is found in a variable's
  ;; value slot at compile time implies that it's a global definition.
  (compile-call-to-global-function op -c-)
  (expr-n-required-parameters self))

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
  ;; namely compile/let, requires a temp location, even when
  ;; initialized to literal values.
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-stack-temp -c-)))
    (emit STORE $ temp)
    temp))

(define-function compile/let-binding (binding comp)
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

(define-function compile/let (expr -c-)
  (let ((temps (map-with compile/let-binding (caddr expr) -c-)))
    (list-do stmt (cdddr expr)
      (comp stmt))
    (free-temps temps)))

(define-function compile/and (expr -c-)
  (let ((done (label)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (emit BF $ done)))
    (label! done)))

(define-function compile/or (expr -c-)
  (let ((done (label)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (emit BT $ done)))
    (label! done)))

(define-function compile/if (expr -c-)
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

(define-function compile/while (expr -c-)
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

(define-function compile/return (expr -c-)
  (list-do stmt (cdr expr)
    (comp stmt))
  (emit BR (or (<x86-compiler>-fn-epilogue-label -c-)
               (set (<x86-compiler>-fn-epilogue-label -c-) (label)))))

(define-function emit-object/C-string (self -c-)
  (emit-comment 3 "emit-object/C-string for: "self)
  (GLOBAL-ADDR
   (with-new-label 'ro-data
     (.ascii self)
     (.i8 0))))

(define-function compile/C-string (expr -c-)
  (assert (= (list-length expr) 2))
  (emit LOAD (emit-object/C-string (second expr) -c-)))

(define-method compile-object <string> (-c-)
  (emit-object/C-string self -c-))

(define-method compile-object <undefined> (-c-)
  (LITERAL (target-value false)))

(define-function compile/lambda (form -c-)
  (let ((expr (eval form)))
    (emit LOAD (compile-expr expr () -c-))))

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



;; KLUDGE replace the env binding for the base class. the reason is
;; that this way we can use (LITERAL 42) in some parts of the code
;; that is shared between 32 and 64 bits... but there must be a nice
;; way to achieve this.
(define LITERAL LI64)

;;;
;;; x86-64 -- INSTRUCTIONS
;;;

;; ENTER is slow, so don't use it (LEAVE is fine): https://stackoverflow.com/questions/5959890/enter-vs-push-ebp-mov-ebp-esp-sub-esp-imm-and-leave-vs-mov-esp-ebp
(define-instruction ENTER-FRAME	()
  ((_)				(PUSHQr RBP)
                                (MOVQrr RSP RBP)
                                (unless (= 0 $1)
                                  (SUBQir $1 RSP))))

(define-instruction LEAVE-FRAME	()
  ((_)				(LEAVE)
                                (RET)))

(define-instruction SEXT	()
  ((R32 R64)			(MOVSBQrr (<REGISTER>-name $1) (<REGISTER>-name $2))))

;;;
;;; Compiler Infrastructure
;;;
(define-constant +param-registers+   `(quote ,(list op/RDI op/RSI op/RDX op/RCX op/R8 op/R9)))
(define-constant +n-param-registers+ (list-length +param-registers+))

(define-constant +callee-saved-registers+   `(quote ,(list op/RBX op/R12 op/R13 op/R14 op/R15)))
(define-constant +n-callee-saved-registers+ (list-length +callee-saved-registers+))

(define-record <x86-64-compiler> <x86-compiler>
  (free-temp-regs
   clobbered-temp-regs))

(define-function x86-64-compiler (level)
  (make <x86-64-compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (free-temp-regs		+callee-saved-registers+)
    (clobbered-temp-regs	(array +n-callee-saved-registers+))
    (gen-buffer			(array))
    (current-value		op/RAX)

    (arg-offset			0)
    (arg-limit			0)
    ;; delme (asm-cell-type		".8byte")
    ))

(define-function run-compiler (env)
  (compile-env env (x86-64-compiler 1)))

(define-function new-stack-cell (-c-)
  (STACK-CELL (- 0 (* (+ 1 (new-temp-index -c-)) +word-size-in-bytes+))))

(define-function alloc-reg-temp (self)
  (with-instance-accessors self <x86-64-compiler>
    (if false ;; TODO self.free-temp-regs
        (let ((reg (pop self.free-temp-regs)))
          (set (array-at self.clobbered-temp-regs (<REGISTER>-index reg)) reg)
          reg)
      (or (pop (<compiler>-free-stack-cells self))
          (new-stack-cell self)))))

(define-function %free-temp (-c- obj)
  ;; FIXME this is a mess! %free-temp is called with all kinds of objects...
  (typecase obj
    (<R64>		(push (<x86-64-compiler>-free-temp-regs -c-) obj))
    (<STACK-CELL>	(push (<compiler>-free-stack-cells -c-) obj))))

;;;
;;; Compiling lambdas
;;;

(define-function emit-expr-code (self entry-point-label parent-comp)
  ;;(assert (is <expr> self))
  ;; NOTE printing the code as-is, i.e. without escaping, may break the comment syntax
  (.align +function-alignmet+ 0x90)

  (let* ((body		(<expr>-body self))
         (-c-		(x86-64-compiler (+ 1 (<compiler>-level parent-comp))))
         (params	(<expr>-parameters self))
         (param-count	(list-length params))
         (frame-body-size (label)))

    (label! entry-point-label)
    ;; (emit-comment 1 "params: "(list-length (<expr>-parameters self))
    ;;               ", frame-size: "frame-size"("(/ frame-size +word-size-in-bytes+)
    ;;               "), temp-size: "temp-size "("(/ temp-size  +word-size-in-bytes+)")")
    (emit ENTER-FRAME frame-body-size)

    (let ((spill-locs	()))
      ;; allocate stack-cells for spilling the reg params
      (times-do (min param-count +n-param-registers+)
        (let ((spill-loc	(new-stack-cell -c-))
              (var		(pop params)))
          (set (<variable>-value var) spill-loc)
          (push spill-locs spill-loc)))

      ;; assign the stack locations to the params passed on the stack
      (let ((i 2))        ; 2 is the pushed RBP and the return address
        (list-do var params
          (let ((offset (* i +word-size-in-bytes+)))
            (set (<variable>-value var) (STACK-PARAM offset)))
          (incr i)))

      (emit-comment 2 "emitting "self", at level: "(<compiler>-level parent-comp))
      (emit-comment 3 ", code: "(<expr>-body self))
      ;; Unconditionally spill the params to the stack.
      (let ((regs		+param-registers+)
            (stack-cells	(list-reverse! spill-locs)))
        (times-do (min param-count +n-param-registers+)
          (emit MOVE (pop regs) (pop stack-cells))))

      ;; Compile the fn body (COMP is a form, we cannot MAP it).
      (list-do el body
        (comp el))

      ;; Calculate the frame and emit the entire fn
      (let* ((temp-size	(* (<compiler>-temp-limit -c-)
                           +word-size-in-bytes+))
             (frame-size	(align +call-frame-alignmet+
                                       (+ temp-size
                                          ;; the pushed %ebp and the return address
                                          (* 2 +word-size-in-bytes+)))))

        (label! frame-body-size (- frame-size (* 2 +word-size-in-bytes+)))

        (awhen (<x86-compiler>-fn-epilogue-label -c-)
          (label! it))

        (emit LEAVE-FRAME frame-body-size))))

  (let ((name (<expr>-name self)))
    (when name
      ;; FIXME this uses the same .code suffix as closure-code-label,
      ;; but they are not bound together.
      (emit-symtab-entry/function (concat-string (symbol->string name) ".code")
                                  (laddress entry-point-label)
                                  (- (current-laddress)
                                     (laddress entry-point-label)))))
  (GLOBAL-ADDR entry-point-label))

;; serious KLUDGE
(define expr-queue ())

(define-function compiled-expr-wrapper (name entry-point -c-)
  entry-point)

;; even when emitting is deferred into the queue we still create,
;; register, and return a label. it's set when the queue is eventually
;; emitted.
(define-function compile-expr (self name -c-)
  (emit-comment 2 "0x" (integer->string (current-laddress) 16)
                ": compiling fn "term/FG-GREEN (or name "/unnamed/") term/RESET", "self", level " (<compiler>-level -c-))
  (let ((entry-point (if name
                         (closure-code-label name)
                       (label))))
    (if (< 1 (<compiler>-level -c-))
        ;; a lambda inside a lambda : save it for later
        (begin
         (emit-comment 2 "queueing fn for later: "(or name "/unnamed/")", "self", level " (<compiler>-level -c-))
         (push expr-queue (cons entry-point self)))

      ;; we are at the toplevel, emit ourselves first
      (emit-expr-code self entry-point -c-)
      ;; then emit the queue, if any
      (let (el)
        (while (set el (pop expr-queue))
          (let ((entry-point	(car el))
                (expr		(cdr el)))
            (emit-comment 2 "compiling queued fn "expr", entry-point "entry-point)
            (emit-expr-code expr entry-point -c-)))))

    ;; TODO this cries for a cleanup...
    (GLOBAL-ADDR (compiled-expr-wrapper name entry-point -c-))))

;;;
;;; Compiling calls
;;;

(define-function compile-call-form (op args -c-)
  (emit-comment 2 "compile-call: "op", args: "args)
  (safety 2 (assert (or (pair? op) (variable? op))))
  ;; NOTE this implements a left-to-right evaluation order, including the operator.
  ;; i.e. moving this op-tmp means changing the evaluation order!
  (let* ((tmps-to-free	())
         (maybe-store	(lambda (operand)
                          ;; TODO cleanup
                          (if (or (is <R64> operand)
                                  (is <R32> operand))
                              (let ((temp (alloc-reg-temp -c-)))
                                (push tmps-to-free temp)
                                (emit STORE $ temp)
                                temp)
                            operand)))
         (arg-operands	(map (lambda (expr)
                               (maybe-store (compile/expression-to-operand expr -c-)))
                             args))
         (arg-count	(list-length args))
         (op-value	(if (variable? op)
                            ;; get the value for dispatch purposes
                            (<variable>-value op)
                          ;; compile to a temp or a literal
                          (maybe-store (compile/expression-to-operand op -c-))))
         ;; NOTE here we *must* store the arg values calculated by
         ;; expression into temps (as opposed to storing them straight
         ;; into the arg locations, i.e. first 6 into registers)
         ;; because the arg expression can be of any complexity;
         ;; i.e. they may call other functions, which would overwrite
         ;; the arg registers...
         (arg-stack-cell-count	(max 0 (- arg-count +n-param-registers+)))
         (arg-regs	+param-registers+))

    ;; move the reg passed operands into the regs
    (times-do (min arg-count +n-param-registers+)
      (emit MOVE (pop arg-operands) (pop arg-regs)))

    ;; push the remaining (i.e. stack-passed) arguments in reverse order
    (list-do op (list-reverse! arg-operands)
      (emit PUSH op))

    (let* ((n-params	 (emit-comment 2 "compile-call-to: "op-value)
                         ;; FIXME delete unused arg-locs
                         (compile-call-to op-value op -c-))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))
    (emit ADD op/RSP (LI64 (* arg-stack-cell-count +word-size-in-bytes+)))
    (free-temps tmps-to-free)))

(define-method compile-call-to <STACK-CELL> (op -c-)
  (emit LOAD self)
  (compile-call-to-<target-function> -c-))

(define-method compile-call-to <R64> (op -c-)
  (unless (= RAX (<REGISTER>-name self))
    (emit MOVE self op/RAX))
  (compile-call-to-<target-function> -c-))

;; TODO
;; (define-method compile-call-to <C-function> (op -c-)
;;   (let* ((c-function-entries	(<x86-compiler>-c-function-entries -c-))
;;          (var			(defined? self.name c-function-entries))
;;          (c-function-entry	(if var
;;                                     (<variable>-value var)
;;                                   (let* ((ptr-label (with-new-label 'data
;;                                                       (.cell 0)))
;;                                          (stub-label (with-new-label 'code
;;                                                        ;; TODO
;;                                                        ))
;;                                          (entry ()))
;;                                     (environment-define c-function-entries self.name entry)
;;                                     entry))))
;;     )
;;
;;   (.segment 'data)
;;   (let ((fnptr (label))
;;         (stub  (flabel)))
;;     (.cell stub)
;;     (.segment 'code)
;;     (label stub)
;;     )
;;
;;   (emit CALL (EXTERNAL-LABEL (<C-function>-name self)))
;;   (case (<C-function>-return-type self)
;;     ;; TODO introduce a proper infrastructure for this
;;     (int
;;      (emit SEXT op/EAX op/RAX))
;;     (short
;;      (error "TODO sign-extend a short to 64 bits")))
;;   (unless (<C-function>-vararg? self)
;;     (list-length (<C-function>-parameter-types self))))

;;;
;;; Special Forms
;;;
(define-function compile/set (expr -c-)
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

(define-function compile/address-of (expr -c-)
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

;;;
;;; *special-forms*
;;;
(define *special-forms* (list
  (cons (target-value let)		compile/let)
  (cons (target-value and)		compile/and)
  (cons (target-value or)		compile/or)
  (cons (target-value if)		compile/if)
  (cons (target-value while)		compile/while)
  (cons (target-value set)		compile/set)
  (cons (target-value lambda)		compile/lambda)
  (cons (target-value return)		compile/return)
  (cons (target-value address-of)	compile/address-of)
  (cons (target-value C-string)		compile/C-string)
  (cons (target-value stack-pointer-on-entry)
        (lambda (expr -c-)
          ;; the function prologue we also employ is like this:
          ;;
          ;; push	%rbp
          ;; mov	%rsp, %rbp
          ;; sub	$n, %rsp
          ;; ...
          ;;
          ;; so, the 8(%rbp) is to undo the push %rbp, so that we
          ;; regain the %rsp value at the entry point to the function.

          (LEAQmr	8 RBP 0 0 RAX)
          (set (<compiler>-current-value -c-) op/RAX)))
  ))

;;;
;;; Special Operators
;;;

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
  (emit LOAD (LITERAL self)))

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

(define-function features->print-forms (names)
  (let ((elements ())
        (first-time true))
    (map (lambda (name)
           (if first-time
               (set first-time false)
             (push elements ", "))
           (push elements (symbol->string name))
           (push elements "=")
           (push elements `(feature ,name)))
         names)
    (list-reverse! elements)))

(define-form comment-features ()
  `(emit-comment 0 "features: "
                 ,@(features->print-forms
                    '(emit-with-object-headers
                      redefinable-functions-in-target
                      strict-semantics-for-compiled-set
                      profiler
                      track-expr-names
                      object-canary
                      debug-info))))

(define elf/page-size	0x1000) ; is this the system page-size?
(define ideal-cache-line-alignment 64)

(assert (= elf/sizeof-Elf64_Ehdr 64))
(assert (= elf/sizeof-Elf64_Phdr 56))

(define-constant +n-segments+ 5)
(define-constant +n-sections+ 8)
(define-constant +elf-prefix-size+ (+ elf/sizeof-Elf64_Ehdr
                                      (* +n-segments+
                                         elf/sizeof-Elf64_Phdr)
                                      (* +n-sections+
                                         elf/sizeof-Elf64_Shdr)))

(define-constant +code-segment-address+		0x00400000)
(define-constant +ro-data-segment-address+	0x00500000)
(define-constant +data-segment-address+		0x00600000)
(define-constant +bss-segment-address+		0x00700000)

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

(define-function write-elf-to-stream (stream)
  (.segment	'code)
  (.align	elf/page-size)

  (.segment	'data)
  (.align	elf/page-size)

  (.segment	'ro-data)
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
  (.i64		(closure-code-label '_start)) ; e_entry (entry point)
  (.i64		(label 'program-headers	(- self (laddress 'elf-header-start)))) ; e_phoff	Start of program headers (file offset)
  (.i64		(label 'section-headers	(- self (laddress 'elf-header-start)))) ; e_shoff	Start of section headers
  (.i32		0)               ; e_flags
  (.i16		(label 'elf-header-end	(- self (laddress 'elf-header-start)))) ; e_ehsize	Size of this header
  (.i16		elf/sizeof-Elf64_Phdr) ; e_phentsize	Size of program header entry
  (.i16		+n-segments+)          ; e_phnum	Number of program headers
  (.i16		elf/sizeof-Elf64_Shdr) ; e_shentsize	Size of section header
  (.i16		+n-sections+)          ; e_shnum	Number of section headers
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
         size/bss)

    ;; text segment
    (emit-program-header elf/PT_LOAD file-offset/text
                         size/text size/text
                         (+ elf/PF_R elf/PF_X)
                         +code-segment-address+
                         elf/page-size)
    (incr file-position size/text)

    ;; ro-data segment (must be last, because this will also mmap the )
    (set size/ro-data (segment-length 'ro-data))
    (set file-offset/ro-data file-position)
    (emit-program-header elf/PT_LOAD file-offset/ro-data
                         size/ro-data size/ro-data
                         (+ elf/PF_R elf/PF_W)
                         +ro-data-segment-address+
                         elf/page-size)
    (incr file-position size/ro-data)

    ;; mark the entire ro-data segment to become read-only after
    ;; relocation is finished. note that it's possible to mark only a
    ;; subset of it using this extra PT_GNU_RELRO program header.
    (emit-program-header elf/PT_GNU_RELRO file-offset/ro-data
                         size/ro-data size/ro-data
                         elf/PF_R
                         +ro-data-segment-address+
                         elf/page-size)

    ;; data segment
    (set size/data (segment-length 'data))
    (set file-offset/data file-position)
    (emit-program-header elf/PT_LOAD file-offset/data
                         size/data size/data
                         (+ elf/PF_R elf/PF_W)
                         +data-segment-address+
                         elf/page-size)
    (incr file-position size/data)

    ;; BSS, aka zero-initialized data
    (set size/bss (segment-length 'bss))
    (when (= 0 size/bss)
      ;; zero is illegal, and not emitting is more trouble than just
      ;; setting it to 1.
      (set size/bss 1))
    (emit-program-header elf/PT_LOAD file-position
                         0 size/bss
                         (+ elf/PF_R elf/PF_W)
                         +bss-segment-address+
                         elf/page-size)

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

    ;; section #5
    (let ((size/symtab (segment-length '.symtab)))
      (emit-section-header (emit-shstrtab-entry ".symtab")
                           elf/SHT_SYMTAB
                           0 0
                           file-position
                           size/symtab
                           +.strtab-section-index+
                           (/ size/symtab elf/sizeof-Elf64_Sym)
                           8
                           elf/sizeof-Elf64_Sym)
      (incr file-position size/symtab))

    ;; section #6
    (let ((size/strtab (segment-length '.strtab)))
      (emit-section-header (emit-shstrtab-entry ".strtab")
                           elf/SHT_STRTAB 0 0
                           file-position
                           size/strtab 0 0 1 0)
      (incr file-position size/strtab))

    ;; section #7
    (let* ((name-offset		(emit-shstrtab-entry ".shstrtab"))
           ;; must emit prior to taking the segment-length...
           (size/shstrtab	(segment-length '.shstrtab)))
      (emit-section-header name-offset
                           elf/SHT_STRTAB 0 0
                           file-position
                           size/shstrtab
                           0 0 1 0)))

  ;; we can start writing the file. note that the order must be in
  ;; sync with the headers above.
  (list-do name '(elf-prefix code ro-data data ; bss is discarded
                  .symtab .strtab .shstrtab)
    (write-segment-to-stream name stream)))

(define-form syscall (sys-number . args)
  `(begin
    (MOVQir	,sys-number RAX)
    ,@(map (lambda (arg reg)
             ;; this being a macro opens the possibility for automatic
             ;; opcode selection based on the provided arg.
             `(MOVQir	,arg ,reg))
           args '(RDI RSI RDX R10 R8 R9))
    (SYSCALL)))

(define-function compile-env (env -c-)
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

    ;; write to *standard-output* to be compatible with the other backends
    (write-elf-to-stream *standard-output*)

    (when (<= 1 *compiler-verbosity*)
      (array-do var (<env>-bindings (<assembler>-env *assembler*))
        (let ((value (<variable>-value var)))
          (when (is <label> value)
            (emit COMMENT (list "0x"(integer->string (<label>-laddress value) 16)
                                "\t" (<variable>-name var))))))))
  (verbosity 1 (warn "\n")))

;;;
;;; <selector>
;;;
;; TODO ideally the method vector of the selector should be
;; addressed/filled according to the slave type id's. when that is
;; achieved, then we can simply COMPILE-DEFINITION the method array,
;; without the translation.
;;
;; TODO this whole thing should be merged with the emit-object stuff,
;; or rather, with whatever simplified will replace the current
;; emit-object machinery.
(define-method compile-definition (slave-value <selector>) (name -c-)
  (let ((target-env		(slave-value *globals*))
        (methods		(eval-in-slave `(<selector>-methods ,self)))
        (target-methods		(array))
        (dispatch-table-name	(concat-symbols name '.method-table))
        (parameters		())
        (index-min		())
        (index-max		0))
    ;; build a trimmed methods array with the slave type id's as indexes
    (for (i 0 (array-length methods))
      (let ((impl-fn (array-at methods i)))
        (when impl-fn
          (let ((slave-type-id (eval-in-slave `(<type>-slave-id ,(type-object-for-id i)))))
            (emit-comment 2 "<selector> method for "name", type id "slave-type-id" (in host: "i"), parameters: "(<expr>-parameters impl-fn))
            (or index-min (set index-min slave-type-id))
            (set index-max slave-type-id)
            ;; NOTE this takes the parameter signature of the first method
            ;; and assumes it's the same for the rest.
            (if parameters
                (assert (= (list-length parameters) (list-length (<expr>-parameters impl-fn))) "unsupported: <selector> "name" has specializations with varying number of parameters")
              (set parameters (map (lambda (el)
                                     (<variable>-name el))
                                   (<expr>-parameters impl-fn)))
              (assert (= (first parameters) 'self)))
            (set (array-at target-methods (- slave-type-id index-min)) impl-fn)))))
    ;; define and emit the dispatch table
    (emit-comment 2 "<selector> dispatch table for '"name"', from "index-min", to "index-max)
    (environment-define target-env dispatch-table-name target-methods)
    (compile-definition target-methods dispatch-table-name -c-)
    ;; the selector function
    (emit-comment 2 "<selector> stub for "name)
    (let ((stub	(eval-in-target
                 `(,lambda ,parameters
                    (let ((type (type-of self)))
                      (safety 1
                        (unless (and (<= ,index-min type)
                                     (<= type ,index-max))
                          ;; TODO ideally this should use the default handler provided at DEFINE-SELECTOR
                          (error "selector '",(symbol->string name)"' has no method for type " (box <long> type))))
                      ((oop-at (address-of ,dispatch-table-name) (- type ,index-min)) ,@parameters))))))
      (compile-definition stub name -c-))))
