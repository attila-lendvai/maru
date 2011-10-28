(load "port.l")
(load "data-stream.k")
(load "ansiterm.l")

(define-function nth (n list)
  (while (and (pair? list) (>= (incr n -1) 0))
    (set list (cdr list)))
  (car list))

(define-function %receive (vars)
  (and (pair? vars)
       (cons `(set ,(car vars) (car _))
	     (cons '(set _ (cdr _))
		   (%receive (cdr vars))))))

(define-form receive (expr . vars)
  `(let ((_ ,expr))
     ,@(%receive vars)))

(define values list)

(define-function _B (d x)	(data-stream-put-byte d x))
(define-function _W (d x)	(_B d x) (_B d (>> x 8)))
(define-function _L (d x)	(_W d x) (_W d (>> x 16)))

(define-function _D1 (d x)	(_B d (- (- x (data-stream-address d)) 1)))
(define-function _D4 (d x)	(_L d (- (- x (data-stream-address d)) 4)))

(load "asm-x86.k")

(define-function getB (s)	(data-stream-get-byte s))
(define-function getL (s)	(let ((a (getB s)) (b (getB s)) (c (getB s)) (d (getB s)))  (+ a (+ (<< b 8) (+ (<< c 16) (<< d 24))))))

(load "dsm-x86.k")

(define %EAX 0x40)
(define %ECX 0x41)
(define %EDX 0x42)
(define %EBX 0x43)
(define %ESP 0x44)
(define %EBP 0x45)
(define %ESI 0x46)
(define %EDI 0x47)

(define-structure <label> (name address))

(define-function label (name . rest)	(new <label> name (car rest)))

(define-method do-print <label> ()	(print "<label "self.name" 0x"(and self.address (format "%08x" self.address))">"))

(define putchar (label "putchar" (long-at (subr "putchar") 0)))

(println putchar)

(define-function LABEL (l x)	(set (<label>-address l) (data-stream-address x)) (println l))

(let ((x    (data-stream 1024))
      (loop (label "loop")))
  (PUSHLr %EBP					x)
  (MOVLrr %ESP        %EBP			x)
  (SUBLir  8          %ESP			x)
  (MOVLim ?A	       0 %ESP 0 0		x)
  (LABEL  loop					x)
  (CALLm  (<label>-address putchar) 0 0 0	x)
  (ADDLim  1	       0 %ESP 0 0		x)
  (CMPLim (+ ?Z 1)     0 %ESP 0 0		x)
  (JNESm  (<label>-address loop) 0 0 0		x)
  (MOVLim ?\n          0 %ESP 0 0		x)
  (CALLm  (<label>-address putchar) 0 0 0	x)
  (LEAVE					x)
  (RET						x)
  (println (data-stream-position x)" bytes generated")
  (data-stream-truncate x)
  (data-stream-rewind x)
  (let ((p (console-port)))
    (while (not (data-stream-at-end? x))
      (port-write p (format "%08x"(data-stream-address x))"\t")
      (disassemble-on x p)
      (port-put p ?\n)))
  (println (call (data-stream-data x) 3 4))
  )
