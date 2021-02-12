;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/unit-test.l")
(require "source/sequences.l")
(require "source/conversion.l")
(require "source/streams.l")

;;;----------------------------------------------------------------

(define-selector $size)

(<selector>-add-method $size <string> string-length)

(define-selector $at)

(<selector>-add-method $at <string> string-at)

;;;----------------------------------------------------------------

;(define <token> <pair>)		(define token cons)			(define new-<token> cons)
;(define <token>-value car)	(define set-<token>-value set-car)
;(define <token>-tail  cdr)	(define set-<token>-tail  set-cdr)

(define-record <token> () (value tail position notes index))

(define-function new-<token> () (new <token>))

(define-function token (value index srcpos)
  (make <token>
    (value	value)
    (index	index)
    (position	srcpos)))

(define-print-method <token>
  (print-all -stream- "<token "self.index" "(character->string self.value))
;  (map (lambda (x)
;	 (and (symbol? (car x))
;	      (print " "(car x))))
;       self.notes)
  (print-all -stream- ">"))

;(define <token> <pair>)		;(define token cons)			;(define new-<token> cons)
;(define <token>-value car)	(define set-<token>-value set-car)
;(define <token>-tail  cdr)	(define set-<token>-tail  set-cdr)

(define-record <group> () (first last))

(define-function group ()
  (let ((self  (new <group>))
	(token (new-<token>)))
    (set (<group>-first self) token)
    (set (<group>-last  self) token)
    self))

(define-function list-from-to (start stop)
  (and (!= start stop)
       (cons (<token>-value start) (list-from-to (<token>-tail start) stop))))

(define-function group-from-to (first last)
  (let ((self  (new <group>)))
    (set (<group>-first self) first)
    (set (<group>-last  self) last)
    self))

(define-print-method <group>
  (print-all -stream- "{ ")
  (let ((pos (<group>-first self))
	(lim (<group>-last  self)))
    (while (!= pos lim)
      (dump-all -stream- (<token>-value pos))
      (print-all -stream- " ")
      (set pos (<token>-tail pos))))
  (print-all -stream- "}"))

(define-function token-preceeds (a b)
  (while (and a (!= (<token>-tail a) b))
    (set a (<token>-tail a)))
  a)

(define-function group-empty? (self)
  (= (<group>-first self) (<group>-last  self)))

(define-function group-length (self)
  (let ((tok (<group>-first self))
	(lim (<group>-last  self))
	(len 0))
    (while (!= tok lim)
      (set len (+ len 1))
      (set tok (<token>-tail tok)))
    len))

(define-function group-append (self value . stream)
  (let ((tok  (new-<token>))
	(last (<group>-last self)))
    (set (<token>-value    last) value)
    (set (<token>-tail     last) tok)
    (set (<token>-position last) ($source-position (car stream)))
    (set (<group>-last     self) tok)))

;; (define-function group-append-all (self value)
;;   (let ((tok (<group>-first value))
;; 	(lim (<group>-last value)))
;;     (while (!= tok lim)
;;       (group-append self (<token>-value tok))
;;       (set tok (<token>-tail tok)))))

(define-function group-append-list (self list)
  (while (pair? list)
    (group-append self (car list))
    (set list (cdr list))))

(define-function group->string (self)
  (let* ((len (group-length self))
	 (str (string len))
	 (idx 0)
	 (tok (<group>-first self)))
    (while (< idx len)
      (set (string-at str idx) (<token>-value tok))
      (set tok (<token>-tail tok))
      (set idx (+ idx 1)))
    str))

(define-selector group->list (self) self)

(define-function set-pair-source-position (obj pos)
  (set (<pair>-source obj) pos)
  obj)

(define-function make-group->list (first last)
  (and (!= first last)
       (set-pair-source-position
	 (cons (<token>-value first) ;(group->list (<token>-value first))
	       (make-group->list (<token>-tail first) last))
	  (<token>-position first)
	  )))

(define-method group->list <group> ()
  (make-group->list (<group>-first self) (<group>-last self)))

(define-function group->list! (self)
  (group->list self)
;;    (let ((start (<group>-first self))
;;  	(stop  (<group>-last self)))
;;      (and (!= start stop)
;;  	 (let ((pos start))
;;  	   (while (!= (<token>-tail pos) stop) (set pos (<token>-tail pos)))
;;  	   (set (<token>-tail pos) ())
;;  	   start)))
  )

;; (define-function group->list (self)
;;   ;;(println "\n\n\n === " self)
;;   (let ((first (<group>-first self))
;; 	(last  (<group>-last  self)))
;;     (if (= first last)
;; 	()
;;       (while (!= last (cdr first))
;; 	;;(println "\n\n\n" first last)
;; 	(set first (cdr first)) last)
;;       (set-cdr first ())
;;       (<group>-first self))))

(unit-test "<group>"
  (let ((g (group)))			(unit-assert (= 0 (group-length g)))	(unit-assert (equal (group->list g) '()))
    (group-append g 'foo)		(unit-assert (= 1 (group-length g)))	(unit-assert (equal (group->list g) '(foo)))
    (group-append g 'bar)		(unit-assert (= 2 (group-length g)))	(unit-assert (equal (group->list g) '(foo bar)))
    (group-append-list g '(baz qux))	(unit-assert (= 4 (group-length g)))	(unit-assert (equal (group->list g) '(foo bar baz qux)))))

;;;----------------------------------------------------------------

(define-record <parser-stream> () (source position index))

;;(define-function parser-stream (source)
;;  (let ((self (new <parser-stream>)))
;;    (set (<parser-stream>-source self)   source)
;;    (set (<parser-stream>-position self) (new-<token>))
;;    self))

(define-function parser-stream (source)
  (make <parser-stream>
    (source	source)
    (position	(token ($next source) 0 ($source-position (<parser-stream>-source self))))
    (index	0)))

(define-function parser-stream-at-end (self)
  (and (= +end+ (<token>-value (<parser-stream>-position self)))))

(define-function parser-stream-peek-token (self)
  (<parser-stream>-position self))

(define-function parser-stream-peek (self)
  (<token>-value (<parser-stream>-position self)))

(define-function parser-stream-next-token (self)
  (let ((here (<parser-stream>-position self)))
    (or (= +end+ (<token>-value here))
	(let ((tail (<token>-tail here)))
	  (set (<parser-stream>-position self)
	       (or tail (set (<token>-tail here)
			     (token ($next (<parser-stream>-source self))
				    (incr (<parser-stream>-index self) 1)
				    ($source-position (<parser-stream>-source self))
				    ))))))
    here))

(define-function parser-stream-next (self)
  (<token>-value (parser-stream-next-token self)))

(define-function parser-stream-push-token (self token)
  (set (<token>-tail token) (<parser-stream>-position self))
  (set (<parser-stream>-position self) token))

(define-function parser-stream-push (self value)
  (parser-stream-push-token self (token value (<parser-stream>-index self) ($source-position (<parser-stream>-source self)))))

(define-function parser-stream-match-object (self value)
  (and (= value (parser-stream-peek self))
       (parser-stream-next self)))

(define-function parser-stream-match-any (self)
  (and (!= +end+ (parser-stream-peek self))
       (parser-stream-next self)))

(define-function make-class (s)
  (let* ((out (array))
	 (i   0)
	 (l   (string-length s))
	 (k   (- l 2)))
    (while (< i k)
      (let ((c (string-at s i))
	    (d (string-at s (+ i 1))))
	(if (= ?- d)
	    (let ((e (string-at s (+ i 2))))
	      (if (<= c e)
		  (if (<= (- e c) 2048)
		      (for (d c (+ e 1)) (array-append out d))
		    (error "character range too large: "c"-"e))
		(error "malformed character range: "c"-"e))
	      (set i (+ i 3)))
	  (array-append out c)
	  (set i (+ i 1)))))
    (while (< i l)
      (array-append out (string-at s i))
      (set i (+ i 1)))
    (let ((c (array->string (array-sort out))))
      c)))

(define-function parser-stream-match-class (self class)
  ;; class is a string here, obj is a char (currently represented as <long>)
  (let ((obj (parser-stream-peek self)))
    (and (long? obj)
         (<= 0 (binary-search class $size $at obj -))
         (parser-stream-next self))))

(define-function parser-stream-fail (self position)
  (set (<parser-stream>-position self) position)
  ())

(define-function parser-stream-match-string (self str)
  (let ((pos (<parser-stream>-position self))
	(idx 0)
	(lim (string-length str)))
    (while (and (< idx lim) (parser-stream-match-object self (string-at str idx)))
      (set idx (+ idx 1)))
    (if (= idx lim)
	str
      (parser-stream-fail self pos))))

(define-function parser-stream-short-context (self)
  (let ((a (array))
	(p (<parser-stream>-position self)))
    (while (and (<token>-tail (parser-stream-peek-token self))
		(!= +end+ (parser-stream-peek self))
		(!= ?\n   (parser-stream-peek self))
		(!= ?\r   (parser-stream-peek self)))
      (array-append a (parser-stream-next self)))
    (for (i 0 32)
      (if (and (!= +end+ (parser-stream-peek self))
	       (!= ?\n   (parser-stream-peek self))
	       (!= ?\r   (parser-stream-peek self)))
	  (array-append a (parser-stream-next self))
	(set i 999)))
    ;;(array-do x a (println x))
    (set (<parser-stream>-position self) p)
    (array->string a)))

(define-function parser-stream-context (self)
  (let ((a (array))
	(p (<parser-stream>-position self)))
    (while (and (<token>-tail (parser-stream-peek-token self))
		(!= +end+ (parser-stream-peek self)))
      (array-append a (parser-stream-next self)))
    (and (> (array-length a) 0)
	 (string-do c "[31;1m<!>[30;0m" (array-append a c)))
    (for (i 0 32)
      (if (!= +end+ (parser-stream-peek self))
	  (array-append a (parser-stream-next self))
	(string-do c "[34;1m<EOF>[30;0m" (array-append a c))
	(set i 999)))
    ;;(array-do x a (println x))
    (set (<parser-stream>-position self) p)
    (array->string a)))

(define-method $source-position <parser-stream> () ($source-position self.source))

;;;----------------

(unit-test "<parser-stream>"
  (let ((s (parser-stream (string-stream "xhello")))
	(c 0)
	(a (array)))						(unit-assert (= ?x (parser-stream-peek s)))
								(unit-assert (= ?x (parser-stream-next s)))
								(unit-assert (= ?h (parser-stream-peek s)))
    (let ((p (<parser-stream>-position s)))
      (while (!= +end+ (set c (parser-stream-next s)))
	(array-append a c))					(unit-assert (= +end+ (parser-stream-peek s)))
								(unit-assert (= +end+ (parser-stream-next s)))
      (set (<parser-stream>-position s) p)			(unit-assert (= ?h (parser-stream-peek s)))
								(unit-assert (= ?h (parser-stream-next s)))
      (parser-stream-push s ?r)					(unit-assert (= ?r (parser-stream-peek s)))
      (parser-stream-push s ?o)					(unit-assert (= ?o (parser-stream-peek s)))
      (parser-stream-push s ?m)					(unit-assert (= ?m (parser-stream-peek s)))
      (while (!= +end+ (set c (parser-stream-next s)))
	(array-append a c))					(unit-assert (= "hellomorello" (array->string a)))
      (set (<parser-stream>-position s) p)			(unit-assert (= ?h (parser-stream-peek s)))
								(unit-assert (= ?h (parser-stream-next s)))
      (while (!= +end+ (set c (parser-stream-next s)))
	(array-append a c))					(unit-assert (= "hellomorelloello" (array->string a)))
      (parser-stream-push s (list 'and "strings!" (list 'and (list 'lists))))
      (parser-stream-push s 'symbols)
      (parser-stream-push s "yo dude...")			(unit-assert (= "yo dude..." (parser-stream-next s)))
								(unit-assert (= 'symbols (parser-stream-next s)))
								(unit-assert (equal '(and "strings!" (and (lists)))
										    (parser-stream-next s))))))

;;;----------------------------------------------------------------

(define-record <parser-input-stream> () (source))

(define-function parser-input-stream (source)	(new <parser-input-stream> source))

(define-method $at-end?		<parser-input-stream> () ($at-end? self.source))
(define-method $peek		<parser-input-stream> () (or ($peek self.source) +end+))
(define-method $next		<parser-input-stream> () (or ($next self.source) +end+))
(define-method $source-position	<parser-input-stream> () ($source-position self.source))

;;;----------------------------------------------------------------

(define-record <rule> () (name body recursive?))

(define-function new-<rule> (name body)
  (let ((self (new <rule>)))
    (set (<rule>-name self) name)
    (set (<rule>-body self) body)
    self))

(define-print-method <rule>
  (print-all -stream- "<rule "self.name"="self.body">"))

;;;----------------------------------------------------------------

(define-record <grammar> () (name base fields rules type))

(define-print-method <grammar>
  (print-all -stream- "Grammar["(<grammar>-name self)":"(<grammar>-base self)(<grammar>-fields self)"]={\n")
  (list-do rule (<grammar>-rules self)
    (print-all -stream- "  "rule"\n"))
  (print-all -stream- " }"))

(define-function grammar-add-rule (self rule)
  (let* ((name  (car rule))
	 (body  (cadr rule))
	 (rules (<grammar>-rules self))
	 (pair  (or (assq name rules)
		    (car (set (<grammar>-rules self)
			      (cons (cons name body) rules))))))
    (set-cdr pair (new-<rule> name body))))

(define-function grammar (name base fields rules)
  (let ((self (new <grammar>)))
    (set (<grammar>-name   self) name)
    (set (<grammar>-base   self) base)
    (set (<grammar>-fields self) fields)
    (with-map grammar-add-rule self rules)
    self))

(define-function grammar-find-rule-or-nil (self name)
  (cdr (assq name (<grammar>-rules self))))

(define-function grammar-find-rule (self name)
  (or (grammar-find-rule-or-nil self name)
      (error "rule '"name"' not found in grammar "(<grammar>-name self))))

(define-function grammar-find-body (self name)
  (<rule>-body (grammar-find-rule self name)))

;;;----------------

(define-method $reachable-from <grammar> (exp reached)
  ;;(dumpln "REACHABLE-FROM "exp)
  (and (pair? exp)
       (let ((op (car exp)))
	 (and (!= op 'quasiquote)
	      (!= op 'quote)
	      (if (= 'match-rule (car exp))
		  (let ((name (cadr exp)))
		    (or (member? name reached)
			(set reached ($reachable-from self (grammar-find-body self name) (cons name reached)))))
		(map (lambda (exp) (set reached ($reachable-from self exp reached))) (cdr exp))))))
  reached)

(define-method $warn-unreachable <grammar> ()
  (let ((start (grammar-find-rule-or-nil self 'start)))
    (and start
	 (let ((reached ($reachable-from self (<rule>-body start) '(start))))
	   (list-do assoc self.rules
	     (or (member? (<rule>-name (cdr assoc)) reached)
		 (println "; WARNING: unreachable from start: "(<rule>-name (cdr assoc)))))))))

(define-selector $consumes-input?)

(define-method $consumes-input-all? <grammar> (exps)
  (and exps
       (or ($consumes-input?     self (car exps))
	   ($consumes-input-all? self (cdr exps)))))

(define-method $consumes-input-first? <grammar> (exps)
  (or (not exps)
      (and ($consumes-input?       self (car exps))
	   ($consumes-input-first? self (cdr exps)))))

(define-method $consumes-input? <grammar> (exp)
  ;;(dumpln "CONSUMES-INPUT? "exp)
  (let ((op (car exp)))
    (cond
      ((= op 'match-object)		1)
      ((= op 'match-string)		1)
      ((= op 'match-class)		1)
      ((= op 'match-rule-in)		1)	;xxx THIS IS NOT RELIABLE xxx
      ((= op 'match-rule)		($consumes-input? self (grammar-find-body self (cadr exp))))
      ((= op 'match-any)		1)
      ((= op 'result-expr)		())
      ((= op 'match-list)		1)
      ((= op 'match-zero-one)		())
      ((= op 'match-zero-more)		())
      ((= op 'match-one-more)		($consumes-input? 	self (cadr  exp)))
      ((= op 'make-span)		($consumes-input? 	self (cadr  exp)))
      ((= op 'make-number)		($consumes-input? 	self (caddr exp)))
      ((= op 'make-radix-number)	($consumes-input? 	self (caddr exp)))
      ((= op 'make-symbol)		($consumes-input? 	self (cadr  exp)))
      ((= op 'make-string)		($consumes-input? 	self (cadr  exp)))
      ((= op 'assign-result)		($consumes-input? 	self (caddr exp)))
      ((= op 'peek-not)			($consumes-input? 	self (cadr  exp)))
      ((= op 'peek-for)			($consumes-input? 	self (cadr  exp)))
      ((= op 'match-all)		($consumes-input-all?   self (cdr   exp)))
      ((= op 'match-first)		($consumes-input-first? self (cdr   exp)))
      (else				(error "$consumes-input? does not know about "op)))))

(define-selector $recursive-from?)

(define-method $recursive-from-all? <grammar> (exps name)
  (and exps
       (let ((hd (car exps)))
	 (or ($recursive-from? self hd name)
	     (and (not ($consumes-input? self hd))
		  ($recursive-from-all? self (cdr exps) name))))))

(define-method $recursive-from-first? <grammar> (exps name)
  (and exps
       (or ($recursive-from?       self (car exps) name)
	   ($recursive-from-first? self (cdr exps) name))))

(define-method $recursive-from? <grammar> (exp name)
  ;;(dumpln "RECURSIVE-FROM? "exp)
  (let ((op (car exp)))
    (cond
      ((= op 'match-object)		())
      ((= op 'match-string)		())
      ((= op 'match-class)		())
      ((= op 'match-rule-in)		())	;xxx THIS IS NOT RELIABLE xxx
      ((= op 'match-rule)		(or (= name (cadr exp)) ($recursive-from? self (grammar-find-body self (cadr exp)) name)))
      ((= op 'match-any)		())
      ((= op 'result-expr)		())
      ((= op 'match-list)		())
      ((= op 'match-zero-one)		($recursive-from? 	self (cadr  exp) name))
      ((= op 'match-zero-more)		($recursive-from? 	self (cadr  exp) name))
      ((= op 'match-one-more)		($recursive-from? 	self (cadr  exp) name))
      ((= op 'make-span)		($recursive-from? 	self (cadr  exp) name))
      ((= op 'make-number)		($recursive-from? 	self (caddr exp) name))
      ((= op 'make-radix-number)	($recursive-from? 	self (caddr exp) name))
      ((= op 'make-symbol)		($recursive-from? 	self (cadr  exp) name))
      ((= op 'make-string)		($recursive-from? 	self (cadr  exp) name))
      ((= op 'assign-result)		($recursive-from? 	self (caddr exp) name))
      ((= op 'peek-not)			($recursive-from? 	self (cadr  exp) name))
      ((= op 'peek-for)			($recursive-from? 	self (cadr  exp) name))
      ((= op 'match-all)		($recursive-from-all?   self (cdr   exp) name))
      ((= op 'match-first)		($recursive-from-first? self (cdr   exp) name))
      (else				(error "$recursive-from? does not know about "op)))))

(define-method $left-recursive? <grammar> (rule)
  ($recursive-from? self (<rule>-body rule) (<rule>-name rule)))

(define-method $warn-left-recursion <grammar> ()
  (list-do assoc self.rules
    (let ((rule (cdr assoc)))
      (and ($left-recursive? self rule)
	   (set (<rule>-recursive? rule) 1)
	   (println "; WARNING: left-recursive rule: "(<rule>-name (cdr assoc)))))))

(define-method $sanity-check <grammar> ()
  ($warn-unreachable self)
  ($warn-left-recursion self)
  )

;;;----------------------------------------------------------------

(define-record <parser> () (source result position))

(define-function parser (type stream)
  (let ((self (new* type)))
    (set (<parser>-source self) stream)
    self))

(define-selector $start)

(define-selector parse-from)

(define-method parse-from <parser> (source rule)
  (set self.source (parser-stream source))
  (rule self))

(define-selector parse)

(define-function parse (self source)
  (parse-from self source $start))

(define-selector parse-all-from)

(define-method parse-all-from <parser> (source rule)
  (set self.source (parser-stream source))
  (let ((results (array)))
    (while (rule self)
      (array-append results self.result))
    results))

(define-function parse-all (self source)
  (parse-all-from self source $start))

(define-method parser-context <parser> ()
  (parser-stream-context self.source))

;;;----------------------------------------------------------------

(define-class <peg> <parser> (grammar-name))

(define-function peg (name stream)
  (let ((self (new <peg>)))
    (set (<parser>-source self) stream)
    (set (<peg>-grammar-name self) name)
    self))

;;;----------------------------------------------------------------

(define-function %set-list-source (x y)
  (and (pair? x)
       (let ()
	 (and (pair? y) (set (<pair>-source x) (<pair>-source y)))
	 (%set-list-source (cdr x) (cdr y))))
  x)

(define-function set-list-source (x pos)
  ;;(println "SET LIST "x" SOURCE "pos)
  (%set-list-source x pos) ;; ($source-position pos))
  x)

;;;----------------------------------------------------------------

(define *outer* '(*outer*))
(define *inner* '(*inner*))
(define *recur* '(*recur*))

(define-record <memo> () (state result position))

(define-print-method <memo>
  (print-all -stream- "<memo:"self.state">"))

(define-function memo-set (self state result position)
  (with-instance-accessors self <memo>
    (set self.result   result)
    (set self.position position)
    (set self.state    state)))

(define %cookies 0)

(define-form put (where key val)	`(set ,where (cons (cons ,key ,val) ,where)))
(define-form get (where key)		`(cdr (assq ,key ,where)))
(define-form del (where key)		`(set ,where (%del ,where ,key)))

(define-function %del (where key)
  (and (pair? where)
       (if (= key (caar where))
	   (cdr where)
	 (cons (car where) (%del (cdr where) key)))))

;;;----------------------------------------------------------------

(define-form peg-define-rule (name type vars expr)
  (if vars
      `(define-method ,name ,type () (let ,vars ,expr))
    `(define-method ,name ,type () ,expr)))

(define *succeeded*	'(*succeeded*))
(define *failed*	'(*failed*))
(define *active*	'(*active*))
(define *recurred*	'(*recurred*))

(define-function peg-source-range-begin (self)	(push (<parser>-position self) ($source-position (<parser>-source self))))
(define-function peg-source-range-end (self)	(pop (<parser>-position self)))

(define-function peg-invoke-rule-simply (rule name self)
  ;;(println "; simple "name)
  (peg-source-range-begin self)
  (let ((result (rule self)))
    (peg-source-range-end self)
    result))

(define-function peg-invoke-rule-with-memo (rule name self)
  ;;(println "; memoised "name" "self)
  (let* ((here (<parser-stream>-position (<parser>-source self)))
	 (memo (get (<token>-notes here) name)))
    ;;(println "; memo "memo)
    (cond
      (memo	(and (= *succeeded* (<memo>-state memo))
		     (let ()
		       (set (<parser>-result self) (<memo>-result memo))
		       (set (<parser-stream>-position (<parser>-source self)) (<memo>-position memo)))))
      (else	(put (<token>-notes here) name (set memo (new <memo>)))
		(if (peg-invoke-rule-simply rule name self)
		    (memo-set memo *succeeded* (<parser>-result self) (<parser-stream>-position (<parser>-source self)))
		  (set (<memo>-state memo) *failed*)
		  ())))))

(define-function peg-invoke-rule-with-recursion (rule name self)
  (let* ((stream (<parser>-source self))
	 (posn   (<parser-stream>-position stream))
	 (notes  (<token>-notes posn))
	 (memo   (get notes name)))
    (if memo
	;; this rule has already been entered at this position and has either succeeded, failed, or is in left-recursive iteration
	(let ((state  (<memo>-state  memo))
	      (result (<memo>-result memo)))
	  (cond
	    ((= state *succeeded*)	(set (<parser>-result	       self)   (<memo>-result   memo))
					(set (<parser-stream>-position stream) (<memo>-position memo)))
	    ((= state *active*)		(set (<memo>-state memo) *recurred*)
					())
	    (else			())))
      ;; this rule has not been entered at this position
      (put (<token>-notes posn) name (set memo (new <memo> *active* () posn)))
      (if (peg-invoke-rule-simply rule name self)
	  ;; rule succeeded without recursion or entered recursion and found a non-recursive initial prefix
	  (let ((state (<memo>-state memo)))
	    (memo-set memo *succeeded* (<parser>-result self) (<parser-stream>-position stream))
	    (if (= state *recurred*)
		(let ()
		  (set (<parser-stream>-position stream) posn)	;; rewind to start of recursive match
		  (while (and (peg-invoke-rule-simply rule name self)
			      (token-preceeds (<memo>-position memo) (<parser-stream>-position stream)))	;; grow the prefix recursively
		    (set (<memo>-result   memo) (<parser>-result self))
		    (set (<memo>-position memo) (<parser-stream>-position stream))
		    (set (<parser-stream>-position stream) posn))
		  (set (<parser>-result self) (<memo>-result memo))			;; store the final result when recursion fails to grow prefix
		  (set (<parser-stream>-position stream) (<memo>-position memo)))
	      (or (= state *active*) (error "unknown parser state after recursion: "state))))
	(set (<memo>-state memo) *failed*)
	()))))

(define peg-invoke-rule peg-invoke-rule-simply)

;;(define rule-counter 0)

(define-form peg-match-rule (name self)
  ;;(let ((qname (list 'quote (concat-symbol (format "%d." (incr rule-counter)) name))))
  (let ((qname (list 'quote name)))
    `(peg-invoke-rule ,name ,qname ,self)))

(define-function peg-disable-memoisation ()	(println "; PEG memoisation disabled")	(set peg-invoke-rule peg-invoke-rule-simply))
(define-function peg-enable-memoisation ()	(println "; PEG memoisation enabled")	(set peg-invoke-rule peg-invoke-rule-with-memo))
(define-function peg-enable-recursion ()	(println "; PEG recursion enabled")	(set peg-invoke-rule peg-invoke-rule-with-recursion))

;;(peg-enable-recursion)

;;;----------------------------------------------------------------

(define-function parse-stream (grammar rule stream)
  (let* ((s (parser-stream stream))
	 (p (parser grammar s)))
    (or (rule p)
	(let ()
	  (print "\nfailed to parse with gramamr "(name-of-type grammar)"."(<selector>-name rule)" near: ")
	  (until (parser-stream-at-end stream)
	    (print (character->string (parser-stream-next stream))))
	  (println "<EOF>")
	  (error "abort")))
    (<parser>-result p)))

(define-function parse-file (grammar rule path)
  (let* ((handle  (or (file-open path "r") (error "cannot open: "path)))
	 (stream  (input-stream handle path))
	 (result  (parse-stream grammar rule stream)))
    (file-close handle)
    result))

(define-function parse-string (grammar rule str)
  (parse-stream grammar rule (string-stream str)))
