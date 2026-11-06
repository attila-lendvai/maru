;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion-min.l")

;; NOTE: not all of them are in this file.

(define-vm-function (define () fixed) ((variable <variable>) value-form)
  (let ((value (eval value-form -ctx-)))
    (set (<variable>-value variable) value)
    ;; maybe set the <expr>'s name slot
    (when-at-expand (feature track-expr-names)
      (let ((tmp value))
        (when (is <form> tmp)
          (set tmp (<form>-function tmp)))
        (when (and (is <expr> tmp)
                   (not (<expr>-name tmp)))
          (set (<expr>-name tmp) (<variable>-name variable)))))
    value))

;; TODO ideally, but it needs a gc/let*:(define-vm-function (eval ()) (form (env <env> (environment *globals* 1 0)))
(define-vm-function (eval ()) _
  (let ((env (if (cdr -args-) ; let's fail early when called with nil env
                 (cadr -args-)
               *globals*)))
    (let ((toplevel-env?	(= 0 (unbox <long> (<env>-level env))))
          (prev-globals	*globals*)
          result)
      (when toplevel-env?
        (set-current-globals env))
      (set result (gc/let* ((child-env (environment env 1 0)))
                    ;; TODO resolve this naming anomaly somehow
                    (expand-encode-eval* (car -args-) child-env)))
      (when toplevel-env?
        (set-current-globals prev-globals))
      result)))

(define-vm-function (lambda () fixed) ((env <env>) parameters . body)
  (assert (or (not parameters) (is <variable> parameters) (pair? parameters)) "lambda vm-function: parameters is of wrong type: " parameters)
  (expr parameters body env -ctx-))

(define-vm-function (let () fixed) (env bindings . body)
  (let ((locals (<context>-bindings -ctx-)))
    (gc/let* (tmp)
      (list-do binding bindings
        (when (pair? binding)
          (let ((var  (get/head binding))
                (prog (get/tail binding)))
            (debug-print "let vm-function is initializing var "var" in context "-ctx-)
            (set tmp ())
            (while (pair? prog)
              (set tmp (eval (get/head prog) -ctx-))
              (set prog (get/tail prog)))
            (debug-print "let vm-function is setting var "var" to value "tmp" in context "-ctx-)
            (set (array-at locals (unbox <long> (<variable>-index var))) tmp))))
      (set tmp ())
      (list-do exp body
        (set tmp (eval exp -ctx-)))
      tmp)))

(define-vm-function (set () fixed) ((var <variable>) value-form)
  (debug-print "SET "var" = "value-form" IN "-ctx-)
  (gc/let* ((value (eval value-form -ctx-)))
    (if (global-variable? var)
        (set (<variable>-value var) value)
      (let ((delta (- (unbox <long> (<env>-level (<context>-env -ctx-)))
                  (unbox <long> (<env>-level (<variable>-env var))))))
        (debug-print "set vm-function is writing local var "var" with delta "(box <long> delta))
        (while (< 0 delta)
          (set -ctx- (<context>-home -ctx-))
          (decr delta))
        (let ((index (unbox <long> (<variable>-index var))))
          (debug-print "set vm-function is setting local var in context "-ctx-" at index "(box <long> index)", to value "value)
          (set (array-at (<context>-bindings -ctx-) index) value))))))

(define-vm-function (while () fixed) _
  (let ((test	(car -args-))
        (prog	-args-))
    (while (eval test -ctx-)
      (let ((body prog))
        (while (pair? (set body (cdr body)))
          (eval (get/head body) -ctx-))))))

(define-vm-function (if () fixed) (test then . else)
  (if (eval test -ctx-)
      (eval then -ctx-)
    (let ((ans ()))
      (while (pair? else)
        (set ans (eval (get/head else) -ctx-))
        (set else (cdr else)))
      ans)))

(define-vm-function (or () fixed) _
  (let ((ans ()))
    (while (pair? -args-)
      (and (set ans (eval (get/head -args-) -ctx-))
           (return ans))
      (set -args- (get/tail -args-)))))

(define-vm-function (and () fixed) _
  (let ((ans symbol/true))
    (while (pair? -args-)
      (or (set ans (eval (get/head -args-) -ctx-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-vm-function (quote () fixed) (thing)
  thing)

(define-vm-function (not ()) (thing)
  (if thing () symbol/true))

;;;
;;; boxed words
;;;
;;; <u64> has a single cell on a 64-bit image, and two cells on a 32-bit
;;; one (low half first), so that a 32-bit image can carry the target's
;;; 64-bit words. The helpers below are compiled into the image; their
;;; bodies are lower-realm code, hence the raw operators.

;; unsigned comparison in the lower realm, where < is signed
(define-function %unsigned-< (a b)
  (let ((sign-bit (bitwise-shift 1 (- target/cell-size/bits 1))))
    (< (bitwise-xor a sign-bit) (bitwise-xor b sign-bit))))

(define-function %u64-lo (x)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (unbox <u64> x)
    (oop-at x 0)))

(define-function %u64-hi (x)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (error "%u64-hi: called on a single-cell <u64>")
    (oop-at x 1)))

(define-function %make-u64 (lo hi)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> lo)
    (%allocate-two-cell-word <u64> lo hi)))

(define-function %u32-mask ()
  (- (bitwise-shift 1 32) 1))

(define-function %make-u32 (value)
  (box <u32> (bitwise-and value (%u32-mask))))

(define-function %long->u32 (x)
  (%make-u32 (unbox <long> x)))

(define-function %long->u64 (x)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (unbox <long> x))
    (%make-u64 (unbox <long> x) 0)))

(define-function %u32->u64 (x)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (unbox <u32> x))
    (%make-u64 (unbox <u32> x) 0)))

(define-function %numeric? (x)
  (or (is <long> x) (is <u32> x) (is <u64> x)))

(define-function %to-u32 (x)
  (cond
    ((is <u32> x) x)
    ((is <long> x) (%long->u32 x))
    (else (error "%to-u32: not a number: " x))))

(define-function %to-u64 (x)
  (cond
    ((is <u64> x) x)
    ((is <u32> x) (%u32->u64 x))
    ((is <long> x) (%long->u64 x))
    (else (error "%to-u64: not a number: " x))))

;; interpreter-facing constructors; the high half is ignored on a
;; 64-bit image, where a single cell holds the whole word.
(define-vm-function (make-u32 ()) ((value <long>))
  (%make-u32 value))

(define-vm-function (make-u64 ()) ((lo <long>) (hi <long> 0))
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (bitwise-or lo (bitwise-shift hi 32)))
    (%allocate-two-cell-word <u64> lo hi)))

;;; u32 (one cell)

(define-function %u32-add (a b)
  (%make-u32 (bitwise-and (+ (unbox <u32> a) (unbox <u32> b))
                          (%u32-mask))))

(define-function %u32-sub (a b)
  (%make-u32 (bitwise-and (- (unbox <u32> a) (unbox <u32> b))
                          (%u32-mask))))

(define-function %u32-mul (a b)
  (%make-u32 (bitwise-and (* (unbox <u32> a) (unbox <u32> b))
                          (%u32-mask))))

;; NOTE signed division: exact only while the operands fit in a signed
;; word; the interpreter's uses are small counts.
(define-function %u32-div (a b)
  (%make-u32 (/ (unbox <u32> a) (unbox <u32> b))))

(define-function %u32-and (a b)
  (%make-u32 (bitwise-and (unbox <u32> a) (unbox <u32> b))))

(define-function %u32-or (a b)
  (%make-u32 (bitwise-or (unbox <u32> a) (unbox <u32> b))))

(define-function %u32-xor (a b)
  (%make-u32 (bitwise-xor (unbox <u32> a) (unbox <u32> b))))

(define-function %u32-not (a)
  (%make-u32 (bitwise-and (bitwise-not (unbox <u32> a))
                          (%u32-mask))))

(define-function %u32-= (a b)
  (= (unbox <u32> a) (unbox <u32> b)))

(define-function %u32-unsigned-< (a b)
  (%unsigned-< (unbox <u32> a) (unbox <u32> b)))

;;; u64 (one or two cells)

(define-function %u64-add (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (+ (unbox <u64> a) (unbox <u64> b)))
    (let* ((alo	(%u64-lo a))
           (blo	(%u64-lo b))
           (lo	(+ alo blo))
           (carry	(if (%unsigned-< lo alo) 1 0)))
      (%make-u64 lo (+ (%u64-hi a) (+ (%u64-hi b) carry))))))

(define-function %u64-sub (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (- (unbox <u64> a) (unbox <u64> b)))
    (let* ((alo	(%u64-lo a))
           (blo	(%u64-lo b))
           (borrow	(if (%unsigned-< alo blo) 1 0))
           (lo	(- alo blo)))
      (%make-u64 lo (- (%u64-hi a) (+ (%u64-hi b) borrow))))))

(define-function %u64-mul (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (* (unbox <u64> a) (unbox <u64> b)))
    (let ((alo (%u64-lo a))
          (blo (%u64-lo b)))
      (unless (and (= 0 (%u64-hi a)) (= 0 (%u64-hi b)))
        (error "64-bit multiplication is not supported on a 32-bit image"))
      ;; NOTE exact only while the product fits in the low cell.
      (%make-u64 (* alo blo) 0))))

;; NOTE signed division: exact only while the operands fit in a signed
;; word; the interpreter's uses are small counts.
(define-function %u64-div (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (/ (unbox <u64> a) (unbox <u64> b)))
    (let ((alo (%u64-lo a))
          (blo (%u64-lo b)))
      (unless (and (= 0 (%u64-hi a)) (= 0 (%u64-hi b)))
        (error "64-bit division is not supported on a 32-bit image"))
      (%make-u64 (/ alo blo) 0))))

(define-function %u64-and (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (bitwise-and (unbox <u64> a) (unbox <u64> b)))
    (%make-u64 (bitwise-and (%u64-lo a) (%u64-lo b))
               (bitwise-and (%u64-hi a) (%u64-hi b)))))

(define-function %u64-or (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (bitwise-or (unbox <u64> a) (unbox <u64> b)))
    (%make-u64 (bitwise-or (%u64-lo a) (%u64-lo b))
               (bitwise-or (%u64-hi a) (%u64-hi b)))))

(define-function %u64-xor (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (bitwise-xor (unbox <u64> a) (unbox <u64> b)))
    (%make-u64 (bitwise-xor (%u64-lo a) (%u64-lo b))
               (bitwise-xor (%u64-hi a) (%u64-hi b)))))

(define-function %u64-not (a)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (box <u64> (bitwise-not (unbox <u64> a)))
    (%make-u64 (bitwise-not (%u64-lo a))
               (bitwise-not (%u64-hi a)))))

(define-function %u64-= (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (= (unbox <u64> a) (unbox <u64> b))
    (and (= (%u64-lo a) (%u64-lo b))
         (= (%u64-hi a) (%u64-hi b)))))

(define-function %u64-unsigned-< (a b)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (%unsigned-< (unbox <u64> a) (unbox <u64> b))
    (let ((ahi (%u64-hi a))
          (bhi (%u64-hi b)))
      (if (= ahi bhi)
          (%unsigned-< (%u64-lo a) (%u64-lo b))
        (%unsigned-< ahi bhi)))))

;;; shifts

(define-function %raw-shl32 (x n)
  (if (<= 32 n)
      0
    (bitwise-and (arithmethic-shift-left x n) (%u32-mask))))

(define-function %raw-shr32 (x n)
  (if (<= 32 n)
      0
    (bitwise-and (arithmethic-shift-right x n)
                 (- (bitwise-shift 1 (- 32 n)) 1))))

(define-function %u32-shift (x n)
  (%make-u32 (if (< n 0)
                 (%raw-shr32 (unbox <u32> x) (- n))
               (%raw-shl32 (unbox <u32> x) n))))

(define-function %u64-shift (x n)
  (if-at-expand (single-cell-boxed-type? <u64>)
      (let ((raw (unbox <u64> x)))
        (if (< n 0)
            (let ((m (- n)))
              (if (<= 64 m)
                  (box <u64> 0)
                (box <u64> (bitwise-and (arithmethic-shift-right raw m)
                                        (- (bitwise-shift 1 (- 64 m)) 1)))))
          (if (<= 64 n)
              (box <u64> 0)
            (box <u64> (arithmethic-shift-left raw n)))))
    (let ((lo (%u64-lo x))
          (hi (%u64-hi x)))
      (if (< n 0)
          (let ((m (- n)))
            (cond
              ((<= 64 m) (%make-u64 0 0))
              ((<= 32 m) (%make-u64 (%raw-shr32 hi (- m 32)) 0))
              (else (%make-u64 (bitwise-or (%raw-shr32 lo m)
                                           (%raw-shl32 hi (- 32 m)))
                               (%raw-shr32 hi m)))))
        (cond
          ((<= 64 n) (%make-u64 0 0))
          ((<= 32 n) (%make-u64 0 (%raw-shl32 lo (- n 32))))
          (else (%make-u64 (%raw-shl32 lo n)
                           (bitwise-or (%raw-shl32 hi n)
                                       (%raw-shr32 lo (- 32 n))))))))))

;;; dispatch

(define-function %add (a b)
  (cond
    ((is <u64> a) (%u64-add a (%to-u64 b)))
    ((is <u64> b) (%u64-add (%to-u64 a) b))
    ((is <u32> a) (%u32-add a (%to-u32 b)))
    ((is <u32> b) (%u32-add (%to-u32 a) b))
    (else (box <long> (+ (unbox <long> a) (unbox <long> b))))))

(define-function %sub (a b)
  (cond
    ((is <u64> a) (%u64-sub a (%to-u64 b)))
    ((is <u64> b) (%u64-sub (%to-u64 a) b))
    ((is <u32> a) (%u32-sub a (%to-u32 b)))
    ((is <u32> b) (%u32-sub (%to-u32 a) b))
    (else (box <long> (- (unbox <long> a) (unbox <long> b))))))

(define-function %mul (a b)
  (cond
    ((is <u64> a) (%u64-mul a (%to-u64 b)))
    ((is <u64> b) (%u64-mul (%to-u64 a) b))
    ((is <u32> a) (%u32-mul a (%to-u32 b)))
    ((is <u32> b) (%u32-mul (%to-u32 a) b))
    (else (box <long> (* (unbox <long> a) (unbox <long> b))))))

(define-function %div (a b)
  (cond
    ((is <u64> a) (%u64-div a (%to-u64 b)))
    ((is <u64> b) (%u64-div (%to-u64 a) b))
    ((is <u32> a) (%u32-div a (%to-u32 b)))
    ((is <u32> b) (%u32-div (%to-u32 a) b))
    (else (box <long> (/ (unbox <long> a) (unbox <long> b))))))

(define-function %lt (a b)
  (cond
    ((is <u64> a) (%u64-unsigned-< a (%to-u64 b)))
    ((is <u64> b) (%u64-unsigned-< (%to-u64 a) b))
    ((is <u32> a) (%u32-unsigned-< a (%to-u32 b)))
    ((is <u32> b) (%u32-unsigned-< (%to-u32 a) b))
    (else (< (unbox <long> a) (unbox <long> b)))))

(define-function %eq (a b)
  (cond
    ((is <u64> a) (%u64-= a (%to-u64 b)))
    ((is <u64> b) (%u64-= (%to-u64 a) b))
    ((is <u32> a) (%u32-= a (%to-u32 b)))
    ((is <u32> b) (%u32-= (%to-u32 a) b))
    ((and (is <long> a) (is <long> b)) (= (unbox <long> a) (unbox <long> b)))
    (else ())))

(define-function %le (a b) (or (%lt a b) (%eq a b)))
(define-function %gt (a b) (%lt b a))
(define-function %ge (a b) (%le b a))

(define-function %bitand (a b)
  (cond
    ((is <u64> a) (%u64-and a (%to-u64 b)))
    ((is <u64> b) (%u64-and (%to-u64 a) b))
    ((is <u32> a) (%u32-and a (%to-u32 b)))
    ((is <u32> b) (%u32-and (%to-u32 a) b))
    (else (box <long> (bitwise-and (unbox <long> a) (unbox <long> b))))))

(define-function %bitor (a b)
  (cond
    ((is <u64> a) (%u64-or a (%to-u64 b)))
    ((is <u64> b) (%u64-or (%to-u64 a) b))
    ((is <u32> a) (%u32-or a (%to-u32 b)))
    ((is <u32> b) (%u32-or (%to-u32 a) b))
    (else (box <long> (bitwise-or (unbox <long> a) (unbox <long> b))))))

(define-function %bitxor (a b)
  (cond
    ((is <u64> a) (%u64-xor a (%to-u64 b)))
    ((is <u64> b) (%u64-xor (%to-u64 a) b))
    ((is <u32> a) (%u32-xor a (%to-u32 b)))
    ((is <u32> b) (%u32-xor (%to-u32 a) b))
    (else (box <long> (bitwise-xor (unbox <long> a) (unbox <long> b))))))

;; -, +, *, and / all have some peculiarities that makes them somewhat resistant to macrology
;; TODO these silently ignore non-pair values in cdr position
(define-vm-function (- ()) _
  (cond
    ((and -args- (pair? (get/tail -args-)))
     (let ((value (pop -args-)))
       (while -args-
         (set value (%sub value (pop -args-))))
       value))
    (-args-	(%sub (box <long> 0) (pop -args-)))
    (else	(box <long> 0))))

(define-vm-function (+ ()) _
  (let ((value (box <long> 0)))
    (while -args-
      (set value (%add value (pop -args-))))
    value))

(define-vm-function (/ ()) _
  (if -args-
      (let ((value (pop -args-)))
        (while -args-
          (set value (%div value (pop -args-))))
        value)
    (error "operator '/' needs at least one argument")))

(define-vm-function (* ()) _
  (let ((value (box <long> 1)))
    (while -args-
      (set value (%mul value (pop -args-))))
    value))

(define-form define-bitwise-operator (op helper)
  `(define-vm-function (,op ()) _
     (or -args- (error ,(concat-strings "operator '"(symbol->string op)"': called with zero arguments")))
     (let ((value (pop -args-)))
       (while -args-
         (set value (,helper value (pop -args-))))
       value)))

(define-bitwise-operator bitwise-and %bitand)
(define-bitwise-operator bitwise-or %bitor)
(define-bitwise-operator bitwise-xor %bitxor)

(define-vm-function (bitwise-not ()) _
  (or -args- (error "operator 'bitwise-not': called with zero arguments"))
  (let ((value (pop -args-)))
    (cond
      ((is <u64> value) (%u64-not value))
      ((is <u32> value) (%u32-not value))
      (else (box <long> (bitwise-not (unbox <long> value)))))))

(define-vm-function (bitwise-shift ()) ((value _) (shift <long>))
  (cond
    ((is <u64> value) (%u64-shift value shift))
    ((is <u32> value) (%u32-shift value shift))
    (else (box <long> (bitwise-shift (unbox <long> value) shift)))))

(define-form define-relation (op helper)
  `(define-vm-function (,op ()) _
     (unless -args-
       (return symbol/true))
     (let ((current	(pop -args-))
           next)
       (while -args-
         (let ((next (pop -args-)))
           (unless (,helper current next)
             (return false))
           (set current next)))
       symbol/true)))

(define-relation < %lt)
(define-relation <= %le)
(define-relation >= %ge)
(define-relation > %gt)

;; FIXME restore arity check
(define-vm-function (= ()) _
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-))))
    (to-upper-boolean
     (cond
       ((is <u64> lhs) (and (%numeric? rhs) (%u64-= lhs (%to-u64 rhs))))
       ((is <u64> rhs) (and (%numeric? lhs) (%u64-= (%to-u64 lhs) rhs)))
       ((is <u32> lhs) (and (%numeric? rhs) (%u32-= lhs (%to-u32 rhs))))
       ((is <u32> rhs) (and (%numeric? lhs) (%u32-= (%to-u32 lhs) rhs)))
       ((is <long> lhs) (and (long? rhs) (= (unbox <long> lhs) (unbox <long> rhs))))
       ((is <string> lhs) (and (string? rhs) (= 0 (string-compare lhs rhs))))
       (else (= lhs rhs))))))

(define-vm-function (exit ()) ((exit-code <long> 0))
  (when-at-expand (feature profiler)
    (profiler/disable))
  (platform/flush-streams)
  (platform/halt exit-code))

(define-vm-function (warn ()) _
  (list-do arg -args-
    (do-print *error-output* arg false))
  (platform/flush-streams))

(define-vm-function (type-of ())	(thing) (box <long> (type-of thing)))
(define-vm-function (string? ())	(thing) (and (string? thing) symbol/true))
(define-vm-function (symbol? ())	(thing) (and (symbol? thing) symbol/true))
(define-vm-function (pair?   ())	(thing) (and (pair?   thing) symbol/true))
(define-vm-function (array?  ())	(thing)	(and (array?  thing) symbol/true))

(define-vm-function set-car ((pair <pair>) value)
  (set (<pair>-head pair) value))

(define-vm-function set-cdr ((pair <pair>) value)
  (set (<pair>-tail pair) value))

(with-forms
    ((with-bounds-checking
         (body
          `(begin
            (safety 2 (let ((header (gc/header-of base)))
                        (assert (and (gc/valid-header-canary? header)
                                     (<= 0 cellindex)
                                     (<= (words-to-bytes (+ 1 cellindex)) (<header>-size header)))
                                "[set-]oop-at: trying to access beyond the gc chunk boundaries")
                        (assert (not (bitwise-and (<header>-flags header) <header>-flags/opaque))
                                "[set-]oop-at: trying to access an opaque object")))
            ,@body))))

  (define-vm-function (oop-at ()) (base (cellindex <long>))
    (with-bounds-checking
      (oop-at base cellindex)))

  (define-vm-function (set-oop-at ()) (base (cellindex <long>) value)
    (with-bounds-checking
      (set (oop-at base cellindex) value))))

(define-vm-function lower-cell->long ((value <lower-cell>))
  ;; this is potentially a lossy conversion, depending on the chosen
  ;; representation of <long>. when <long> is a tagged immediate, then
  ;; this loses some bits of precision from the high end, typically
  ;; just one bit, though.
  (box <long> value))

(define-vm-function long->lower-cell ((value <long>))
  (box <lower-cell> value))

;; (define-vm-function (copy-oops ()) (from to (wordcount <long>))
;;   (error "copy-oops: who called me in interpreted code?! TODO i need proper bounds checking added.")
;;   (copy-oops from to wordcount))

(define-vm-function (array-length ()) ((arg <array>))
  (<array>-size arg))

(define-vm-function (string-length ()) ((arg <string>))
  (<string>-size arg))

(define-vm-function (string-compare ()) ((s1 <string>) (s2 <string>)))

(define-vm-function (array-at ()) ((array <array>) (index <long>))
  (array-at array index))

(define-vm-function (string-at ()) ((string <string>) (index <long>))
  (box <long> (string-at string index)))

;; adding [set-]char-at to the evaluator makes it source-level compatible with the level-shifted code, and with that enables us to load files like buffer.l into both worlds
(define-vm-function (char-at ()) ((string <string>) (index <long>))
  (box <long> (string-at string index)))

(define-vm-function (set-array-at ()) ((array <array>) (index <long>) value)
  (set-array-at array index value))

(define-vm-function (set-string-at ()) ((string <string>) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 2 (assert (<= index (string-length string))))
  (set-string-at string index value)
  (box <long> value))

(define-vm-function (set-char-at ()) ((string <string>) (index <long>) (value <long>))
  ;; NOTE set-string-at happily extends the string with a gap of zeores, so
  ;; we also assert here that idx is out of bounds at most by +1.
  (safety 2 (assert (<= index (string-length string))))
  (safety 2 (assert (and (<= value 256) (<= 0 value)) "set-char-at: value is out of range: "(box <long> value)))
  (set-string-at string index value)
  (box <long> value))

(define-vm-function (array-insert ()) ((array <array>) (index <long>) value))

(define-vm-function (string-insert ()) ((string <string>) (index <long>) (value <long>))
  (safety 2 (assert (and (<= value 256) (<= 0 value)) "string-insert: value is out of range: "(box <long> value)))
  (string-insert string index value)
  (box <long> value))

(define-vm-function (array-append ()) ((array <array>) value))

(define-vm-function (string-append ()) ((string <string>) (value <long>))
  (safety 2 (assert (and (<= value 255) (<= 0 value)) "string-append: value is out of range: "(box <long> value)))
  (box <long> (string-append string value)))

(define-vm-function number->string ((num <long>) (radix <long> 10))
  (long->string* num radix))

(define-vm-function integer->string ((num <long>) (radix <long> 10))
  (long->string* num radix))

(define-vm-function string->number ((str <string>) (radix <long> 10))
  (let ((res (string->long* str radix)))
    (when (= res +end+)
      (error "string->number: failed for "str))
    (box <long> res)))

(define-vm-function string->integer ((str <string>) (radix <long> 10))
  (let ((res (string->long* str radix)))
    (when (= res +end+)
      (error "string->integer: failed for "str))
    (box <long> res)))

;; TODO delme; instead somehow export $put-all as a selector into the upper
(define-vm-function lower/$put-all (stream thing)
  ($put-all stream thing))

(define-vm-function pointer->target-function (ptr)
  (make <target-function>
    (program-code ptr)))

(when-at-expand (= target/arch 'x86-32)
  (define-vm-function call-x86-32-machine-code (fn)
    (debug-print "call-x86-32-machine-code will call "fn)
    (assert (is <target-function> fn) "call-x86-32-machine-code: cannot call object of type "(type-of fn)", printing as "fn)
    (let ((result (box <long> (fn))))
      (debug-print "call-x86-32-machine-code got back the control from "fn)
      result)))

(when-at-expand (= target/arch 'x86-64)
  (define-vm-function call-x86-64-machine-code (fn)
    (debug-print "call-x86-64-machine-code will call "fn)
    (assert (is <target-function> fn) "call-x86-64-machine-code: cannot call object of type "(type-of fn)", printing as "fn)
    (let ((result (box <long> (fn))))
      (debug-print "call-x86-64-machine-code got back the control from "fn)
      result)))

(when-at-expand (feature debug-output)
  (define-vm-function enable-debug-output	() (set *debug-output-enabled?* true))
  (define-vm-function disable-debug-output	() (set *debug-output-enabled?* false)))

;; FIXME WHEN-AT-EXPAND body loses toplevelness, so it must be outside of it
(define-form with-open-pipe (args . body)
  (let ((read-fd-name  (pop args))
        (write-fd-name (pop args)))
    `(let* ((__fds__ (posix/pipe*))
            (,read-fd-name  (unbox <long> (car __fds__)))
            (,write-fd-name (unbox <long> (cdr __fds__))))
       ,@body)))

;; FIXME: why do i need the HOST-VALUE here?! WHEN-AT-EXPAND should be
;; evaluating in the slave env, where the unwrapped DEFINED? should
;; just work. instead i get: form encountered in interpreted code with
;; args ((oop-at.0+29 obj.2+0 0) 1)
(when-at-expand (and (feature memory-block)
                     (host-value (defined? 'posix/spawn-program *target-env*)))

(define-vm-function spawn-program ((path <string>)
                                   argv envp
                                   (stdout-fd <long> -1) (stderr-fd <long> -1))
  (safety 2 (or (not argv) (pair? argv) (is <array> argv) (error "spawn-program: argv is of type " (type-of argv))))
  ;; TODO actually use envp
  (let ((argv/lower (to-C-strings argv 1))
        (path/lower (string->C-string path)))
    ;; argv[0] is the path of the binary
    (set (oop-at (<memory-block>-elements argv/lower) 0) path/lower)
    ;; NULL terminated
    (let ((i (bytes-to-words (memory-block/length argv/lower))))
      ;; TODO use cell-at here
      (memory-block/ensure-size/cell argv/lower i)
      (set (oop-at (<memory-block>-elements argv/lower) i) 0))

    (box <long> (posix/spawn-program path/lower
                                     (<memory-block>-elements argv/lower)
                                     (posix/envp)
                                     stdout-fd
                                     stderr-fd))))

(define-function waitpid-or-die (child-pid)
  (let ((exit-code (posix/waitpid child-pid 0)))
    (unless (= 0 exit-code)
      (error "spawn-program returned exit code: "(box <long> exit-code)))
    (box <long> exit-code)))

(define-function run-program/stdout/slurp (path argv envp)
  (with-open-pipe (stdout-read-fd stdout-write-fd)
    (let ((child-pid (unbox <long> (spawn-program path argv envp
                                                  stdout-write-fd -1))))
      (posix/close stdout-write-fd)

      (let ((result (string 16))
            char)
        (while (<= 0 (set char (posix/read-byte stdout-read-fd)))
          (string-append result char))

        (posix/close stdout-read-fd)
        (waitpid-or-die child-pid)
        result))))

(define-function run-program/stdout/file (path argv envp stdout-path)
  (let* ((stdout-fd (posix/open stdout-path
                                (bitwise-or (bitwise-or posix/O_WRONLY
                                                        posix/O_CREAT)
                                            posix/O_TRUNC)
                                posix/default-file-mode))
         (child-pid (unbox <long> (spawn-program path argv envp
                                                 stdout-fd -1))))
    (posix/close stdout-fd)
    (waitpid-or-die child-pid)))

(define-vm-function (run-program ()) _
  (let* ((path (or (pop -args-)
                   (error "run-program/capture: path is mandatory")))
         (argv (pop -args-))
         (envp (pop -args-))
         (stdin  (pop -args-))          ; TODO
         (stdout (pop -args-))
         (stderr (pop -args-))          ; TODO
         )
    (set envp 0)            ; TODO
    (cond
      ((string? stdout)
       (run-program/stdout/file path argv envp (string->C-string stdout)))
      ;; TODO replace when we can emit symbols: (= 'string stdout)
      ((and (symbol? stdout)
            (string= "string" (symbol->string stdout)))
       (run-program/stdout/slurp path argv envp))
      ((= () stdout)
       (waitpid-or-die
        (unbox <long> (spawn-program path argv envp -1 -1))))
      (else (error "run-program: unexpected stdout value: "stdout)))))
)
