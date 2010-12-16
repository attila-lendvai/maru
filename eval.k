;;; -*- coke -*-

(define-form debug prog ())
;;(define-form debug prog `(let () ,@prog))

(define-structure <header> (size flags next type))
(define-structure <buffer> (contents size position))

(define-function make-gc-protectors (vars)
  (map (lambda (v) (list 'gc_push_root (list 'address-of (car vars))))
       vars))

(define-function make-gc-unprotectors (vars)
  (let ((result ()))
    (while (pair? vars)
      (set result (cons (list 'gc_pop_root (list 'address-of (car vars))) result))
      (set vars (cdr vars)))
    result))

(define-form gc-protect (vars . prog)
  `(let ()
     ,@(make-gc-protectors vars)
     (let ((__answer__ ,@prog))
       ,@(make-gc-unprotectors vars)
       __answer__)))

(compile-begin)

(define gc_quantum	65504)
(define gc_frequency	10);32768)

(define exit	(extern 'exit))
(define malloc	(extern 'malloc))
(define free	(extern 'free))
(define memset	(extern 'memset))
(define memcpy	(extern 'memcpy))
(define printf	(extern 'printf))

(define gc_roots	0)
(define gc_root_count	0)
(define gc_root_max	0)

(define gc_memory_base	0)
(define gc_memory_last	0)
(define gc_alloc_count	0)

(define-form size-of-structure (type)	(* 4 (array-at %structure-sizes (eval type))))

(define-form <header>-flags-used ()	1)
(define-form <header>-flags-atom ()	2)
(define-form <header>-flags-mark ()	4)	(define-form <header>-flags-mark-mask ()	-5)

(define-form <header>-flags-used+atom ()	(+ (<header>-flags-used) (<header>-flags-atom)))

(define-function max (a b)	(if (> a b) a b))

(define-function fatal (reason)		(printf "\n%s\n" reason) (exit 1))

(define-function fatal1 (fmt arg)	(printf "\n") (printf fmt arg)		(printf "\n") (exit 1))
(define-function fatal2 (fmt arg brg)	(printf "\n") (printf fmt arg brg)	(printf "\n") (exit 1))

(define-function new_memory_block (size)
  (let ((ptr (malloc size)))
    (or ptr (fatal "out of memory"))
    (set (<header>-size  ptr) (- size (size-of-structure <header>)))
    (set (<header>-flags ptr) 0)
    (set (<header>-next  ptr) ptr)
    (printf "BRK %p %d %d/%d\n" ptr size gc_alloc_count gc_frequency)
    ptr))

(define-function gc_initialise ()
  (let ((ptr (new_memory_block gc_quantum)))
    (set gc_memory_base ptr)
    (set gc_memory_last ptr)))

(define-function gc_push_root (ptr)
  (and (= gc_root_count gc_root_max)
       (let ((roots (malloc (* 4 (set gc_root_max (* 2 gc_root_max))))))
	 (memcpy roots gc_roots (* 4 gc_root_count))
	 (and gc_roots (free gc_roots))
	 (set gc_roots roots)))
  (set-oop-at gc_roots gc_root_count ptr)
  (debug (printf "gc add root %d at %p\n" gc_root_count ptr))
  (set gc_root_count (+ 1 gc_root_count)))

(define-function gc_pop_root (ptr)
  (or gc_root_count (fatal "root table underflow"))
  (set gc_root_count (- gc_root_count 1))
  (debug (printf "gc del root %d at %p\n" gc_root_count ptr))
  (or (= ptr (oop-at gc_roots gc_root_count)) (fatal "non-lifo root")))

(define-function gc_grow_memory (size)
  (let ((brk (new_memory_block size)))
    (set (<header>-next brk)            (<header>-next gc_memory_last))
    (set (<header>-next gc_memory_last) brk)))

(define-function gc_malloc_chunk (size)
  (let ((ptr   (<header>-next gc_memory_last))
	(done  ())
	(chunk ()))
    (let ((lim ptr))
      (while (not done)
	(debug (printf "alloc? %d %p %p [%p] %d >= %d %d\n" (<header>-flags ptr) ptr (<header>-next ptr) lim (<header>-size ptr) size (<= size (<header>-size ptr))))
	(if (and (=  0    (<header>-flags ptr))
		 (<= size (<header>-size  ptr)))
	    (let ()
	      (set chunk ptr)
	      (set done 1))
	  (set done (= lim (set ptr (<header>-next ptr)))))))
    (debug (printf "gc_malloc_chunk found free %p\n" chunk))
    (if chunk
	(let ((csize (<header>-size chunk)))
	  (debug (printf "csize %d\n" csize))
	  (and (> csize (+ size (size-of-structure <header>)))
	       (let ((split (+ chunk (+ (size-of-structure <header>) size))))
		 (debug (printf "split %p\n" split))
		 (set (<header>-size  split) (- csize (+ size (size-of-structure <header>))))
		 (set (<header>-flags split) 0)
		 (set (<header>-next  split) (<header>-next chunk))
		 (set (<header>-size  chunk) size)
		 (set (<header>-next  chunk) split)))
	  (set (<header>-flags chunk) (<header>-flags-used))
	  (set gc_memory_last chunk)
	  (debug (printf "alloc chunk %p\n" chunk))
	  (let ((obj (+ chunk (size-of-structure <header>))))
	    (memset obj 0 size)
	    (set gc_alloc_count (+ gc_alloc_count 1))
	    obj)))))

(define-function gc_sweep (obj)
  (debug (printf "sweep\n"))
  (let ((ptr gc_memory_base)
	(nused 0)
	(nfree 0))
    (while ptr
      (debug (printf "sweep? %d %p + %d\n" (<header>-flags ptr) ptr (<header>-size ptr)))
      (let ((flags (<header>-flags ptr)))
	(if (& flags (<header>-flags-mark))
	    (let ()
	      (set nused (+ nused (<header>-size ptr)))
	      (set (<header>-flags ptr) (& flags (<header>-flags-mark-mask))))
	  (debug (printf "collect %p %d\n" ptr (<header>-size ptr)))
;; 	  (while (and (= 0 (& (<header>-flags-mark) (<header>-flags (<header>-next ptr))))
;; 		      (printf "%p + %d + %d = %p ? %p\n"
;; 			      ptr (size-of-structure <header>) (<header>-size ptr)
;; 			      (+ ptr (+ (size-of-structure <header>) (<header>-size ptr)))
;; 			      (<header>-next ptr))
;; 		      (= (<header>-next ptr) (+ ptr (+ (size-of-structure <header>) (<header>-size ptr)))))
;; 	    (let ((next (<header>-next (<header>-next ptr))))
;; 	      (printf "COALESCE %p < %p > %p\n" ptr (<header>-next ptr) next)
;; 	      (set (<header>-size ptr) (- (- next ptr) (size-of-structure <header>)))
;; 	      (set (<header>-next ptr) next)))
	  (set nfree (+ nfree (<header>-size ptr)))
	  (set (<header>-flags ptr) 0)))
      (and (= gc_memory_base (set ptr (<header>-next ptr)))
	   (set ptr 0)))
    (printf "%d used, %d free, %d allocations\n" nused nfree gc_alloc_count)
    (and (< nfree nused)
	 (gc_grow_memory gc_quantum))
    ))

(define-function gc_mark_and_trace (obj)
  (debug (printf "mark and trace %p\n" obj))
  (and obj
       (not (& 1 obj))
       (let* ((ptr   (- obj (size-of-structure <header>)))
	      (flags (<header>-flags ptr)))
	 (and (not (& flags (<header>-flags-mark)))
	      (let ()
		(and (not (& flags (<header>-flags-atom)))
		     (let ((size (>> (<header>-size ptr) 2)))
		       (debug (printf "mark %p %d\n" ptr size))
		       (while size
			 (set size (- size 1))
			 (debug (printf "@%d %p\n" size (oop-at obj size)))
			 (gc_mark_and_trace (oop-at obj size)))))
		(set (<header>-flags ptr) (| flags (<header>-flags-mark))))))))

(define-function gc_gcollect ()
  (let ((i 0))
    (while (< i gc_root_count)
      (debug (let ((ptr (oop-at gc_roots i))) (printf "mark gc root at %p -> %p\n" ptr (oop-at ptr 0))))
      (gc_mark_and_trace (oop-at (oop-at gc_roots i) 0))
      (set i (+ 1 i))))
  (gc_sweep)
  (set gc_alloc_count 0))

(define-function gc_malloc (size)
  (set size (& -4 (+ 3 size)))
  (and (= gc_alloc_count gc_frequency) (gc_gcollect))
  (or (gc_malloc_chunk size)
      (let ()
	(gc_grow_memory (max (+ (size-of-structure <header>) size) gc_quantum))
	(gc_malloc_chunk size))
      (fatal "internal error: failed to allocate object after growing memory")))

(define-function gc_malloc_atomic (size)
  (let* ((obj (gc_malloc size)))
    (set (<header>-flags (- obj (size-of-structure <header>))) (<header>-flags-used+atom))
    obj))

;;; ----------------------------------------------------------------

(define strcmp	(extern 'strcmp))
(define strdup	(extern 'strdup))
(define getc	(extern 'getc))
(define putc	(extern 'putc))
(define ungetc	(extern 'ungetc))
(define fdopen	(extern 'fdopen))
(define fflush	(extern 'fflush))

(define stdin	0)
(define stdout	0)
(define stderr	0)

(define EOF	-1)

(define <undefined>	 0)
(define <long>		 1)
(define <string>	 2)
(define <symbol>	 3)
(define <pair>		 4)
(define <_array>	 5)
(define <array>		 6)
(define <expr>		 7)
(define <form>		 8)
(define <fixed>		 9)
(define <subr>		10)

(define symbols	0)

(define-function new-bits (type size)
  (let ((obj (gc_malloc_atomic size)))
    (set (oop-at obj -1) type)
    obj))

(define-function new-oops (type size)
  (let ((obj (gc_malloc size)))
    (set (oop-at obj -1) type)
    obj))

(define-function new-<symbol> (cstr)
  (let ((obj (new-bits <symbol> (size-of-structure <symbol>))))
    (set (<symbol>-_bits obj) (strdup cstr))
    obj))

(define-function new-<pair> (head tail)
  (let ((obj (new-oops <pair> (size-of-structure <pair>))))
    (set (<pair>-head obj) head)
    (set (<pair>-tail obj) tail)
    obj))

(define-form is (type arg)
  `(let ((__arg__ ,arg))
     (and __arg__
	  (not (& 1 __arg__))
	  (= ,type (oop-at __arg__ -1)))))

(define-form get-type (arg)
  `(let ((__arg__ ,arg))
     (if __arg__
	 (oop-at __arg__ -1)
       <undefined>)))

(define-function type_check_fail (exp act)
  (fatal2 "illegal type: expected %d got %d" exp act))

(define-form get (type field object)
  `(let ((__obj__ ,object))
     (let ((t (get-type __obj__))) (or (= ,type t) (type_check_fail ,type t)))
     (,(concat-symbol (concat-symbol type '-) field) __obj__)))

(define-form put (type field object value)
  `(let ((__obj__ ,object))
     (let ((t (get-type __obj__))) (or (= ,type t) (type_check_fail ,type t)))
     (,(concat-symbol (concat-symbol (concat-symbol 'set- type) '-) field) __obj__)))

(define-form get_head (obj)	`(oop-at ,obj 0))
(define-form get_tail (obj)	`(oop-at ,obj 1))

(define-function is_blank (c)	(or 	 ( = 0x20 c)			; sp
				    	 ( = 0x09 c)			; ht
				    	 ( = 0x0a c)			; nl
				    	 ( = 0x0b c)			; vt
				    	 ( = 0x0c c)			; ff
				    	 ( = 0x0d c)))			; cr

(define-function is_digit10 (c)	    (and (<= 0x30 c) (<= c 0x39)))	; 0 1 2 3 4 5 6 7 8 9

(define-function is_letter (c)	(or      ( = 0x21 c)			; !
				    (and (<= 0x23 c) (<= c 0x26))	; # $ % &
				    (and (<= 0x2a c) (<= c 0x2f))	; * + , - . /
					 ( = 0x3a c)			; :
				    (and (<= 0x3c c) (<= c 0x5a))	; < = > ?  @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
					 ( = 0x5c c)			; \
					 ( = 0x5e c)			; ^
					 ( = 0x5f c)			; _
				    (and (<= 0x61 c) (<= c 0x7a))	; a b c d e f g h i j k l m n o p q r s t u v w x y z
					 ( = 0x7c c)			; |
					 ( = 0x7e c)))			; ~

(define-function new_buffer ()
  (let ((buf (malloc (size-of-structure <buffer>))))
    (set (<buffer>-contents buf) (malloc 32))
    (set (<buffer>-size     buf) 32)
    (set (<buffer>-position buf) 0)
    buf))

(define-function buffer_delete (buf)
  (free (<buffer>-contents buf))
  (free buf))

(define-function buffer_grow (buf)
  (let ((size     (<buffer>-size buf))
	(contents (malloc (* 2 size))))
    (memcpy contents (<buffer>-contents buf) size)
    (free (<buffer>-contents buf))
    (set (<buffer>-contents buf) contents)
    (set (<buffer>-size buf) (* 2 size))))

(define-function buffer_append (buf c)
  (and (= (<buffer>-position buf) (<buffer>-size buf))
       (buffer_grow buf))
  (let ((posn (<buffer>-position buf)))
    (set-char-at (<buffer>-contents buf) posn c)
    (set (<buffer>-position buf) (+ 1 posn))))

(define-function intern (cstr)
  (let ((list symbols))
    (while (is <pair> list)
      (let ((sym (get_head list)))
	(or (strcmp cstr (get <symbol> _bits sym))
	    (return sym)))
      (set list (get_tail list))))
  (let ((sym (new-<symbol> cstr)))
    (gc-protect (sym)
      (set symbols (new-<pair> sym symbols))
      sym)))

(define-function read (stream)
  (while 1
    (let ((c (getc stream)))
      (cond
	((is_blank c)	())
	((is_letter c)	(let ((buf (new_buffer)))
			  (while (or (is_letter c) (is_digit10 c))
			    (buffer_append buf c)
			    (set c (getc stream)))
			  (ungetc c stream)
			  (buffer_append buf 0)
			  (let ((result (intern (<buffer>-contents buf))))
			    (buffer_delete buf)
			    (return result))))
	((is_digit10 c)	(let ((result (- c 48)))
			  (while (is_digit10 (set c (getc stream)))
			    (set result (+ (* 10 result) (- c 48))))
			  (ungetc c stream)
			  (return result)))
	((< c 0)	(return EOF))
	(else		(fatal1 "illegal character: %c" c))))))

(define-function k_println (obj)
  (printf "println %d %p\n" obj obj))

(define-function main (argc argv)
  (set stdin  (fdopen 0 "r"))
  (set stdout (fdopen 1 "a"))
  (set stderr (fdopen 2 "a"))
  (gc_initialise)
  (gc_push_root (address-of symbols))
  (while (set argc (- argc 1))
    (set argv (+ argv 4))
    (printf "%s\n" (oop-at argv 0)))
  (let ((obj 0))
    (while (!= EOF (set obj (read stdin)))
      (k_println obj)))
  (gc_gcollect)
  0)

(compile-end)
