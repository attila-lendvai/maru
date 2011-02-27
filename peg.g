# -*- fundamental -*-

equals    	= "=" space ;
blank		= [\t ] ;
eol		= ("\n" "\r"*) | ("\r" "\n"*) ;
comment		= "#" (!eol .)* ;
space		= (blank | eol | comment)* ;
bar       	= "|"  space ;
pling     	= "!"  space ;
ampersand 	= "&"  space ;
colon     	= ":"  space ;
arrow     	= "->" space ;
quotesgl     	= "\'" space ;
backquote     	= "`"  space ;
commaat     	= ",@" space ;
comma     	= ","  space ;
dollarhash	= "$#" space ;
dollardbl	= "$$" space ;
dollar		= "$"  space ;
at		= "@"  space ;
query     	= "?"  space ;
minus      	= "-"  space ;
plus      	= "+"  space ;
star      	= "*"  space ;
lparen      	= "("  space ;
rparen     	= ")"  space ;
lbrace      	= "{"  space ;
rbrace     	= "}"  space ;
dot       	= "."  space ;
digit		= [0123456789] ;
letter		= [ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz] ;
idpart		= (letter (letter | digit)*) @$$ ;
identifier	= idpart:id space				-> id ;
char		= "\\"	( "t"	->  9
			| "n"	-> 10
			| "r"	-> 13
			| .
                        )
		| . ;
string		= "\""  (!"\""  char)* $:s "\""  space		-> s ;
class		= "["   (!"]"   char)* $:s "]"   space		-> s ;

grammar         = symbol:name space plus                definition*:rules     -> `(grammar-extend ,name         ,@rules)
                | symbol:name space colon symbol:parent definition*:rules     -> `(grammar-define ,name ,parent ,@rules)
                | definition*:d space expression?:e                           -> `(grammar-eval ,d ,(car e))
                ;

symfirst	= [!#$%&*+-./<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|~] ;
symrest		= [!#$%&*+-./0123456789<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|~] ;
symbol		= (symfirst symrest*) @$$ ;
sexpr		= symbol
		| digit+ $#
		| "\""  (!"\""  char)* $:e "\""			-> e
		| "("  sexpression*:e sspace ")"		-> e
		| "'"  sexpression:e				-> (list 'quote e)
		| "`"  sexpression:e				-> (list 'quasiquote e)
		| ",@" sexpression:e				-> (list 'unquote-splicing e)
		| ","  sexpression:e				-> (list 'unquote e)
		| "{"  space grammar:e "}"			-> e
		| ";" (![\n\r] .)*
		;
scomment	= ";" (!eol .)* ;
sspace		= (blank | eol | scomment)* ;
sexpression	= sspace sexpr ;

llist		= lparen expression:e rparen			-> e ;
atom		= lparen expression:e rparen			-> e
		| quotesgl sexpression:e space			-> `(match-object ,e)
		| string:e					-> `(match-string ,e)
		| class:e					-> `(match-class ,e)
		| idpart:p "-" identifier:e			-> `(match-rule-in ,p ,e)
		| identifier:e					-> `(match-rule ,e)
		| lbrace sexpression*:e space rbrace		-> `(match-rule ,@e)
		| dot						-> `(match-any)
		| arrow sexpression:e space			-> `(result-expr ,e)
		| backquote llist:e				-> `(match-list ,e)
		| colon identifier :i				-> `(assign-result ,i)
		;
repetition	= atom :e ( query				-> `(match-zero-one ,e)  :e
			  | star				-> `(match-zero-more ,e) :e
			  | plus				-> `(match-one-more ,e)  :e
			  )?					-> e ;
conversion	= repetition :e ( at				-> `(make-span   ,e) :e
				| dollarhash			-> `(make-number ,e) :e
				| dollardbl			-> `(make-symbol ,e) :e
				| dollar			-> `(make-string ,e) :e
				)*				-> e ;
predicate	= pling     conversion:e			-> `(peek-not ,e)
		| ampersand conversion:e			-> `(peek-for ,e)
		| conversion ;
sequence	= predicate :p	( sequence:e			-> `(match-both ,p ,e) :p
				)?				-> p ;
expression	= sequence :s   ( bar expression:e		-> `(match-first ,s ,e) :s
				)?				-> s ;

definition	= space identifier:id equals expression:e ";"	-> `(,id ,e) ;

start		= definition ;

#----------------------------------------------------------------


gen_cola		= &gen_cola_declarations:a
			   gen_cola_definitions:b		-> `( ,@a ,@b ) ;

gen_cola_declarations	= gen_cola_declaration* ;
gen_cola_declaration	= `( .:id )				-> `(define-selector ,(concat-symbol '$ id)) ;

gen_cola_definitions	= gen_cola_definition* ;
gen_cola_definition	= `( .:id &{findvars ()}:vars value:exp )	-> `(define-method ,(concat-symbol '$ id) <peg> () (let ,vars ,exp)) ;

findvars		= .:vars `( 'assign-result .:name	-> (if (assq name vars) vars (cons (cons name) vars))
				  | 'result-expr		-> vars
				  | . ({findvars vars}:vars)*	-> vars
				  |				-> vars
				  ) ;

value	= 
`( 'match-rule .:name .+:args		-> `(let ()
   	       	      			      ,@(map (lambda (arg) (list 'parser-stream-push 'self.source arg)) args)
					      (or (,(concat-symbol '$ name) self)
					      (let () (set (<parser-stream>-position self.source) pos) ())))
 | 'match-rule .:name			-> `(,(concat-symbol '$ name) self)
 | 'match-rule-in .:type .:name .+:args	-> `(let ((pos (<parser-stream>-position self.source)))
         				      (let ()
  					        ,@(map (lambda (arg) (list 'parser-stream-push 'self.source arg)) args)
  						(or (,(concat-symbol '$ name)
						      (parser ,(concat-symbol '< (concat-symbol type '>)) self.source))
						    (let () (set (<parser-stream>-position self.source) pos) ()))))
 | 'match-rule-in .:type .:name		-> `(,(concat-symbol '$ name)
					      (parser ,(concat-symbol '< (concat-symbol type '>)) self.source))
 | 'match-first value:lhs value:rhs	-> `(or ,lhs ,rhs)
 | 'match-both value:lhs value:rhs	-> `(let ((pos (<parser-stream>-position self.source))) (or (and ,lhs ,rhs) (let () (set (<parser-stream>-position self.source) pos) ())))
 | 'match-zero-one value:exp		-> `(let ((_list_ (group)))
   		   			      (and ,exp (group-append _list_ self.result))
 					      (set self.result (group->list! _list_))
 					      't)
 | 'match-zero-more value:exp		-> `(let ((_list_ (group)))
   		    			      (while ,exp (group-append _list_ self.result))
 					      (set self.result (group->list! _list_))
 					      't)
 | 'match-one-more value:exp		-> `(let ((_list_ (group)))
     		   			      (while ,exp (group-append _list_ self.result))
 					      (and (not (group-empty? _list_))
 					      	   (let ()
 						     (set self.result (group->list! _list_))
 						     't)))
 | 'peek-for value:exp			-> `(let ((pos (<parser-stream>-position self.source))) (and ,exp (set (<parser-stream>-position self.source) pos)))
 | 'peek-not value:exp			-> `(not (let ((pos (<parser-stream>-position self.source))) (and ,exp (set (<parser-stream>-position self.source) pos))))
 | 'match-list value:exp		-> `(and (pair? (parser-stream-peek self.source))
 					      (let ((src self.source))
 					        (set self.source (parser-stream (list-stream (parser-stream-peek src))))
 						(let ((ok ,exp))
 						  (set self.source src)
 						  (and ok (parser-stream-next src)))))
 | 'match-class .:str			-> `(set self.result (parser-stream-match-class self.source ,str))
 | 'match-string .:str			-> `(set self.result (parser-stream-match-string self.source ,str))
 | 'match-object .:obj			-> `(and (= ',obj (parser-stream-peek self.source))
 					         (set self.result (parser-stream-next self.source)))
 | 'match-any				-> '(and (!= *end* (parser-stream-peek self.source)) (let () (set self.result (parser-stream-next self.source)) 't))
 | 'make-span value:exp			-> `(let ((pos (<parser-stream>-position self.source)))
 					      (and ,exp
 					           (let ()
 						     (set self.result (list-from-to pos (<parser-stream>-position self.source)))
 						     't)))
 | 'make-string value:exp		-> `(and ,exp (set self.result (list->string self.result)))
 | 'make-symbol value:exp		-> `(and ,exp (set self.result (string->symbol (list->string self.result))))
 | 'make-number value:exp		-> `(and ,exp (set self.result (string->number (list->string self.result))))
 | 'assign-result .:name		-> `(let () (set ,name self.result) 't)
 | 'result-object .:obj			-> `(let () (set self.result ',obj) 't)
 | 'result-expr .:exp			-> `(let () (set self.result ,exp) 't)
 | 'result-list .*:exps			-> `(let ((_list_ (group))) ,@exps (set self.result (group->list! _list_)) 't)
 | 'result-list-symbol .:sym		-> `(group-append _list_ ',sym)
 | 'result-list-variable .:var		-> `(group-append _list_ ,var)
 | 'result-list-variable-splicing .:var	-> `(group-append-list _list_ ,var)
 | .:op					->  (error "cannot generate value for "op)
 |					->  (error "cannot generate value for nil")
 ) ;
