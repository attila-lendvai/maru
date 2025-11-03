;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/compiler/emit-early.l")

;; TODO this is kludgey. why only this one, etc...
(define-constant +word-size-in-bytes+ (target-value +word-size-in-bytes+))

(define-constant +external-label-prefix+
    (case (target-value +operating-system+)
      (darwin	"_")
      (else	"")))

(define-function mangle-label (name)
  (with-forms ((putnext ((c) `(string-append mangled ,c))))
    (let* ((plain   (symbol->string name))
           (mangled (string))
           (digit-for (lambda (c)
                        (if (< c 10)
                            (+ c ?0)
                          (+ c (- ?A 10))))))
      (string-do c plain
        (cond
          ((or (and (<= ?a c) (<= c ?z))
               (and (<= ?A c) (<= c ?Z))
               (and (<= ?0 c) (<= c ?9)))
           (putnext c))
          ((or (= ?- c)
               (= ?_ c))
           (putnext ?_))
          (else
           (putnext ?_)
           (putnext (digit-for (bitwise-shift c -4)))
           (putnext (digit-for (bitwise-and c 0xf))))))
      mangled)))

;;;
;;; OPERANDS
;;;
(define-operand LABEL () (name)		+maru-label-prefix+ (mangle-label self.name))		; a label that we generate
(define-operand EXTERNAL-LABEL LABEL ()	+external-label-prefix+ self.name)			; a label in the global C namespace

(define-function UNIQUE-LABEL args
  (LABEL (unique-name (or (first args) "L"))))

;; Naming convention: global, literal, temp, general register
(define-operand GI32 () (name)		self.name)
(define-operand LI32 () (value)		"$"self.value)
(define-operand TI32 () (offset)	self.offset"(%esp)")
(define-operand GR32 () (name)		self.name)

(define-operand GI64 () (name)		self.name)
(define-operand LI64 () (value)		"$"self.value)
(define-operand TI64 () (offset)	self.offset"(%rsp)")
(define-operand GR64 () (name)		self.name)

;;;
;;; INSTRUCTIONS
;;;
(define-instruction COMMENT	()
  ((pair)			(print "# ") (apply println $1)))

(define-instruction INLINE	()
  ((string)			(println $1)))

(define-instruction TEXT	()
  (()				(println "	.text")))

(define-instruction DATA	()
  (()				(println "	.section .data")))

(define-instruction RODATA	()
  (()				(println "	.section .rodata")))

;;(define-instruction    (SECTION string)		(println "	.section "$1))
;;(define-instruction    (INDIRECT LABEL)		(println "	.indirect_symbol "$1))

(define-instruction TYPE	()
  ((_ _)			(println "	.type "$1", "$2)))

(define-instruction ALIAS	()
  ((_ _)			(println "	.set "$1", "$2)))

(define-instruction EXPORT	()
  ((LABEL)			(println "	.globl "$1)))

(define-instruction ALIGN	()
  ((long)			(println "	.align " $1)))

(define-instruction ASCIZ	()
  ((string)			(print   "	.asciz ") (dumpln $1)))

;; TODO rename to DEFINE? that would be less unique
(define-instruction DEFLABEL	()
  ((LABEL)			(println $1":")))

(define-instruction LEAVE	()
  ((long)			(println "	leave")
				(println "	ret")))

(define-instruction BR		()
  ((LABEL)			(println "	jmp	"$1)))

;; TODO arg2 is arg-locs. what for? for the arity? delme?
(define-instruction CALL	(false 0 true)
  ((LABEL _)			(println "	call	"$1)))

(define-instruction ADD		(true 0 true)
  ((GR32 TI32)			(println "	add	"$2","$1))
  ((GR32 LI32)			(unless (= 0 (<LI32>-value $2))
				  (println "	add	"$2","$1)))
  ((GR64 TI64)			(println "	add	"$2","$1))
  ((GR64 LI64)			(unless (= 0 (<LI64>-value $2))
                                  (println "	add	"$2","$1))))

(define-instruction SUB		(true 0 true)
  ((GR32 TI32)			(println "	sub	"$2", "$1))
  ((GR32 LI32)			(unless (= 0 (<LI32>-value $2))
				  (println "	sub	"$2", "$1)))
  ((GR64 TI64)			(println "	sub	"$2", "$1))
  ((GR64 LI64)			(unless (= 0 (<LI64>-value $2))
                                  (println "	sub	"$2", "$1))))

;; TODO x86 mul operates on eax, which somehow needs to be encoded
;; into the instruction. same applies to div.
(define-instruction MUL		()
  ((TI32)			(println "	mull	"$1))
  ((LI32)			(cond
                                  ((= (<LI32>-value $1) 1)) ; nothing to do
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	mov	"$1", %ecx")
                                   (println "	mul	%ecx"))))
  ((TI64)			(println "	mulq	"$1))
  ((LI64)			(cond
                                  ((= (<LI64>-value $1) 1)) ; nothing to do
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	mov	"$1", %rcx")
                                   (println "	mul	%rcx")))))

;; the x86 div instruction is unsigned division
(define-instruction DIV		()
  ((TI32)			(println "	xor	%edx, %edx")
                                (println "	divl	"$1))
  ((LI32)			(cond
                                  ((= (<LI32>-value $1) 1)
                                   ;; remainder is zero, %eax is unchanged
                                   (println "	xor	%edx, %edx"))
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	xor	%edx, %edx") ; the upper side of 64 bit operand
                                   (println "	mov	"$1", %ecx") ; divisor
                                   (println "	div	%ecx"))))
  ((TI64)			(println "	xor	%rdx, %rdx")
                                (println "	divq	"$1))
  ((LI64)			(cond
                                  ((= (<LI64>-value $1) 1)
                                   ;; remainder is zero, %rax is unchanged
                                   (println "	xor	%rdx, %rdx"))
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	xor	%rdx, %rdx") ; the upper side of 64 bit operand
                                   (println "	mov	"$1", %rcx") ; divisor
                                   (println "	div	%rcx")))))

(define-instruction AND		(true 0 true)
  ((GR32 TI32)			(println "	and	"$2", "$1))
  ((GR32 LI32)			(unless (= -1 (<LI32>-value $2))
                                  (println "	and	"$2", "$1)))
  ((GR64 TI64)			(println "	and	"$2", "$1))
  ((GR64 LI64)			(unless (= -1 (<LI64>-value $2))
                                  (println "	and	"$2", "$1))))

(define-instruction OR		(true 0 true)
  ((GR32 TI32)			(println "	or	"$2", "$1))
  ((GR32 LI32)			(unless (= 0 (<LI32>-value $2))
                                  (println "	or	"$2", "$1)))
  ((GR64 TI64)			(println "	or	"$2", "$1))
  ((GR64 LI64)			(unless (= 0 (<LI64>-value $2))
                                  (println "	or	"$2", "$1))))

(define-instruction XOR		(true 0 true)
  ((GR32 TI32)			(println "	xor	"$2", "$1))
  ((GR32 LI32)			(unless (= 0 (<LI32>-value $2))
                                  (println "	xor	"$2", "$1)))
  ((GR64 TI64)			(println "	xor	"$2", "$1))
  ((GR64 LI64)			(unless (= 0 (<LI64>-value $2))
                                  (println "	xor	"$2", "$1))))

;; TODO should use reg1 and allocate a reg instead of directly using
;; ecx. same applies to asr.
(define-instruction ASL		(true 0 true)
  ((GR32 TI32)			(println "	mov	"$2", %ecx")
				(println "	sal	%cl, "$1))
  ((GR32 LI32)			(unless (= 0 (<LI32>-value $2))
				  (println "	shl	"$2", "$1)))
  ((GR64 TI64)			(println "	mov	"$2", %rcx")
		                (println "	sal	%cl, "$1))
  ((GR64 LI64)			(unless (= 0 (<LI64>-value $2))
                                  (println "	shl	"$2", "$1))))

(define-instruction ASR		(true 0 true)
  ((GR32 TI32)			(println "	mov	"$2", %ecx")
				(println "	sar	%cl, "$1))
  ((GR32 LI32)			(unless (= 0 (<LI32>-value $2))
				  (println "	sar	"$2", "$1)))
  ((GR64 TI64)			(println "	mov	"$2", %rcx")
		                (println "	sar	%cl, "$1))
  ((GR64 LI64)			(unless (= 0 (<LI64>-value $2))
                                  (println "	sar	"$2", "$1))))

(define-instruction ADDR	(false 0 true)
  ((GI32)			(println "	mov	$"$1", %eax"))
  ((TI32)			(println "	lea	"$1", %eax"))
  ((GI64)			(println "	lea	"$1"(%rip), %rax"))
  ((TI64)			(println "	lea	"$1", %rax")))

(define-instruction MOVE	(false 0 false)
  ((TI32 TI32)			(println "	mov	"$1", %ecx")
				(println "	mov	%ecx, "$2))
  ((LI32 TI32)			(println "	movl	"$1", "$2))
  ((TI64 TI64)			(println "	mov	"$1", %rcx")
                                (println "	mov	%rcx, "$2))
  ((GR64 _)			(println "	movq	"$1", "$2))
  ((_ GR64)			(println "	movq	"$1", "$2)))

(define-instruction STORE	(true 0 false)
  ((GR32 TI32)			(println "	mov	"$1", "$2))
  ((GR32 GI32)			(println "	mov	"$1", "$2))
  ((GR64 GI64)			(println "	lea	"$2"(%rip), %rbx")
                                (println "	mov	"$1", (%rbx)"))
  ((GR64 GR64)			(println "	mov	"$1", ("$2")"))
  ((GR64 TI64)			(println "	mov	"$1", "$2)))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; in haskell the signed ones are called integer, and the unsigned one are called word.
;; for now these are all unsigned, i.e. not sign extended.
(define-instruction LOAD-I8	(false 0 true)
  ((TI32)			(println "	mov	"$1", %ecx")
				(println "	lea	(%eax, %ecx), %ecx")
				(println "	xor	%eax, %eax")
				(println "	movb	(%ecx), %al"))
  ((LI32)			(let ((offset (<LI32>-value $1)))
				  (if (= 0 offset)
				      (println "	movl	%eax, %ecx")
				    (println "	lea	"offset"(%eax), %ecx")))
				(println "	xor	%eax, %eax")
				(println "	movb	(%ecx), %al"))
  ((TI64)			(println "	mov	"$1", %rcx")
                                (println "	lea	(%rax, %rcx), %rcx")
                                (println "	xor	%rax, %rax")
                                (println "	mov	(%rcx), %al"))
  ((LI64)			(let ((offset (<LI64>-value $1)))
                                  (if (= 0 offset)
                                      (println "	mov	%rax, %rcx")
                                    (println "	lea	"offset"(%rax), %rcx")))
                                (println "	xor	%rax, %rax")
                                (println "	mov	(%rcx), %al")))

(define-instruction STORE-I8	(false 0 true)
  ((TI32 _)			(if-at-expand feature/strict-semantics-for-compiled-set
                                    ;; NOTE this works out just fine for a TI32, too, because we are little-endian.
                                    (let ()
                                      (println "	mov	"$1", %ecx")
                                      (println "	lea	(%eax, %ecx), %ecx")
                                      (println "	xor	%eax, %eax")
                                      (println "	mov	"$2", %al")
                                      (println "	mov	%al, (%ecx)"))
                                  (println "	mov	"$1", %ecx")
                                  (println "	lea	(%eax, %ecx), %eax")
                                  (println "	movb	"$2", (%eax)")))
  ((LI32 _)			(let ((offset (<LI32>-value $1)))
                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%eax, %ecx")
                                          (println "	lea	"offset"(%eax), %ecx"))
                                        (println "	xor	%eax, %eax")
                                        (println "	mov	"$2", %al") ; this also leaves it as return value in %eax
                                        (println "	mov	%al, (%ecx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"offset"(%eax), %eax"))
                                    (println "	movb	"$2", (%eax)"))))
  ((TI64 _)			(if-at-expand feature/strict-semantics-for-compiled-set
				    ;; NOTE this works out just fine for a TI64, too, because we are little-endian.
                                    (let ()
                                      (println "	mov	"$1", %rcx")
                                      (println "	lea	(%rax, %rcx), %rcx")
                                      (println "	xor	%rax, %rax")
                                      (println "	movb	"$2", %al")
                                      (println "	movb	%al, (%rcx)"))
                                  ;;                                                  (println "	mov	"$1", %rcx")
                                  (println "	lea	"$1"(%rip), %rcx")
                                  (println "	lea	(%rax, %rcx), %rax")
                                  (println "	movb	"$2", (%rax)")))
  ((LI64 _)			(let ((offset (<LI64>-value $1)))
                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%rax, %rcx")
                                          (println "	lea	"offset"(%rax), %rcx"))
                                        (println "	xor	%rax, %rax")
                                        (println "	mov	"$2", %al") ; this also leaves it as return value in %rax
                                        (println "	mov	%al, (%rcx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"offset"(%rax), %rax"))
                                    (println "	movb	"$2", (%rax)")))))

(define-instruction LOAD-OOP	(false 0 true)
  ((TI32)			(println "	mov	"$1", %ecx")
                                (println "	lea	(%eax, %ecx, 4), %ecx")
                                (println "	mov	(%ecx), %eax"))
  ((LI32)			(let ((offset (<LI32>-value $1)))
                                  (if (= 0 offset)
                                      (println "	mov	(%eax), %eax")
                                    (println "	lea	"(* 4 offset)"(%eax), %ecx")
                                    (println "	mov	(%ecx), %eax"))))
  ((TI64)			(println "	mov	"$1", %rcx")
				(println "	lea	(%rax, %rcx, "+word-size-in-bytes+"), %rcx")
				(println "	mov	(%rcx), %rax"))
  ((LI64)			(let ((offset (<LI64>-value $1)))
                                  (if (= 0 offset)
                                      (println "	mov	(%rax), %rax")
                                    (println "	lea	"(* +word-size-in-bytes+ offset)"(%rax), %rcx")
                                    (println "	mov	(%rcx), %rax")))))

(define-instruction STORE-OOP	(false 0 true)
  ((TI32 _)			(if-at-expand feature/strict-semantics-for-compiled-set
                                    (let ()
                                      (println "	mov	"$1", %ecx")
                                      (println "	lea	(%eax, %ecx, 4), %ecx")
                                      (println "	mov	"$2", %eax")
                                      (println "	mov	%eax, (%ecx)"))
                                  (println "	mov	"$1", %ecx")
                                  (println "	lea	(%eax, %ecx, 4), %eax")
                                  (println "	mov	"$2", (%eax)")))
  ((LI32 _)			(let ((offset (<LI32>-value $1)))
                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%eax, %ecx")
                                          (println "	lea	"(* 4 offset)"(%eax), %ecx"))
                                        (println "	mov	"$2", %eax") ; this also leaves it as return value in %eax
                                        (println "	mov	%eax, (%ecx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"(* 4 offset)"(%eax), %eax"))
                                    (println "	mov	"$2", (%eax)"))))
  ((TI64 _)			(if-at-expand feature/strict-semantics-for-compiled-set
                                    (let ()
                                      (println "	mov	"$1", %rcx")
                                      (println "	lea	(%rax, %rcx, "+word-size-in-bytes+"), %rcx")
                                      (println "	mov	"$2", %rax")
                                      (println "	mov	%rax, (%rcx)"))
                                  (println "	mov	"$1", %rcx")
                                  (println "	lea	(%rax, %rcx, "+word-size-in-bytes+"), %rax")
                                  (println "	mov	"$2", (%rax)")))
  ((LI64 _)			(let ((offset (<LI64>-value $1)))
                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%rax, %rcx")
                                          (println "	lea	"(* +word-size-in-bytes+ offset)"(%rax), %rcx"))
                                        (println "	mov	"$2", %rax") ; this also leaves it as return value in %rax
                                        (println "	mov	%rax, (%rcx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"(* +word-size-in-bytes+ offset)"(%rax), %rax"))
                                    (println "	mov	"$2", (%rax)")))))

(define-form define-instruction/comparator (maru-name x86-name)
  `(define-instruction ,maru-name (true 0 true)
     ((GR32 TI32)
      (println "	cmp	"$2", "$1)
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, %eax"))
     ((GR32 LI32)
      (if (= 0 (<LI32>-value $2))
          (println "	test	"$1", "$1)
        (println "	cmp	"$2", "$1))
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, %eax"))
     ((GR64 TI64)
      (println "	cmp	"$2", "$1)
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, "$1))
     ((GR64 LI64)
      (if (= 0 (<LI64>-value $2))
          (println "	test	"$1", "$1)
        (println "	cmp	"$2", "$1))
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, "$1))))

(define-instruction/comparator LT "setl")
(define-instruction/comparator LE "setle")
(define-instruction/comparator EQ "sete")
(define-instruction/comparator GE "setge")
(define-instruction/comparator GT "setg")
;;(define-instruction/comparator NE "setne")


;;;
;;; Compiler Infrastructure
;;;

(define-function %gen (-c- factory args)
  ;; TODO it feels wasteful/unnecessary to allocate an instr instance here...
  ;; at least until we start storing something in the instances
  (let ((instr (factory)))
    (when (<instruction>-has-input? instr)
      (push args (<compiler>-current-value -c-)))
    (emit-comment 2 "GEN of "instr", args: " args)
    (when (<instruction>-produces-output? instr)
      ;; KLUDGE
      (set (<compiler>-current-value -c-)
           (if (= 4 +word-size-in-bytes+)
               (GR32 "%eax")
             (GR64 "%rax"))))
    ;; save into the gen buffer
    (array-append (<compiler>-gen-buffer -c-) (cons instr args))
    ()))

(define-function closure-code-label (name)
  ;; KLUDGE object "names" (i.e. addresses) should be tied together
  ;; explicitly, not through giving them the "right" name
  (LABEL (concat-string (symbol->string name) "__code")))

;;;
;;; Emitting objects
;;;

(define-function emit-object/C-string (self -c-)
  (let ((label (UNIQUE-LABEL "cstr")))
    (emit RODATA)
    (emit DEFLABEL label)
    (emit ASCIZ self)
    label))

;;;
;;; Compiling lambdas
;;;

(define-function compile/prog-into-temp (prog -c-)
  (assert (pair? prog) "compile/prog-into-temp: prog is empty") ; this is against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  ;; NOTE it's tempting here to check for single-element prog's, and turning them into a compile/expr-into-temp-or-literal
  ;; but our single caller, namely compile/let, requires a temp location, even when initialized to literal values.
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-temp -c-)))
    (gen STORE temp)
    temp))
