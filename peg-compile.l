(define-form match-save (exp)	`(let ((pos (<parser-stream>-position self.source))) ,exp))
(define-form match-ok ()	`(set (<parser-stream>-position self.source) pos))
(define-form match-ko ()	`(let () (set (<parser-stream>-position self.source) pos) ()))

(define-form match-rule (name . args)
  (if args
      `(match-save
	 (let ()
	   ,@(map (lambda (arg) (list 'parser-stream-push 'self.source arg)) args)
	   (or (,(concat-symbol '$ name) self)
	       (match-ko))))
    `(,(concat-symbol '$ name) self)))

(define-form match-first (lhs rhs)	`(or ,lhs ,rhs))
(define-form match-both (lhs rhs)	`(match-save (or (and ,lhs ,rhs) (match-ko))))

(define-form match-zero-one (exp)
  `(let ((_list_ (group)))
     (and ,exp (group-append _list_ self.result))
     (set self.result (group->list! _list_))
     't))

(define-form match-zero-more (exp)
  `(let ((_list_ (group)))
     (while ,exp (group-append _list_ self.result))
     (set self.result (group->list! _list_))
     't))

(define-form match-one-more (exp)
  `(let ((_list_ (group)))
     (while ,exp (group-append _list_ self.result))
     (and (not (group-empty? _list_))
	  (let ()
	    (set self.result (group->list! _list_))
	    't))))

(define-form peek-for (exp)	`(match-save (and ,exp (match-ok))))
(define-form peek-not (exp)	`(not (peek-for ,exp)))

(define-form match-list (exp)
  `(and (pair? (parser-stream-peek self.source))
	(let ((src self.source))
	  (set self.source (parser-stream (list-stream (parser-stream-peek src))))
	  (let ((ok ,exp))
	    (set self.source src)
	    (and ok (parser-stream-next src))))))

(define-form match-class (str)	`(set self.result (parser-stream-match-class self.source ,str)))
(define-form match-string (str)	`(set self.result (parser-stream-match-string self.source ,str)))
(define-form match-object (obj)	`(and (= ',obj (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source))))
(define-form match-any ()	'(set self.result (parser-stream-next self.source)))

(define-form make-span (exp)
  `(let ((pos (<parser-stream>-position self.source)))
     (and ,exp
	  (let ()
	    (set self.result (list-from-to pos (<parser-stream>-position self.source)))
	    't))))

(define-form make-string (exp)	`(and ,exp (set self.result (list->string self.result))))
(define-form make-symbol (exp)	`(and ,exp (set self.result (string->symbol (list->string self.result)))))
(define-form make-number (exp)	`(and ,exp (set self.result (string->number (list->string self.result)))))

(define-form assign-result (name)	`(let () (set ,name self.result) 't))
(define-form result-object (obj)	`(let () (set self.result ',obj) 't))
(define-form result-expr (exp)		`(let () (set self.result ,exp) 't))

(define-form result-list exps				`(let ((_list_ (group))) ,@exps (set self.result (group->list! _list_)) 't))
(define-form result-list-symbol (sym)			`(group-append _list_ ',sym))
(define-form result-list-variable (var)			`(group-append _list_ ,var))
(define-form result-list-variable-splicing (var)	`(group-append-list _list_ ,var))

(define-function peg-find-variables (tree vars)
  (and (pair? tree)
       (if (= (car tree) 'assign-result)
	   (or (assq (cadr tree) vars)
	       (set vars (cons (cons (cadr tree)) vars)))
	 (and (!= (car tree) 'result-expr)
	      (let ((e1 (cadr tree))
		    (e2 (caddr tree)))
		(set vars (peg-find-variables e1 vars))
		(set vars (peg-find-variables e2 vars))))))
  vars)

(define-function peg-make-declaration (type rule)
  `(define-selector ,(concat-symbol '$ (car rule))))

(define-function peg-make-definition (type rule)
  `(define-method ,(concat-symbol '$ (car rule)) ,type ()
     (let ,(peg-find-variables (cadr rule) ())
       ,(expand (cadr rule)))))

(define-function pval (expr)
  (dumpln expr)
  (eval expr))

(define-function peg-compile-grammar (grammar)
  (let ((class (list 'define-class (<grammar>-name grammar) (<grammar>-base grammar) (<grammar>-fields grammar)))
	(decls (with-map peg-make-declaration (<grammar>-name grammar) (<grammar>-rules grammar)))
	(defns (with-map peg-make-definition  (<grammar>-name grammar) (<grammar>-rules grammar))))
    (eval class)
    (map eval decls)
    (map eval defns)
    (cons class (concat-list decls defns))))
