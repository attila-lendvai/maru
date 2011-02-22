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
symchar		= [!#$%&*+-./<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|~] ;
symbol		= (symchar (symchar | digit)*) @$$ ;
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

definition	= space identifier:id equals expression:e ";"	-> `(rule ,id ,e) ;

start = definition ;

#----------------------------------------------------------------

gen_cola_declaration	= `( 'rule .:id )			-> `(define-selector ,id) ;
gen_cola_declarations	= gen_cola_declaration* ;

gen_cola_definition	= `( 'rule .:id .:exp )			-> `(define-method ,id <peg-parser> () (let () ,exp)) ;
gen_cola_definitions	= gen_cola_definition* ;

gen_cola		= &gen_cola_declarations:a
			   gen_cola_definitions:b		-> `( ,@a ,@b ) ;
