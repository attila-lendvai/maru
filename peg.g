# -*- fundamental -*-

equals    	= "=" space ;
blank		= [\t ] ;
eol		= { "\n" "\r"* } | { "\r" "\n"* } ;
comment		= "#" { !eol . }* ;
space		= { blank | eol | comment }* ;
bar       	= "|"  space ;
pling     	= "!"  space ;
ampersand 	= "&"  space ;
colon     	= ":"  space ;
colondbl     	= "::" space ;
arrow     	= "->" space ;
quotesgl     	= "\'" space ;
dollarhash	= "$#" space ;
dollardbl	= "$$" space ;
dollar		= "$"  space ;
at		= "@"  space ;
query     	= "?"  space ;
plus      	= "+"  space ;
star      	= "*"  space ;
lparen      	= "("  space ;
rparen     	= ")"  space ;
lbrace      	= "{"  space ;
rbrace     	= "}"  space ;
dot       	= "."  space ;
digit		= [0123456789] ;
number		= digit+ $#:n space -> n ;
letter		= [ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz] ;

identifier	= { letter { letter | digit }* } @$$:id space	-> id ;
char		= "\\"	{ "t"	->  9
			| "n"	-> 10
			| "r"	-> 13
			| .
                        }
		| . ;
string		= "\""  {!"\""  char}* $:s "\""  space		-> s ;
class		= "["   {!"]"   char}* $:s "]"   space		-> s ;
symchar		= [!#$%&*+,-/<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|~] ;
symbol		= {symchar {symchar | digit}*} @$$:id space	-> id ;
variable2	= colondbl identifier ;
variable	= colon identifier ;
relement	= symbol:e					-> (result-list-symbol :e)
		| variable2:e					-> (result-list-variable-splicing :e)
		| variable:e					-> (result-list-variable :e)
		| rlist:e					-> (result-list-list :e)
		;
rlist		= lparen relement*:e rparen			-> e ;
llist		= lparen expression:e rparen			-> e ;
atom		= lbrace expression :e rbrace			-> e
		| quotesgl symbol:e				-> (match-object :e)
		| string:e					-> (match-string :e)
		| class:e					-> (match-class :e)
		| identifier:e					-> (match-rule :e)
		| dot						-> (match-any)
		| arrow { identifier:e				-> (result-variable :e)
			| number:e				-> (result-object :e)
			| string:e				-> (result-string :e)
			| rlist:e				-> (result-list ::e)
			}
		| llist:e					-> (match-list :e)
		| colon identifier :i				-> (assign-result :i)
		;
repetition	= atom :e { query				-> (match-zero-one :e)  :e
			  | star				-> (match-zero-more :e) :e
			  | plus				-> (match-one-more :e)  :e
			  }?					-> e ;
conversion	= repetition :e { at				-> (make-span   :e) :e
				| dollarhash			-> (make-number :e) :e
				| dollardbl			-> (make-symbol :e) :e
				| dollar			-> (make-string :e) :e
				}*				-> e ;
predicate	= pling     conversion:e			-> (peek-not :e)
		| ampersand conversion:e			-> (peek-for :e)
		| conversion ;
sequence	= predicate :p	{ sequence:e			-> (match-both :p :e) :p
				}?				-> p ;
expression	= sequence :s   { bar expression:e		-> (match-first :s :e) :s
				}?				-> s ;
definition	= space identifier:id equals expression:e ";"	-> (rule :id :e) ;

start = definition ;

#----------------------------------------------------------------

gen_cola_declaration	= ( 'rule .:id )			-> (define-selector :id) ;
gen_cola_declarations	= gen_cola_declaration* ;

gen_cola_definition	= ( 'rule .:id )			-> (define-method :id <peg-parser>) ;
gen_cola_definitions	= gen_cola_definition* ;

gen_cola		= &gen_cola_declarations:a
			   gen_cola_definitions:b		-> ( ::a ::b ) ;
