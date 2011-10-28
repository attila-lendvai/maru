;;; ./eval repl.l gen-asm-86.k

(println "(load \"asm-common.k\")")

{
  comment       = "//" (!newline .)*
                | "/*" (!"*/" .)* "*/" ;
  blank         = " " | "\t" | "\\"newline ;
  newline       = ("\r""\n"*) | ("\n""\r"*) ;
  _             = blank* ;
  __            = (blank | comment | newline)* ;
  identifier    = ([a-zA-Z_][a-zA-Z_0-9]*)@$$ ;
  name          = identifier:id _ -> id ;
  unumber       = ( "0x"[0-9A-Fa-f]+ @$#16 | [0-9]+ @$#10 ) :s _ -> s ;
  number        = "-" unumber:n -> `(- ,n)
                |     unumber ;
  string        = "\"" (!"\"".)*@$:s "\""_ ( "#"name )* -> s ;
  primary       = number | name | string | "("_ expressions:e ")"_ -> e ;
  arglist       = expression?:e _ (","_ expression)*:f -> `(,@e ,@f) ;
  suffix        = primary:a     ( "("                           _ arglist:b     ")"_            -> (cons a b):a )*              -> a ;
  prefix        = suffix ;
  mulop         = prefix:a      ( ("*"|"/"|"%")@$$:o            _ mulop:b                       -> (list o    a b):a    )*      -> a ;
  addop         = mulop:a       ( ("+"|"-")@$$:o                _ addop:b                       -> (list o    a b):a    )*      -> a ;
  shift         = addop:a       ( ("<<"|">>")@$$:o              _ shift:b                       -> (list o    a b):a    )*      -> a ;
  inequality    = shift:a       ( ("<="|"<"|">="|">")@$$:o      _ inequality:b                  -> (list o    a b):a    )*      -> a ;
  equality      = inequality:a  ( ("=="|"!=")@$$:o              _ equality:b                    -> (list o    a b):a    )*      -> a ;
  bitand        = equality:a    ( "&"!"&"                       _ bitand:b                      -> (list '&   a b):a    )*      -> a ;
  bitxor        = bitand:a      ( "^"                           _ bitxor:b                      -> (list '^   a b):a    )*      -> a ;
  bitor         = bitxor:a      ( "|"!"|"                       _ bitor:b                       -> (list '|   a b):a    )*      -> a ;
  logand        = bitor:a       ( "&&"                          _ logand:b                      -> (list 'and a b):a    )*      -> a ;
  logor         = logand:a      ( "||"                          _ logor:b                       -> (list 'or  a b):a    )*      -> a ;
  ternary       = logor:a       ( "?"                           _ ternary:b     ":"_ ternary:c  -> (list 'if a b c):a   )*      -> a ;
  expression    = ternary:a     ( "="!"="                       _ ternary:b                     -> (list 'set a b):a    )*      -> a ;
  expressions   = expression:a  ( (","_ expression )+:b -> `(let () ,a ,@b):a )? -> a ;
  paramlist     = name?:i (","_ name)*:j -> `(,@i ,@j) ;
  macrodef      = identifier:id "("_ paramlist:p ")"_  expressions:e -> (list 'define-function id p e) ;
  constdef      = identifier:id _ expressions:e -> (list 'define-constant id e) ;
  definition    = __ "#"_ "define"_ ( macrodef | constdef ):d -> (dumpln d) ;
  program       = definition* ;
  program
}

#define _b00            0
#define _b01            1
#define _b10            2
#define _b11            3
        
#define _b000           0
#define _b001           1
#define _b010           2
#define _b011           3
#define _b100           4
#define _b101           5
#define _b110           6
#define _b111           7

/*** REGISTERS ***/     /* [size,,number] */

#define _AL             0x10
#define _CL             0x11
#define _DL             0x12
#define _BL             0x13
#define _AH             0x14
#define _CH             0x15
#define _DH             0x16
#define _BH             0x17

#define _AX             0x20
#define _CX             0x21
#define _DX             0x22
#define _BX             0x23
#define _SP             0x24
#define _BP             0x25
#define _SI             0x26
#define _DI             0x27

#define _EAX            0x40
#define _ECX            0x41
#define _EDX            0x42
#define _EBX            0x43
#define _ESP            0x44
#define _EBP            0x45
#define _ESI            0x46
#define _EDI            0x47

#define _rS(R)          ((R)>>4)
#define _rN(R)          ((R)&0x7)

#define _r0P(R)         ((R)==0)
#define _rLP(R)         (((R)>=_AL)&&((R)<=_BL))
#define _rHP(R)         (((R)>=_AH)&&((R)<=_BH))
#define _r1P(R)         (_rS(R)==1)
#define _r2P(R)         (_rS(R)==2)
#define _r4P(R)         (_rS(R)==4)

#define _rL(R)          (_rLP(R) ? _rN(R) : ASMFAIL( "8-bit L register required"))
#define _rH(R)          (_rHP(R) ? _rN(R) : ASMFAIL( "8-bit H register required"))
#define _r1(R)          (_r1P(R) ? _rN(R) : ASMFAIL( "8-bit register required"))
#define _r2(R)          (_r2P(R) ? _rN(R) : ASMFAIL("16-bit register required"))
#define _r4(R)          (_r4P(R) ? _rN(R) : ASMFAIL("32-bit register required"))

#define _rAL(R)         (((R)==_AL)  ? _rN(R) : ASMFAIL( "AL register required"))
#define _rAX(R)         (((R)==_AX)  ? _rN(R) : ASMFAIL( "AX register required"))
#define _rEAX(R)        (((R)==_EAX) ? _rN(R) : ASMFAIL("EAX register required"))

/*** IMMEDIATES ***/

#define _u1P(I)         (((I) & 0xffffff00) == 0)
#define _u2P(I)         (((I) & 0xffff0000) == 0)

#define _s1(I)          (_s1P(I) ? (I) : ASMFAIL( "8-bit signed immediate required"))
#define _s2(I)          (_s2P(I) ? (I) : ASMFAIL("16-bit signed immediate required"))

#define _u1(I)          (_u1P(I) ? (I) : ASMFAIL( "8-bit unsigned immediate required"))
#define _u2(I)          (_u2P(I) ? (I) : ASMFAIL("16-bit unsigned immediate required"))

#define _d1(I)          (_s1P(I) ? (I) : ASMFAIL( "8-bit displacement out of range"))

/*** ASSEMBLER ***/

#define _M(M)           (((M)>3) ? ASMFAIL("internal error: mod = " #M) : (M))
#define _r(R)           (((R)>7) ? ASMFAIL("internal error: reg = " #R) : (R))
#define _m(M)           (((M)>7) ? ASMFAIL("internal error: r/m = " #M) : (M))
#define _s(S)           (((S)>3) ? ASMFAIL("internal error: memory scale = " #S) : (S))
#define _i(I)           (((I)>7) ? ASMFAIL("internal error: memory index = " #I) : (I))
#define _b(B)           (((B)>7) ? ASMFAIL("internal error: memory base = "  #B) : (B))

#define _Mrm(X,Md,R,M)  _B(X,(_M(Md)<<6)|(_r(R)<<3)|_m(M))
#define _SIB(X,Sc,I, B) _B(X,(_s(Sc)<<6)|(_i(I)<<3)|_b(B))

#define _SCL(S)         ((((S)==1) ? _b00 : \
                         (((S)==2) ? _b01 : \
                         (((S)==4) ? _b10 : \
                         (((S)==8) ? _b11 : ASMFAIL("illegal scale: " #S))))))

/* memory subformats */

#define _r_D(   X,R, D      )           (_Mrm(X,_b00,_rN(R),_b101 )                              ,_L(X,D))
#define _r_0B(  X,R,   B    )           (_Mrm(X,_b00,_rN(R),_r4(B))                                      )
#define _r_0BIS(X,R,   B,I,S)           (_Mrm(X,_b00,_rN(R),_b100 ),_SIB(X,_SCL(S),_r4(I),_r4(B))        )
#define _r_0DIS(X,R, D,  I,S)           (_Mrm(X,_b00,_rN(R),_b100 ),_SIB(X,_SCL(S),_r4(I),    5 ),_L(X,D))
#define _r_1B(  X,R, D,B    )           (_Mrm(X,_b01,_rN(R),_r4(B))                              ,_B(X,D))
#define _r_1BIS(X,R, D,B,I,S)           (_Mrm(X,_b01,_rN(R),_b100 ),_SIB(X,_SCL(S),_r4(I),_r4(B)),_B(X,D))
#define _r_4B(  X,R, D,B    )           (_Mrm(X,_b10,_rN(R),_r4(B))                              ,_L(X,D))
#define _r_4BIS(X,R, D,B,I,S)           (_Mrm(X,_b10,_rN(R),_b100 ),_SIB(X,_SCL(S),_r4(I),_r4(B)),_L(X,D))
 
#define _r_DB(  X,R, D,B    )           ((_s0P(D) ? _r_0B  (X,R,  B    ) : (_s1P(D) ? _r_1B(  X,R,D,B    ) : _r_4B(  X,R,D,B    ))))
#define _r_DBIS(X,R, D,B,I,S)           ((_s0P(D) ? _r_0BIS(X,R,  B,I,S) : (_s1P(D) ? _r_1BIS(X,R,D,B,I,S) : _r_4BIS(X,R,D,B,I,S))))
 
#define _r_X( X,R, D,B,I,S)             (_r0P(I)  ? (_r0P(B)   ? _r_D   (X,R,D            )   : \
                                                    (_ESP==(B) ? _r_DBIS(X,R,D,_ESP,_ESP,1)   : \
                                                                 _r_DB  (X,R,D,   B       ))) : \
                                         ((_r0P(B) ?             _r_0DIS(X,R,D,        I,S)   : \
                                          (((I)!=_ESP)         ? _r_DBIS(X,R,D,   B,   I,S)   : \
                                                                 ASMFAIL("illegal index register: %esp")))))

/* instruction formats */

/*       _format                                                     Opcd         ModR/M dN(rB,rI,Sc)     imm... */
        
#define  _d16(       X                            )  (                _B(X,0x66      )                               )
#define   _O(        X,OP                         )  (                _B(X,(OP)      )                               )
#define   _Or(       X,OP,R                       )  (                _B(X,(OP)|_r(R))                               )
#define  _OO(        X,OP                         )  ( _B(X,(OP)>>8), _B(X,(OP)      )                               )
#define  _OOr(       X,OP,R                       )  ( _B(X,(OP)>>8), _B(X,(OP)|_r(R))                               )
#define   _Os(       X,OP,B                       )  (     _s1P(B) ?  _B(X,(OP)|_b10 ) : _B(X,OP)                    )
#define     _sW(     X,                        W  )  (                                      _s1P(W) ? _B(X,W):_W(X,W))
#define     _sL(     X,                        L  )  (                                      _s1P(L) ? _B(X,L):_L(X,L))
#define   _O_W(      X,OP                     ,W  )  (         _O        (X,OP  )                            ,_W(X,W))
#define   _O_D1(     X,OP                     ,D  )  (         _O        (X,OP  )                           ,_D1(X,D))
#define   _O_D4(     X,OP                     ,D  )  (         _O        (X,OP  )                           ,_D4(X,D))
#define  _OO_D4(     X,OP                     ,D  )  (        _OO        (X,OP  )                           ,_D4(X,D))
#define   _Os_sW(    X,OP                     ,W  )  (         _Os       (X,OP,W)                           ,_sW(X,W))
#define   _Os_sL(    X,OP                     ,L  )  (         _Os       (X,OP,L)                           ,_sL(X,L))
#define   _O_W_B(    X,OP                     ,W,B)  (         _O        (X,OP  )                    ,_W(X,W),_B(X,B))
#define   _Or_B(     X,OP,R                   ,B  )  (         _Or       (X,OP,R)                            ,_B(X,B))
#define   _Or_W(     X,OP,R                   ,W  )  (         _Or       (X,OP,R)                            ,_W(X,W))
#define   _Or_L(     X,OP,R                   ,L  )  (         _Or       (X,OP,R)                            ,_L(X,L))
#define   _O_Mrm(    X,OP  ,MO,R,M                )  (         _O        (X,OP  ),_Mrm(X,MO,R,M            )         )
#define  _OO_Mrm(    X,OP  ,MO,R,M                )  (        _OO        (X,OP  ),_Mrm(X,MO,R,M            )         )
#define   _O_Mrm_B(  X,OP  ,MO,R,M            ,B  )  (         _O        (X,OP  ),_Mrm(X,MO,R,M            ) ,_B(X,B))
#define   _O_Mrm_W(  X,OP  ,MO,R,M            ,W  )  (         _O        (X,OP  ),_Mrm(X,MO,R,M            ) ,_W(X,W))
#define   _O_Mrm_L(  X,OP  ,MO,R,M            ,L  )  (         _O        (X,OP  ),_Mrm(X,MO,R,M            ) ,_L(X,L))
#define  _OO_Mrm_B(  X,OP  ,MO,R,M            ,B  )  (        _OO        (X,OP  ),_Mrm(X,MO,R,M            ) ,_B(X,B))
#define   _Os_Mrm_sW(X,OP  ,MO,R,M            ,W  )  (         _Os       (X,OP,W),_Mrm(X,MO,R,M            ),_sW(X,W))
#define   _Os_Mrm_sL(X,OP  ,MO,R,M            ,L  )  (         _Os       (X,OP,L),_Mrm(X,MO,R,M            ),_sL(X,L))
#define   _O_r_X(    X,OP     ,R  ,MD,MB,MI,MS    )  (         _O        (X,OP  ),_r_X(X,   R  ,MD,MB,MI,MS)         )
#define  _OO_r_X(    X,OP     ,R  ,MD,MB,MI,MS    )  (        _OO        (X,OP  ),_r_X(X,   R  ,MD,MB,MI,MS)         )
#define   _O_r_X_B(  X,OP     ,R  ,MD,MB,MI,MS,B  )  (         _O        (X,OP  ),_r_X(X,   R  ,MD,MB,MI,MS) ,_B(X,B))
#define   _O_r_X_W(  X,OP     ,R  ,MD,MB,MI,MS,W  )  (         _O        (X,OP  ),_r_X(X,   R  ,MD,MB,MI,MS) ,_W(X,W))
#define   _O_r_X_L(  X,OP     ,R  ,MD,MB,MI,MS,L  )  (         _O        (X,OP  ),_r_X(X,   R  ,MD,MB,MI,MS) ,_L(X,L))
#define  _OO_r_X_B(  X,OP     ,R  ,MD,MB,MI,MS,B  )  (        _OO        (X,OP  ),_r_X(X,   R  ,MD,MB,MI,MS) ,_B(X,B))
#define   _Os_r_X_sW(X,OP     ,R  ,MD,MB,MI,MS,W  )  (         _Os       (X,OP,W),_r_X(X,   R  ,MD,MB,MI,MS),_sW(X,W))
#define   _Os_r_X_sL(X,OP     ,R  ,MD,MB,MI,MS,L  )  (         _Os       (X,OP,L),_r_X(X,   R  ,MD,MB,MI,MS),_sL(X,L))
#define   _O_X_B(    X,OP         ,MD,MB,MI,MS,B  )  (         _O_r_X_B  (X,OP           ,0    ,MD,MB,MI,MS       ,B))
#define   _O_X_W(    X,OP         ,MD,MB,MI,MS,W  )  (         _O_r_X_W  (X,OP           ,0    ,MD,MB,MI,MS       ,W))
#define   _O_X_L(    X,OP         ,MD,MB,MI,MS,L  )  (         _O_r_X_L  (X,OP           ,0    ,MD,MB,MI,MS       ,L))
#define  _wO(        X,OP                         )  (_d16(X), _O        (X,OP                                      ))
#define  _wOr(       X,OP,R                       )  (_d16(X), _Or       (X,OP,R                                    ))
#define  _wOr_W(     X,OP,R                   ,W  )  (_d16(X), _Or_W     (X,OP,R                                  ,W))
#define  _wOs_sW(    X,OP                     ,W  )  (_d16(X), _Os_sW    (X,OP                                    ,W))
#define  _wO_Mrm(    X,OP  ,MO,R,M                )  (_d16(X), _O_Mrm    (X,OP          ,MO,R,M                     ))
#define _wOO_Mrm(    X,OP  ,MO,R,M                )  (_d16(X),_OO_Mrm    (X,OP          ,MO,R,M                     ))
#define  _wO_Mrm_B(  X,OP  ,MO,R,M            ,B  )  (_d16(X), _O_Mrm_B  (X,OP          ,MO,R,M                   ,B))
#define _wOO_Mrm_B(  X,OP  ,MO,R,M            ,B  )  (_d16(X),_OO_Mrm_B  (X,OP          ,MO,R,M                   ,B))
#define  _wO_Mrm_W(  X,OP  ,MO,R,M            ,W  )  (_d16(X), _O_Mrm_W  (X,OP          ,MO,R,M                   ,W))
#define  _wOs_Mrm_sW(X,OP  ,MO,R,M            ,W  )  (_d16(X), _Os_Mrm_sW(X,OP          ,MO,R,M                   ,W))
#define  _wO_X_W(    X,OP         ,MD,MB,MI,MS,W  )  (_d16(X), _O_X_W    (X,OP                 ,MD,MB,MI,MS       ,W))
#define  _wO_r_X(    X,OP     ,R  ,MD,MB,MI,MS    )  (_d16(X), _O_r_X    (X,OP             ,R  ,MD,MB,MI,MS         ))
#define _wOO_r_X(    X,OP     ,R  ,MD,MB,MI,MS    )  (_d16(X),_OO_r_X    (X,OP             ,R  ,MD,MB,MI,MS         ))
#define  _wO_r_X_B(  X,OP     ,R  ,MD,MB,MI,MS,B  )  (_d16(X), _O_r_X_B  (X,OP             ,R  ,MD,MB,MI,MS       ,B))
#define _wOO_r_X_B(  X,OP     ,R  ,MD,MB,MI,MS,B  )  (_d16(X),_OO_r_X_B  (X,OP             ,R  ,MD,MB,MI,MS       ,B))
#define  _wO_r_X_W(  X,OP     ,R  ,MD,MB,MI,MS,W  )  (_d16(X), _O_r_X_W  (X,OP             ,R  ,MD,MB,MI,MS       ,W))
#define  _wOs_r_X_sW(X,OP     ,R  ,MD,MB,MI,MS,W  )  (_d16(X), _Os_r_X_sW(X,OP             ,R  ,MD,MB,MI,MS       ,W))

/* +++ fully-qualified intrinsic instructions */

/*                                      _format          Opcd           ,Mod ,r     ,m          ,mem=dsp+sib    ,imm... */
        
#define ADCBrr(X,RS, RD)                  _O_Mrm          (X,0x10           ,_b11,_r1(RS),_r1(RD)                           )
#define ADCBmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x12                ,_r1(RD)           ,MD,MB,MI,MS            )
#define ADCBrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x10                ,_r1(RS)           ,MD,MB,MI,MS            )
#define ADCBir(X,IM, RD)                  _O_Mrm_B        (X,0x80           ,_b11,_b010  ,_r1(RD)                   ,_s1(IM))
#define ADCBim(X,IM, MD, MB, MI, MS)      _O_r_X_B        (X,0x80                ,_b010             ,MD,MB,MI,MS    ,_s1(IM))
        
#define ADCWrr(X,RS, RD)                  _wO_Mrm         (X,0x11           ,_b11,_r2(RS),_r2(RD)                           )
#define ADCWmr(X,MD, MB, MI, MS, RD)      _wO_r_X         (X,0x13                ,_r2(RD)           ,MD,MB,MI,MS            )
#define ADCWrm(X,RS, MD, MB, MI, MS)      _wO_r_X         (X,0x11                ,_r2(RS)           ,MD,MB,MI,MS            )
#define ADCWir(X,IM, RD)                  _wOs_Mrm_sW     (X,0x81           ,_b11,_b010  ,_r2(RD)                   ,_s2(IM))
#define ADCWim(X,IM, MD, MB, MI, MS)      _wOs_r_X_sW     (X,0x81                ,_b010             ,MD,MB,MI,MS    ,_s2(IM))
        
#define ADCLrr(X,RS, RD)                  _O_Mrm          (X,0x11           ,_b11,_r4(RS),_r4(RD)                           )
#define ADCLmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x13                ,_r4(RD)           ,MD,MB,MI,MS            )
#define ADCLrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x11                ,_r4(RS)           ,MD,MB,MI,MS            )
#define ADCLir(X,IM, RD)                  _Os_Mrm_sL      (X,0x81           ,_b11,_b010  ,_r4(RD)                   ,IM     )
#define ADCLim(X,IM, MD, MB, MI, MS)      _Os_r_X_sL      (X,0x81                ,_b010             ,MD,MB,MI,MS    ,IM     )
        
        
#define ADDBrr(X,RS, RD)                  _O_Mrm          (X,0x00           ,_b11,_r1(RS),_r1(RD)                           )
#define ADDBmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x02                ,_r1(RD)           ,MD,MB,MI,MS            )
#define ADDBrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x00                ,_r1(RS)           ,MD,MB,MI,MS            )
#define ADDBir(X,IM, RD)                  _O_Mrm_B        (X,0x80           ,_b11,_b000  ,_r1(RD)                   ,_s1(IM))
#define ADDBim(X,IM, MD, MB, MI, MS)      _O_r_X_B        (X,0x80                ,_b000             ,MD,MB,MI,MS    ,_s1(IM))
        
#define ADDWrr(X,RS, RD)                  _wO_Mrm         (X,0x01           ,_b11,_r2(RS),_r2(RD)                           )
#define ADDWmr(X,MD, MB, MI, MS, RD)      _wO_r_X         (X,0x03                ,_r2(RD)           ,MD,MB,MI,MS            )
#define ADDWrm(X,RS, MD, MB, MI, MS)      _wO_r_X         (X,0x01                ,_r2(RS)           ,MD,MB,MI,MS            )
#define ADDWir(X,IM, RD)                  _wOs_Mrm_sW     (X,0x81           ,_b11,_b000  ,_r2(RD)                   ,_s2(IM))
#define ADDWim(X,IM, MD, MB, MI, MS)      _wOs_r_X_sW     (X,0x81                ,_b000             ,MD,MB,MI,MS    ,_s2(IM))
        
#define ADDLrr(X,RS, RD)                  _O_Mrm          (X,0x01           ,_b11,_r4(RS),_r4(RD)                           )
#define ADDLmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x03                ,_r4(RD)           ,MD,MB,MI,MS            )
#define ADDLrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x01                ,_r4(RS)           ,MD,MB,MI,MS            )
#define ADDLir(X,IM, RD)                  _Os_Mrm_sL      (X,0x81           ,_b11,_b000  ,_r4(RD)                   ,IM     )
#define ADDLim(X,IM, MD, MB, MI, MS)      _Os_r_X_sL      (X,0x81                ,_b000             ,MD,MB,MI,MS    ,IM     )
        
        
#define ANDBrr(X,RS, RD)                  _O_Mrm          (X,0x20           ,_b11,_r1(RS),_r1(RD)                           )
#define ANDBmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x22                ,_r1(RD)           ,MD,MB,MI,MS            )
#define ANDBrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x20                ,_r1(RS)           ,MD,MB,MI,MS            )
#define ANDBir(X,IM, RD)                  _O_Mrm_B        (X,0x80           ,_b11,_b100  ,_r1(RD)                   ,_s1(IM))
#define ANDBim(X,IM, MD, MB, MI, MS)      _O_r_X_B        (X,0x80                ,_b100             ,MD,MB,MI,MS    ,_s1(IM))
        
#define ANDWrr(X,RS, RD)                  _wO_Mrm         (X,0x21           ,_b11,_r2(RS),_r2(RD)                           )
#define ANDWmr(X,MD, MB, MI, MS, RD)      _wO_r_X         (X,0x23                ,_r2(RD)           ,MD,MB,MI,MS            )
#define ANDWrm(X,RS, MD, MB, MI, MS)      _wO_r_X         (X,0x21                ,_r2(RS)           ,MD,MB,MI,MS            )
#define ANDWir(X,IM, RD)                  _wOs_Mrm_sW     (X,0x81           ,_b11,_b100  ,_r2(RD)                   ,_s2(IM))
#define ANDWim(X,IM, MD, MB, MI, MS)      _wOs_r_X_sW     (X,0x81                ,_b100             ,MD,MB,MI,MS    ,_s2(IM))
        
#define ANDLrr(X,RS, RD)                  _O_Mrm          (X,0x21           ,_b11,_r4(RS),_r4(RD)                           )
#define ANDLmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x23                ,_r4(RD)           ,MD,MB,MI,MS            )
#define ANDLrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x21                ,_r4(RS)           ,MD,MB,MI,MS            )
#define ANDLir(X,IM, RD)                  _Os_Mrm_sL      (X,0x81           ,_b11,_b100  ,_r4(RD)                   ,IM     )
#define ANDLim(X,IM, MD, MB, MI, MS)      _Os_r_X_sL      (X,0x81                ,_b100             ,MD,MB,MI,MS    ,IM     )


#define BSWAPLr(X,R)                      _OOr            (X,0x0fc8,_r4(R)                                                  )


#define BTWir(X,IM,RD)                    _wOO_Mrm_B      (X,0x0fba         ,_b11,_b100  ,_r2(RD)                   ,_u1(IM))
#define BTWim(X,IM,MD,MB,MI,MS)           _wOO_r_X_B      (X,0x0fba              ,_b100             ,MD,MB,MI,MS    ,_u1(IM))
#define BTWrr(X,RS,RD)                    _wOO_Mrm        (X,0x0fa3         ,_b11,_r2(RS),_r2(RD)                           )
#define BTWrm(X,RS,MD,MB,MI,MS)           _wOO_r_X        (X,0x0fa3              ,_r2(RS)           ,MD,MB,MI,MS            )

#define BTLir(X,IM,RD)                    _OO_Mrm_B       (X,0x0fba         ,_b11,_b100  ,_r4(RD)                   ,_u1(IM))
#define BTLim(X,IM,MD,MB,MI,MS)           _OO_r_X_B       (X,0x0fba              ,_b100             ,MD,MB,MI,MS    ,_u1(IM))
#define BTLrr(X,RS,RD)                    _OO_Mrm         (X,0x0fa3         ,_b11,_r4(RS),_r4(RD)                           )
#define BTLrm(X,RS,MD,MB,MI,MS)           _OO_r_X         (X,0x0fa3              ,_r4(RS)           ,MD,MB,MI,MS            )


#define BTCWir(X,IM,RD)                   _wOO_Mrm_B      (X,0x0fba         ,_b11,_b111  ,_r2(RD)                   ,_u1(IM))
#define BTCWim(X,IM,MD,MB,MI,MS)          _wOO_r_X_B      (X,0x0fba              ,_b111             ,MD,MB,MI,MS    ,_u1(IM))
#define BTCWrr(X,RS,RD)                   _wOO_Mrm        (X,0x0fbb         ,_b11,_r2(RS),_r2(RD)                           )
#define BTCWrm(X,RS,MD,MB,MI,MS)          _wOO_r_X        (X,0x0fbb              ,_r2(RS)           ,MD,MB,MI,MS            )

#define BTCLir(X,IM,RD)                   _OO_Mrm_B       (X,0x0fba         ,_b11,_b111  ,_r4(RD)                   ,_u1(IM))
#define BTCLim(X,IM,MD,MB,MI,MS)          _OO_r_X_B       (X,0x0fba              ,_b111             ,MD,MB,MI,MS    ,_u1(IM))
#define BTCLrr(X,RS,RD)                   _OO_Mrm         (X,0x0fbb         ,_b11,_r4(RS),_r4(RD)                           )
#define BTCLrm(X,RS,MD,MB,MI,MS)          _OO_r_X         (X,0x0fbb              ,_r4(RS)           ,MD,MB,MI,MS            )


#define BTRWir(X,IM,RD)                   _wOO_Mrm_B      (X,0x0fba         ,_b11,_b110  ,_r2(RD)                   ,_u1(IM))
#define BTRWim(X,IM,MD,MB,MI,MS)          _wOO_r_X_B      (X,0x0fba              ,_b110             ,MD,MB,MI,MS    ,_u1(IM))
#define BTRWrr(X,RS,RD)                   _wOO_Mrm        (X,0x0fb3         ,_b11,_r2(RS),_r2(RD)                           )
#define BTRWrm(X,RS,MD,MB,MI,MS)          _wOO_r_X        (X,0x0fb3              ,_r2(RS)           ,MD,MB,MI,MS            )

#define BTRLir(X,IM,RD)                   _OO_Mrm_B       (X,0x0fba         ,_b11,_b110  ,_r4(RD)                   ,_u1(IM))
#define BTRLim(X,IM,MD,MB,MI,MS)          _OO_r_X_B       (X,0x0fba              ,_b110             ,MD,MB,MI,MS    ,_u1(IM))
#define BTRLrr(X,RS,RD)                   _OO_Mrm         (X,0x0fb3         ,_b11,_r4(RS),_r4(RD)                           )
#define BTRLrm(X,RS,MD,MB,MI,MS)          _OO_r_X         (X,0x0fb3              ,_r4(RS)           ,MD,MB,MI,MS            )


#define BTSWir(X,IM,RD)                   _wOO_Mrm_B      (X,0x0fba         ,_b11,_b101  ,_r2(RD)                   ,_u1(IM))
#define BTSWim(X,IM,MD,MB,MI,MS)          _wOO_r_X_B      (X,0x0fba              ,_b101             ,MD,MB,MI,MS    ,_u1(IM))
#define BTSWrr(X,RS,RD)                   _wOO_Mrm        (X,0x0fab         ,_b11,_r2(RS),_r2(RD)                           )
#define BTSWrm(X,RS,MD,MB,MI,MS)          _wOO_r_X        (X,0x0fab              ,_r2(RS)           ,MD,MB,MI,MS            )

#define BTSLir(X,IM,RD)                   _OO_Mrm_B       (X,0x0fba         ,_b11,_b101  ,_r4(RD)                   ,_u1(IM))
#define BTSLim(X,IM,MD,MB,MI,MS)          _OO_r_X_B       (X,0x0fba              ,_b101             ,MD,MB,MI,MS    ,_u1(IM))
#define BTSLrr(X,RS,RD)                   _OO_Mrm         (X,0x0fab         ,_b11,_r4(RS),_r4(RD)                           )
#define BTSLrm(X,RS,MD,MB,MI,MS)          _OO_r_X         (X,0x0fab              ,_r4(RS)           ,MD,MB,MI,MS            )


#define CALLm(X,MD,MB,MI,MS)              (X,(_r0P(MB) && _r0P(MI)) ? _O_D4 (X,0xe8              ,(MD)                   ) : \
                                          ((            _r0P(MI)) ? _O_Mrm(X,0xff,_b11,_b010,_r4    (MB)               ) : \
                                                                    _O_r_X(X,0xff,     _b010   ,(MD),MB,MI,MS)         ))

#define CBW(X)                           _O              (X,0x98                                                           )
#define CLC(X)                           _O              (X,0xf8                                                           )
#define CLTD(X)                          _O              (X,0x99                                                           )
#define CMC(X)                           _O              (X,0xf5                                                           )


#define CMPBrr(X,RS, RD)                  _O_Mrm          (X,0x38           ,_b11,_r1(RS),_r1(RD)                           )
#define CMPBmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x3a                ,_r1(RD)           ,MD,MB,MI,MS            )
#define CMPBrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x38                ,_r1(RS)           ,MD,MB,MI,MS            )
#define CMPBir(X,IM, RD)                  _O_Mrm_B        (X,0x80           ,_b11,_b111  ,_r1(RD)                   ,_s1(IM))
#define CMPBim(X,IM, MD, MB, MI, MS)      _O_r_X_B        (X,0x80                ,_b111             ,MD,MB,MI,MS    ,_s1(IM))
        
#define CMPWrr(X,RS, RD)                  _wO_Mrm         (X,0x39           ,_b11,_r2(RS),_r2(RD)                           )
#define CMPWmr(X,MD, MB, MI, MS, RD)      _wO_r_X         (X,0x3b                ,_r2(RD)           ,MD,MB,MI,MS            )
#define CMPWrm(X,RS, MD, MB, MI, MS)      _wO_r_X         (X,0x39                ,_r2(RS)           ,MD,MB,MI,MS            )
#define CMPWir(X,IM, RD)                  _wOs_Mrm_sW     (X,0x81           ,_b11,_b111  ,_r2(RD)                   ,_s2(IM))
#define CMPWim(X,IM, MD, MB, MI, MS)      _wOs_r_X_sW     (X,0x81                ,_b111             ,MD,MB,MI,MS    ,_s2(IM))
        
#define CMPLrr(X,RS, RD)                  _O_Mrm          (X,0x39           ,_b11,_r4(RS),_r4(RD)                           )
#define CMPLmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x3b                ,_r4(RD)           ,MD,MB,MI,MS            )
#define CMPLrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x39                ,_r4(RS)           ,MD,MB,MI,MS            )
#define CMPLir(X,IM, RD)                  _O_Mrm_L        (X,0x81           ,_b11,_b111  ,_r4(RD)                   ,IM     )
#define CMPLim(X,IM, MD, MB, MI, MS)      _O_r_X_L        (X,0x81                ,_b111             ,MD,MB,MI,MS    ,IM     )
        

#define CWD(X)                           _O              (X,0x99                                                           )


#define CMPXCHGBrr(X,RS,RD)               _OO_Mrm         (X,0x0fb0         ,_b11,_r1(RS),_r1(RD)                           )
#define CMPXCHGBrm(X,RS,MD,MB,MI,MS)      _OO_r_X         (X,0x0fb0              ,_r1(RS)           ,MD,MB,MI,MS            )

#define CMPXCHGWrr(X,RS,RD)               _wOO_Mrm        (X,0x0fb1         ,_b11,_r2(RS),_r2(RD)                           )
#define CMPXCHGWrm(X,RS,MD,MB,MI,MS)      _wOO_r_X        (X,0x0fb1              ,_r2(RS)           ,MD,MB,MI,MS            )

#define CMPXCHGLrr(X,RS,RD)               _OO_Mrm         (X,0x0fb1         ,_b11,_r4(RS),_r4(RD)                           )
#define CMPXCHGLrm(X,RS,MD,MB,MI,MS)      _OO_r_X         (X,0x0fb1              ,_r4(RS)           ,MD,MB,MI,MS            )


#define DECBr(X,RD)                       _O_Mrm          (X,0xfe           ,_b11,_b001  ,_r1(RD)                           )
#define DECBm(X,MD,MB,MI,MS)              _O_r_X          (X,0xfe                ,_b001             ,MD,MB,MI,MS            )

#define DECWr(X,RD)                       _wOr            (X,0x48,_r2(RD)                                                   )
#define DECWm(X,MD,MB,MI,MS)              _wO_r_X         (X,0xff                ,_b001             ,MD,MB,MI,MS            )

#define DECLr(X,RD)                       _Or             (X,0x48,_r4(RD)                                                   )
#define DECLm(X,MD,MB,MI,MS)              _O_r_X          (X,0xff                ,_b001             ,MD,MB,MI,MS            )


#define DIVBrr(X,RS,RD)           ( _rAL (RD) +   _O_Mrm  (X,0xf6           ,_b11,_b110  ,_r1(RS)                           ) )
#define DIVBmr(X,MD,MB,MI,MS,RD)  ( _rAL (RD) +   _O_r_X  (X,0xf6                ,_b110             ,MD,MB,MI,MS            ) )

#define DIVWrr(X,RS,RD)           ( _rAX (RD) +   _wO_Mrm (X,0xf7          ,_b11,_b110  ,_r2(RS)                           ) )
#define DIVWmr(X,MD,MB,MI,MS,RD)  ( _rAX (RD) +   _wO_r_X (X,0xf7                 ,_b110             ,MD,MB,MI,MS            ) )

#define DIVLrr(X,RS,RD)           ( _rEAX(RD) +   _O_Mrm  (X,0xf7           ,_b11,_b110  ,_r4(RS)                           ) )
#define DIVLmr(X,MD,MB,MI,MS,RD)  ( _rEAX(RD) +   _O_r_X  (X,0xf7                ,_b110             ,MD,MB,MI,MS            ) )


#define ENTERii(X,W, B)                   _O_W_B          (X,0xc8                                             ,_s2(W),_s1(B))
#define HLT(X)                           _O              (X,0xf4                                                           )


#define IDIVBrr(X,RS,RD)          ( _rAL (RD) +   _O_Mrm  (X,0xf6           ,_b11,_b111  ,_r1(RS)                           ) )
#define IDIVBmr(X,MD,MB,MI,MS,RD) ( _rAL (RD) +   _O_r_X  (X,0xf6                ,_b111             ,MD,MB,MI,MS            ) )

#define IDIVWrr(X,RS,RD)          ( _rAX (RD) +   _wO_Mrm (X,0xf7           ,_b11,_b111  ,_r2(RS)                           ) )
#define IDIVWmr(X,MD,MB,MI,MS,RD) ( _rAX (RD) +   _wO_r_X (X,0xf7                ,_b111             ,MD,MB,MI,MS            ) )

#define IDIVLrr(X,RS,RD)          ( _rEAX(RD) +   _O_Mrm  (X,0xf7           ,_b11,_b111  ,_r4(RS)                           ) )
#define IDIVLmr(X,MD,MB,MI,MS,RD) ( _rEAX(RD) +   _O_r_X  (X,0xf7                ,_b111             ,MD,MB,MI,MS            ) )


#define IMULWrr(X,RS,RD)                  _wOO_Mrm        (X,0x0faf         ,_b11,_r2(RS),_r2(RD)                           )
#define IMULWmr(X,MD,MB,MI,MS,RD)         _wOO_r_X        (X,0x0faf              ,_r2(RD)           ,MD,MB,MI,MS            )
#define IMULWirr(X,IM,RS,RD)              _wOs_Mrm_sW     (X,0x69           ,_b11,_r2(RS),_r2(RD)                   ,IM     )
#define IMULWimr(X,IM,MD,MB,MI,MS,RD)     _wOs_r_X_sW     (X,0x69                ,_r2(RD)           ,MD,MB,MI,MS    ,IM     )

#define IMULLrr(X,RS,RD)                  _OO_Mrm         (X,0x0faf         ,_b11,_r4(RD),_r4(RS)                           )
#define IMULLmr(X,MD,MB,MI,MS,RD)         _OO_r_X         (X,0x0faf              ,_r4(RD)           ,MD,MB,MI,MS            )
#define IMULLirr(X,IM,RS,RD)              _Os_Mrm_sL      (X,0x69           ,_b11,_r4(RS),_r4(RD)                   ,IM     )
#define IMULLimr(X,IM,MD,MB,MI,MS,RD)     _Os_r_X_sL      (X,0x69                ,_r4(RD)           ,MD,MB,MI,MS    ,IM     )


#define INCBr(X,RD)                       _O_Mrm          (X,0xfe           ,_b11,_b000  ,_r1(RD)                           )
#define INCBm(X,MD,MB,MI,MS)              _O_r_X          (X,0xfe                ,_b000             ,MD,MB,MI,MS            )

#define INCWr(X,RD)                       _wOr            (X,0x40,_r2(RD)                                                   )
#define INCWm(X,MD,MB,MI,MS)              _wO_r_X         (X,0xff                ,_b000             ,MD,MB,MI,MS            )

#define INCLr(X,RD)                       _Or             (X,0x40,_r4(RD)                                                   )
#define INCLm(X,MD,MB,MI,MS)              _O_r_X          (X,0xff                ,_b000             ,MD,MB,MI,MS            )


#define INVD(X)                          _OO             (X,0x0f08                                                         )
#define INVLPGm(X,MD, MB, MI, MS)         _OO_r_X         (X,0x0f01              ,_b111             ,MD,MB,MI,MS            )


#define JCCSim(X,CC,D,B,I,S)              ((_r0P(B) && _r0P(I)) ? _O_D1   (X,0x70|(CC)              ,(D)                    ) : \
                                                                ASMFAIL("illegal mode in conditional jump"))

#define JOSm(X,D,B,I,S)                   JCCSim(X,0x0,D,B,I,S)
#define JNOSm(X,D,B,I,S)                  JCCSim(X,0x1,D,B,I,S)
#define JBSm(X,D,B,I,S)                   JCCSim(X,0x2,D,B,I,S)
#define JNAESm(X,D,B,I,S)                 JCCSim(X,0x2,D,B,I,S)
#define JNBSm(X,D,B,I,S)                  JCCSim(X,0x3,D,B,I,S)
#define JAESm(X,D,B,I,S)                  JCCSim(X,0x3,D,B,I,S)
#define JESm(X,D,B,I,S)                   JCCSim(X,0x4,D,B,I,S)
#define JZSm(X,D,B,I,S)                   JCCSim(X,0x4,D,B,I,S)
#define JNESm(X,D,B,I,S)                  JCCSim(X,0x5,D,B,I,S)
#define JNZSm(X,D,B,I,S)                  JCCSim(X,0x5,D,B,I,S)
#define JBESm(X,D,B,I,S)                  JCCSim(X,0x6,D,B,I,S)
#define JNASm(X,D,B,I,S)                  JCCSim(X,0x6,D,B,I,S)
#define JNBESm(X,D,B,I,S)                 JCCSim(X,0x7,D,B,I,S)
#define JASm(X,D,B,I,S)                   JCCSim(X,0x7,D,B,I,S)
#define JSSm(X,D,B,I,S)                   JCCSim(X,0x8,D,B,I,S)
#define JNSSm(X,D,B,I,S)                  JCCSim(X,0x9,D,B,I,S)
#define JPSm(X,D,B,I,S)                   JCCSim(X,0xa,D,B,I,S)
#define JPESm(X,D,B,I,S)                  JCCSim(X,0xa,D,B,I,S)
#define JNPSm(X,D,B,I,S)                  JCCSim(X,0xb,D,B,I,S)
#define JPOSm(X,D,B,I,S)                  JCCSim(X,0xb,D,B,I,S)
#define JLSm(X,D,B,I,S)                   JCCSim(X,0xc,D,B,I,S)
#define JNGESm(X,D,B,I,S)                 JCCSim(X,0xc,D,B,I,S)
#define JNLSm(X,D,B,I,S)                  JCCSim(X,0xd,D,B,I,S)
#define JGESm(X,D,B,I,S)                  JCCSim(X,0xd,D,B,I,S)
#define JLESm(X,D,B,I,S)                  JCCSim(X,0xe,D,B,I,S)
#define JNGSm(X,D,B,I,S)                  JCCSim(X,0xe,D,B,I,S)
#define JNLESm(X,D,B,I,S)                 JCCSim(X,0xf,D,B,I,S)
#define JGSm(X,D,B,I,S)                   JCCSim(X,0xf,D,B,I,S)

#define JCCim(X,CC,D,B,I,S)               ((_r0P(B) && _r0P(I)) ? _OO_D4  (X,0x0f80|(CC)            ,(D)                    ) : \
                                                                ASMFAIL("illegal mode in conditional jump"))

#define JOm(X,D,B,I,S)                    JCCim(X,0x0,D,B,I,S)
#define JNOm(X,D,B,I,S)                   JCCim(X,0x1,D,B,I,S)
#define JBm(X,D,B,I,S)                    JCCim(X,0x2,D,B,I,S)
#define JNAEm(X,D,B,I,S)                  JCCim(X,0x2,D,B,I,S)
#define JNBm(X,D,B,I,S)                   JCCim(X,0x3,D,B,I,S)
#define JAEm(X,D,B,I,S)                   JCCim(X,0x3,D,B,I,S)
#define JEm(X,D,B,I,S)                    JCCim(X,0x4,D,B,I,S)
#define JZm(X,D,B,I,S)                    JCCim(X,0x4,D,B,I,S)
#define JNEm(X,D,B,I,S)                   JCCim(X,0x5,D,B,I,S)
#define JNZm(X,D,B,I,S)                   JCCim(X,0x5,D,B,I,S)
#define JBEm(X,D,B,I,S)                   JCCim(X,0x6,D,B,I,S)
#define JNAm(X,D,B,I,S)                   JCCim(X,0x6,D,B,I,S)
#define JNBEm(X,D,B,I,S)                  JCCim(X,0x7,D,B,I,S)
#define JAm(X,D,B,I,S)                    JCCim(X,0x7,D,B,I,S)
#define JSm(X,D,B,I,S)                    JCCim(X,0x8,D,B,I,S)
#define JNSm(X,D,B,I,S)                   JCCim(X,0x9,D,B,I,S)
#define JPm(X,D,B,I,S)                    JCCim(X,0xa,D,B,I,S)
#define JPEm(X,D,B,I,S)                   JCCim(X,0xa,D,B,I,S)
#define JNPm(X,D,B,I,S)                   JCCim(X,0xb,D,B,I,S)
#define JPOm(X,D,B,I,S)                   JCCim(X,0xb,D,B,I,S)
#define JLm(X,D,B,I,S)                    JCCim(X,0xc,D,B,I,S)
#define JNGEm(X,D,B,I,S)                  JCCim(X,0xc,D,B,I,S)
#define JNLm(X,D,B,I,S)                   JCCim(X,0xd,D,B,I,S)
#define JGEm(X,D,B,I,S)                   JCCim(X,0xd,D,B,I,S)
#define JLEm(X,D,B,I,S)                   JCCim(X,0xe,D,B,I,S)
#define JNGm(X,D,B,I,S)                   JCCim(X,0xe,D,B,I,S)
#define JNLEm(X,D,B,I,S)                  JCCim(X,0xf,D,B,I,S)
#define JGm(X,D,B,I,S)                    JCCim(X,0xf,D,B,I,S)


#define JMPSm(X,D,B,I,S)                  ((_r0P(B) && _r0P(I)) ? _O_D1   (X,0xeb                   ,(D)                    ) : \
                                                                ASMFAIL("illegal mode in short jump"))

#define JMPm(X,D,B,I,S)                   ((_r0P(B) && _r0P(I)) ? _O_D4   (X,0xe9                   ,(D)                    ) : \
                                                   ((_r0P(I)) ? _O_Mrm  (X,0xff   ,_b11,_b100,_r4(B)                      ) : \
                                                                _O_r_X  (X,0xff        ,_b100     ,(D),B,I,S              ) ))


#define LAHF(X)                          _O              (X,0x9f                                                           )
#define LEALmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x8d                ,_r4(RD)           ,MD,MB,MI,MS            )
#define LEAVE(X)                         _O              (X,0xc9                                                           )

        
#define LMSWr(X,RS)                       _OO_Mrm         (X,0x0f01         ,_b11,_b110,_r4(RS)                             )
#define LMSWm(X,MD,MB,MI,MS)              _OO_r_X         (X,0x0f01              ,_b110             ,MD,MB,MI,MS            )

#define LOOPm(X,MD,MB,MI,MS)              ((_r0P(MB) && _r0P(MI)) ? _O_D1 (X,0xe2                   ,MD                     ) : \
                                                                  ASMFAIL("illegal mode in loop"))

#define LOOPEm(X,MD,MB,MI,MS)             ((_r0P(MB) && _r0P(MI)) ? _O_D1 (X,0xe1                   ,MD                     ) : \
                                                                  ASMFAIL("illegal mode in loope"))

#define LOOPZm(X,MD,MB,MI,MS)             ((_r0P(MB) && _r0P(MI)) ? _O_D1 (X,0xe1                   ,MD                     ) : \
                                                                  ASMFAIL("illegal mode in loopz"))

#define LOOPNEm(X,MD,MB,MI,MS)            ((_r0P(MB) && _r0P(MI)) ? _O_D1 (X,0xe0                   ,MD                     ) : \
                                                                  ASMFAIL("illegal mode in loopne"))

#define LOOPNZm(X,MD,MB,MI,MS)            ((_r0P(MB) && _r0P(MI)) ? _O_D1 (X,0xe0                   ,MD                     ) : \
                                                                  ASMFAIL("illegal mode in loopnz"))


#define MOVBrr(X,RS, RD)                  _O_Mrm          (X,0x80           ,_b11,_r1(RS),_r1(RD)                           )
#define MOVBmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x8a                ,_r1(RD)           ,MD,MB,MI,MS            )
#define MOVBrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x88                ,_r1(RS)           ,MD,MB,MI,MS            )
#define MOVBir(X,IM,  R)                  _Or_B           (X,0xb0,_r1(R)                                            ,_s1(IM))
#define MOVBim(X,IM, MD, MB, MI, MS)      _O_X_B          (X,0xc6                                   ,MD,MB,MI,MS    ,_s1(IM))

#define MOVWrr(X,RS, RD)                  _wO_Mrm         (X,0x89           ,_b11,_r2(RS),_r2(RD)                           )
#define MOVWmr(X,MD, MB, MI, MS, RD)      _wO_r_X         (X,0x8b                ,_r2(RD)           ,MD,MB,MI,MS            )
#define MOVWrm(X,RS, MD, MB, MI, MS)      _wO_r_X         (X,0x89                ,_r2(RS)           ,MD,MB,MI,MS            )
#define MOVWir(X,IM,  R)                  _wOr_W          (X,0xb8,_r2(R)                                            ,_s2(IM))
#define MOVWim(X,IM, MD, MB, MI, MS)      _wO_X_W         (X,0xc7                                   ,MD,MB,MI,MS    ,_s2(IM))

#define MOVLrr(X,RS, RD)                  _O_Mrm          (X,0x89           ,_b11,_r4(RS),_r4(RD)                           )
#define MOVLmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x8b                ,_r4(RD)           ,MD,MB,MI,MS            )
#define MOVLrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x89                ,_r4(RS)           ,MD,MB,MI,MS            )
#define MOVLir(X,IM,  R)                  _Or_L           (X,0xb8,_r4(R)                                            ,IM     )
#define MOVLim(X,IM, MD, MB, MI, MS)      _O_X_L          (X,0xc7                                   ,MD,MB,MI,MS    ,IM     )

#define MOVSBLrr(X,RS,RD)                 _OO_Mrm         (X,0x0fbe         ,_b11,_r1(RS),_r4(RD)                           )
#define MOVSBLmr(X,MD,MB,MI,MS,RD)        _OO_r_X         (X,0x0fbe              ,_r4(RD)           ,MD,MB,MI,MS            )

#define MULBrr(X,RS,RD)           ( _rAL (RD) +   _O_Mrm  (X,0xf6           ,_b11,_b100  ,_r1(RS)                           ) )
#define MULBmr(X,MD,MB,MI,MS,RD)  ( _rAL (RD) +   _O_r_X  (X,0xf6                ,_b100             ,MD,MB,MI,MS            ) )

#define MULWrr(X,RS,RD)           ( _rAX (RD) +   _wO_Mrm (X,0xf7           ,_b11,_b100  ,_r2(RS)                           ) )
#define MULWmr(X,MD,MB,MI,MS,RD)  ( _rAX (RD) +   _wO_r_X (X,0xf7                ,_b100             ,MD,MB,MI,MS            ) )

#define MULLrr(X,RS,RD)           ( _rEAX(RD) +   _O_Mrm  (X,0xf7           ,_b11,_b100  ,_r4(RS)                           ) )
#define MULLmr(X,MD,MB,MI,MS,RD)  ( _rEAX(RD) +   _O_r_X  (X,0xf7                ,_b100             ,MD,MB,MI,MS            ) )


#define NEGBr(X,RD)                       _O_Mrm          (X,0xf6           ,_b11,_b011  ,_r1(RD)                           )
#define NEGBm(X,MD,MB,MI,MS)              _O_r_X          (X,0xf6                ,_b011             ,MD,MB,MI,MS            )

#define NEGWr(X,RD)                       _wO_Mrm         (X,0xf7           ,_b11,_b011  ,_r2(RD)                           )
#define NEGWm(X,MD,MB,MI,MS)              _wO_r_X         (X,0xf7                ,_b011             ,MD,MB,MI,MS            )

#define NEGLr(X,RD)                       _O_Mrm          (X,0xf7           ,_b11,_b011  ,_r4(RD)                           )
#define NEGLm(X,MD,MB,MI,MS)              _O_r_X          (X,0xf7                ,_b011             ,MD,MB,MI,MS            )


#define NOP(X)                           _O              (X,0x90                                                           )


#define NOTBr(X,RD)                       _O_Mrm          (X,0xf6           ,_b11,_b010  ,_r1(RD)                           )
#define NOTBm(X,MD,MB,MI,MS)              _O_r_X          (X,0xf6                ,_b010             ,MD,MB,MI,MS            )

#define NOTWr(X,RD)                       _wO_Mrm         (X,0xf7           ,_b11,_b010  ,_r2(RD)                           )
#define NOTWm(X,MD,MB,MI,MS)              _wO_r_X         (X,0xf7                ,_b010             ,MD,MB,MI,MS            )

#define NOTLr(X,RD)                       _O_Mrm          (X,0xf7           ,_b11,_b010  ,_r4(RD)                           )
#define NOTLm(X,MD,MB,MI,MS)              _O_r_X          (X,0xf7                ,_b010             ,MD,MB,MI,MS            )


#define ORBrr(X,RS, RD)                   _O_Mrm          (X,0x08           ,_b11,_r1(RS),_r1(RD)                           )
#define ORBmr(X,MD, MB, MI, MS, RD)       _O_r_X          (X,0x0a                ,_r1(RD)           ,MD,MB,MI,MS            )
#define ORBrm(X,RS, MD, MB, MI, MS)       _O_r_X          (X,0x08                ,_r1(RS)           ,MD,MB,MI,MS            )
#define ORBir(X,IM, RD)                   _O_Mrm_B        (X,0x80           ,_b11,_b001  ,_r1(RD)                   ,_s1(IM))
#define ORBim(X,IM, MD, MB, MI, MS)       _O_r_X_B        (X,0x80                ,_b001             ,MD,MB,MI,MS    ,_s1(IM))
        
#define ORWrr(X,RS, RD)                   _wO_Mrm         (X,0x09           ,_b11,_r2(RS),_r2(RD)                           )
#define ORWmr(X,MD, MB, MI, MS, RD)       _wO_r_X         (X,0x0b                ,_r2(RD)           ,MD,MB,MI,MS            )
#define ORWrm(X,RS, MD, MB, MI, MS)       _wO_r_X         (X,0x09                ,_r2(RS)           ,MD,MB,MI,MS            )
#define ORWir(X,IM, RD)                   _wOs_Mrm_sW     (X,0x81           ,_b11,_b001  ,_r2(RD)                   ,_s2(IM))
#define ORWim(X,IM, MD, MB, MI, MS)       _wOs_r_X_sW     (X,0x81                ,_b001             ,MD,MB,MI,MS    ,_s2(IM))
        
#define ORLrr(X,RS, RD)                   _O_Mrm          (X,0x09           ,_b11,_r4(RS),_r4(RD)                           )
#define ORLmr(X,MD, MB, MI, MS, RD)       _O_r_X          (X,0x0b                ,_r4(RD)           ,MD,MB,MI,MS            )
#define ORLrm(X,RS, MD, MB, MI, MS)       _O_r_X          (X,0x09                ,_r4(RS)           ,MD,MB,MI,MS            )
#define ORLir(X,IM, RD)                   _Os_Mrm_sL      (X,0x81           ,_b11,_b001  ,_r4(RD)                   ,IM     )
#define ORLim(X,IM, MD, MB, MI, MS)       _Os_r_X_sL      (X,0x81                ,_b001             ,MD,MB,MI,MS    ,IM     )


#define POPWr(X,RD)                       _wOr            (X,0x58,_r2(RD)                                                   )
#define POPWm(X,MD,MB,MI,MS)              _wO_r_X         (X,0x8f                ,_b000             ,MD,MB,MI,MS            )

#define POPLr(X,RD)                       _Or             (X,0x58,_r4(RD)                                                   )
#define POPLm(X,MD,MB,MI,MS)              _O_r_X          (X,0x8f                ,_b000             ,MD,MB,MI,MS            )


#define POPA(X)                          _wO             (X,0x61                                                           )
#define POPAD(X)                         _O              (X,0x61                                                           )

#define POPF(X)                          _wO             (X,0x9d                                                           )
#define POPFD(X)                         _O              (X,0x9d                                                           )


#define PUSHWr(X,R)                       _wOr            (X,0x50,_r2(R)                                                    )
#define PUSHWm(X,MD,MB,MI,MS)             _wO_r_X         (X,0xff                ,_b110             ,MD,MB,MI,MS            )
#define PUSHWi(X,IM)                      _wOs_sW         (X,0x68                                                   ,IM     )

#define PUSHLr(X,R)                       _Or             (X,0x50,_r4(R)                                                    )
#define PUSHLm(X,MD,MB,MI,MS)             _O_r_X          (X,0xff                ,_b110             ,MD,MB,MI,MS            )
#define PUSHLi(X,IM)                      _Os_sL          (X,0x68                                                   ,IM     )


#define PUSHA(X)                         _wO             (X,0x60                                                           )
#define PUSHAD(X)                        _O              (X,0x60                                                           )

#define PUSHF(X)                         _O              (X,0x9c                                                           )
#define PUSHFD(X)                        _wO             (X,0x9c                                                           )

#define RET(X)                           _O              (X,0xc3                                                           )
#define RETi(X,IM)                        _O_W            (X,0xc2                                                   ,_s2(IM))


#define ROLBir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd0   ,_b11,_b000,_r1(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc0   ,_b11,_b000,_r1(RD)                     ,_u1(IM) ) )
#define ROLBim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd0        ,_b000             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc0        ,_b000             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define ROLBrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd2   ,_b11,_b000,_r1(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define ROLBrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd2        ,_b000             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )

#define ROLWir(X,IM,RD)           (((IM)==1) ?    _wO_Mrm         (X,0xd1   ,_b11,_b000,_r2(RD)                             ) : \
                                                _wO_Mrm_B       (X,0xc1   ,_b11,_b000,_r2(RD)                     ,_u1(IM) ) )
#define ROLWim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _wO_r_X         (X,0xd1        ,_b000             ,MD,MB,MI,MS            ) : \
                                                _wO_r_X_B       (X,0xc1        ,_b000             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define ROLWrr(X,RS,RD)           (((RS)==_CL) ?  _wO_Mrm         (X,0xd3   ,_b11,_b000,_r2(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                                   ) )
#define ROLWrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _wO_r_X         (X,0xd3        ,_b000             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                                   ) )

#define ROLLir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd1   ,_b11,_b000,_r4(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc1   ,_b11,_b000,_r4(RD)                     ,_u1(IM) ) )
#define ROLLim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd1        ,_b000             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc1        ,_b000             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define ROLLrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd3   ,_b11,_b000,_r4(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define ROLLrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd3        ,_b000             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )


#define RORBir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd0   ,_b11,_b001,_r1(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc0   ,_b11,_b001,_r1(RD)                     ,_u1(IM) ) )
#define RORBim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd0        ,_b001             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc0        ,_b001             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define RORBrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd2   ,_b11,_b001,_r1(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define RORBrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd2        ,_b001             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )

#define RORWir(X,IM,RD)           (((IM)==1) ?    _wO_Mrm         (X,0xd1   ,_b11,_b001,_r2(RD)                             ) : \
                                                _wO_Mrm_B       (X,0xc1   ,_b11,_b001,_r2(RD)                     ,_u1(IM) ) )
#define RORWim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _wO_r_X         (X,0xd1        ,_b001             ,MD,MB,MI,MS            ) : \
                                                _wO_r_X_B       (X,0xc1        ,_b001             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define RORWrr(X,RS,RD)           (((RS)==_CL) ?  _wO_Mrm         (X,0xd3   ,_b11,_b001,_r2(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                                   ) )
#define RORWrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _wO_r_X         (X,0xd3        ,_b001             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                                   ) )

#define RORLir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd1   ,_b11,_b001,_r4(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc1   ,_b11,_b001,_r4(RD)                     ,_u1(IM) ) )
#define RORLim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd1        ,_b001             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc1        ,_b001             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define RORLrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd3   ,_b11,_b001,_r4(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define RORLrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd3        ,_b001             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )


#define SAHF(X)                                  _O              (X,0x9e                                                           )


#define SARBir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd0   ,_b11,_b111,_r1(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc0   ,_b11,_b111,_r1(RD)                     ,_u1(IM) ) )
#define SARBim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd0        ,_b111             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc0        ,_b111             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SARBrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd2   ,_b11,_b111,_r1(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SARBrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd2        ,_b111             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )

#define SARWir(X,IM,RD)           (((IM)==1) ?    _wO_Mrm         (X,0xd1   ,_b11,_b111,_r2(RD)                             ) : \
                                                _wO_Mrm_B       (X,0xc1   ,_b11,_b111,_r2(RD)                     ,_u1(IM) ) )
#define SARWim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _wO_r_X         (X,0xd1        ,_b111             ,MD,MB,MI,MS            ) : \
                                                _wO_r_X_B       (X,0xc1        ,_b111             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SARWrr(X,RS,RD)           (((RS)==_CL) ?  _wO_Mrm         (X,0xd3   ,_b11,_b111,_r2(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                                   ) )
#define SARWrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _wO_r_X         (X,0xd3        ,_b111             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                                   ) )

#define SARLir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd1   ,_b11,_b111,_r4(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc1   ,_b11,_b111,_r4(RD)                     ,_u1(IM) ) )
#define SARLim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd1        ,_b111             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc1        ,_b111             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SARLrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd3   ,_b11,_b111,_r4(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SARLrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd3        ,_b111             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )


#define SBBBrr(X,RS, RD)                  _O_Mrm                  (X,0x18           ,_b11,_r1(RS),_r1(RD)                           )
#define SBBBmr(X,MD, MB, MI, MS, RD)      _O_r_X                  (X,0x1a                ,_r1(RD)           ,MD,MB,MI,MS            )
#define SBBBrm(X,RS, MD, MB, MI, MS)      _O_r_X                  (X,0x18                ,_r1(RS)           ,MD,MB,MI,MS            )
#define SBBBir(X,IM, RD)                  _O_Mrm_B                (X,0x80           ,_b11,_b011  ,_r1(RD)                   ,_s1(IM))
#define SBBBim(X,IM, MD, MB, MI, MS)      _O_r_X_B                (X,0x80                ,_b011             ,MD,MB,MI,MS    ,_s1(IM))
        
#define SBBWrr(X,RS, RD)                  _wO_Mrm    	        (X,0x19           ,_b11,_r2(RS),_r2(RD)                           )
#define SBBWmr(X,MD, MB, MI, MS, RD)      _wO_r_X                 (X,0x1b                ,_r2(RD)           ,MD,MB,MI,MS            )
#define SBBWrm(X,RS, MD, MB, MI, MS)      _wO_r_X                 (X,0x19                ,_r2(RS)           ,MD,MB,MI,MS            )
#define SBBWir(X,IM, RD)                  _wOs_Mrm_sW             (X,0x81           ,_b11,_b011  ,_r2(RD)                   ,_s2(IM))
#define SBBWim(X,IM, MD, MB, MI, MS)      _wOs_r_X_sW             (X,0x81                ,_b011             ,MD,MB,MI,MS    ,_s2(IM))
        
#define SBBLrr(X,RS, RD)                  _O_Mrm                  (X,0x19           ,_b11,_r4(RS),_r4(RD)                           )
#define SBBLmr(X,MD, MB, MI, MS, RD)      _O_r_X                  (X,0x1b                ,_r4(RD)           ,MD,MB,MI,MS            )
#define SBBLrm(X,RS, MD, MB, MI, MS)      _O_r_X                  (X,0x19                ,_r4(RS)           ,MD,MB,MI,MS            )
#define SBBLir(X,IM, RD)                  _Os_Mrm_sL              (X,0x81           ,_b11,_b011  ,_r4(RD)                   ,IM     )
#define SBBLim(X,IM, MD, MB, MI, MS)      _Os_r_X_sL              (X,0x81                ,_b011             ,MD,MB,MI,MS    ,IM     )


#define SETCCir(X,CC,RD)                  _OO_Mrm         (X,0x0f90|(CC)    ,_b11,_b000,_r1(RD)                             )

#define SETOr(X,RD)                       SETCCir(X,0x0,RD)
#define SETNOr(X,RD)                      SETCCir(X,0x1,RD)
#define SETBr(X,RD)                       SETCCir(X,0x2,RD)
#define SETNAEr(X,RD)                     SETCCir(X,0x2,RD)
#define SETNBr(X,RD)                      SETCCir(X,0x3,RD)
#define SETAEr(X,RD)                      SETCCir(X,0x3,RD)
#define SETEr(X,RD)                       SETCCir(X,0x4,RD)
#define SETZr(X,RD)                       SETCCir(X,0x4,RD)
#define SETNEr(X,RD)                      SETCCir(X,0x5,RD)
#define SETNZr(X,RD)                      SETCCir(X,0x5,RD)
#define SETBEr(X,RD)                      SETCCir(X,0x6,RD)
#define SETNAr(X,RD)                      SETCCir(X,0x6,RD)
#define SETNBEr(X,RD)                     SETCCir(X,0x7,RD)
#define SETAr(X,RD)                       SETCCir(X,0x7,RD)
#define SETSr(X,RD)                       SETCCir(X,0x8,RD)
#define SETNSr(X,RD)                      SETCCir(X,0x9,RD)
#define SETPr(X,RD)                       SETCCir(X,0xa,RD)
#define SETPEr(X,RD)                      SETCCir(X,0xa,RD)
#define SETNPr(X,RD)                      SETCCir(X,0xb,RD)
#define SETPOr(X,RD)                      SETCCir(X,0xb,RD)
#define SETLr(X,RD)                       SETCCir(X,0xc,RD)
#define SETNGEr(X,RD)                     SETCCir(X,0xc,RD)
#define SETNLr(X,RD)                      SETCCir(X,0xd,RD)
#define SETGEr(X,RD)                      SETCCir(X,0xd,RD)
#define SETLEr(X,RD)                      SETCCir(X,0xe,RD)
#define SETNGr(X,RD)                      SETCCir(X,0xe,RD)
#define SETNLEr(X,RD)                     SETCCir(X,0xf,RD)
#define SETGr(X,RD)                       SETCCir(X,0xf,RD)

#define SETCCim(X,CC,MD,MB,MI,MS)         _OO_r_X         (X,0x0f90|(CC)         ,_b000             ,MD,MB,MI,MS            )

#define SETOm(X,D,B,I,S)                  SETCCim(X,0x0,D,B,I,S)
#define SETNOm(X,D,B,I,S)                 SETCCim(X,0x1,D,B,I,S)
#define SETBm(X,D,B,I,S)                  SETCCim(X,0x2,D,B,I,S)
#define SETNAEm(X,D,B,I,S)                SETCCim(X,0x2,D,B,I,S)
#define SETNBm(X,D,B,I,S)                 SETCCim(X,0x3,D,B,I,S)
#define SETAEm(X,D,B,I,S)                 SETCCim(X,0x3,D,B,I,S)
#define SETEm(X,D,B,I,S)                  SETCCim(X,0x4,D,B,I,S)
#define SETZm(X,D,B,I,S)                  SETCCim(X,0x4,D,B,I,S)
#define SETNEm(X,D,B,I,S)                 SETCCim(X,0x5,D,B,I,S)
#define SETNZm(X,D,B,I,S)                 SETCCim(X,0x5,D,B,I,S)
#define SETBEm(X,D,B,I,S)                 SETCCim(X,0x6,D,B,I,S)
#define SETNAm(X,D,B,I,S)                 SETCCim(X,0x6,D,B,I,S)
#define SETNBEm(X,D,B,I,S)                SETCCim(X,0x7,D,B,I,S)
#define SETAm(X,D,B,I,S)                  SETCCim(X,0x7,D,B,I,S)
#define SETSm(X,D,B,I,S)                  SETCCim(X,0x8,D,B,I,S)
#define SETNSm(X,D,B,I,S)                 SETCCim(X,0x9,D,B,I,S)
#define SETPm(X,D,B,I,S)                  SETCCim(X,0xa,D,B,I,S)
#define SETPEm(X,D,B,I,S)                 SETCCim(X,0xa,D,B,I,S)
#define SETNPm(X,D,B,I,S)                 SETCCim(X,0xb,D,B,I,S)
#define SETPOm(X,D,B,I,S)                 SETCCim(X,0xb,D,B,I,S)
#define SETLm(X,D,B,I,S)                  SETCCim(X,0xc,D,B,I,S)
#define SETNGEm(X,D,B,I,S)                SETCCim(X,0xc,D,B,I,S)
#define SETNLm(X,D,B,I,S)                 SETCCim(X,0xd,D,B,I,S)
#define SETGEm(X,D,B,I,S)                 SETCCim(X,0xd,D,B,I,S)
#define SETLEm(X,D,B,I,S)                 SETCCim(X,0xe,D,B,I,S)
#define SETNGm(X,D,B,I,S)                 SETCCim(X,0xe,D,B,I,S)
#define SETNLEm(X,D,B,I,S)                SETCCim(X,0xf,D,B,I,S)
#define SETGm(X,D,B,I,S)                  SETCCim(X,0xf,D,B,I,S)


#define SHLBir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd0   ,_b11,_b100,_r1(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc0   ,_b11,_b100,_r1(RD)                     ,_u1(IM) ) )
#define SHLBim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd0        ,_b100             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc0        ,_b100             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SHLBrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd2   ,_b11,_b100,_r1(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SHLBrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd2        ,_b100             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )

#define SHLWir(X,IM,RD)           (((IM)==1) ?    _wO_Mrm         (X,0xd1   ,_b11,_b100,_r2(RD)                             ) : \
                                                _wO_Mrm_B       (X,0xc1   ,_b11,_b100,_r2(RD)                     ,_u1(IM) ) )
#define SHLWim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _wO_r_X         (X,0xd1        ,_b100             ,MD,MB,MI,MS            ) : \
                                                _wO_r_X_B       (X,0xc1        ,_b100             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SHLWrr(X,RS,RD)           (((RS)==_CL) ?  _wO_Mrm         (X,0xd3   ,_b11,_b100,_r2(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SHLWrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _wO_r_X         (X,0xd3        ,_b100             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                                   ) )

#define SHLLir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd1   ,_b11,_b100,_r4(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc1   ,_b11,_b100,_r4(RD)                     ,_u1(IM) ) )
#define SHLLim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd1        ,_b100             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc1        ,_b100             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SHLLrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd3   ,_b11,_b100,_r4(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SHLLrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd3        ,_b100             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )


#define SHRBir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd0   ,_b11,_b101,_r1(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc0   ,_b11,_b101,_r1(RD)                     ,_u1(IM) ) )
#define SHRBim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd0        ,_b101             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc0        ,_b101             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SHRBrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd2   ,_b11,_b101,_r1(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SHRBrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd2        ,_b101             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )

#define SHRWir(X,IM,RD)           (((IM)==1) ?    _wO_Mrm         (X,0xd1   ,_b11,_b101,_r2(RD)                             ) : \
                                                _wO_Mrm_B       (X,0xc1   ,_b11,_b101,_r2(RD)                     ,_u1(IM) ) )
#define SHRWim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _wO_r_X         (X,0xd1        ,_b101             ,MD,MB,MI,MS            ) : \
                                                _wO_r_X_B       (X,0xc1        ,_b101             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SHRWrr(X,RS,RD)           (((RS)==_CL) ?  _wO_Mrm         (X,0xd3   ,_b11,_b101,_r2(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SHRWrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _wO_r_X         (X,0xd3        ,_b101             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )

#define SHRLir(X,IM,RD)           (((IM)==1) ?    _O_Mrm          (X,0xd1   ,_b11,_b101,_r4(RD)                             ) : \
                                                _O_Mrm_B        (X,0xc1   ,_b11,_b101,_r4(RD)                     ,_u1(IM) ) )
#define SHRLim(X,IM,MD,MB,MS,MI)  (((IM)==1) ?    _O_r_X          (X,0xd1        ,_b101             ,MD,MB,MI,MS            ) : \
                                                _O_r_X_B        (X,0xc1        ,_b101             ,MD,MB,MI,MS    ,_u1(IM) ) )
#define SHRLrr(X,RS,RD)           (((RS)==_CL) ?  _O_Mrm          (X,0xd3   ,_b11,_b101,_r4(RD)                             ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )
#define SHRLrm(X,RS,MD,MB,MS,MI)  (((RS)==_CL) ?  _O_r_X          (X,0xd3        ,_b101             ,MD,MB,MI,MS            ) : \
                                                ASMFAIL         ("source register must be CL"                           ) )


#define STC(X)                           _O              (X,0xf9                                                           )


#define SUBBrr(X,RS, RD)                  _O_Mrm          (X,0x28           ,_b11,_r1(RS),_r1(RD)                           )
#define SUBBmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x2a                ,_r1(RD)           ,MD,MB,MI,MS            )
#define SUBBrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x28                ,_r1(RS)           ,MD,MB,MI,MS            )
#define SUBBir(X,IM, RD)                  _O_Mrm_B        (X,0x80           ,_b11,_b101  ,_r1(RD)                   ,_s1(IM))
#define SUBBim(X,IM, MD, MB, MI, MS)      _O_r_X_B        (X,0x80                ,_b101             ,MD,MB,MI,MS    ,_s1(IM))
        
#define SUBWrr(X,RS, RD)                  _wO_Mrm         (X,0x29           ,_b11,_r2(RS),_r2(RD)                           )
#define SUBWmr(X,MD, MB, MI, MS, RD)      _wO_r_X         (X,0x2b                ,_r2(RD)           ,MD,MB,MI,MS            )
#define SUBWrm(X,RS, MD, MB, MI, MS)      _wO_r_X         (X,0x29                ,_r2(RS)           ,MD,MB,MI,MS            )
#define SUBWir(X,IM, RD)                  _wOs_Mrm_sW     (X,0x81           ,_b11,_b101  ,_r2(RD)                   ,_s2(IM))
#define SUBWim(X,IM, MD, MB, MI, MS)      _wOs_r_X_sW     (X,0x81                ,_b101             ,MD,MB,MI,MS    ,_s2(IM))
        
#define SUBLrr(X,RS, RD)                  _O_Mrm          (X,0x29           ,_b11,_r4(RS),_r4(RD)                           )
#define SUBLmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x2b                ,_r4(RD)           ,MD,MB,MI,MS            )
#define SUBLrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x29                ,_r4(RS)           ,MD,MB,MI,MS            )
#define SUBLir(X,IM, RD)                  _Os_Mrm_sL      (X,0x81           ,_b11,_b101  ,_r4(RD)                   ,IM     )
#define SUBLim(X,IM, MD, MB, MI, MS)      _Os_r_X_sL      (X,0x81                ,_b101             ,MD,MB,MI,MS    ,IM     )


#define TESTBrr(X,RS, RD)                 _O_Mrm          (X,0x84           ,_b11,_r1(RS),_r1(RD)                           )
#define TESTBrm(X,RS, MD, MB, MI, MS)     _O_r_X          (X,0x84                ,_r1(RS)           ,MD,MB,MI,MS            )
#define TESTBir(X,IM, RD)                 _O_Mrm_B        (X,0xf6           ,_b11,_b000  ,_r1(RD)                   ,_u1(IM))
#define TESTBim(X,IM, MD, MB, MI, MS)     _O_r_X_B        (X,0xf6                ,_b000             ,MD,MB,MI,MS    ,_u1(IM))

#define TESTWrr(X,RS, RD)                 _wO_Mrm         (X,0x85           ,_b11,_r2(RS),_r2(RD)                           )
#define TESTWrm(X,RS, MD, MB, MI, MS)     _wO_r_X         (X,0x85                ,_r2(RS)           ,MD,MB,MI,MS            )
#define TESTWir(X,IM, RD)                 _wO_Mrm_W       (X,0xf7           ,_b11,_b000  ,_r2(RD)                   ,_u2(IM))
#define TESTWim(X,IM, MD, MB, MI, MS)     _wO_r_X_W       (X,0xf7                ,_b000             ,MD,MB,MI,MS    ,_u2(IM))

#define TESTLrr(X,RS, RD)                 _O_Mrm          (X,0x85           ,_b11,_r4(RS),_r4(RD)                           )
#define TESTLrm(X,RS, MD, MB, MI, MS)     _O_r_X          (X,0x85                ,_r4(RS)           ,MD,MB,MI,MS            )
#define TESTLir(X,IM, RD)                 _O_Mrm_L        (X,0xf7           ,_b11,_b000  ,_r4(RD)                   ,IM     )
#define TESTLim(X,IM, MD, MB, MI, MS)     _O_r_X_L        (X,0xf7                ,_b000             ,MD,MB,MI,MS    ,IM     )


#define XADDBrr(X,RS,RD)                  _OO_Mrm         (X,0x0fc0         ,_b11,_r1(RS),_r1(RD)                           )
#define XADDBrm(X,RS,MD,MB,MI,MS)         _OO_r_X         (X,0x0fc0              ,_r1(RS)           ,MD,MB,MI,MS            )

#define XADDWrr(X,RS,RD)                  _wOO_Mrm        (X,0x0fc1         ,_b11,_r2(RS),_r2(RD)                           )
#define XADDWrm(X,RS,MD,MB,MI,MS)         _wOO_r_X        (X,0x0fc1              ,_r2(RS)           ,MD,MB,MI,MS            )

#define XADDLrr(X,RS,RD)                  _OO_Mrm         (X,0x0fc1         ,_b11,_r4(RS),_r4(RD)                           )
#define XADDLrm(X,RS,MD,MB,MI,MS)         _OO_r_X         (X,0x0fc1              ,_r4(RS)           ,MD,MB,MI,MS            )


#define XCHGBrr(X,RS,RD)                  _O_Mrm          (X,0x86           ,_b11,_r1(RS),_r1(RD)                           )
#define XCHGBrm(X,RS,MD,MB,MI,MS)         _O_r_X          (X,0x86                ,_r1(RS)           ,MD,MB,MI,MS            )

#define XCHGWrr(X,RS,RD)                  _wO_Mrm         (X,0x87           ,_b11,_r2(RS),_r2(RD)                           )
#define XCHGWrm(X,RS,MD,MB,MI,MS)         _wO_r_X         (X,0x87                ,_r2(RS)           ,MD,MB,MI,MS            )

#define XCHGLrr(X,RS,RD)                  _O_Mrm          (X,0x87           ,_b11,_r4(RS),_r4(RD)                           )
#define XCHGLrm(X,RS,MD,MB,MI,MS)         _O_r_X          (X,0x87                ,_r4(RS)           ,MD,MB,MI,MS            )


#define XORBrr(X,RS, RD)                  _O_Mrm          (X,0x30           ,_b11,_r1(RS),_r1(RD)                           )
#define XORBmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x32                ,_r1(RD)           ,MD,MB,MI,MS            )
#define XORBrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x30                ,_r1(RS)           ,MD,MB,MI,MS            )
#define XORBir(X,IM, RD)                  _O_Mrm_B        (X,0x80           ,_b11,_b110  ,_r1(RD)                   ,_s1(IM))
#define XORBim(X,IM, MD, MB, MI, MS)      _O_r_X_B        (X,0x80                ,_b110             ,MD,MB,MI,MS    ,_s1(IM))

#define XORWrr(X,RS, RD)                  _wO_Mrm         (X,0x31           ,_b11,_r2(RS),_r2(RD)                           )
#define XORWmr(X,MD, MB, MI, MS, RD)      _wO_r_X         (X,0x33                ,_r2(RD)           ,MD,MB,MI,MS            )
#define XORWrm(X,RS, MD, MB, MI, MS)      _wO_r_X         (X,0x31                ,_r2(RS)           ,MD,MB,MI,MS            )
#define XORWir(X,IM, RD)                  _wOs_Mrm_sW     (X,0x81           ,_b11,_b110  ,_r2(RD)                   ,_s2(IM))
#define XORWim(X,IM, MD, MB, MI, MS)      _wOs_r_X_sW     (X,0x81                ,_b110             ,MD,MB,MI,MS    ,_s2(IM))

#define XORLrr(X,RS, RD)                  _O_Mrm          (X,0x31           ,_b11,_r4(RS),_r4(RD)                           )
#define XORLmr(X,MD, MB, MI, MS, RD)      _O_r_X          (X,0x33                ,_r4(RD)           ,MD,MB,MI,MS            )
#define XORLrm(X,RS, MD, MB, MI, MS)      _O_r_X          (X,0x31                ,_r4(RS)           ,MD,MB,MI,MS            )
#define XORLir(X,IM, RD)                  _Os_Mrm_sL      (X,0x81           ,_b11,_b110  ,_r4(RD)                   ,IM     )
#define XORLim(X,IM, MD, MB, MI, MS)      _Os_r_X_sL      (X,0x81                ,_b110             ,MD,MB,MI,MS    ,IM     )

#define SALBir  SHLBir  
#define SALBim  SHLBim  
#define SALBrr  SHLBrr  
#define SALBrm  SHLBrm  
#define SALWir  SHLWir  
#define SALWim  SHLWim  
#define SALWrr  SHLWrr  
#define SALWrm  SHLWrm  
#define SALLir  SHLLir  
#define SALLim  SHLLim  
#define SALLrr  SHLLrr  
#define SALLrm  SHLLrm  
