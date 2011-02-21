(define-function putchar (c) (print (format "%c" c)))

(define-function long? (self) (= <long> (type-of self)))

(define-selector $size)

(<selector>-add-method $size <string> string-length)

(define-selector $at)

(<selector>-add-method $at <string> string-at)

(define-function binary-search (seq obj cmp)
  (let ((lo 0)
	(hi (- ($size seq) 1))
	(ix ()))
    (while (and (not ix) (<= lo hi))
      (let* ((m (/ (+ lo hi) 2))
	     (s ($at seq m)))
	(cond
	  ((cmp obj s)	(set hi (- m 1)))
	  ((cmp s obj)	(set lo (+ m 1)))
	  (else		(set ix m)))))
    (or ix -1)))

;;;----------------------------------------------------------------

;; (define-structure <token> (value tail))

;; (define-function token (value)
;;   (let ((self (new <token>)))
;;     (set (<token>-value self) value)
;;     self))

;; (define-method do-print <token> ()
;;   (let ((value (<token>-value self)))
;;     (if (long? value)
;; 	(let ((s " "))
;; 	  (set-string-at s 0 value)
;; 	  (dump s))
;;       (dump value))))

;; (define-function new-<token> () (new <token>))

(define <token> <pair>)		(define token cons)			(define new-<token> cons)
(define <token>-value car)	(define set-<token>-value set-car)
(define <token>-tail  cdr)	(define set-<token>-tail  set-cdr)

(define-structure <group> (first last))

(define-function group ()
  (let ((self  (new <group>))
	(token (new-<token>)))
    (set (<group>-first self) token)
    (set (<group>-last  self) token)
    self))

(define-function list-from-to (start stop)
  (and (pair? start)
       (!= start stop)
       (cons (car start) (list-from-to (cdr start) stop))))

(define-function list->string (list)
  (let* ((len (list-length list))
	 (str (string len))
	 (idx 0))
    (while (< idx len)
      (set-string-at str idx (car list))
      (set idx (+ idx 1))
      (set list (cdr list)))
    str))

(define-function group-from-to (first last)
  (let ((self  (new <group>)))
    (set (<group>-first self) first)
    (set (<group>-last  self) last)
    self))

(define-method do-print <group> ()
  (print "{ ")
  (let ((pos (<group>-first self))
	(lim (<group>-last  self)))
    (while (!= pos lim)
      (dump (<token>-value pos))
      (print " ")
      (set pos (<token>-tail pos))))
  (print "}"))

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

(define-function group-append (self value)
  (let ((tok  (new-<token>))
	(last (<group>-last self)))
    (set (<token>-value last) value)
    (set (<token>-tail  last) tok)
    (set (<group>-last  self) tok)))

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

(define-function make-group->list (first last)
  (and (!= first last)
       (cons (group->list (<token>-value first))
	     (make-group->list (<token>-tail first) last))))

(define-method group->list <group> ()
  (make-group->list (<group>-first self) (<group>-last self)))

(define-function group->list! (self)
  (let ((start (<group>-first self))
	(stop  (<group>-last self)))
    (and (!= start stop)
	 (let ((pos start))
	   (while (!= (cdr pos) stop) (set pos (cdr pos)))
	   (set-cdr pos ())
	   start))))

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

(define-selector $peek)
(define-selector $next)

;;;----------------------------------------------------------------

(define-structure <string-stream> (string size position))

(define-function string-stream (string)
  (let ((self (new <string-stream>)))
    (set (<string-stream>-string   self) string)
    (set (<string-stream>-size     self) (string-length string))
    (set (<string-stream>-position self) 0)
    self))

(define-method $peek <string-stream> ()
  (let ((pos self.position))
    (and (< pos self.size)
	 (string-at self.string pos))))

(define-method $next <string-stream> ()
  (let ((pos self.position))
    (and (< pos self.size)
	 (let ((value (string-at self.string pos)))
	   (set self.position (+ pos 1))
	   ;;(print (format "%c" value))
	   value))))

(unit-test "<string-stream>"
  (let ((s (string-stream "xhello"))
	(c 0)
	(a (array)))					(unit-assert (= ?x ($peek s)))
							(unit-assert (= ?x ($next s)))
							(unit-assert (= ?h ($peek s)))
    (while (set c ($next s)) (array-append a c))	(unit-assert (= "hello" (array->string a)))
							(unit-assert (not ($peek s)))
							(unit-assert (not ($next s)))))

;;;----------------------------------------------------------------

(define-structure <list-stream> (source))

(define-function list-stream (source)
  (let ((self (new <list-stream>)))
    (set (<list-stream>-source self) source)
    self))

(define-method $peek <list-stream> ()
  (car self.source))

(define-method $next <list-stream> ()
  (let ((value (car self.source)))
    (set self.source (cdr self.source))
    value))

;;;----------------------------------------------------------------

(define-structure <input-stream> (source pending))

(define-function input-stream (source)
  (let ((self (new <input-stream>)))
    (set (<input-stream>-source self) source)
    self))

(define-method $peek <input-stream> ()
  (or (<input-stream>-pending self)
      (set (<input-stream>-pending self)
	   (and (<input-stream>-source self)
		(or (getc (<input-stream>-source self))
		    (let ()
		      (close (<input-stream>-source self))
		      (set (<input-stream>-source self) ())))))))

(define-method $next <input-stream> ()
  (let ((c ($peek self)))
    (set (<input-stream>-pending self) ())
    c))

(define-function input-stream-up-to (self delimiter)
  (let ((a (array)))
    (while (!= delimiter ($peek self))
      (array-append a ($next self)))
    (array->string a)))

(unit-test "<input-stream>"
  (let ((s (input-stream *input*))
	(c 0)
	(a (array)))						(unit-assert (= ?; ($peek s)))
								(unit-assert (= ?; ($next s)))
								(unit-assert (= ?h ($peek s)))
    (while (!= ?! (set c ($next s)))
      (array-append a c))					(unit-assert (= "hello" (array->string a)))
								(unit-assert (= "goodbye" (input-stream-up-to s ?!)))));hello!goodbye!

;;;----------------------------------------------------------------

(define-structure <parser-stream> (source position))

(define-function parser-stream (source)
  (let ((self (new <parser-stream>)))
    (set (<parser-stream>-source self)   source)
    (set (<parser-stream>-position self) (new-<token>))
    self))

(define-function parser-stream-peek-token (self)
  (let ((here (<parser-stream>-position self)))
    (or (<token>-value here)
	(let ((c ($next (<parser-stream>-source self))))
	  ;;(print "<"(format "%c" c)">")
	  (set (<token>-value here) c)))
    here))

(define-function parser-stream-peek (self)
  (<token>-value (parser-stream-peek-token self)))

(define-function parser-stream-next-token (self)
  (let ((here (<parser-stream>-position self)))
    (or (<token>-value here) (set (<token>-value here) ($next (<parser-stream>-source self))))
    (and (<token>-value here)
	 (let ((tail (<token>-tail here)))
	   (or tail (set tail (set (<token>-tail here) (new-<token>))))
	   (set (<parser-stream>-position self) tail)))
    here))

(define-function parser-stream-next (self)
  (<token>-value (parser-stream-next-token self)))

(define-function parser-stream-push-token (self token)
  (set (<token>-tail token) (<parser-stream>-position self))
  (set (<parser-stream>-position self) token))

(define-function parser-stream-push (self value)
  (parser-stream-push-token self (token value)))

(define-function parser-stream-match-object (self value)
  (and (= value (parser-stream-peek self))
       (parser-stream-next self)))

(define-function parser-stream-match-class (self class)
  (let ((obj (parser-stream-peek self)))
    (and (long? obj) (<= 0 (binary-search class obj <))
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

(define-function parser-stream-context (self)
  (let ((a (array)))
    (for (i 0 32) (let ((c ($next (<parser-stream>-source self)))) (and c (array-append a c))))
    (array->string a)))

;;;----------------

(unit-test "<parser-stream>"
  (let ((s (parser-stream (string-stream "xhello")))
	(c 0)
	(a (array)))						(unit-assert (= ?x (parser-stream-peek s)))
								(unit-assert (= ?x (parser-stream-next s)))
								(unit-assert (= ?h (parser-stream-peek s)))
    (let ((p (<parser-stream>-position s)))
      (while (set c (parser-stream-next s)) (array-append a c))	(unit-assert (not (parser-stream-peek s)))
								(unit-assert (not (parser-stream-next s)))
      (set (<parser-stream>-position s) p)			(unit-assert (= ?h (parser-stream-peek s)))
								(unit-assert (= ?h (parser-stream-next s)))
      (parser-stream-push s ?r)					(unit-assert (= ?r (parser-stream-peek s)))
      (parser-stream-push s ?o)					(unit-assert (= ?o (parser-stream-peek s)))
      (parser-stream-push s ?m)					(unit-assert (= ?m (parser-stream-peek s)))
      (while (set c (parser-stream-next s)) (array-append a c))	(unit-assert (= "hellomorello" (array->string a)))
      (set (<parser-stream>-position s) p)			(unit-assert (= ?h (parser-stream-peek s)))
								(unit-assert (= ?h (parser-stream-next s)))
      (while (set c (parser-stream-next s)) (array-append a c))	(unit-assert (= "hellomorelloello" (array->string a)))
      (parser-stream-push s (list 'and "strings!" (list 'and (list 'lists))))
      (parser-stream-push s 'symbols)
      (parser-stream-push s "yo dude...")			(unit-assert (= "yo dude..." (parser-stream-next s)))
								(unit-assert (= 'symbols (parser-stream-next s)))
								(unit-assert (equal '(and "strings!" (and (lists)))
										    (parser-stream-next s))))))

;;;----------------------------------------------------------------

(define-structure <grammar> (name base fields rules))

(define-function grammar (name base fields)
  (let ((self (new <grammar>)))
    (set (<grammar>-name   self) name)
    (set (<grammar>-base   self) base)
    (set (<grammar>-fields self) fields)
    self))

(define-method do-print <grammar> ()
  (print "Grammar["(<grammar>-name self)":"(<grammar>-base self)(<grammar>-fields self)"]={\n")
  (list-do rule (<grammar>-rules self) (println "  " rule))
  (print " }"))

(define-function grammar-add-rule (self rule)
  (set (<grammar>-rules self)
       (cons (cons (cadr rule) (cddr rule)) (<grammar>-rules self))))

(define-function grammar-find-rule (self name)
  (let ((rule (assq name (<grammar>-rules self))))
    (or rule (error "rule '"name"' not found in grammar "(<grammar>-name self)))
    rule))

;;;----------------

(define-method $reachable-from <grammar> (exp reached)
  (and (pair? exp)
       (let ((op (car exp)))
	 (and (!= op 'quasiquote)
	      (!= op 'quote)
	      (if (= 'match-rule (car exp))
		  (let ((name (cadr exp)))
		    (or (member? name reached)
			(set reached ($reachable-from self (cadr (grammar-find-rule self name)) (cons name reached)))))
		(set reached ($reachable-from self (cadr  exp) reached))
		(set reached ($reachable-from self (caddr exp) reached))))))
  reached)

(define-method $sanity-check <grammar> ()
  (let* ((start   (grammar-find-rule self 'start))
	 (reached ($reachable-from self (cadr start) '(start))))
    (list-do rule self.rules
      (or (member? (car rule) reached)
	  (println "; WARNING: unreachable from start: "(car rule))))))

;;;----------------------------------------------------------------

(define-structure <parser> (source result))

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
