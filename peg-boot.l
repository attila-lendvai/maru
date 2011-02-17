(define-structure <begpeg> (result))

(define-form define-rule (rule . body)
  (let ((name (concat-symbol '$ rule)))
    (or (defined? name) (eval (list 'define-selector name)))
    `(define-method ,name <begpeg> (_) ,@body)))

(define-form FAIL (pos)		`(let () (set (<parser-stream>-position _) ,pos) ()))
(define-form RULE (rule)	`(,(concat-symbol '$ rule) self _))
(define-form OBJECT (object)	`(parser-stream-match-object _ ,object))
(define-form CLASS (class)	`(parser-stream-match-class _ ,class))

(define-rule blank
  (or (OBJECT ?\ )
      (OBJECT ?\t)))

(define-rule eol
  (or (and (OBJECT ?\n)
	   (let ()
	     (while (OBJECT ?\r))
	     't))
      (and (OBJECT ?\r)
	   (let ()
	     (while (OBJECT ?\n))
	     't))))

(define-rule comment
  (if (OBJECT ?\#)
      (let ()
	(while (and (parser-stream-peek _)
		    (not (RULE eol)))
	  (parser-stream-next _))
	't)))

(define-rule space
  (while (or (RULE blank) (RULE eol) (RULE comment)))
  't)

(define-rule equals	(and (OBJECT ?=) (RULE space)))
(define-rule bar	(and (OBJECT ?|) (RULE space)))
(define-rule pling	(and (OBJECT ?!) (RULE space)))
(define-rule ampersand	(and (OBJECT ?&) (RULE space)))
(define-rule semicolon	(and (OBJECT ?\;) (RULE space)))
(define-rule colon	(and (OBJECT ?:) (RULE space)))

(define-rule colondbl	(let ((pos (<parser-stream>-position _)))
			  (and (OBJECT ?:)
				    (if (OBJECT ?:)
					(RULE space)
				      (FAIL pos)))))

(define-rule arrow	(let ((pos (<parser-stream>-position _)))
			  (and (OBJECT ?-)
				    (if (OBJECT ?>)
					(RULE space)
				      (FAIL pos)))))

(define-rule dollardbl	(let ((pos (<parser-stream>-position _)))
			  (and (OBJECT ?$)
				    (if (OBJECT ?$)
					(RULE space)
				      (FAIL pos)))))

(define-rule dollar	(and (OBJECT ?$) (RULE space)))
(define-rule at		(and (OBJECT ?@) (RULE space)))
(define-rule query    	(and (OBJECT ??) (RULE space)))
(define-rule plus     	(and (OBJECT ?+) (RULE space)))
(define-rule star     	(and (OBJECT ?*) (RULE space)))
(define-rule lparen    	(and (OBJECT ?() (RULE space)))
(define-rule rparen    	(and (OBJECT ?)) (RULE space)))
(define-rule lbrace   	(and (OBJECT ?{) (RULE space)))
(define-rule rbrace   	(and (OBJECT ?}) (RULE space)))
(define-rule dot      	(and (OBJECT ?.) (RULE space)))

(define-rule letter
  (set (<begpeg>-result self)
       (CLASS "ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz")))

(define-rule digit
  (set (<begpeg>-result self)
       (CLASS "0123456789")))

(define-rule identifier
  (let ((pos (<parser-stream>-position _)))
    (and (RULE letter)
	 (let ((ans (group)))
	   (group-append ans (<begpeg>-result self))
	   (while (or (RULE letter) (RULE digit))
	     (group-append ans (<begpeg>-result self)))
	   (RULE space)
	   (set (<begpeg>-result self) (string->symbol (group->string ans)))))))

(define-rule char
  (if (OBJECT ?\\)
      (or
        (and (OBJECT ?\\)	(set (<begpeg>-result self) ?\\))
	(and (OBJECT ?t)	(set (<begpeg>-result self) ?\t))
	(and (OBJECT ?n)	(set (<begpeg>-result self) ?\n))
	(and (OBJECT ?r)	(set (<begpeg>-result self) ?\r))
	(and (OBJECT ?\")	(set (<begpeg>-result self) ?\"))
	(and (OBJECT ?\')	(set (<begpeg>-result self) ?\'))
	(set (<begpeg>-result self) (parser-stream-next _)))
    (set (<begpeg>-result self) (parser-stream-next _))))

(define-rule character
  (and (OBJECT ?\')
       (or (RULE char) (error "char expected"))
       (let ((c (<begpeg>-result self)))
	 (or (OBJECT ?\') (error "closing ' expected in character constant"))
	 (RULE space)
	 (set (<begpeg>-result self) c))))

(define-rule string
  (and (OBJECT ?\")
       (let ((ans (group)))
	 (while (not (OBJECT ?\"))
	   (if (RULE char)
	       (group-append ans (<begpeg>-result self))
	     (error "char expected")))
	 (RULE space)
	 (set (<begpeg>-result self) (group->string ans)))))

(define-rule class
  (and (OBJECT ?\[)
       (let ((ans (group)))
	 (while (not (OBJECT ?\]))
	   (if (RULE char)
	       (group-append ans (<begpeg>-result self))
	     (error "char expected")))
	 (RULE space)
	 (set (<begpeg>-result self) (group->string ans)))))

(define-selector $expression) ;; forward

(define-rule variable2
  (and (RULE colondbl)
       (or (RULE identifier)
	   (error "identifier expected after ::"))))

(define-rule variable
  (and (RULE colon)
       (or (RULE identifier)
	   (error "identifier expected after :"))))

(define-rule symchar
  (set (<begpeg>-result self)
       (CLASS "!#$%&*+,-/<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|~")))

(define-rule symbol
  (let ((pos (<parser-stream>-position _)))
    (and (RULE symchar)
	 (let ((ans (group)))
	   (group-append ans (<begpeg>-result self))
	   (while (or (RULE symchar) (RULE digit))
	     (group-append ans (<begpeg>-result self)))
	   (RULE space)
	   (set (<begpeg>-result self) (string->symbol (group->string ans)))))))

(define-rule list
  (and (RULE lparen)
       (let ((ans (group)))
	 (while
	   (cond
	     ((RULE symbol)	(group-append ans (list 'result-list-symbol (<begpeg>-result self))))
	     ((RULE variable2)	(group-append ans (list 'result-list-variable-splicing (<begpeg>-result self))))
	     ((RULE variable)	(group-append ans (list 'result-list-variable (<begpeg>-result self))))
	     (else			())))
	 (or (RULE rparen) (error ") expected"))
	 (RULE space)
	 (set (<begpeg>-result self) (group->list! ans)))))

(define-rule atom
  (cond 
    ((RULE lbrace)	(let ((ans))
			  (or (RULE expression) (error "expression expected after {"))
			  (set ans (<begpeg>-result self))
			  (or (RULE rbrace) (error "} expected"))
			  (set (<begpeg>-result self) ans)))
    ((RULE character)	(set (<begpeg>-result self) (list 'match-object (<begpeg>-result self))))
    ((RULE string)	(set (<begpeg>-result self) (list 'match-string (<begpeg>-result self))))
    ((RULE class)	(set (<begpeg>-result self) (list 'match-class  (<begpeg>-result self))))
    ((RULE identifier)	(set (<begpeg>-result self) (list 'match-rule   (<begpeg>-result self))))
    ((RULE dot)		(set (<begpeg>-result self) (list 'match-any)))
    ((RULE arrow)	(cond
			  ((RULE identifier)	(set (<begpeg>-result self) (list 'result-variable (<begpeg>-result self))))
			  ((RULE character)	(set (<begpeg>-result self) (list 'result-object (<begpeg>-result self))))
			  ((RULE string)		(set (<begpeg>-result self) (list 'result-string (<begpeg>-result self))))
			  ((RULE list)		(set (<begpeg>-result self) (cons 'result-list (<begpeg>-result self))))
			  (else				(error "identifier/string/list expected after ->"))))
    ((RULE colon)	(if (RULE identifier)
			    (set (<begpeg>-result self) (list 'assign-result (<begpeg>-result self)))
			  (error "identifier expected after :")))
    (else		())))

(define-rule repetition
  (and (RULE atom)
       (let ((exp (<begpeg>-result self)))
	 (cond
	   ((RULE query)	(set exp (list 'match-zero-one  exp)))
	   ((RULE star)		(set exp (list 'match-zero-more exp)))
	   ((RULE plus)		(set exp (list 'match-one-more  exp))))
	 (set (<begpeg>-result self) exp))))

(define-rule conversion
  (and (RULE repetition)
       (let ((exp (<begpeg>-result self)))
	 (while (cond
		  ((RULE at)		(set exp (list 'make-span exp)))
		  ((RULE dollardbl)	(set exp (list 'make-symbol exp)))
		  ((RULE dollar)	(set exp (list 'make-string exp)))
		  (else			())))
	 (set (<begpeg>-result self) exp))))

(define-rule predicate
  (let ((pos (<parser-stream>-position _)))
    (if (and (RULE pling) (RULE conversion))
	(set (<begpeg>-result self) (list 'peek-not (<begpeg>-result self)))
      (set (<parser-stream>-position _) pos)
      (if (and (RULE ampersand) (RULE conversion))
	  (set (<begpeg>-result self) (list 'peek-for (<begpeg>-result self)))
	(RULE conversion)))))

(define-rule sequence
  (and (RULE predicate)
       (let ((lhs (<begpeg>-result self)))
	 (and (RULE sequence)
	      (set lhs (list 'match-both lhs (<begpeg>-result self))))
	 (set (<begpeg>-result self) lhs))))

(define-rule expression
  (let ((lhs))
    (and (RULE sequence)
	 (set lhs (<begpeg>-result self))
	 (and (RULE bar)
	      (or (RULE expression) (error "expression expected after |"))
	      (set lhs (list 'match-first lhs (<begpeg>-result self)))))
    (set (<begpeg>-result self) lhs)))

(define-rule definition
  (let ((id) (exp))
    (RULE space)
    (and (RULE identifier)
	 (set id (<begpeg>-result self))
	 (RULE equals)
	 (or (RULE expression) (error "expression expected after ="))
	 (set exp (<begpeg>-result self))
	 (or (OBJECT ?\;) (error "; expected"))
	 (set (<begpeg>-result self) (list 'rule id exp)))))

(unit-test "<begpeg>"
  (let ((self (new <begpeg>))
        (_    (parser-stream (string-stream "= | ! & : :: -> $ ? + * ( ) { } .
  					q6ident1f1er
  					a\nb'x'\"multi\n\tline\n\tstring\"
  					[character-class]
  					\"string\" [class] identifier .
  					foo? bar* baz+
  					letter+$
  					:id
  					( this :is ::a list )
  					&foo !bar -> baz -> \"string\" -> ( a list )
  					this is a sequence of stuffs ;
  					and this | is an | expression ;
  					definition = lots of | rules here . ;
  					"))))
    (unit-assert (RULE equals		))
    (unit-assert (RULE bar		))
    (unit-assert (RULE pling		))
    (unit-assert (RULE ampersand	))
    (unit-assert (RULE colon		))
    (unit-assert (RULE colondbl		))
    (unit-assert (RULE arrow		))
    (unit-assert (RULE dollar		))
    (unit-assert (RULE query		))
    (unit-assert (RULE plus		))
    (unit-assert (RULE star		))
    (unit-assert (RULE lparen		))
    (unit-assert (RULE rparen		))
    (unit-assert (RULE lbrace		))
    (unit-assert (RULE rbrace		))
    (unit-assert (RULE dot		))
    (unit-assert (RULE letter		))	(unit-assert (= (<begpeg>-result self) ?q ))
    (unit-assert (RULE digit		))	(unit-assert (= (<begpeg>-result self) ?6 ))
    (unit-assert (RULE identifier	))	(unit-assert (= (<begpeg>-result self) 'ident1f1er))
    (unit-assert (RULE char		))	(unit-assert (= (<begpeg>-result self) ?a ))
    (unit-assert (RULE char		))	(unit-assert (= (<begpeg>-result self) ?\n))
    (unit-assert (RULE char		))	(unit-assert (= (<begpeg>-result self) ?b ))
    (unit-assert (RULE character	))	(unit-assert (= (<begpeg>-result self) ?x ))
    (unit-assert (RULE string		))	(unit-assert (= (<begpeg>-result self) "multi\n	line\n	string"))
    (unit-assert (RULE class		))	(unit-assert (= (<begpeg>-result self) "character-class"))
    (unit-assert (RULE atom		))	(unit-assert (equal (<begpeg>-result self) '(match-string "string")))
    (unit-assert (RULE atom		))	(unit-assert (equal (<begpeg>-result self) '(match-class "class")))
    (unit-assert (RULE atom		))	(unit-assert (equal (<begpeg>-result self) '(match-rule identifier)))
    (unit-assert (RULE atom		))	(unit-assert (equal (<begpeg>-result self) '(match-any)))
    (unit-assert (RULE repetition	))	(unit-assert (equal (<begpeg>-result self) '(match-zero-one (match-rule foo))))
    (unit-assert (RULE repetition	))	(unit-assert (equal (<begpeg>-result self) '(match-zero-more (match-rule bar))))
    (unit-assert (RULE repetition	))	(unit-assert (equal (<begpeg>-result self) '(match-one-more (match-rule baz))))
    (unit-assert (RULE conversion	))	(unit-assert (equal (<begpeg>-result self) '(make-string (match-one-more (match-rule letter)))))
    (unit-assert (RULE variable		))	(unit-assert (= (<begpeg>-result self) 'id))
    (unit-assert (RULE list		))	(unit-assert (equal (<begpeg>-result self) '((result-list-symbol this) (result-list-variable is) (result-list-variable-splicing a) (result-list-symbol list))))
    (unit-assert (RULE predicate	))	(unit-assert (equal (<begpeg>-result self) '(peek-for (match-rule foo))))
    (unit-assert (RULE predicate	))	(unit-assert (equal (<begpeg>-result self) '(peek-not (match-rule bar))))
    (unit-assert (RULE predicate	))	(unit-assert (equal (<begpeg>-result self) '(result-variable baz)))
    (unit-assert (RULE predicate	))	(unit-assert (equal (<begpeg>-result self) '(result-string "string")))
    (unit-assert (RULE predicate	))	(unit-assert (equal (<begpeg>-result self) '(result-list (result-list-symbol a) (result-list-symbol list))))
    (unit-assert (RULE sequence		))	(unit-assert (equal (<begpeg>-result self) '(match-both (match-rule this) (match-both (match-rule is) (match-both (match-rule a) (match-both (match-rule sequence) (match-both (match-rule of) (match-rule stuffs))))))))
    (unit-assert (RULE semicolon	))
    (unit-assert (RULE expression	))	(unit-assert (equal (<begpeg>-result self) '(match-first (match-both (match-rule and) (match-rule this)) (match-first (match-both (match-rule is) (match-rule an)) (match-rule expression)))))
    (unit-assert (RULE semicolon	))
    (unit-assert (RULE definition	))	(unit-assert (equal (<begpeg>-result self) '(rule definition (match-first (match-both (match-rule lots) (match-rule of)) (match-both (match-rule rules) (match-both (match-rule here) (match-any)))))))))

;;;----------------------------------------------------------------

(define peg-grammar-string (input-stream-up-to (input-stream (open "peg.g")) ()))

;;;----------------

(define-structure <peg-interpreter> (grammar stream variables result list))

(define-function peg-interpreter (grammar stream)
  (let ((self (new <peg-interpreter>)))
    (set (<peg-interpreter>-grammar self) grammar)
    (set (<peg-interpreter>-stream  self) stream)
    self))

(define-function peg-interpreter-define (self name value)
  (let ((cell (or (assq name (<peg-interpreter>-variables self))
		  (car (set (<peg-interpreter>-variables self)
			    (cons (cons name value)
				  (<peg-interpreter>-variables self)))))))
    (set-cdr cell value)))

(define-function peg-interpreter-lookup (self name)
  (let ((cell (assq name (<peg-interpreter>-variables self))))
    (or cell (error "undefined rule variable: "name))
    (cdr cell)))

(define-function peg-interpreter-push-variables (self)
  (let ((vars (<peg-interpreter>-variables self)))
    (set (<peg-interpreter>-variables self) ())
    vars))

(define-function peg-interpreter-pop-variables (self vars)
  (set (<peg-interpreter>-variables self) vars))

(define-function peg-interpreter-push-list (self)
  (let ((list (<peg-interpreter>-list self)))
    (set (<peg-interpreter>-list self) (group))
    list))

(define-function peg-interpreter-list-append (self value)
  (group-append (<peg-interpreter>-list self) value))

(define-function peg-interpreter-list-append-all (self value)
  (group-append-list (<peg-interpreter>-list self) value))

(define-function peg-interpreter-pop-list (self list)
  (let ((grp (<peg-interpreter>-list self)))
    (set (<peg-interpreter>-list self) list)
    (group->list! grp)))

(define-selector match-rule)

(define peg-interpret ()) ;; forward

(define-function peg-interpreter-match-both (self tree)
  (and (peg-interpret self (cadr tree))
       (peg-interpret self (caddr tree))))

(define-function peg-interpreter-match-first (self tree)
  (or  (peg-interpret self (cadr tree))
       (peg-interpret self (caddr tree))))

(define-function peg-interpreter-match-any (self tree)
  (set (<peg-interpreter>-result self) (parser-stream-next (<peg-interpreter>-stream self))))

(define-function peg-interpreter-match-rule (self tree)
  (match-rule self (cadr tree)))

(define-function peg-interpreter-match-object (self tree)
  (set (<peg-interpreter>-result self)
       (parser-stream-match-object (<peg-interpreter>-stream self)
				   (cadr tree))))

(define-function peg-interpreter-match-class (self tree)
  (set (<peg-interpreter>-result self)
       (parser-stream-match-class (<peg-interpreter>-stream self)
				  (cadr tree))))

(define-function peg-interpreter-match-string (self tree)
  (set (<peg-interpreter>-result self)
       (parser-stream-match-string (<peg-interpreter>-stream self)
				   (cadr tree))))

(define-function peg-interpreter-make-symbol (self tree)
  (and (peg-interpret self (cadr tree))
       (set (<peg-interpreter>-result self)
	    (string->symbol (list->string (<peg-interpreter>-result self))))))

(define-function peg-interpreter-make-string (self tree)
  (and (peg-interpret self (cadr tree))
       (set (<peg-interpreter>-result self)
	    (list->string (<peg-interpreter>-result self)))))

(define-function peg-interpreter-make-span (self tree)
  (let ((pos (<parser-stream>-position (<peg-interpreter>-stream self))))
    (and (peg-interpret self (cadr tree))
	 (set (<peg-interpreter>-result self)
	      (list-from-to pos (<parser-stream>-position (<peg-interpreter>-stream self)))))))

(define-function peg-interpreter-assign-result (self tree)
  (let () (peg-interpreter-define self (cadr tree) (<peg-interpreter>-result self)) 't))

(define-function peg-interpreter-result-variable (self tree)
  (let () (set (<peg-interpreter>-result self) (peg-interpreter-lookup self (cadr tree))) 't))

(define-function peg-interpreter-result-object (self tree)
  (let () (set (<peg-interpreter>-result self) (cadr tree)) 't))

(define-function peg-interpreter-result-list (self tree)
  (let ((list (peg-interpreter-push-list self)))
    (list-do rule (cdr tree) (peg-interpret self rule))
    (set (<peg-interpreter>-result self)
	 (peg-interpreter-pop-list self list))))

(define-function peg-interpreter-result-list-symbol (self tree)
  (peg-interpreter-list-append self (string->symbol (cadr tree))))

(define-function peg-interpreter-result-list-variable (self tree)
  (peg-interpreter-list-append self (peg-interpreter-lookup self (cadr tree))))

(define-function peg-interpreter-result-list-variable-splicing (self tree)
  (peg-interpreter-list-append-all self (peg-interpreter-lookup self (cadr tree))))

(define-function peg-interpreter-peek-not (self tree)
  (let ((pos (<parser-stream>-position (<peg-interpreter>-stream self))))
    (if (peg-interpret self (cadr tree))
	(parser-stream-fail (<peg-interpreter>-stream self) pos)
      't)))

(define-function peg-interpreter-match-zero-one (self tree)
  (set (<peg-interpreter>-result self)
       (and (peg-interpret self (cadr tree))
	    (list (<peg-interpreter>-result self))))
  't)

(define-function peg-interpreter-match-zero-more (self tree)
  (let ((grp (group)))
    (while (peg-interpret self (cadr tree)) (group-append grp (<peg-interpreter>-result self)))
    (set (<peg-interpreter>-result self) (group->list! grp))
    't))

(define-function peg-interpreter-peek-for (self tree)
  (let ((pos (<parser-stream>-position (<peg-interpreter>-stream self))))
    (and (peg-interpret self (cadr tree))
	 (set (<parser-stream>-position (<peg-interpreter>-stream self)) pos))))

;;(define profiles ())

(set peg-interpret
     (lambda (self tree)
       (let ((op (car tree)))
;; 	 (let ((cell (or (assq op profiles)
;; 			 (car (set profiles (cons (cons op 0) profiles))))))
;; 	   (set-cdr cell (+ (cdr cell) 1)))
	 (cond
	   ((= op 'match-both)				(peg-interpreter-match-both self tree))
	   ((= op 'match-rule)				(peg-interpreter-match-rule self tree))
	   ((= op 'match-first)				(peg-interpreter-match-first self tree))
	   ((= op 'match-object)			(peg-interpreter-match-object self tree))
	   ((= op 'match-class)				(peg-interpreter-match-class self tree))
	   ((= op 'assign-result)			(peg-interpreter-assign-result self tree))
	   ((= op 'match-zero-more)			(peg-interpreter-match-zero-more self tree))
	   ((= op 'result-variable)			(peg-interpreter-result-variable self tree))
	   ((= op 'result-list-variable)		(peg-interpreter-result-list-variable self tree))
	   ((= op 'match-zero-one)			(peg-interpreter-match-zero-one self tree))
	   ((= op 'result-list-symbol)			(peg-interpreter-result-list-symbol self tree))
	   ((= op 'result-list)				(peg-interpreter-result-list self tree))
	   ((= op 'make-symbol)				(peg-interpreter-make-symbol self tree))
	   ((= op 'make-string)				(peg-interpreter-make-string self tree))
	   ((= op 'make-span)				(peg-interpreter-make-span self tree))
	   ((= op 'match-string)			(peg-interpreter-match-string self tree))
	   ((= op 'match-any)				(peg-interpreter-match-any self tree))
	   ((= op 'peek-not)				(peg-interpreter-peek-not self tree))
	   ((= op 'result-list-variable-splicing)	(peg-interpreter-result-list-variable-splicing self tree))
	   ((= op 'result-object)			(peg-interpreter-result-object self tree))
	   ((= op 'peek-for)				(peg-interpreter-peek-for self tree))
	   (else					(error "peg-interpret does not understand "op))))))

;;(define indent 0)

(define-method match-rule <peg-interpreter> (name)
  ;;(print (format "%3d" indent))  (for (i 0 indent) (print " | "))  (println name " @ " (format "%c" (parser-stream-peek (<peg-interpreter>-stream self))))  (set indent (+ indent 1))
  (let* ((rule (grammar-find-rule (<peg-interpreter>-grammar self) name))
	 (vars (peg-interpreter-push-variables self))
	 (ok   (peg-interpret self (cadr rule))))
    (peg-interpreter-pop-variables self vars)
    ;;(set indent (- indent 1))  (print (format "%3d" indent))  (for (i 0 indent) (print " | "))  (println name " => "ok" "(<peg-interpreter>-result self))
    ok))

;;;----------------

(define BEG (grammar 'BEG () ()))

(let ((p (new <begpeg>))
      (_ (parser-stream (string-stream peg-grammar-string))))
  (while ($definition p _)
    ;;(println "BEG: " (<begpeg>-result p) " ")
    (grammar-add-rule BEG (<begpeg>-result p)))
  ;;(println)
  ($space p _)
  (and (parser-stream-peek _) (error "syntax error in BEG"))
  )

(define PEG (grammar '<peg-parser> '<parser> ()))

(let* ((_ (parser-stream (string-stream peg-grammar-string)))
       (p (peg-interpreter BEG _)))
  (while (match-rule p 'definition)
    (let* ((result (<peg-interpreter>-result p)))
      ;;(println "PEG: " result)
      (grammar-add-rule PEG result)))
  (match-rule p 'space)
  (and (parser-stream-peek _) (error "syntax error in PEG near: " (parser-stream-context _)))
  )

(or (equal (<grammar>-rules BEG) (<grammar>-rules PEG))
    (error "grammars are not identical"))

;; (map println profiles)

;; (println PEG)

;; (define peg-to-cola-string (input-stream-up-to (input-stream (open "peg-to-cola.g")) ()))

;;;----------------------------------------------------------------

(let ((p (peg-compiler PEG)))
  ($compile p))
