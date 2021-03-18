;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits LLVM IR text.
;;;
;;; Status: it should successfully compile eval.l into eval.s,
;;; that in turn can be compiled by the gcc toolchain into an executable eval binary.
;;;

;;; It can compile a subset of Maru.
;;;
;;; Limitations and peculiarities:
;;;   - no closures
;;;   - no variable number of args for functions
;;;   - only supports the following literals: Long, String (no lists, quoted literals, etc)
;;;   - string literals are compiled into .asciz, which means that they
;;;     are *not* tagged Maru objects on the heap; i.e. (t/print "foo") will
;;;     go astray because "foo" will be emitted as a null terminated string of
;;;     ascii bytes (instead of a Maru object of type <string>).
;;;   - probaby more
;;;   - see +special-operators+ and +special-forms+ for the list of specially
;;;     handled constructs
;;;
;;; Naming:
;;;   - EMIT: emit instructions into the output stream
;;;   - GEN:  like EMIT, but collect instructions into a buffer for later emission
;;;   - -foo- is an implicit var in the lexenv
;;;   - +foo+ is a constant
;;;   - *foo* is a global

;; Shall we map function params directly to LLVM IR function params?
;; NOTE: They are read-only in LLVM IR, and as of now eval.l violates this assumption.
(define-constant +function-parameters-are-read-only+ ())

;; we can't say anything smarter than this, because the LLVM IR doesn't have a NOT primitive.
;; so, let's just define a macro instead of a full compiler primitive.
(eval-in-target
 '(define-form bitwise-not (value)
   `(bitwise-xor ,value -1)))

(define *C-type->llvm-type*
    (concat-list
     '((void		void))
     (case (target-value +word-size-in-bits+)
       (32
        '((int			i32)
          (long			i32)
          (unsigned-long	i32)
          (size_t		i32)))
       (64
        '((int			i32)
          (long			i64)
          (unsigned-long	i64)
          (size_t		i32)))
       (else
        (error "unexpected word size in +word-size-in-bits+: "(target-value +word-size-in-bits+))))))

(define-function C-type->llvm-type (type)
  (cond
    ((pair? type)
     (cond
       ((= '* (first type))
        (concat-string (symbol->string (C-type->llvm-type (second type)))
                       "*"))
       (else
        (error "C-type->llvm-type has failed for "type))))
    ((= '* type)
     '%oop)
    ((string? type)                     ; KLUDGE or is it?
     type)
    (else
     (aif (assq type *C-type->llvm-type*)
         (second it)
       (error "C-type->llvm-type has failed for "type)))))

(define-function llvm-type-bitsize (type)
  (assert (symbol? type))
  (case type
    (%oop	(target-value +word-size-in-bits+))
    (void	0)
    (else
     (let ((entry (assq type '((i64 . 64) (i32 . 32) (i16 . 16) (i8 . 8)))))
       (unless entry
         (error "llvm-type-bitsize: unexpected type "type))
       (cdr entry)))))

(define-function %llvm-escape (prefix str char-needs-wrapping? legal-char? . with-zero)
  (with-forms ((putnext ((c) `(string-append mangled ,c))))
    (let* ((mangled (string))
           (wrap-result? ())
           (digit-for (lambda (c)
                        (if (< c 10)
                            (+ c ?0)
                          (+ c (- ?A 10)))))
           (write-char (lambda (c)
                         (when (char-needs-wrapping? c)
                           (set wrap-result? true))
                         (if (legal-char? c)
                             (putnext c)
                           (putnext ?\\)
                           (putnext (digit-for (bitwise-shift c -4)))
                           (putnext (digit-for (bitwise-and c 0xf)))))))
      (when prefix
        (string-do c prefix
          (write-char c)))
      (string-do c str
        (write-char c))
      (when with-zero
        (write-char ?\x00))
      (when wrap-result?
        (putnext ?\")
        (string-insert mangled 0 ?\"))
      mangled)))

(define-function llvm/escape-string (str . with-zero)
  (%llvm-escape ()
                str
                (lambda _ true)           ; always wrap it in double quotes
                ;; TODO this felxibility may be unnecessary; duplicate code below
                (lambda (c)
                  (and (<= 32 c) (<= c 127)
                       (not (= ?\" c))
                       (not (= ?\\ c))))
                with-zero))

(define-function llvm/escape-identifier (prefix name)
  ;; NOTE we don't need to escape ptr and word (two globally defined types that we use) because
  ;; our globals are prefixed by llvm/escape-global-identifier.
  (set name (symbol->string name))
  (%llvm-escape prefix
                name
                (lambda (c)
                  (not (or (and (<= ?a c) (<= c ?z))
                           (and (<= ?A c) (<= c ?Z))
                           (and (<= ?0 c) (<= c ?9))
                           (member? c '(?- ?$ ?. ?_)))))
                (lambda (c)
                  (and (<= 32 c) (<= c 127)
                       (not (= ?\" c))
                       (not (= ?\\ c))))))

(define-function llvm/escape-local-identifier (name)
  (llvm/escape-identifier () name))

(define-function llvm/escape-global-identifier (name)
  (llvm/escape-identifier +maru-label-prefix+ name))

;;;
;;; Operands
;;;

(define-operand		GLOBAL		() (name)		"@"(llvm/escape-global-identifier self.name))
(define-operand		EXTERNAL    GLOBAL ()			"@"self.name)
(define-operand		LOCAL		() (name)		"%"(llvm/escape-local-identifier self.name))
(define-operand		LITERAL		() (value)		self.value)
;; TODO delete the value slot
(define-operand		CONSTANT	() (name value)		self.name)
(define-operand		TEMP		() (id)			"%"(llvm/escape-local-identifier (concat-string "t" (number->string self.id))))
(define-operand		LABEL		() (name)		(llvm/escape-local-identifier self.name))

(define-form UNIQUE-LABEL ()
  `(LABEL (new-label-name -c-)))

(define-function local? (obj)
  (= <LOCAL> (type-of obj)))

(define-function temp? (obj)
  (= <TEMP> (type-of obj)))

(define-function closure-code-label (name)
  ;; KLUDGE object "names" (i.e. addresses) should be tied together
  ;; explicitly, not through giving them the "right" name
  (GLOBAL (concat-string (symbol->string name) ".code")))

(define-function closure-object-label (name)
  (GLOBAL (if feature/redefinable-functions-in-target
              (concat-string (symbol->string name) ".obj")
            name)))

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

(define-generic emit-instruction)

(define-form emit (instr-name . args)
  `(%emit -c- ,instr-name (list ,@args)))

(define-function %emit (-c- factory args)
  (let* ((instr (factory)))
    (and *compiler-verbose* (println "; EMIT of "instr", args: " args)) ; TODO move this into emit-instruction?
    (apply emit-instruction (cons -c- (cons instr args)))))

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
      (cons `(define-multimethod emit-instruction ((<llvm-compiler> -c-) (,type-name self) ,@(%emit-form/mm-params 1 args))
               ;;(println "; emitting " self)
               (let ((__regs__ (<instruction>-regs self)))
                 (with-forms (,@(%emit-form/reg-accessors (- n-regs 1)))
                   ,@body)))
            (%define-instruction/emit-forms instr-name n-regs type-name (rest emit-forms))))))

;; (define-instruction name (has-input? n-regs produces-output?) emit-forms)
(define-form define-instruction (instr-name reg-spec . emit-forms)
  (let ((has-input?		(first reg-spec))
        (n-regs			(or (second reg-spec) 0))
        (produces-output?	(third reg-spec))
        (type-name		(symbol->type-name instr-name)))
    `(let ()
       (define-record ,type-name <instruction> ())
       ;;(define-print-method ,type-name (print-all -stream- ,(symbol->string name)))
       (define-function ,instr-name ()
         (let ((i (new ,type-name)))
           (set (<instruction>-has-input? i)		',has-input?)
           (set (<instruction>-n-regs i)		',n-regs)
           (set (<instruction>-produces-output? i)	',produces-output?)
           i))
       ,@(%define-instruction/emit-forms instr-name n-regs type-name emit-forms))))

;;;
;;; Compiler early
;;;
(define-record <llvm-compiler> <compiler>
  (reg-counter
   label-counter))

(define-function llvm-compiler (level)
  (make <llvm-compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (gen-buffer			(array))
    (current-value		())

    (reg-counter		0)
    (label-counter		0)))

(define compiler llvm-compiler)

(define-function new-temp (-c-)
  (TEMP (new-temp-index -c-)))

(define-function %free-temp (-c- obj)
  (when (is <TEMP> obj)
    (push (<compiler>-temps -c-) obj)))

;;;
;;; LLVM IR Instructions
;;;
(define-function emit-llvm-fn-type (return-type param-types vararg?)
  (let ((first? true))
    (print return-type " (")
    (list-do param-type param-types
      (if first? (set first? false) (print ", "))
      (print param-type))
    (when vararg?
      (unless first? (print ", "))
      (print "..."))
    (print ")")))

(define-function emit-llvm-fn-type-for-expr (self)
  ;; TODO optimize
  (let ((param-types (map (lambda _ '%oop) (<expr>-parameters self))))
    (emit-llvm-fn-type '%oop param-types ())))

(define-function emit-llvm-C-fn-type (ffn print-name?)
  (print (C-type->llvm-type (<C-function>-return-type ffn)) " ")
  (when print-name?
    (print "@"(<C-function>-name ffn)))
  (print "(")
  (let ((first? true)
        (param-types (<C-function>-parameter-types ffn)))
    (list-do param-type (if (<C-function>-vararg? ffn)
                            (concat-list param-types (list "..."))
                          param-types)
      (if first?
          (set first? ())
        (print ", "))
      (print (C-type->llvm-type param-type))))
  (print ")"))

(define-function emit-llvm-call (result-reg name args return-type param-types vararg?)
  (let ((void? (= return-type 'void)))
    (print "	")
    (unless void?
      (print result-reg" = " ))
    (print "call ")
    (if vararg?
        (emit-llvm-fn-type return-type param-types vararg?) ; LLVM only demands a full type when calling a vararg fn
      (print return-type))              ; short version
    (print " "name"(")
    (map (let ((first? true))
           (lambda (arg)
             (let ((param-type (or (pop param-types) '%oop)))
               ;; TODO FIXME this ... situation is messy
               (when (= param-type '...)
                 (set param-type '%oop))
               (if first?
                   (set first? ())
                 (print ", "))
               (print param-type " " arg))))
         args)
    (println ")")))

(define-instruction COMMENT	()
  ;;((string)			(when *compiler-verbose* (print "; ") (println $1)))
  ((pair)			(when *compiler-verbose* (print "; ") (apply println $1))))

(define-instruction INLINE	()
  ((string)			(print $1))
  ((pair)			(apply print $1)))

(define-instruction DEFINE	()
  ((CONSTANT string)		(let ((length (+ 1 (string-length $2))))
				  (println $1" = private unnamed_addr constant [" length " x i8] c" (llvm/escape-string $2 true))))
  ((GLOBAL long)		(println $1" = global %oop inttoptr (%word "$2" to %oop)")))

(define-instruction DECLARE	()
  ((C-function)			(print "declare ") (emit-llvm-C-fn-type $1 true) (println))
  ((C-variable)			(println "@"(<C-variable>-name $1)" = external global "(C-type->llvm-type (<C-variable>-type $1)))))

(define-instruction ALLOCA	()
  ((TEMP)			(println "	"$1" = alloca %oop")))

(define-instruction SEXT	(t 1 t)
  ((LOCAL _ _)			(println "	"$reg1" = sext "$2" "$1" to "$3)))

(define-instruction INTTOPTR	(t 1 t)
  ((LOCAL _)			(println "	"$reg1" = inttoptr "$2" "$1" to %oop")))

(define-instruction BITCAST	(t 1 t)
  ((LOCAL _ _)			(println "	"$reg1" = bitcast "$2" "$1" to "$3)))

(define-instruction GEP	(t 1 t)
  ((_ _ _ _)			(println "	"$reg1" = getelementptr "$2", "$2"* "$1", i32 "$3", i32 "$4)))

(define-instruction RET		(() 1 ())
  ((LITERAL)			(println "	"$reg1" = inttoptr %word "$1" to %oop")
                                (println "	ret %oop "$reg1))
  ;; ((TEMP)			(println "	"$reg1" = load %oop, %oop* "$1)
  ;;       			(println "	ret %oop "$reg1))
  ((LOCAL)			(println "	ret %oop "$1)))

(define-instruction LOAD-VALUE	(() 1 t)
  ((LITERAL long)		(println "	"$reg1" = inttoptr %word "$1" to %oop"))
  ((TEMP    _)			(println "	"$reg1" = load %oop, %oop* "$1))
  ((GLOBAL  _)			(println "	"$reg1" = load %oop, %oop* "$1))
  ((GLOBAL  expr)		(if-at-expand feature/redefinable-functions-in-target
                                    (println "	"$reg1" = load %oop, %oop* "$1) ; this could be a call-next-method
                                  (println "	"$reg1" = bitcast %\"<target-function>\"* "$1" to %oop")))
  ((CONSTANT  expr)		(println "	"$reg1" = bitcast %\"<target-function>\"* "$1" to %oop"))
  ((GLOBAL  C-function)		(print "	"$reg1" = bitcast ")
				(emit-llvm-C-fn-type $2 false)
				(println "* @" (<C-function>-name $2) " to %oop"))
  ((GLOBAL  C-variable)		(let ((type (C-type->llvm-type (<C-variable>-type $2))))
                                  (println "	"$reg1" = load "type", "type"* @"(<C-variable>-name $2)))))

(define-instruction LOAD	(t 1 t)
  ((LOCAL)			(println "	"$reg1" = load %oop, %oop* "$1)))

(define-instruction STORE	(t 0 ())
  ((_ _)			(println "	store %oop "$1", %oop* "$2))
  ((LOCAL C-variable)		(let ((type (C-type->llvm-type (<C-variable>-type $2))))
				  (println "	store "type" "$1", "type"* @"(<C-variable>-name $2)))))

(define-instruction ADDR	(() 2 t)
  ((CONSTANT string)		(let* ((str (<CONSTANT>-value $1))
                                       (length (+ 1 (string-length str))))
                                  (println "	"$reg2" = getelementptr [" length " x i8], [" length " x i8]* "$1", %word 0, %word 0")))
  ((CONSTANT array)		(let* ((arr (<CONSTANT>-value $1))
                                       (length (array-length arr)))
                                  (println "	"$reg1" = getelementptr [" length " x %oop], [" length " x %oop]* "$1", %word 0, %word 0")
                                  (println "	"$reg2" = bitcast %oop* "$reg1" to %oop")))
  ((_ _)			(println "	"$reg1" = getelementptr %oop, %oop* "$1", %word 0")
				(println "	"$reg2" = bitcast %oop* "$reg1" to %oop")))

;; this crashes llvm: https://bugs.llvm.org/show_bug.cgi?id=49635
;; (define-instruction SPONENTRY	(() 1 t)
;;   (()				(println "	"$reg1" = i8* @llvm.sponentry()")))
;; therefore we need to do this complicated version (it's llvm.frameaddress() + 1 pointer)
(define-instruction SPONENTRY	(() 4 t)
  (()				(println "	"$reg1" = call i8* @llvm.frameaddress(i32 0)")
				(println "	"$reg2" = bitcast %oop "$reg1" to [0 x %oop]*")
				(println "	"$reg3" = getelementptr [0 x %oop], [0 x %oop]* "$reg2", %word 0, %word 1")
                                (println "	"$reg4" = bitcast %oop* "$reg3" to %oop")))

;; (define-instruction FRAMEADDRESS	(() 1 t)
;;   ((long)			(println "	"$reg1" = call i8* @llvm.frameaddress(i32 "$1")")))

(define-instruction CALL	(() 1 t)
  ((GLOBAL _)			(emit-llvm-call $reg1
                                                $1
                                                $2
                                                '%oop
                                                (map (lambda _ '%oop) $2) ; param types
                                                ()))
  ((C-function _)		(emit-llvm-call $reg1
                                                (EXTERNAL (<C-function>-name $1))
                                                $2
                                                (C-type->llvm-type (<C-function>-return-type $1))
                                                (map C-type->llvm-type (<C-function>-parameter-types $1))
                                                (<C-function>-vararg? $1))))

(define-instruction CALLPTR	(t 2 t)
  ((LOCAL _)			(let ((param-types (map (lambda _ '%oop) $2)))
                                  (print "	"$reg1" = bitcast %oop "$1" to ")
                                  (emit-llvm-fn-type '%oop param-types ())
                                  (println "*")
                                  (emit-llvm-call $reg2 $reg1 $2 '%oop param-types ()))))

(define-instruction DEFLABEL	()
  ((LABEL)			(println $1":")))

(define-instruction BR		()
  ((LABEL)			(println "	br label %"$1)))

(define-instruction BRIF	(t 2 ())
  ((LOCAL LABEL LABEL)		(println "	"$reg1" = ptrtoint %oop "$1" to %word")
				(println "	"$reg2" = icmp ne %word "$reg1", 0")
				(println "	br i1 "$reg2", label %"$2", label %"$3)))

(define-instruction NEG		(t 3 t)
  ((LOCAL)			(println "	"$reg1" = ptrtoint %oop "$1" to %word")
				(println "	"$reg2" = sub nsw %word 0, "$reg1)
				(println "	"$reg3" = inttoptr %word "$reg2" to %oop")))

(define-instruction LOGIC-NOT	(t 4 t)
  ((LOCAL)			(println "	"$reg1" = ptrtoint %oop "$1" to %word")
				(println "	"$reg2" = icmp eq %word "$reg1", 0")
				(println "	"$reg3" = zext i1 "$reg2" to %word")
				(println "	"$reg4" = inttoptr %word "$reg3" to %oop")))

(define-form define-cmp-instruction (instr-name llvm-comparator)
  `(define-instruction ,instr-name (t 4 t)
    ((LOCAL LOCAL)		(println "	"$reg1" = ptrtoint %oop "$1" to %word")
				(println "	"$reg2" = ptrtoint %oop "$2" to %word")
				(println "	"$reg3" = icmp " ,llvm-comparator " %word "$reg1", "$reg2)
				(println "	"$reg4" = inttoptr i1 "$reg3" to %oop"))))

(define-cmp-instruction LT "slt")
(define-cmp-instruction LE "sle")
(define-cmp-instruction EQ "eq")
(define-cmp-instruction GE "sge")
(define-cmp-instruction GT "sgt")
;;(define-cmp-instruction NE "ne")

(define-form define-arithmetic-instruction (instr-name llvm-op)
  `(define-instruction ,instr-name (t 4 t)
    ((LOCAL LOCAL)		(println "	"$reg1" = ptrtoint %oop "$1" to %word")
				(println "	"$reg2" = ptrtoint %oop "$2" to %word")
				(println "	"$reg3" = " ,llvm-op " %word "$reg1", "$reg2)
				(println "	"$reg4" = inttoptr %word "$reg3" to %oop"))))

(define-arithmetic-instruction ADD "add")
(define-arithmetic-instruction SUB "sub")
(define-arithmetic-instruction MUL "mul")
(define-arithmetic-instruction DIV "sdiv")

(define-arithmetic-instruction AND "and")
(define-arithmetic-instruction OR  "or")
(define-arithmetic-instruction XOR "xor")

(define-arithmetic-instruction ASL "shl")
(define-arithmetic-instruction ASR "ashr")

;; args: baseptr, index
(define-instruction LOAD-I8	(t 5 t)
  ((LOCAL LOCAL)		(println "	"$reg1" = bitcast %oop "$1" to [0 x i8]*")
				(println "	"$reg2" = ptrtoint %oop "$2" to %word")
				(println "	"$reg3" = getelementptr [0 x i8], [0 x i8]* "$reg1", %word 0, %word "$reg2)
				(println "	"$reg4" = load i8, i8* "$reg3)
				(println "	"$reg5" = inttoptr i8 "$reg4" to %oop")))

(define-instruction LOAD-OOP	(t 4 t)
  ((LOCAL LOCAL)		(println "	"$reg1" = bitcast %oop "$1" to [0 x %oop]*")
				(println "	"$reg2" = ptrtoint %oop "$2" to %word")
				(println "	"$reg3" = getelementptr [0 x %oop], [0 x %oop]* "$reg1", %word 0, %word "$reg2)
				(println "	"$reg4" = load %oop, %oop* "$reg3))
  ((LOCAL LITERAL)		(println "	"$reg1" = bitcast %oop "$1" to [0 x %oop]*")
				(println "	"$reg2" = getelementptr [0 x %oop], [0 x %oop]* "$reg1", %word 0, %word "$2)
				(println "	"$reg4" = load %oop, %oop* "$reg2)))

;; args: baseptr, index, value
(define-instruction STORE-I8	(t 6 t)
  ((LOCAL LOCAL LOCAL)		(println "	"$reg1" = bitcast %oop "$1" to [0 x i8]*")
				(println "	"$reg2" = ptrtoint %oop "$2" to %word")
				(println "	"$reg3" = getelementptr [0 x i8], [0 x i8]* "$reg1", %word 0, %word "$reg2)
				(println "	"$reg4" = ptrtoint %oop "$3" to i8")
				(println "	store i8 "$reg4", i8* "$reg3)
				(println "	"$reg5" = zext i8 "$reg4" to %word")
				(println "	"$reg6" = inttoptr %word "$reg5" to %oop")))

(define-instruction STORE-OOP	(t 4 t)
  ((LOCAL LOCAL LOCAL)		(println "	"$reg1" = bitcast %oop "$1" to [0 x %oop]*")
				(println "	"$reg2" = ptrtoint %oop "$2" to %word")
				(println "	"$reg3" = getelementptr [0 x %oop], [0 x %oop]* "$reg1", %word 0, %word "$reg2)
				(println "	store %oop "$3", %oop* "$reg3)
				(println "	"$reg4" = bitcast %oop "$3" to %oop")))

;;;
;;; Compiler
;;;

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit COMMENT (list "COMPILE of "__obj__))
     (compile __obj__ -c-)
     (<compiler>-current-value -c-)))

(define-form gen (instr-name . args)
  `(%gen -c- ,instr-name (list ,@args)))

(define-function new-reg-name (base -c-)
  (concat-string base (number->string (incr (<llvm-compiler>-reg-counter -c-)))))

(define-function new-label-name (-c-)
  (concat-string "L" (number->string (incr (<llvm-compiler>-label-counter -c-)))))

(define-function %gen (-c- factory args)
  (let ((instr (factory)))
    (when (<instruction>-has-input? instr)
      (push args (<compiler>-current-value -c-)))
    (emit COMMENT (list "GEN of "instr", args: " args))
    ;; instantiate the regs
    (set (<instruction>-regs instr)
         (let ((temps ()))
           (times-do (<instruction>-n-regs instr)
             (push temps (LOCAL (new-reg-name "r" -c-))))
           (list->array temps)))
    ;; update current-value
    (when (<instruction>-produces-output? instr)
      (assert (> (<instruction>-n-regs instr) 0))
      (set (<compiler>-current-value -c-)
           (array-at (<instruction>-regs instr)
                     (- (<instruction>-n-regs instr) 1))))
    ;; save into the gen buffer
    (array-append (<compiler>-gen-buffer -c-) (cons instr args))
    ()))

(define-function previous-instruction (-c-)
  (let* ((buffer (<compiler>-gen-buffer -c-))
         (idx (- (array-length buffer) 1)))
    (when (<= 0 idx)
      (first (array-at buffer idx)))))

(define-function emit-gen-buffer (-c-)
  (array-do entry (<compiler>-gen-buffer -c-)
    (let* ((instr (first entry))
           (args (rest entry)))
      (emit COMMENT (list "EMIT-INSTRUCTION of "instr", args: "args))
      (apply emit-instruction (cons -c- (cons instr args))))))

;;;
;;; Emitting objects
;;;
;;; if you want to grok this, then you better head over to the x86 backend...

;; KLUDGE this shouldn't be done by hand, but automated based on the type meta-data
;; TODO optimize: these are doing a lot of repeated work with all the slave-value calls

(define-function emit-object-header (type-id)
  (print "%\"<header>\" { %word "
         (slave-value (+ <header>-flags/used <header>-flags/opaque))
         ", %word "type-id)
  (when (slave-value feature/object-canary)
    (print ", %word "(slave-value +canary-value+)))
  (print "}"))

(define-function emit-object/<long> (self -c-)
  (cond
    ((slave-value (is <immediate-type> <long>))
     (eval-in-slave `(box <long> ,self)))
    ((slave-value (and (is <boxed-type> <long>)
                       (<boxed-type>-one-word? <long>)))
     (emit-object-header (slave-value (<type>-slave-id <long>)))
     ;; TODO the "receiving place" of this value needs to by typesafe
     ;; emitting variable <long> representation requires a place to
     ;; keep track of such session-wide config/cache that -c- cannot
     ;; do currently, because it's recreated for each level.
     (error "TODO emit-object/<long>"))
    (else
     (error "emit-object/<long>: unexpected slave representation for <long>"))))

(define-function emit-object/C-string (self -c-)
  (let ((const (CONSTANT (GLOBAL (unique-name "cstr")) self)))
    (emit DEFINE const self)
    const))

(define-function emit-object/<string> (self -c-)
  ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
  (let ((elements	(emit-object/C-string self -c-))
        (object-label	(GLOBAL (unique-name "ostr"))))
    ;; TODO? this here is an (emit DEFINE (CONSTANT ...) ...) inlined
    (print object-label" = private unnamed_addr constant %\"<string>\" { ")
    (emit-object-header (slave-value (<type>-slave-id <string>)))
    (print ", %word "
           ;; FIXME this only works when <long> is an immediate
           (eval-in-slave `(box <long> ,(string-length self)))
           ", %oop bitcast (["(+ 1 (string-length self))" x i8]* "elements" to %oop) }\n")
    object-label))

(define-function emit-object/<target-function> (expr name entry-label -c-)
  (let ((object-label	(if name
                            (closure-object-label name)
                          (GLOBAL (unique-name "oclosure"))))
        (name-obj	(when (slave-value feature/track-expr-names)
                          (if name
                              (emit-object/<string> (symbol->string name) -c-)
                            "null")))
        ;; TODO a counter in the read-only space?
        (profiler-counter (when (slave-value feature/profiler)
                            (emit-object/<long> 0 -c-))))
    ;; TODO? this here is an (emit DEFINE (CONSTANT ...) ...) inlined
    (print object-label" = private unnamed_addr constant %\"<target-function>\" { ")
    (emit-object-header (slave-value (<type>-slave-id <string>)))
    (print ", %oop bitcast (")
    (emit-llvm-fn-type-for-expr expr)
    (print "* "entry-label" to %oop)")
    (and name-obj (print ", %\"<string>\"* "name-obj))
    (and profiler-counter (print ", %word "profiler-counter))
    (print " }\n")
    (CONSTANT object-label expr)))

;;;
;;; Compiling lambdas
;;;

(define-function compile/prog-into-temp (prog -c-)
  (assert (pair? prog) "compile/prog-into-temp: prog is empty") ; against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-temp -c-)))
    (gen STORE temp)
    temp))

(define-function emit/comma-separated-%oops (params)
  (let ((first? true))
    (list-do param params
      (if first?
          (set first? ())
        (print ", "))
      (print "%oop ")
      (print param))))

(define-function emit/function-prologue (name params)
  (print "define %oop "name"(")
  (emit/comma-separated-%oops params)
  (println ") {"))

(define-function emit/function-epilogue ()
  (println "}"))

(define-function emit-expr-code (self entry-point-label parent-comp)
  (let* ((body		(<expr>-body self))
         (-c-		(llvm-compiler (+ 1 (<compiler>-level parent-comp))))
         (parameters	(<expr>-parameters self))
         (init-param	(lambda (var)
                          (set (<variable>-value var)
                               (if +function-parameters-are-read-only+
                                   (LOCAL (<variable>-name var))
                                 (alloc-temp -c-)))))
         (param-locs	(map init-param parameters))
         (param-decls	(map (lambda (var)
                               (LOCAL (<variable>-name var)))
                             parameters)))
    (emit COMMENT (list "emitting <expr> "self", code: "(<expr>-body self)))
    (list-do e body
      (comp e))

    (emit/function-prologue entry-point-label param-decls)

    (unless +function-parameters-are-read-only+
      (free-temps param-locs))

    ;; all temps must be free-temp'ed properly at this point.
    (map (lambda (tmp)
           (emit ALLOCA tmp))
         (<compiler>-temps -c-))

    ;; store the parameters in the temps
    (unless +function-parameters-are-read-only+
      (map (lambda (local temp)
             (emit STORE local temp))
           param-decls param-locs))

    ;; make sure we finish off with a ret
    (unless (= <RET> (type-of (previous-instruction -c-)))
      (gen RET (or (<compiler>-current-value -c-)
                   (LITERAL 0))))

    ;; emit the body from the gen buffer
    (emit-gen-buffer -c-)

    (emit/function-epilogue)))

(define-function compile-expr (self name -c-)
  (emit COMMENT (list "compiling fn "name", "self))
  (let ((entry-point-label (if name
                               (closure-code-label name)
                             (GLOBAL (unique-name "code")))))
    (emit-expr-code self entry-point-label -c-)
    (emit-object/<target-function> self name entry-point-label -c-)))

;;;
;;; Compiling calls
;;;

(define-function compile-call (op args raw? -c-)
  (safety 2 (assert (or (pair? op) (variable? op))))
  (let ((arg-regs (map (lambda (arg)
                         (gen COMMENT (list "arg " arg))
                         (comp arg)
                         (<compiler>-current-value -c-))
                       args)))

    (let* ((op-value	(if (variable? op)
                            (<variable>-value op)
                          op))
           (n-params	(if raw?
                            (let ()
                              (comp op)
                              (gen CALLPTR arg-regs))
                          (compile-call-to op-value op arg-regs -c-)))
          (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))))

(define-function compile-call-to-object (arg-regs -c-)
  ;; TODO assert the type to be <target-function>
  ;; TODO assert nr of args = params
  (gen BITCAST '%oop "%\"<target-function>\"*")
  (gen GEP (LOCAL '<target-function>) 0 1) ; TODO use (record/slot-index <target-function> 'program-code)
  (gen LOAD)
  (gen CALLPTR arg-regs)
  ())

(define-function compile-call-to-global-function (op arg-regs -c-)
  (if feature/redefinable-functions-in-target
      (let ()
        (comp op)
        (compile-call-to-object arg-regs -c-))
    (gen CALL (closure-code-label (<variable>-name op)) arg-regs))
  ())

(define-method compile-call-to <TEMP> (op arg-regs -c-)
  (comp op)
  (compile-call-to-object arg-regs -c-)
  ())

(define-method compile-call-to <pair> (op arg-regs -c-)
  (comp op)
  (compile-call-to-object arg-regs -c-)
  ())

(define-method compile-call-to <expr> (op arg-regs -c-)
  (compile-call-to-global-function op arg-regs -c-)
  (expr-n-required-parameters self))

(define-method compile-call-to <C-function> (op arg-regs -c-)
  (let ((param-types self.parameter-types))
    (gen COMMENT (list "	casting FFI args"))
    ;; for FFI calls we need to cast the non-pointer llvm args
    ;; using ptrtoint to the specific llvm type.
    (let ((param-type	())
          (new-arg-regs	())
          (arg		())
          (arg-lst	arg-regs)
          (param-lst	param-types))
      (while (set arg (pop arg-lst))
        (set param-type (awhen (pop param-lst)
                          (C-type->llvm-type it)))
        (if (or (= ()    param-type) ; vararg calls have more args than params
                (= '%oop param-type))
            (push new-arg-regs arg)
          (let ((cast-reg (LOCAL (new-reg-name "ffi-cast" -c-))))
            ;; TODO check for value range issues?
            (gen INLINE (list "	"cast-reg" = ptrtoint %oop "arg" to "param-type"\n"))
            (push new-arg-regs cast-reg))))
      ;; gen the call itself
      (gen CALL self (list-reverse! new-arg-regs)))
    ;; convert return value
    (let ((return-type (C-type->llvm-type self.return-type)))
      (case return-type
        (%oop)                          ; all good
        (void
         (gen COMMENT (list "	void FFI call return value"))
         (gen LOAD-VALUE (LITERAL 0) 0))
        (else
         (let ((bitsize	(llvm-type-bitsize return-type))
               (word-size	(target-value +word-size-in-bits+)))
           (cond
             ((< bitsize word-size)
	      (gen SEXT return-type '%word))

             ((> bitsize word-size)
	      (error "This shouldn't happen: (> bitsize +word-size-in-bits+) for FFI type " return-type))))
         (gen INTTOPTR '%word))))
    (unless (<C-function>-vararg? self)
      (list-length param-types))))

(define-method compile-call-to (slave-value <selector>) (op arg-regs -c-)
  (compile-call-to-global-function op arg-regs -c-)
  ;; TODO extract and return n-params
  ())

;;;
;;; Special Forms
;;;

(define-function compile/let-binding (binding -c-)
  ;; we unconditionally initialize empty bindings to () to avoid hidden bugs,
  ;; at a small cost of initializing temp locations even when it wouldn't be necessary.
  (unless (pair? binding)
    (set binding (list binding ())))
  (unless (cdr binding)
    (set binding (list (car binding) ())))
  (let ((var (car binding))
        (prg (cdr binding)))
    (assert (= (type-of var) <variable>) "compile/let-binding: encountered a non-variable: " var)
    (set (<variable>-value var) (compile/prog-into-temp prg -c-))))

(define-function compile/let (expr -c-)
  (let ((temps (map-with compile/let-binding (third expr) -c-)))
    (list-do form (cdddr expr)
      (comp form))
    (list-do temp temps
      (free-temp temp))))

(define-function %compile/and-or (op expr -c-)
  (let ((lend	(UNIQUE-LABEL))
        (retval	(alloc-temp -c-)))
    (gen LOAD-VALUE (LITERAL (case op
                               (and (target-value true))
                               (or  (target-value false))))
         0) ; just for the type dispatch
    (gen STORE retval)
    (while (set expr (rest expr))
      (let ((value-reg (comp (first expr))))
        (gen STORE retval)
        (gen LOAD-VALUE (LITERAL 0) 0)
        (gen EQ value-reg))
      (let ((lcont (UNIQUE-LABEL)))
        (case op
          (and (gen BRIF lend  lcont))
          (or  (gen BRIF lcont lend)))
        (gen DEFLABEL lcont)))
    (gen BR lend)
    (gen DEFLABEL lend)
    (gen LOAD-VALUE retval ())
    (free-temp retval)))

(define-function compile/and (expr -c-)
  (%compile/and-or 'and expr -c-))

(define-function compile/or (expr -c-)
  (%compile/and-or 'or  expr -c-))

(define-function compile/if (expr -c-)
  (let ((ltrue	(UNIQUE-LABEL))
        (lfalse	(UNIQUE-LABEL))
        (lend	(UNIQUE-LABEL))
        (retval	(alloc-temp -c-)))
    (comp (second expr))                ; condition
    (gen BRIF ltrue lfalse)

    ;; true
    (gen DEFLABEL ltrue)
    (comp (third expr))
    (gen STORE retval)
    (gen BR lend)

    ;; false
    (gen DEFLABEL lfalse)
    (let ((else-prg (cdddr expr)))
      (if else-prg
          (list-do stmt else-prg
            (comp stmt))
        (gen LOAD-VALUE (LITERAL 0) 0))
      (gen STORE retval))
    (gen BR lend)

    ;; end
    (gen DEFLABEL lend)
    (gen LOAD-VALUE retval ())
    (free-temp retval)))

(define-function compile/while (expr -c-)
  ;; TODO double-check the return value semantics
  (let ((l/body	(UNIQUE-LABEL))
        (l/cond	(UNIQUE-LABEL))
        (l/done	(UNIQUE-LABEL)))
    (gen BR l/cond)

    (gen DEFLABEL l/body)
    (list-do stmt (cddr expr)
      (and stmt (comp stmt)))
    (gen BR l/cond)

    (gen DEFLABEL l/cond)
    (comp (second expr))

    (gen BRIF l/body l/done)

    (gen DEFLABEL l/done)))

(define-function compile/set (expr -c-)
  (let* ((var	(second expr))
         (value	(<variable>-value var)))
    (accessible-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ;; NOTE the LLVM IR is SSA, LOCALs cannot be written
      ((temp? value)
       (gen STORE value))
      ((global-variable? var)
       (cond
         ((is <C-variable> value)
          (gen BITCAST '%oop (C-type->llvm-type (<C-variable>-type value)))
          (gen STORE value))
         (else
          (gen STORE (GLOBAL (<variable>-name var))))))
      (else
       (error "compile/set failed for variable " (<variable>-name var) ", holding value " value)))))

(define-function compile/lambda (form -c-)
  (let* ((expr	(eval form))
         (label	(compile-expr expr () -c-)))
    ;; NOTE compile-expr returns with a CONSTANT here
    (gen LOAD-VALUE label expr)))

(define-function compile/return (form -c-)
  (assert (<= (list-length form) 2))
  (let ((value (second form)))
    (comp value)
    (gen RET (<compiler>-current-value -c-))))

(define-function compile/address-of (expr -c-)
  (let ((var (second expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (cond
        ((global-variable? var)
         (gen ADDR (GLOBAL (<variable>-name var)) val))
        ((temp? val)
         (gen ADDR val ()))
        (else
         (error "compile/address-of don't know how to handle "var", holding value "val))))))

(define-function compile/C-string (expr -c-)
  ;; just an optimization to compile string literals into a C string
  ;; when they would be immediately converted anyway.
  (safety 1 (assert (= (list-length expr) 2)))
  (let* ((str (second expr))
         (const (emit-object/C-string str -c-)))
    (gen ADDR const str)))

;;;
;;; linux syscalls
;;;
;;; https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/
;;; https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux

(eval-in-slave `(define linux-syscall (fixed (lambda args (print "linux-syscall encountered in interpreted code with args " args "\n") (abort)))))

(define-instruction LINUX-SYSCALL (() 1 t)
  ;; TODO does this properly communicate to LLVM which registers get overwritten?
  ((pair)
   (println "	"$reg1" = call %oop asm sideeffect \"")
   (let ((arg-index	1)
         (clobbers	())
         mov syscall regs)
     (case (slave-value +architecture+)
       (IA-32
        (set mov	"	movl")
        (set syscall	"	int	$$0x80")
        (set regs	+linux/syscall-registers/32+))
       (x86-64
        (set mov	"	movq")
        (set syscall	"	syscall")
        (set regs	+linux/syscall-registers/64+)
        ;; https://stackoverflow.com/questions/47983371/why-do-x86-64-linux-system-calls-modify-rcx-and-what-does-the-value-mean
        ;; https://refspecs.linuxfoundation.org/elf/x86_64-abi-0.99.pdf
        ;; "The kernel destroys registers %rcx and %r11."
        (push clobbers "rcx")
        (push clobbers "r11"))
       (else
        (error "LLVM LINUX-SYSCALL instruction is not implemented for +architecture+ "(slave-value +architecture+))))
     (list-do _ $1
       (let ((reg (pop regs)))
         (push clobbers reg)
         (println mov"	$"arg-index", %"reg)
         (incr arg-index)))
     (println syscall"\", ")
     (print "	\"=A")
     (list-do _ $1
       ;; TODO this should be (print ",r") to use rigsters, but then
       ;; on 32 bits it fails because movl doesn't support the
       ;; register combination (or something like that):
       ;; error: invalid operand for instruction
       ;;  movl    %rdx, %eax
       (print ",r"))
     ;; list clobbered registers
     (while clobbers
       (print ",~{"(pop clobbers)"}"))
     ;; ~{memory} indicates that the assembly writes to arbitrary undeclared memory
     ;; locations - not only the memory pointed to by a declared indirect output.
     (print ",~{memory}\"\n	(")
     (emit/comma-separated-%oops $1)
     (println ")"))))

(define-function compile/linux-syscall (expr -c-)
  (let ((args		(cdr expr))
        (arg-locs	()))
    (while args
      (comp (pop args))
      (push arg-locs (<compiler>-current-value -c-)))
    (gen LINUX-SYSCALL (list-reverse! arg-locs))))

(define +special-forms+ (list
  (cons (target-value let)		compile/let)
  (cons (target-value and)		compile/and)
  (cons (target-value or)		compile/or)
  (cons (target-value if)		compile/if)
  (cons (target-value while)		compile/while)
  (cons (target-value set)		compile/set)
  (cons (target-value lambda)		compile/lambda)
  (cons (target-value return)		compile/return)
  (cons (target-value address-of)	compile/address-of)
  (cons (target-value linux-syscall)	compile/linux-syscall)
  (cons (target-value C-string)		compile/C-string)
  ;;(cons (target-value C-call)		(lambda (expr -c-) (compile-call (second expr) (cddr expr) true -c-)))
  (cons (target-value stack-pointer-on-entry)	(lambda (expr -c-) (gen SPONENTRY)))
  ))

;;;
;;; Special Operators
;;;

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  (gen op))

;; FIXME? these implement a right-to-left evaluation order, while
;; function calls implement the opposite. note that this is entangled
;; with e.g. the LOAD/STORE instructions above, as the ones that mark
;; that they have an input will receive <compiler>-current-value as
;; their first, $1 param. changing the order here needs to take care
;; of that.
(define-function compile/binary-operator (op args -c-)
  (comp (second args))
  (let ((arg2 (<compiler>-current-value -c-)))
    (comp (first args))
    (gen op arg2)))

(define-function compile/ternary-operator (op args -c-)
  (let ((tmp2 (let ()
                (comp (third  args))
                (<compiler>-current-value -c-)))
        (tmp1 (let ()
                (comp (second args))
                (<compiler>-current-value -c-))))
    (comp (first args))
    (gen op tmp1 tmp2)))

(define +operator-compilers+ (list->array (list () compile/unary-operator compile/binary-operator compile/ternary-operator)))

;; a vector of assoc lists indexed by operator arity
(define +special-operators+
    (let ((table
           `(;; nullary
             ()
             ;; unary
             ((-  ,NEG) (not ,LOGIC-NOT))
             ;; binary
             ((+  ,ADD) (-   ,SUB) (* ,MUL) (/ ,DIV)
              (bitwise-and  ,AND) (bitwise-or   ,OR ) (bitwise-xor ,XOR)
              (<  ,LT ) (<=  ,LE ) (= ,EQ ) (>= ,GE) (> ,GT) ; (!= ,NE)
              (arithmethic-shift-left ,ASL) (arithmethic-shift-right  ,ASR)
              (char-at		,LOAD-I8)
              (byte-at		,LOAD-I8)
              (oop-at		,LOAD-OOP))
             ;; ternary
             ((set-char-at	,STORE-I8)
              (set-byte-at	,STORE-I8)
              (set-oop-at	,STORE-OOP)))))
      (list->array
       (map (lambda (arity-line)
              (map (lambda (entry)
                     (let* ((op-name (car entry))
                            (op (eval-in-target op-name)))
                       (assert op "operator not found while building +special-operators+: "op)
                       (cons op (cdr entry))))
                   arity-line))
            table))))

(define-method compile <undefined> (-c-)
  (let ((false-value (target-value false)))
    (gen LOAD-VALUE (LITERAL false-value) false-value)))

(define-method compile <long> (-c-)
  (gen LOAD-VALUE (LITERAL self) self))

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((local? value)		(set (<compiler>-current-value -c-) value))
      ((temp? value)		(gen LOAD-VALUE value ()))
      ((global-variable? self)	(let ((value-type (type-of value)))
                                  (cond
                                    ((= 'true self.name)
                                     (let ((true-value (target-value true)))
                                       (gen LOAD-VALUE (LITERAL true-value) true-value)))
                                    ((subtype? value-type <type>)
                                     ;; generics don't support inheritance yet, so let's short-circuit all <type>'s here into a LITERAL
                                     (gen LOAD-VALUE (LITERAL (eval-in-slave `(<type>-slave-id ,value))) 0))
                                    ((is <C-variable> value)
                                     (gen LOAD-VALUE (EXTERNAL (<C-variable>-name value)) value)
                                     (gen BITCAST (C-type->llvm-type (<C-variable>-type value)) '%oop))
                                    (else
                                     (gen LOAD-VALUE (GLOBAL self.name) value)))))
      (else
       (error "compile of <variable> failed for " self ", holding the value " value)))))

(define-method compile <string> (-c-)
  (set (<compiler>-current-value -c-)
       (emit-object/<string> self -c-))
  (gen GEP (LOCAL '<string>) 0 1) ; 1 means skip the header
  (gen BITCAST "%word*" "%oop"))

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
    (cond
      ((set handler (second (assq op-value (array-at +special-operators+ arity))))
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((set handler (cdr (assq op +special-forms+)))
       (handler self -c-))
      (else
       (compile-call op args false -c-)))))

;;;
;;; COMPILE-DEFINITION
;;;
(define-method compile-definition <type>		(name -c-)	(emit COMMENT (list "type "name))) ; we don't need (target-value <type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition 0 name -c-))
(define-method compile-definition <C-function>		(name -c-)	(emit DECLARE self))
(define-method compile-definition <C-variable>		(name -c-)	(emit DECLARE self))
(define-method compile-definition <long>		(name -c-)	(emit DEFINE (GLOBAL name) self))

(define-method compile-definition <expr> (name -c-)
  (let ((object-label (compile-expr self name -c-)))
    (when (member? name '(main _start))
      ;; KLUDGE export special casing
      (print (EXTERNAL name)" = external alias ")
      (emit-llvm-fn-type-for-expr self)
      (print ", ")
      (emit-llvm-fn-type-for-expr self)
      (println "* "(closure-code-label name)))
    (when feature/redefinable-functions-in-target
      ;; TODO? this here is an (emit DEFINE (GLOBAL ...) ...) inlined
      (println (GLOBAL name)" = global %oop bitcast(%\"<target-function>\"* "
               object-label" to %oop)"))))

;; kinda KLUDGE
;; this is used when emitting the literal dispatch tables of <selectors>
(define-method compile-definition <array> (name -c-)
  (let ((compiled	(compile-array self -c-))
        (array-label	(GLOBAL (unique-name "arr"))))
    (let ((first? true))
      (print array-label" = private unnamed_addr constant ["(array-length compiled)" x %oop] [")
      (array-do el compiled
        (if first? (set first? false) (print ", "))
        (print "%oop ")
        (if el
            (print "bitcast (%\"<target-function>\"* "el" to %oop)")
          (print "null")))
      (println "]"))
    (print (GLOBAL name)" = global %oop bitcast (["(array-length compiled)" x %oop]* "
           array-label" to %oop)")))

(define-method emit-prelude <llvm-compiler> ()
  (let (;;(target-triplet		(slave-value +target-triplet+))
        (word-size		(target-value +word-size-in-bits+))
        (-c- self))
    (verbosity 1 (warn "\nCompiling to LLVM, word size: " word-size " bits\n\n"))
    ;;(assert (string?	target-triplet))
    (assert (long?	word-size))
    ;; our output is less specific, so allow the makefile, or whoever builds the
    ;; bitcode output to chose the proper target triplet.
    ;;(emit INLINE (concat-strings "target triple = \"" target-triplet "\"\n"))
    (emit INLINE (list "%word = type i"word-size"\n"))
    (emit INLINE "%oop = type i8*\n")
    ;; TODO this should be done by a general emitter
    (emit INLINE (list "%\"<header>\" = type { %word, %word"
                       (if (and (slave-value (defined? 'feature/object-canary))
                                (slave-value feature/object-canary))
                           ", %word"
                         "")
                       " }\n"))
    (cond
      ((slave-value (is <immediate-type> <long>))
       ())
      ((slave-value (and (is <boxed-type> <long>)
                         (<boxed-type>-one-word? <long>)))
       (error "TODO LLVM emit-object/<string> only supports immediate <long> representation for now")
       (emit INLINE "%\"<long>\" = type { %\"<header>\", %word }\n"))
      (else
       (error "LLVM emit-prelude: unexpected slave representation for <long>")))
    (emit INLINE "%\"<string>\" = type { %\"<header>\", %word, %oop }\n")
    (emit INLINE (list "%\"<target-function>\" = type { %\"<header>\", %oop "
                       (if (slave-value feature/track-expr-names)
                           ", %\"<string>\"* " "")
                       (if (slave-value feature/profiler)
                           ", %word" "")
                       "}\n"))
    ;; we represent libc's FILE* with an opaque type
    (emit INLINE "%m_libc-FILE = type opaque\n")
    ;;(emit INLINE "declare i8* @llvm.sponentry()\n")
    (emit INLINE "declare i8* @llvm.frameaddress(i32)\n")
    ))
