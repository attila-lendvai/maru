;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; types
;;;
;;;
;;; type-id-of: returns the type-id that the target VM is working with,
;;; i.e. the "level-shifted name" of the type (an integer).
;;;
;;; type-of: returns a maru record holding the metadata for that type
;;; (i.e. its name, type-id, etc).
;;;
;;; the <foo> global definitions are also holding full maru type objects.

(define-form is (type obj)
  ;; TODO use subtype? because this ignores inheritance
  `(= ,type (type-of ,obj)))

(define type-id-of type-of) ; we will replace type-of later
(set type-of 'not-yet-bootstrapped)

(define %first-type-id		1) ; i.e. the first allocated type will be 1 (so that we can assert for non-zero type in the gc)
(define %last-type-id		(- %first-type-id 1))
(define %types			(array 16))

(define-form types-do (var . body)
  `(for (__i__ %first-type-id %last-type-id)
     (let ((,var (array-at %types __i__)))
       ,@body)))

(if-at-expand bootstrapping?
    (let ()
      ;; integrate with the host vm's type machinery to instantiate slave objects
      ;; in the framework of the host while we are being bootstrapped.
      (define-function allocate-type-id ()
        (eval-in-host '(allocate-type-id)))

      (define-function allocate-type-id/slave ()
        (incr %last-type-id))

      (define %type-id-map/host->slave (array 16)))

  (define-function allocate-type-id ()
    (incr %last-type-id)))

(define-function %make-accessor-forms (type-name slot-names slot-index raw-slot-access?)
  (when slot-names
    (cons (let* ((slot-name (car slot-names))
                 (accessor-name (concat-symbol type-name (concat-symbol '- slot-name))))
            (if raw-slot-access?
                `(define-form ,accessor-name (obj)
                   (list 'oop-at obj ,slot-index))
              `(define-form ,accessor-name (obj)
                 (list 'slot-value ',type-name ',slot-name obj))))
          (%make-accessor-forms type-name (cdr slot-names) (+ 1 slot-index) raw-slot-access?))))

(define <type>)
(define <record>)

(if-at-expand bootstrapping?
    (let ()
      ;; if we want to e.g. use the host's multimethods on the slave's types
      ;; (for example in the compiler) while we are being bootstrapped, then
      ;; we need to "bind" the slave's <type> and <record> to their
      ;; respective versions in the host.
      (define type-id-of-<type>		(eval-in-host '(<type>-id <type>)))
      (define type-id-of-<record>	(eval-in-host '(<type>-id <record>)))
      (define slots-of-<type>		(eval-in-host '(<record>-direct-slots <type>)))
      (define slots-of-<record>		(eval-in-host '(<record>-direct-slots <record>))))

  (define type-id-of-<type>		(allocate-type-id))
  (define type-id-of-<record>		(allocate-type-id))
  (define slots-of-<type>		'(id name))
  (define slots-of-<record>		'(super direct-slots effective-slots)))

;; define temporary, non-typechecking accessors for <type> and <record>
(eval `(let ()
         ,@(%make-accessor-forms	'<type>		slots-of-<type>		0				true)
         ,@(%make-accessor-forms	'<record>	slots-of-<record>	(list-length slots-of-<type>)	true)))

(assert <type>-name)

(if-at-expand bootstrapping?
;;;
;;; bootstrap is happening, i.e. <type> and <record> is mapped into the slave from the host in early.l
;;;
    (let ()
      (set <type>		(eval-in-host '<type>))
      (set <record>		(eval-in-host '<record>))

      (let ((slave-id (allocate-type-id/slave)))
        (set (array-at %type-id-map/host->slave (<type>-id <type>)) slave-id)
        (set (array-at %types slave-id) <type>))

      (let ((slave-id (allocate-type-id/slave)))
        (set (array-at %type-id-map/host->slave (<type>-id <record>)) slave-id)
        (set (array-at %types slave-id) <record>))

      (define-function <type>-slave-id (type)
        (let* ((type-id  (<type>-id type))
               (slave-id (array-at %type-id-map/host->slave type-id)))
          (assert slave-id "no host->slave mapping exists for host type-id: " type-id "?!")
          slave-id))

      (define-function register-type (type)
        ;; while bootstrapping we instantiate types in the host (so that we can use e.g. method dispatch),
        ;; and keep an additional host-id->slave-id map.
        (let ((slave-id	(allocate-type-id/slave))
              (host-id	(<type>-id type)))
          (set (array-at %type-id-map/host->slave host-id) slave-id)
          (set (array-at %types slave-id) type)
          (eval-in-host `(register-type ',type))))

      (define-function type-object-for-id (type-id)
        (or (array-at %types (let ((slave-id (array-at %type-id-map/host->slave type-id)))
                               ;; we could make this smarter and only do the remap when there's an entry...
                               ;; but do we want to? wouldn't that hide some nasty bugs?
                               (assert slave-id "type-object-for-id: no host->slave mapping exists for host type-id: " type-id)
                               slave-id))
            (error "type-object-for-id has failed for type id "type-id", known types are: "%types))))
;;;
;;; we are not being bootstrapped, therefore we need to instantiate <type> and <record> ourselves
;;;
  (define-function register-type (type)
    (set (array-at %types (<type>-id type)) type))

  (define-function type-object-for-id (type-id)
    (or (array-at %types type-id)
        (error "type-object-for-id has failed for type id "type-id", known types are: "%types)))

  (define-function %bootstrap-type (type-name type-id type-type-id slot-count)
    (let ((type-obj (allocate type-type-id slot-count)))
      (set (<type>-id	type-obj)	type-id)
      (set (<type>-name	type-obj)	type-name)
      (register-type type-obj)
      type-obj))

  (define-function %bootstrap-record (type-name type-id super direct-slots)
    (let ((type-obj (%bootstrap-type type-name type-id type-id-of-<record> (+ (list-length slots-of-<type>)
                                                                              (list-length slots-of-<record>)))))
      (set (<record>-super		type-obj)		super)
      (set (<record>-direct-slots	type-obj)		direct-slots)
      (set (<record>-effective-slots	type-obj)		'not-yet-bootstrapped)
      type-obj))

  (set <type>	(%bootstrap-record '<type>		type-id-of-<type>	()	slots-of-<type>))
  (set <record>	(%bootstrap-record '<record>		type-id-of-<record>	<type>	slots-of-<record>)))

(assert (and <type> <record>))
(assert (= (<type>-id <type>) %first-type-id))
(assert (= (<type>-id <record>) (+ %first-type-id 1)))

(assert (= (type-object-for-id (<type>-id <type>)) <type>))
(assert (= (type-object-for-id (<type>-id <record>)) <record>))

(verbosity 2
  (warn "<type> is bootstrapped: "	<type>		", id: "	(<type>-id <type>)"\n")
  (warn "<record> is bootstrapped: "	<record>	", id: "	(<type>-id <record>)"\n"))

(define-function type-of (obj)
  (type-object-for-id (type-id-of obj)))

(assert (= (type-of <type>) <record>))
(assert (= (type-of <record>) <record>))

(define-function name-of-type (type)
  (<type>-name type))

(define-function type-name-of (obj)
  (name-of-type (type-of obj)))

(define subtype?) ; forward

(define-function record-inherits-from? (type super)
  (and type
       (or (= type super)
           (and (subtype? (type-of type) <record>)
                (record-inherits-from? (<record>-super type) super)))))

(define-function subtype? (subtype supertype)
  (assert (and subtype supertype))
  (or (= subtype supertype)
      (record-inherits-from? subtype supertype)))

(assert (subtype? (type-of <type>) <record>))
(assert (subtype? <record> <type>))
(assert (not (subtype? <type> <record>)))

(define-function sanity-check-record-slots (record slots)
  (let ((f slots))
    (while (pair? f)
      (unless (symbol? (car f))
        (error "slot is not symbol?: "(car f)))
      (when (member? (car f) (cdr f))
        (error "slot '"(car f)"' multiply-defined in record: "record" "slots))
      (set f (cdr f)))))

(define-function %record/compute-effective-slots (type)
  (and type
       (subtype? (type-of type) <record>)
       (concat-list (%record/compute-effective-slots (<record>-super type))
                    (<record>-direct-slots type))))

(define-function record/compute-effective-slots (type)
  ;;(print "record/compute-effective-slots for type " (<type>-name type) " of type " (<type>-name (type-of type)) " ?= <record>" (= type <record>) "\n") ; TODO delme
  (assert (subtype? (type-of type) <record>) "record/compute-effective-slots called with a non-record type " type)
  (let ((slots (%record/compute-effective-slots type)))
    (sanity-check-record-slots type slots)
    slots))

(when-at-expand (not bootstrapping?)
  (set (<record>-effective-slots <type>)	(record/compute-effective-slots <type>))
  (set (<record>-effective-slots <record>)	(record/compute-effective-slots <record>)))

(assert (equal slots-of-<type> (<record>-effective-slots <type>)))
(assert (equal (concat-list slots-of-<type> slots-of-<record>) (<record>-effective-slots <record>)))

(define-function record/effective-slot-count (type)
  (list-length (<record>-effective-slots type)))

(define-function record/slot-index (type slot-name)
  (assert (is <record> type))
  (let ((i 0)
        (list (<record>-effective-slots type)))
    (while (and (pair? list)
                (not (= slot-name (car list))))
      (set list (cdr list))
      (incr i))
    (or (and (pair? list)
             i)
        (error "record-slot-index has failed for type "type", slot-name "slot-name))))

;; now that <type> and <record> is instantiated, we can implement type checking in the accessors.
;; let's also redefine the basic accessors that we have defined earlier.
(define-function %accessor-typecheck (expected-type-id slot-name object)
  (unless (= (type-id-of object) expected-type-id)
    (let ((expected-type (type-object-for-id expected-type-id))
          (actual-type (type-of object)))
      (unless (subtype? actual-type expected-type)
        ;; (warn "about to process an %accessor-typecheck failure, which may fail to properly print the error output\nslot name is "slot-name", expected-type-id is "expected-type-id", object's actual type id is "(type-id-of object)"\n")
        (error "type check failed for record slot accessor: expected type "expected-type", slot name "slot-name", got " actual-type))))
  object)

;; slot-value is a "choke-point" that we can override while loading and expanding
;; the level-shifted code. see compile-begin for more details, or compiled peg parsers
;; that inhibit the expansion of slot-value while generating the maru code.
(define-form slot-value (type-name slot-name object)
  (let* ((type (eval type-name))
         (slot-index (record/slot-index type slot-name)))
    `(oop-at
      ,(if feature/typecheck-slot-access
           `(%accessor-typecheck ,(<type>-id type) ',slot-name ,object)
         object)
      ,slot-index)))

;; sometimes (see e.g. compiled peg parsers) we prevent slot-value to get expanded to keep
;; the generated code a little less fragile to changes in the object layout. in those
;; situations, at a later time, when the generated code is expanded, we may
;; encounter set-slot-value forms, so let's provide them, too.
(define-form set-slot-value (type-name slot-name object value)
  (let* ((type (eval type-name))
         (slot-index (record/slot-index type slot-name)))
    `(set-oop-at
      ,(if feature/typecheck-slot-access
           `(%accessor-typecheck ,(<type>-id type) ',slot-name ,object)
         object)
      ,slot-index
      ,value)))

(define-function type/slot-count-of-instances (type)
  (cond
    ((subtype? (type-of type) <record>)	(record/effective-slot-count type))
    ((subtype? (type-of type) <type>)	0)
    (else				(error "type/slot-count-of-instances: called with something unexpected: " type))))

(define-function %make-record-accessors (type raw-slot-access?)
  (assert (subtype? (type-of type) <record>) "%make-record-accessors called with a non-record type " type)
  (%make-accessor-forms (<type>-name type)
                        (<record>-direct-slots type)
                        (or (and (<record>-super type)
                                 (subtype? (<record>-super type) <record>)
                                 (record/effective-slot-count (<record>-super type)))
                            0)
                        raw-slot-access?))

;; redefine the preliminary bootstrap accessors with full featured ones
(eval `(let ()
         ,@(%make-record-accessors <type> false)
         ,@(%make-record-accessors <record> false)))

(verbosity 2 (warn "type bootstrap finished\n"))

;;; at this point the type registry is bootstrapped, containing two types: <type> and <record>

(assert (= (type-of <type>)	<record>))
(assert (= (type-of <record>)	<record>))

(assert (= 2 (list-length (<record>-effective-slots <type>))))
(assert (= (+ 3 (list-length (<record>-effective-slots <type>))) (list-length (<record>-effective-slots <record>))))

(define-function new-type-instance (name type)
  (assert (subtype? type <type>))
  (let ((id (allocate-type-id))
        (result (allocate (<type>-id type) (type/slot-count-of-instances type))))
    (set (<type>-name	result) name)
    (set (<type>-id	result) id)
    (register-type result)
    result))

(define-function new-<type> (name)
  (new-type-instance name <type>))

(define-form define-type (name)
  (let ((type (new-<type> name)))
    ;; TODO we want this to be defined already when the upcoming forms get expanded. but it feels like a kludge...
    (eval `(define ,name ,type))
    `(define ,name ,type)))

(define-function new-<record> (name super slots)
  (assert (or (not super) (and (not (pair? super)) (subtype? (type-of super) <type>))))
  (let ((type (new-type-instance name <record>)))
    (set (<record>-super		type) super)
    (set (<record>-direct-slots		type) slots)
    (set (<record>-effective-slots	type) (record/compute-effective-slots type))
    type))

(define-form define-record (name super slots . props)
  (set slots (map-with expand slots *env*))
  (set slots (list-remove () slots))
  (let ((record-type		(new-<record> name (eval super) slots))
        (raw-slot-access?	false))
    (list-do prop props
      (case prop
        (raw-slot-access	(set raw-slot-access? true))
        (else			(error "define-record: unexpected property "prop))))
    (eval `(define ,name ,record-type))
    `(let ((type-obj ,record-type))
       (define ,name type-obj)
       ,@(%make-record-accessors record-type raw-slot-access?)
       type-obj)))

;;; immediate type

(define-record <immediate-type> <type> (tag-value tag-width))

(define-function new-<immediate-type> (name tag-value tag-width)
  (let ((type (new-type-instance name <immediate-type>)))
    (set (<immediate-type>-tag-value	type) tag-value)
    (set (<immediate-type>-tag-width	type) tag-width)
    type))

(define-form define-immediate (name tag-value tag-width)
  `(define ,name ,(new-<immediate-type> name (eval tag-value) (eval tag-width))))

;;; boxed type

(define-record <boxed-type> <type> (one-word?))

(define-function new-<boxed-type> (name one-word?)
  (let ((type (new-type-instance name <boxed-type>)))
    (set (<boxed-type>-one-word? type) one-word?)
    type))

(define-form define-boxed-word (name)
  `(define ,name ,(new-<boxed-type> name true)))

(define-form define-boxed (name)
  `(define ,name ,(new-<boxed-type> name false)))

;;; classes

(define-form define-class (name basis fields)
  ;; TODO source-level compatibility. decide whether to delme.
  ;; TODO accessor regression: there used to be <peg>-result, now there's only a <parser>-result (inheritance)
  `(define-record ,name ,basis ,fields))

;;; built-in types

;; NOTE: the primitive-functions provided by the eval executable assume
;; a certain memory layout for the built-in types.
;; what actually happens is encoded in the executable, and if you change any of these
;; then you need to bootstrap to reflect the changes in the next executable.
;; types are represented in the target as successive integers.

;; TODO maybe: type objects should be serialized into the compiled binary and this
;; should be wrapped in a big (eval-at-expand (if bootstrapping? ...)). this would also
;; reflect the fact that editing these and bringing it out of sync with the
;; level-shifted binary is not an option without grave consequences.
;; such a setup would hopefully also simplify the bootstrapping dance above.
(define-type		<data>)					; some blob; used for stuff like the elements of <string> and <array>

(define-immediate	<undefined>		0 ())		; nil tag-width means that it's an entire word of a well-known value; in this case zero
(if-at-expand true
  (define-immediate	<long>			1 1)
  (define-boxed-word	<long>))				; provides a full-word integer, but bootstrap is about 25% slower
(define-record		<fixed>			() (function))
(define-boxed-word	<target-pointer>)			; a pointer into the level-shifted realm, boxed, so that it can be stored in the maru heap
(define-record		<target-function>	() (program-code
                                                     (when-at-expand feature/track-expr-names	name)
                                                     (when-at-expand feature/profiler		profiler-counter)))
;;(define-boxed		<symbol>)				; a cstr is inline into the object's body
(define-record		<symbol>		() (name))

(define-record		<array>			() (size elements))
(define-record		<string>		() (size elements))
;; TODO rename body to program-code
;; TODO harmonize name with <target-function>, but how? <function> and <t/function>
(define-record		<expr>			() (parameters body env ctx
                                                     (when-at-expand feature/track-expr-names	name)
                                                     (when-at-expand feature/profiler		profiler-counter)))
(define-record		<form>			() (function symbol))	; these are expander lambda's
(define-record		<variable>		() (name value env index))
(define-record		<env>			() (parent level offset bindings stable
                                                     (when-at-expand feature/debug-info		name)))
(define-record		<module>		() (globals (when-at-expand feature/debug-info name)))		; globals is the <variable> that holds '*globals*
(define-record		<context>		() (home env bindings callee))
(define-record		<pair>			() (head tail))

;; TODO why are some of these here, and some are primitive-functions? unify one way or another!
(define-function long?		(obj)	(= <long>	(type-of obj)))
(define-function expr?		(obj)	(= <expr>	(type-of obj)))
(define-function variable?	(obj)	(= <variable>	(type-of obj)))

(when-at-expand bootstrapping?
  ;; let's map the following host types to their respective slave
  ;; equivalents, so that calling the slave's TYPE-OF on one of their
  ;; instances will return the slave type object instead of that of
  ;; the host's. this is mainly needed to seamlessly interact with the
  ;; data that the host's reader returns; e.g. to be able to install
  ;; <selector> methods on these types in the slave, and expect them
  ;; to be called when e.g. DO-PRINT is used on some source code while
  ;; in the bootstrap process.
  (list-do entry `(("" ,<string>) (42 ,<long>) (t ,<symbol>) ((1) ,<pair>) (() ,<undefined>))
    (apply (lambda (instance type)
             (set (array-at %type-id-map/host->slave (type-id-of instance))
                  (<type>-slave-id type))
             (assert (= (type-of instance) type)))
           entry))
  ;; (print %type-id-map/host->slave "\n" %types "\n")
  )
