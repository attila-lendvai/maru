(require "trie.k")

(define-structure <ir> (function scope program functions struct-types frame error-handler))

(define ir-scope-new) ;; forward
(define ir-frame-new) ;; forward
(define ir-error-handler-new) ;; forward

(define-function ir-new (parent . opts)
  (new <ir> (car opts)
       (ir-scope-new (and parent (<ir>-scope parent)))
       (array) (array) ()
       (ir-frame-new)
       (if parent (<ir>-error-handler parent) (ir-error-handler-new))))

(define-function ir-append (ir insn)		(array-append (<ir>-program ir) insn))
(define-function ir-append-all (ir insns)	(list-do insn insns (ir-append ir insn)))
(define-function ir-append-function (ir fn)	(array-append (<ir>-functions ir) fn))

;;; types

(define-structure <ir-type> (name size alignment pointer function))

(define-function ir-type-size (self)		(<ir-type>-size	     self))
(define-function ir-type-alignment (self)	(<ir-type>-alignment self))

(define-class <ir-void-type>   	 <ir-type> ())
(define-class <ir-scalar-type> 	 <ir-type> ())				(define-function ir-scalar-type? (x)	(inherits-from (type-of x) <ir-scalar-type>))
(define-class <ir-numeric-type>  <ir-scalar-type> ())			(define-function ir-numeric-type? (x)	(inherits-from (type-of x) <ir-numeric-type>))
(define-class <ir-integral-type> <ir-numeric-type> ())			(define-function ir-integral-type? (x)	(inherits-from (type-of x) <ir-integral-type>))
(define-class <ir-floating-type> <ir-numeric-type> ())			(define-function ir-floating-type? (x)	(inherits-from (type-of x) <ir-floating-type>))
(define-class <ir-varargs-type>  <ir-type> ())

(define IR-VOID		(new <ir-void-type>	'void	0 1))
(define IR-INT8		(new <ir-integral-type> 'int8   1 1))
(define IR-INT16	(new <ir-integral-type> 'int16  2 2))
(define IR-INT32	(new <ir-integral-type> 'int32  4 4))
(define IR-INT64	(new <ir-integral-type> 'int64  8 8))
(define IR-FLOAT32	(new <ir-integral-type> 'float  4 4))
(define IR-FLOAT64	(new <ir-integral-type> 'double 8 8))
(define IR-VARARGS	(new <ir-varargs-type>  '...	0 0))

(define IR-INT		IR-INT32)
(define IR-LONG		IR-INT32)
(define IR-FLOAT	IR-FLOAT32)
(define IR-DOUBLE	IR-FLOAT64)

(define IR-BOOL		IR-INT)

(define-class <ir-pointer-type>	 <ir-scalar-type> (referent))		(define-function ir-pointer-type? (x)	(inherits-from (type-of x) <ir-pointer-type>))

(define-function ir-pointer-to (type)
  (or (<ir-type>-pointer type)
      (set (<ir-type>-pointer type)
	   (new <ir-pointer-type> (list (<ir-type>-name type) '*)
		(<ir-type>-size      IR-LONG)
		(<ir-type>-alignment IR-LONG) () ()
		type))))

(define IR-VOID*	(ir-pointer-to IR-VOID))
(define IR-STRING	(ir-pointer-to IR-INT8))

(define-function ir-bool? (type)	(or (ir-integral-type? type) (ir-pointer-type? type)))

(define-class <ir-function-type> <ir-type> (ret-type arg-types))	(define-function ir-function-type? (x)	(inherits-from (type-of x) <ir-function-type>))

(define-function ir-function-of (ret-type param-types)
  (let ((funcs (or (<ir-type>-function ret-type)
		   (set (<ir-type>-function ret-type) (trie-new)))))
    (or (trie-at funcs param-types)
	(set-trie-at funcs param-types
		     (new <ir-function-type> (list '-> ret-type param-types)
			  0 0 () ()
			  ret-type param-types)))))

;

(define-class <ir-struct-type> <ir-type> (members))			(define-function ir-struct-type? (x)	(inherits-from (type-of x) <ir-struct-type>))

(define-method do-print <ir-struct-type> ()	(print "{struct "self.name"}"))

(define-function ir-declare-struct-type (self name members)
  (let ((type (cdr (assq name (<ir>-struct-types self)))))
    (if type
	(let ()
	  (and (<ir-struct-type>-members type)
	       (error "multiple definition of structure type: "name))
	  (set (<ir-struct-type>-members type) members))
      (set type (make <ir-struct-type> (name name) (members members)))
      (push (<ir>-struct-types self) (cons name type)))
    type))

(define-function ir-struct (ir name)
  (or (cdr (assq name (<ir>-struct-types ir)))
      (ir-declare-struct-type ir name ())))

(define-structure <ir-struct-member> (name type offset))

(define-method do-print <ir-struct-member> ()
  (print "<ir-struct-member "self.name" : "self.type" @ "self.offset">"))

(define-function ir-finalise-structs (ir gen)
  (list-do s (<ir>-struct-types ir)
    (let ((sname     (car s))
	  (stype     (cdr s))
	  (offset    0)
	  (alignment 1))
      (list-do m (<ir-struct-type>-members stype)
	(let* ((mname  (car m))
	       (mtype  (cdr m))
	       (msize  (<ir-type>-size mtype))
	       (malign (<ir-type>-alignment mtype)))
	  (set offset (align offset malign))
	  (set-cdr m (new <ir-struct-member> mname mtype offset))
	  (set alignment (max alignment malign))
	  (incr offset msize)))
      (set (<ir-type>-size stype) offset)
      (set (<ir-type>-alignment stype) alignment)
      )))

;

(define-method do-print <ir-type> ()		(print self.name))

(define-method do-print <ir-pointer-type> ()	(print self.referent "*"))

(define-method do-print <ir-function-type> ()
  (print self.ret-type"(")
  (let ((a self.arg-types))
    (while a
      (print (car a))
      (if (pair? (set a (cdr a)))
	  (print ", "))))
  (print ")"))

;;; variables

(define-structure <ir-variable> (name type location))

(define-method do-print <ir-variable> ()
  (print "{"(type-name-of self)" "self.name" : "self.type)
  (and self.location (print " @ "self.location))
  (print "}"))

(define-class <ir-global>    <ir-variable> ())
(define-class <ir-local>     <ir-variable> ())
(define-class <ir-parameter> <ir-variable> ())

(define-structure <ir-location> (zone offset))			;; relative to the frame pointer

(define-method do-print <ir-location> ()	(print self.zone"["self.offset"]"))

;

(define-structure <ir-zone> (type locations index limit))	;; one or more contiguous locations sharing a common type

(define-method do-print <ir-zone> ()		(print "@"self.type))

(define-function ir-zone-new (type)		(new <ir-zone> type (array) 0 0))

(define-function ir-zone-allocate (self)
  (with-instance-accessors <ir-zone>
    (let ((var (if (< self.index self.limit)
		   (array-at self.locations self.index)
		 (set-array-at self.locations self.index (new <ir-location> self self.index)))))
      (set self.limit (max self.limit (incr self.index)))
      var)))

(define-function ir-zone-deallocate (self loc)
  (with-instance-accessors <ir-zone>
    (decr self.index)
    (or (= loc (array-at self.locations self.index))
	(error "non-lifo frame allocation"))))

;

(define-structure <ir-frame> (zones))				;; zero or more contiguous zones

(define-function ir-frame-new ()	(new <ir-frame>))

(define-function ir-frame-allocate (self type)
  (with-instance-accessors <ir-frame>
    (ir-zone-allocate (cdr (or (assq type self.zones)
			       (car (push self.zones (cons type (ir-zone-new type)))))))))

(define-function ir-frame-finalise (self)
  (with-instance-accessors <ir-frame>
    (let ((offset 0))
      (list-do name-zone self.zones
	;;(println name-zone)
	(let ((zone (cdr name-zone)))
	  (let ((type (<ir-zone>-type zone)))
	    (array-do loc (<ir-zone>-locations zone)
	      ;;(println loc)
	      (set offset (align offset (<ir-type>-alignment type)))
	      (set (<ir-location>-offset loc) offset)
	      (incr offset (<ir-type>-size type)))))))))

(define-function ir-finalise (ir)	(ir-frame-finalise (<ir>-frame ir)))

;

(define-structure <ir-scope> (parent bindings))

(define-function ir-scope-new (parent)		(new <ir-scope> parent))

(define-function ir-scope-find (self key)	(assq key (<ir-scope>-bindings self)))

(define-function ir-scope-lookup (self key)
  (and self
       (or (ir-scope-find self key)
	   (ir-scope-lookup (<ir-scope>-parent self) key))))

(define-function ir-scope-define (self key value)
  (let ((binding (ir-scope-find self key)))
    (if binding
	(set-cdr binding value)
      (set binding (cons key value))
      (push (<ir-scope>-bindings self) binding))
    binding))

(define-form ir-scope-do (var scope . body)
  `(let ((_bindings_ (<ir-scope>-bindings ,scope)))
     (while _bindings_
       (let ((,var (cdar _bindings_)))
	 ,@body
	 (set _bindings_ (cdr _bindings_))))))

(define-function ir-begin-scope (self)
  (set (<ir>-scope self) (ir-scope-new (<ir>-scope self))))

(define-function ir-end-scope (self . opts)
  (let ((bindings (<ir-scope>-bindings (<ir>-scope self))))
    (list-do bind bindings
      (let* ((var  (cdr bind))
	     (loc  (<ir-variable>-location var)))
	(ir-zone-deallocate (<ir-location>-zone loc) loc)))
    (set (<ir>-scope self) (if opts (car opts) (<ir-scope>-parent (<ir>-scope self))))
    bindings))

(define-function ir-declare (ir name variable)
  (ir-scope-define (<ir>-scope ir) name variable)
  variable)

(define-function ir-lookup (ir name)
  (cdr (or (ir-scope-lookup (<ir>-scope ir) name)
	   (error "ir-lookup: undefined: "name))))

(define-form assert (what) `(or ,what (error "assertion failed")))

(define-function ir-declare-global    (ir name type)	(ir-declare ir name (new <ir-global>    name type)))

(define-function ir-declare-parameter (ir name type)
  (or type (error "declaration has no type: "name))
  (ir-declare ir name (new <ir-parameter> name type (ir-frame-allocate (<ir>-frame ir) type))))

(define-function ir-declare-local (ir name type)
  (or type (error "declaration has no type: "name))
  (ir-declare ir name (new <ir-local> name type (ir-frame-allocate (<ir>-frame ir) type))))

;;; errors

(define-structure <ir-error-handler> ())

(define-function ir-error-handler-new () (new <ir-error-handler>))

(define-method ir-warning <ir-error-handler> (message source)	(println "warning: "message": "source))
(define-method ir-error <ir-error-handler> (message source)	(error message": "source))

(define ir-error-source) ;; forward

(define-function ir-error-no-value    (ir insn)		(ir-error   (<ir>-error-handler ir) "statement has no value"   (ir-error-source insn)))
(define-function ir-warning-no-effect (ir insn)		(ir-warning (<ir>-error-handler ir) "expression has no effect" (ir-error-source insn)))

;;; instructions

(define-structure <ir-insn> (parameters operands type source))

(define-function ir-error-source (insn)	(or (<ir-insn>-source insn) insn))

(define-function ir-insn-print (self level)
  (with-instance-accessors <ir-insn>
    (for (i 0 level) (print "  "))
    (print "{ "(type-name-of self))
    (when self.parameters (print " ") (dump self.parameters))
    (when self.type (print" : "self.type))
    (list-do operand self.operands (println) (ir-insn-print operand (+ level 1)))
    (print " }")))

(define-method do-print <ir-insn> ()	(ir-insn-print self 0))

(define-function insn (type . operands)		(new type () operands))
(define-function leaf (type . parameters)	(new type parameters))

(define-selector ir-returns?)

(define-method ir-returns? <ir-insn> ()		())
(define-method ir-returns? <ir> ()		(ir-returns? (array-last self.program)))
;

(define ir-nop) ;; forward

(define-selector ir-check-type)

(define-function ir-check-types (ir)
  (array-do insn (<ir>-program ir)
    (ir-check-type insn ir ())))

(define-method ir-check-type <long>   (ir val?)	IR-LONG)
(define-method ir-check-type <double> (ir val?)	IR-DOUBLE)
(define-method ir-check-type <string> (ir val?)	IR-STRING)

(define-function ir-can-assign (ltype rtype rhs)
  (or (=                     ltype                    rtype )
      (and (= IR-VOID*       ltype) (ir-pointer-type? rtype))
      (and (ir-pointer-type? ltype) (= IR-VOID*       rtype))
      (and (ir-pointer-type? ltype) (ir-zero?         rhs  ))))

(define-function ir-check-assignment (ltype rtype rhs who)
  (or (ir-can-assign ltype rtype rhs)
      (error "type mismatch in assignment: "who)))

;

(define-class <ir-nop> <ir-insn> ())			(define-function ir-nop () (new <ir-nop>))

(define-method ir-check-type <ir-nop> (ir val?)		(and val? (ir-error-no-value ir self))
							(set self.type IR-VOID))

(define-selector ir-gen-nop)
(define-method   ir-gen <ir-nop> (gen)			(ir-gen-nop gen))

(define-selector ir-nop? args				())

(define-method ir-nop? <ir-nop> ()			1)

;

(define-class <ir-sizeof> <ir-insn> ())			(define-function ir-sizeof (type)	(new <ir-sizeof> (list type) () IR-LONG))

(define-method ir-check-type <ir-sizeof> (ir val?)	(or val? (ir-warning-no-effect ir self))
							self.type)

(define-selector ir-gen-sizeof)
(define-method   ir-gen <ir-sizeof> (gen)		(ir-gen-sizeof gen (car self.parameters)))

;

(define-class <ir-lit> <ir-insn> ())			(define-function ir-lit (value . opt-type)
							  (new <ir-lit> (list value) () (car opt-type)))

(define-function ir-lit? (x)				(inherits-from (type-of x) <ir-lit>))
(define-function ir-zero? (x)				(and (ir-lit? x) (= 0 (car (<ir-lit>-parameters x)))))

(define-method ir-check-type <ir-lit> (ir val?)		(or val? (ir-warning-no-effect ir self))
							(or self.type (set self.type (ir-check-type (car self.parameters) ir 1))))

(define-selector ir-gen-lit)
(define-method   ir-gen <ir-lit> (gen)			(ir-gen-lit gen (car self.parameters)))

;

(define-class <ir-cast> <ir-insn> ())			(define-function ir-cast (type value)	(new <ir-cast> (list type) (list value)))

(define-method ir-check-type <ir-cast> (ir val?)	(or val? (ir-warning-no-effect ir self))
							(ir-check-type (car self.operands) ir 1)
							(set self.type (car self.parameters)))

(define-selector ir-gen-cast)
(define-method   ir-gen <ir-cast> (gen)			(ir-gen-cast gen (car self.parameters) (car self.operands)))

;

(define-class <ir-extern> <ir-insn> ())			(define-function ir-extern (name) (new <ir-extern> (list name)))

(define-method ir-check-type <ir-extern> (ir val?)	(or val? (ir-warning-no-effect ir self))
							(set self.type IR-VOID*))

(define-selector ir-gen-extern)
(define-method ir-gen <ir-extern> (gen)			(ir-gen-extern gen self))

;

(define-class <ir-function> <ir-insn> (scope))		(define-function ir-function (name type args body)
							  (and (ir-function-type? type) (set type (ir-pointer-to type)))
							  (new <ir-function> (list name args) body type))

(define-method ir-check-type <ir-function> (ir val?)	(or val? (ir-warning-no-effect ir self))
							(let ((name (car  self.parameters))
							      (args (cadr self.parameters))
							      (body self.operands)
							      (type (<ir-pointer-type>-referent self.type))
							      (fir  (ir-new ir self)))
							  (set self.scope (<ir>-scope fir))
							  (ir-append-function ir self)
							  (lists-do ((argn args) (argt (<ir-function-type>-arg-types type)))
							    (ir-declare-parameter fir argn argt))
							  (ir-append-all fir body)
							  (ir-check-types fir)
							  (or (= IR-VOID (<ir-function-type>-ret-type type))
							      (ir-returns? fir)
							      (error "missing return statement: "(or (car self.parameters) self)))
							  (ir-finalise fir)
							  self.type))

(define-selector ir-gen-function)
(define-method   ir-gen <ir-function> (gen)		(ir-gen-function gen self))

(define-function ir-function-name (ir)
  (if (<ir>-function ir)
      (car (<ir-function>-parameters (<ir>-function ir)))
    "<anonymous function>"))

;

(define-class <ir-return> <ir-insn> ())			(define-function ir-return (val) (new <ir-return> () (list val)))

(define-method ir-check-type <ir-return> (ir val?)	(and val? (ir-error-no-value ir self))
							(set self.type
							     (if self.operands
								 (ir-check-type (car self.operands) ir 1)
							       IR-VOID))
							(let ((fn (or (<ir>-function ir)
								      (error "return outside function: "self))))
							  (let* ((fn    (<ir>-function ir))
								 (type  (<ir-insn>-type fn))
								 (ftype (<ir-function-type>-ret-type (<ir-pointer-type>-referent type))))
							    (or (= self.type ftype)
								(and (ir-pointer-type? ftype) (= IR-VOID*       self.type))
								(and (= IR-VOID*       ftype) (ir-pointer-type? self.type))
								(and (ir-pointer-type? ftype) (ir-zero?         (car self.operands)))
								(error (ir-function-name ir)": type mismatch in return: "self))))
							self.type)

(define-selector ir-gen-return)
(define-method ir-gen <ir-return> (gen)			(ir-gen-return gen self))

(define-method ir-returns? <ir-return> ()		self.type)

;

(define-function check-proto-args-rest (proto types args)
  (or (= (car proto) IR-VARARGS)						;; (...) => args can be anything
      (and (not proto) (not types))						;; end of proto => args must end
      (and (ir-can-assign (car proto) (car types) (car args))			;; proto matches arg
	   (check-proto-args-rest (cdr proto) (cdr types) (cdr args)))))

(define-function check-proto-args (proto types args)
  (or (not proto)					;; () => args can be anything
      (and (= (car proto) IR-VOID)			;; (void) => args must be empty
	   (not (cdr proto))
	   (not types))
       (check-proto-args-rest proto types args)))

(define-class <ir-call> <ir-insn> ())			(define-function ir-call (dest args)	(new <ir-call> () (cons dest args)))

(define-method ir-check-type <ir-call> (ir val?)	(let* ((call-sig  (map-with2 ir-check-type self.operands ir 1))
							       (dest-type (car call-sig))
							       (fun-type  (if (ir-pointer-type? dest-type) (<ir-pointer-type>-referent dest-type) dest-type))
							       (fun-args  (<ir-function-type>-arg-types fun-type))
							       (arg-types (cdr call-sig)))
							  (or (ir-function-type? fun-type)
							      (error "called value is not a function: "self))
							  (and fun-args (or (check-proto-args fun-args arg-types (cdr self.operands))
									    (error "expected argument types "(<ir-function-type>-arg-types fun-type)
										   " in call: "self)))
							  (set self.type (<ir-function-type>-ret-type fun-type))))

(define-selector ir-gen-call)
(define-method ir-gen <ir-call> (gen)			(ir-gen-call gen self))

;

(define-class <ir-member> <ir-insn> ())			(define-function ir-member (field value)	(new <ir-member> (list field) (list value)))

(define-method ir-check-type <ir-member> (ir val?)	(or val? (ir-warning-no-effect ir self))
							(let ((fname (car self.parameters))
							      (vtype (ir-check-type (car self.operands) ir 1)))
							  (and (ir-pointer-type? vtype)			(set vtype (<ir-pointer-type>-referent vtype)))
							  (or  (symbol? fname)				(error "field name is not a symbol: "self))
							  (or  (ir-struct-type? vtype)			(error "value is not a structure: "self))
							  (let ((m (cdr (assq fname (<ir-struct-type>-members vtype)))))
							    (or m					(error "no such field: "self))
							    (set self.type (<ir-struct-member>-type m)))))

(define-selector ir-gen-member)
(define-method ir-gen <ir-member> (gen)			(ir-gen-member gen (car self.parameters) (car self.operands)))

(define-selector ir-member? args			())
(define-method ir-member? <ir-member> ()		1)

;

(define-class <ir-set-member> <ir-insn> ())		(define-function ir-set-member (field value init)
							  (new <ir-set-member> (list field) (list value init)))

(define-method ir-check-type <ir-set-member> (ir val?)	(let ((fname (car self.parameters))
							      (vtype (ir-check-type (car  self.operands) ir 1))
							      (itype (ir-check-type (cadr self.operands) ir 1)))
							  (and (ir-pointer-type? vtype)			(set vtype (<ir-pointer-type>-referent vtype)))
							  (or  (symbol? fname)				(error "field name is not a symbol: "self))
							  (or  (ir-struct-type? vtype)			(error "value is not a structure: "self))
							  (let* ((m     (cdr (or (assq fname (<ir-struct-type>-members vtype))
										 (error "no such field: "self))))
								 (mtype (<ir-struct-member>-type m)))
							    (or (= mtype itype) (error "type mismatch in member assignment: "self))
							    (set self.type mtype))))

(define-selector ir-gen-set-member)
(define-method ir-gen <ir-set-member> (gen)		(ir-gen-set-member gen (car self.parameters) (car self.operands) (cadr self.operands)))

;

(define-class <ir-indir> <ir-insn> ())			(define-function ir-indir (base index)	(new <ir-indir> () (list base index)))

(define-method ir-check-type <ir-indir> (ir val?)	(or val? (ir-warning-no-effect ir self))
							(let* ((base  (car  self.operands))  (btype (ir-check-type base  ir 1))
							       (index (cadr self.operands))  (itype (ir-check-type index ir 1)))
							  (or (ir-pointer-type? btype)			(error "dereferencing a non-pointer type: "self))
							  (or (ir-integral-type? itype)			(error "non-integer index: "self))
							  (set self.type (<ir-pointer-type>-referent btype))))

(define-selector ir-gen-indir)
(define-method ir-gen <ir-indir> (gen)			(ir-gen-indir gen self.type (car self.operands) (cadr self.operands)))

;

(define-class <ir-set-indir> <ir-insn> ())		(define-function ir-set-indir (base index value) (new <ir-set-indir> () (list base index value)))

(define-method ir-check-type <ir-set-indir> (ir val?)	(let* ((base  (car   self.operands))  (btype (ir-check-type base  ir 1))
							       (index (cadr  self.operands))  (itype (ir-check-type index ir 1))
							       (value (caddr self.operands))  (vtype (ir-check-type value ir 1)))
							  (or (ir-pointer-type? btype)			(error "dereferencing a non-pointer type: "self))
							  (or (ir-integral-type? itype)			(error "non-integer index: "self))
							  (let ((rtype (<ir-pointer-type>-referent btype)))
							    (ir-check-assignment rtype vtype value self)
							    (set self.type rtype))))

(define-selector ir-gen-set-indir)
(define-method ir-gen <ir-set-indir> (gen)		(ir-gen-set-indir gen self.type (car self.operands) (cadr self.operands) (caddr self.operands)))

;

(define-class <ir-get-var> <ir-insn> ())		(define-function ir-get-var (name)	(new <ir-get-var> name))

(define-method ir-check-type <ir-get-var> (ir val?)	(or val? (ir-warning-no-effect ir self))
							(set self.parameters (ir-lookup ir self.parameters))
							(set self.type (<ir-variable>-type self.parameters)))

(define-selector ir-gen-get-var)
(define-method ir-gen <ir-get-var> (gen)		(ir-gen-get-var gen self.parameters))

(define-selector ir-get-var? args			())
(define-method ir-get-var? <ir-get-var> ()		1)

;

(define-class <ir-set-var> <ir-insn> ())		(define-function ir-set-var (name value) (new <ir-set-var> name (list value)))

(define-method ir-check-type <ir-set-var> (ir val?)	(set self.parameters (ir-lookup ir self.parameters))
							(let ((type (ir-check-type (car self.operands) ir 1)))
							  (or (<ir-variable>-type self.parameters)
							      (set (<ir-variable>-type self.parameters) type))
							  (set self.type (<ir-variable>-type self.parameters))
							  (or (= self.type type)
							      (and (ir-pointer-type? self.type) (= IR-VOID*      type))
							      (and (ir-pointer-type?      type) (= IR-VOID* self.type))
							      (and (ir-pointer-type? self.type) (ir-zero? (car self.operands)))
							      (error "assigning value of type: "type" to variable of type: "self.type)))
							self.type)

(define-selector ir-gen-set-var)
(define-method ir-gen <ir-set-var> (gen)		(ir-gen-set-var gen self.parameters (car self.operands)))

;

(define-class <ir-addressof> <ir-insn> ())		(define-function ir-addressof (args)	(new <ir-addressof> () args))

(define-method ir-check-type <ir-addressof> (ir val?)	(let* ((lval (car self.operands))
							       (type (ir-check-type lval ir 1)))
							  (or (ir-get-var? lval)
							      (ir-member?  lval)
							      (error "non-lvalue in addressof: "self))
							  (set self.type (ir-pointer-to type))))

(define-selector ir-gen-addressof-var)
(define-selector ir-gen-addressof-member)

(define-method ir-gen <ir-addressof> (gen)
  (let ((lval (car self.operands)))
    (cond
      ((ir-get-var? lval)	(ir-gen-addressof-var    gen (<ir-get-var>-parameters lval)))
      ((ir-member? lval)	(ir-gen-addressof-member gen (car (<ir-member>-parameters lval)) (car (<ir-member>-operands lval))))
      (else			(error "this cannot happen")))))

;

(define-class <ir-let> <ir-insn> ())			(define-function ir-let (names types values body)
							  (new <ir-let> (list names types) (list values (or body (list (ir-nop))))))

(define-function ir-check-let-init-type (value ir)	(ir-check-type value ir (if (ir-nop? value) () 1)))

(define-method ir-check-type <ir-let> (ir val?)		(let* ((names  (car  self.parameters))
							       (types  (cadr self.parameters))
							       (values (car  self.operands))
							       (body   (cadr self.operands))
							       (vtypes (map-with ir-check-let-init-type values ir))
							       (seq    body))
							  (ir-begin-scope ir)
							  (lists-do ((name names) (type types) (value values) (vtype vtypes))
							    (or type (set type vtype))
							    (let ((var (ir-declare-local ir name type)))
							      (unless (ir-nop? value)
								(ir-check-assignment type vtype value self)
								(push seq (new <ir-set-var> var (list value) type)))))
							  (set self.type IR-VOID)
							  (while (cdr body)
							    (set self.type (ir-check-type (car body) ir ()))
							    (set body (cdr body)))
							  (and body
							    (set self.type (ir-check-type (car body) ir val?)))
							  (set self.parameters (ir-end-scope ir))
							  (set self.operands seq)
							  (or val? (set self.type IR-VOID))
							  self.type))

(define-selector ir-gen-let)
(define-method ir-gen <ir-let> (gen)			(ir-gen-let gen self.type self.parameters self.operands))

(define-method ir-returns? <ir-let> ()			(ir-returns? (list-last self.operands)))

;

(define-class <ir-define> <ir-insn> (var))		(define-function ir-define (name type value)
							  (when (and (not type) (<ir-insn>-type value))
							    (set type (<ir-insn>-type value)))
							  ;;(new <ir-define> (list name type) (list (ir-set-var name value))))
							  (new <ir-define> (list name type) (list value) type))

(define-method ir-define-global <ir-define> (ir)	(let* ((name (car  self.parameters))
							       (type (cadr self.parameters)))
							  (set self.var (ir-declare-global ir name type))))

(define-method ir-check-type <ir-define> (ir val?)	(let* ((name  (car  self.parameters))
							       (type  (cadr self.parameters))
							       (init  (car  self.operands))
							       (itype (ir-check-type init ir 1)))
							  (or type	(set type itype))
							  (or self.var	(set self.var (ir-declare-local ir name type)))
							  (ir-check-assignment (<ir-variable>-type self.var) itype init self)
							  (set (car self.operands) (new <ir-set-var> self.var (list init) type))
							  (set self.type type)))

(define-method ir-gen <ir-define> (gen)			(ir-gen (car self.operands) gen))

;

(define-class <ir-seq> <ir-insn> ())			(define-function ir-seq (exprs) (new <ir-seq> () exprs))

(define-method ir-check-type <ir-seq> (ir val?)		(or self.operands (set self.operands (ir-void)))
							(ir-begin-scope ir)
							(set self.type IR-VOID)
							(let ((body self.operands))
							  (while (cdr body)
							    (set self.type (ir-check-type (car body) ir ()))
							    (set body (cdr body)))
							  (and body
							    (set self.type (ir-check-type (car body) ir val?))))
							(set self.parameters (ir-end-scope ir))
							self.type)

(define-selector ir-gen-seq)
(define-method ir-gen <ir-seq> (gen)			(ir-gen-seq gen self.parameters self.operands))

(define-method ir-returns? <ir-seq> ()			(ir-returns? (list-last self.operands)))

;

(define-class <ir-while> <ir-insn> ())			(define-function ir-while (test expr) (new <ir-while> () (list test expr)))

(define-method ir-check-type <ir-while> (ir val?)	(and val? (ir-error-no-value ir self))
							(or (ir-bool? (ir-check-type (car self.operands) ir 1)) (error "non-boolean condition: "self))
							(ir-check-type (cadr self.operands) ir ())
							(set self.type IR-VOID))

(define-selector ir-gen-while)
(define-method ir-gen <ir-while> (gen)			(ir-gen-while gen (car self.operands) (cadr self.operands)))

;

(define-class <ir-if> <ir-insn> ())			(define-function ir-if (test exp alt) (new <ir-if> () (list test exp alt)))

(define-method ir-check-type <ir-if> (ir val?)		(or (ir-bool? (ir-check-type (car self.operands) ir 1)) (error "non-boolean condition: "self))
							(let ((t1 (ir-check-type (cadr  self.operands) ir val?))
							      (t2 (ir-check-type (caddr self.operands) ir val?)))
							  (if val?
							      (or (= (set self.type t1) t2) (error "type mismatch: "self))
							    (set self.type IR-VOID)))
							self.type)

(define-selector ir-gen-if)
(define-method ir-gen <ir-if> (gen)			(ir-gen-if gen self.type (car self.operands) (cadr self.operands) (caddr self.operands)))

(define-method ir-returns? <ir-if> ()			(and (ir-returns? (cadr  self.operands)) (ir-returns? (caddr self.operands))))

;

(define-function ir-check-logical (exprs ir val?)
  (if val?
      (let ()
	(list-do insn exprs
	  (or (ir-bool? (ir-check-type insn ir 1))
	      (error "non-boolean condition: "insn)))
	IR-BOOL)
    (while (cdr exprs)
      (or (ir-bool? (ir-check-type (car exprs) ir 1))
	  (error "non-boolean condition: "(car exprs)))
      (set exprs (cdr exprs)))
    (ir-check-type (car exprs) ir ())
    IR-VOID))

(define-class <ir-logand> <ir-insn> ())			(define-function ir-logand (exprs)
							  (let ((n (list-length exprs)))
							    (cond
							      ((= n 0)	(ir-lit 1 IR-BOOL))
							      ((= n 1)	(car exprs))
							      (else	(new <ir-logand> () (or exprs (list (ir-lit 1 IR-BOOL))))))))

(define-method ir-check-type <ir-logand> (ir val?)	(set self.type (ir-check-logical self.operands ir val?)))

(define-selector ir-gen-logand)
(define-method ir-gen <ir-logand> (gen)			(ir-gen-logand gen self.type self.operands))

;

(define-class <ir-logor> <ir-insn> ())			(define-function ir-logor (exprs)
							  (let ((n (list-length exprs)))
							    (cond
							      ((= n 0)	(ir-lit 0 IR-BOOL))
							      ((= n 1)	(car exprs))
							      (else	(new <ir-logor> () (or exprs (list (ir-lit 1 IR-BOOL))))))))

(define-method ir-check-type <ir-logor> (ir val?)	(set self.type (ir-check-logical self.operands ir val?)))

(define-selector ir-gen-logor)
(define-method ir-gen <ir-logor> (gen)			(ir-gen-logor gen self.type self.operands))

;

(define-selector ir-gen-add)

(define-class <ir-add> <ir-insn> ())			(define-function ir-add (args) (new <ir-add> () args))

(define-method ir-check-type <ir-add> (ir val?)		(or val? (ir-warning-no-effect ir self))
							(let ((lhs (ir-check-type (car  self.operands) ir 1))
							      (rhs (ir-check-type (cadr self.operands) ir 1)))
							  (cond
							    ((and (ir-numeric-type? lhs) (= rhs lhs))		)
							    ((and (ir-pointer-type? lhs) (= rhs IR-LONG))	)
							    (else						(error "illegal types in: "self)))
							  (set self.type lhs)))

(define-method ir-gen <ir-add> (gen)			(ir-gen-add gen (car self.operands) (cadr self.operands)))

;

(define-class <ir-sub> <ir-insn> ())			(define-function ir-sub (args) (new <ir-sub> () args))

(define-method ir-check-type <ir-sub> (ir val?)		(or val? (ir-warning-no-effect ir self))
							(let ((lhs (ir-check-type (car  self.operands) ir 1))
							      (rhs (ir-check-type (cadr self.operands) ir 1)))
							  (cond
							    ((and (ir-numeric-type? lhs) (= rhs lhs))		)
							    ((and (ir-pointer-type? lhs) (= rhs lhs))		(set lhs IR-LONG))
							    ((and (ir-pointer-type? lhs) (= rhs IR-LONG))	)
							    (else						(error "illegal types in: "self)))
							  (set self.type lhs)))

(define-selector ir-gen-sub)
(define-method ir-gen <ir-sub> (gen)			(ir-gen-sub gen (car self.operands) (cadr self.operands)))

;

(define-form define-unary-arithmetic (name test)
  (let* ((iname (concat-symbol  'ir- name))
	 (tname (concat-symbols '< iname '>))
	 (gname (concat-symbol 'ir-gen- name)))
    `(let ()
       (define-class ,tname <ir-insn> ())		(define-function ,iname (args) (new ,tname () args))
       (define-method ir-check-type ,tname (ir val?)	(or val? (ir-warning-no-effect ir self))
							(let ((type (ir-check-type (car self.operands) ir 1)))
							  (or (,test type) (error "illegal types in: "self))
							  (set self.type type)))
       (define-selector ,gname)
       (define-method ir-gen ,tname (gen)		(,gname gen (car self.operands))))))

(define-unary-arithmetic neg ir-numeric-type?)
(define-unary-arithmetic com ir-integral-type?)
(define-unary-arithmetic not ir-integral-type?)

(define-form define-binary-arithmetic (name test)
  (let* ((iname (concat-symbol  'ir- name))
	 (tname (concat-symbols '< iname '>))
	 (gname (concat-symbol 'ir-gen- name)))
    `(let ()
       (define-class ,tname <ir-insn> ())		(define-function ,iname (args) (new ,tname () args))
       (define-method ir-check-type ,tname (ir val?)	(or val? (ir-warning-no-effect ir self))
							(let ((lhs (ir-check-type (car  self.operands) ir 1))
							      (rhs (ir-check-type (cadr self.operands) ir 1)))
							  (or (and (,test lhs) (= rhs lhs))
							      (error "illegal types in: "self))
							  (set self.type lhs)))
       (define-selector ,gname)
       (define-method ir-gen ,tname (gen)		(,gname gen (car self.operands) (cadr self.operands))))))

(define-binary-arithmetic mul 	 ir-numeric-type?)
(define-binary-arithmetic div 	 ir-numeric-type?)
(define-binary-arithmetic mod 	 ir-numeric-type?)
(define-binary-arithmetic shl 	 ir-integral-type?)
(define-binary-arithmetic shr 	 ir-integral-type?)
(define-binary-arithmetic bitand ir-integral-type?)
(define-binary-arithmetic bitor  ir-integral-type?)
(define-binary-arithmetic bitxor ir-integral-type?)

(define-form define-relation (name)
  (let* ((iname (concat-symbol  'ir- name))
	 (tname (concat-symbols '< iname '>))
	 (gname (concat-symbol 'ir-gen- name)))
    `(let ()
       (define-class ,tname <ir-insn> ())		(define-function ,iname (args) (new ,tname () args))
       (define-method ir-check-type ,tname (ir val?)	(or val? (ir-warning-no-effect ir self))
							(let* ((lhs (car  self.operands))  (lht (ir-check-type lhs ir 1))
							       (rhs (cadr self.operands))  (rht (ir-check-type rhs ir 1)))
							  (or (and (ir-scalar-type?  lht) (= lht            rht))
							      (and (ir-struct-type?  lht) (= lht            rht))
							      (and (ir-pointer-type? lht) (= IR-VOID*       rht))
							      (and (ir-pointer-type? lht) (ir-zero?         rhs))
							      (and (= IR-VOID*       lht) (ir-pointer-type? rht))
							      (and (ir-zero?         lhs) (ir-pointer-type? rht))
							      (error "illegal types in: "self))
							  (set self.type IR-BOOL)))
       (define-selector ,gname)
       (define-method ir-gen ,tname (gen)		(,gname gen (car self.operands) (cadr self.operands))))))

(define-relation eq)
(define-relation ne)

(define-form define-arithmetic-relation (name)
  (let* ((iname (concat-symbol  'ir- name))
	 (tname (concat-symbols '< iname '>))
	 (gname (concat-symbol 'ir-gen- name)))
    `(let ()
       (define-class ,tname <ir-insn> ())		(define-function ,iname (args) (new ,tname () args))
       (define-method ir-check-type ,tname (ir val?)	(or val? (ir-warning-no-effect ir self))
							(let ((lhs (ir-check-type (car  self.operands) ir 1))
							      (rhs (ir-check-type (cadr self.operands) ir 1)))
							  (or (and (ir-scalar-type? lhs) (= rhs lhs))
							      (error "illegal types in: "self))
							  (set self.type IR-BOOL)))
       (define-selector ,gname)
       (define-method ir-gen ,tname (gen)		(,gname gen (car self.operands) (cadr self.operands))))))

(define-arithmetic-relation lt)
(define-arithmetic-relation le)
(define-arithmetic-relation ge)
(define-arithmetic-relation gt)

;;; compilation

(define-selector ir-define-global (self ir))

(define-function ir-define-globals (ir)
  (array-do init (<ir>-program ir)
    (ir-define-global init ir)))


(define-selector ir-gen-declare-struct)

(define-function ir-declare-structs (ir gen)
  (list-do bind (<ir>-struct-types ir)
    (ir-gen-declare-struct gen (cdr bind))))


(define-selector ir-gen-global-declaration (self gen) ())

(define-function ir-generate-declarations (ir gen)
  (ir-scope-do var (<ir>-scope ir)
    (ir-gen-global-declaration var gen)))

(define-method ir-gen-global-declaration <ir-global> (gen)
  (ir-gen-global-declaration gen self))


(define-selector ir-gen-local-declaration (self gen) ())

(define-method ir-gen-local-declaration <ir-local> (gen)
  (ir-gen-local-declaration gen self))


(define-selector ir-gen-function-implementation)

(define-function ir-generate-functions (ir gen)
  (array-do function (<ir>-functions ir)
    (ir-gen-function-implementation gen function)))


(define-selector ir-gen-statement)

(define-function ir-generate-program (ir gen)
  (array-do statement (<ir>-program ir)
    (ir-gen-statement gen statement)))

(define-selector ir-gen-header)
(define-selector ir-gen-preamble)
(define-selector ir-gen-postamble)


(define *ir-gen-selectors* ())

(namespace-do binding *globals*
  (let ((name (car binding)))
    (when (string-begins-with name "ir-gen-")
      (push *ir-gen-selectors* (cdr binding)))))

(define-function ir-sanity-check-gen (gen)
  (let ((type (type-of gen)))
    (list-do s *ir-gen-selectors*
      (or (array-at (<selector>-methods s) type)
	  (error (type-name-of gen)" does not implement "(<selector>-name s))))))


(define-function ir-generate (ir gen)
  (ir-sanity-check-gen gen)
  (ir-finalise-structs ir gen)
  (ir-gen-header gen)
  (ir-declare-structs ir gen)
  (ir-define-globals ir)
  (ir-check-types ir)
  (ir-generate-declarations ir gen)
  (ir-generate-functions ir gen)
  (ir-gen-preamble gen)
  (ir-generate-program ir gen)
  (ir-gen-postamble gen)
  )
