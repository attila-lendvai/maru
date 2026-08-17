;;; -*- mode: lisp; coding: us-ascii -*-

;; 2025-07 status
;; llvm
;; *** FAILURE form: (equal (list 11 22 33 42) (closure))
;; x86
;; *** FAILURE form: (equal (list 11 22 33 42) (closure))
;; *** FAILURE form: (< 0 (bitwise-shift 268435455 4))
;; *** FAILURE form: (= -5 (/ -1000 20 10))
;; *** FAILURE form: (= -5 (/ 1000 -20 10))


(require "tests/infra.l")

(define-test eval/arithmetic/- ()
  (test-assert (= -42 (- 42)))
  (test-assert (= 0   (- 2 2)))
  (test-assert (= -3  (- 2 2 3))))

(define-test eval/arithmetic/+ ()
  (test-assert (= 0 (+)))
  (test-assert (= 42 (+ 42)))
  (test-assert (= 42 (+ 40 2)))
  (test-assert (= 42 (+ 20 21 1))))

(define-test eval/arithmetic// ()
  (test-assert (= 1   (/ 1)))
  (test-assert (= 100 (/ 1000 10)))
  (test-assert (= 5   (/ 1000 20 10)))
  ;; FIXME division is unsigned in the x86 backend
  (test-assert (= -5  (/ -1000 20 10)))
  (test-assert (= -5  (/ 1000 -20 10)))
  )

(define-test eval/arithmetic/* ()
  (test-assert (= 1   (*)))
  (test-assert (= 42  (* 42)))
  (test-assert (= 24  (* 1 2 3 4)))
  (test-assert (= -24  (* 1 -2 3 4)))
  )

(define-test eval/arithmetic/logic ()
  (test-assert (= 42		(bitwise-or 42)))
  (test-assert (= 3		(bitwise-or 1 2 3)))
  (test-assert (= 42		(bitwise-and 42)))
  (test-assert (= 0x01234567	(bitwise-and 0x01234567 0x0fffffff)))
  (test-assert (= 0xa		(bitwise-and 0x2a 0xff 0xf)))
  (test-assert (= 0xff		(bitwise-xor 0xff)))
  (test-assert (= 0xef		(bitwise-xor 0xff 0x11 0x1)))
  )

(define-test eval/arithmetic/shift ()
  (test-assert (= 0xffffff	(bitwise-shift 0xffffff0 -4)))
  (test-assert (= 1		(bitwise-shift 0xfffffff -27)))
  (test-assert (= 0		(bitwise-shift 0xfffffff -28)))
  (test-assert (= 0xffffff0	(bitwise-shift 0xffffff 4)))
  (test-assert (= 0		(bitwise-shift 0xffffff0 10000)))
  (test-assert (= 0		(bitwise-shift 0xffffff0 -10000)))
  (test-assert (= -1		(bitwise-shift -1 -100)))
  ;; on 32 bit: shifting a positive number into the sign bit
  (test-assert (< 0		(bitwise-shift 0xfffffff 4)))
  ;; on 64 bit platforms a 65 bit shift should zero the place
  (test-assert (= 0		(bitwise-shift 0xfffffff 65)))
  )

(define-test eval/equality/string ()
  (test-assert (=  "alma" "alma"))
  (test-assert (!= "alma" "korte"))
  (test-assert (not (!= "alma" "alma")))
  (test-assert (!= "foo" 'foo)))

(define-test eval/for/1 ()
  (let ((x ()))
    (for (i 5 0 -1)
      (push x i))
    (test-assert (equal x '(1 2 3 4 5))))
  (let ((x ()))
    (times-do 3
      (push x 42))
    (test-assert (equal x '(42 42 42)))))

(define-test eval/apply/bug/1 ()
  (let ((compose (lambda (a b c)
                   (lambda (x y)
                     (list a b c x y)))))
    ;; it returns (42 43 3 42 43) in piumarta's eval.l, but not in eval.c
    (test-assert (equal ((compose 1 2 3) 42 43) '(1 2 3 42 43)))))

(define-test eval/apply/1 ()
  (test-assert (equal (apply - '(1 2 3)) -4))
  (test-assert (equal (map (lambda args (apply ensure-list args)) '(1 2 3))
                      '((1) (2) (3))))
  (test-assert (equal (map (lambda args (first (apply ensure-list args))) '(1 (x 2) 3))
                      '(1 x 3)))
  (test-assert (equal ((lambda args (first (apply ensure-list args))) 42)
                      42))
  (let ((fn (lambda args (first (apply ensure-list args)))))
    (test-assert (equal (fn 42) 42)))
  (let* ((a ensure-list)
         (b first)
         (fn (lambda args (b (apply a args)))))
    (test-assert (equal (fn 42) 42)))
  (let ((compose (lambda (a b)
                   (test-assert (is <expr> a))
                   (test-assert (= b first))
                   (lambda args
                     (test-assert (is <expr> a) "'a' is not an <expr> anymore?! it is: "a)
                     ;;(assert (is <expr> a) "'a' is not an <expr> anymore?! it is: "a)
                     (test-assert (= b first) "'b' is not 'first anymore, it's: "b)
                     (b (apply a args))))))
    ((compose ensure-list first) 42)
    (test-assert (equal ((compose ensure-list first) 42) 42)))
  (test-assert (equal ((compose ensure-list first) 42)
                      42))
  (test-assert (equal (map (compose ensure-list first) '(1 (x 2) 3))
                      '(1 x 3))))

(define-test eval/string/insert ()
  (let ((x "alma"))
    (string-insert x 2 ?z)
    (test-assert (= x "alzma"))
    (string-insert x 5 ?x)
    (test-assert (= x "alzmax")))
  (let ((x (string 8)))
    (string-append x ?y)
    (test-assert (= x "y"))))

(define-test eval/string/concat ()
  (test-assert (= "alma.x\x00y.korte"
                  (concat-strings "alma." "x\x00y" ".korte"))))

(define-test eval/string/output-stream ()
  (test-assert (= "xfooy"
                  (with-output-to-string (out)
                    ($put out ?x)
                    ($put-all out "foo")
                    ($put out ?y)))))

(define-test eval/string/bug/1 ()
  (let ((str (string)))
    (set (string-at str 0) ?a)
    (set (string-at str 1) ?l)
    (set (string-at str 2) ?m)
    (set (string-at str 3) ?a)
    (test-assert (= "alma" str))))

(define-test eval/array/insert ()
  (let ((x (list->array '(1 2 3 4))))
    (array-insert x 2 42)
    (test-assert (equal (array->list x) '(1 2 42 3 4)))
    (array-insert x 5 43)
    (test-assert (equal (array->list x) '(1 2 42 3 4 43)))))

(define-test eval/array/access ()
  (let ((x (list->array '(1 2 3 4))))
    (= 3 (array-at x 2))
    (set (array-at x 1) 42)
    (test-assert (equal (array->list x) '(1 42 3 4)))
    (set (array-at x 5) 99)
    (test-assert (equal (array->list x) '(1 42 3 4 () 99)))
    ;; access beyond size is valid and returns ()
    (test-assert (equal () (array-at x 1000)))
    ))

(define-function eval/let/1/helper (env)
  (let ((env env))
    (set env 42))
  env)

(define-test eval/let/1 ()
  (test-assert (= 9979 (eval/let/1/helper 9979))))

(define-test eval/let/2 ()
  ;; this is present in Piumarta's eval.l (but not in eval.c)
  (let ((x 42))
    (let ((x (+ x 1)))
      (test-assert (= x 43))
      (set x -1)
      (test-assert (= x -1)))
    (test-assert (= x 42))))

(define-test eval/let/3 ()
  (let ((x 42)
        (y (let ((foo 'bar))
             (set foo 99)
             foo)))
    (test-assert (= x 42))
    (test-assert (= y 99))))

;; (define-test eval/let/bug/2 ()
;;   ;; this is a bug present in the piumarta branch
;;   ;; this should error...
;;   (encode '(let ((x 42)
;;                  (y (+ x 1))))))

;; this should probably throw an error like in CL
;; (define-test eval/let/3 ()
;;   (let ((x 42))
;;     (let ((x -1000)
;;           (x (+ x 1)))
;;       (test-assert (= x 43))
;;       (set x -1)
;;       (test-assert (= x -1)))
;;     (test-assert (= x 42))))

(define-test eval/closures/bug/1 ()
  ;; this bug is present in the piumarta branch, both in eval.c and eval.l
  (let ((closure (let ((a 11)
                       (b 22)
                       (c 33)
                       (x 42))
                   (lambda ()
                     (list a b c x)))))
    ;;(println (closure))
    (test-assert (equal (list 11 22 33 42) (closure)))
    (let ((y -1)
          (z))
      ;; (println (closure)) currently print '(-1 () 3 42)
      ;; i.e. the places captured by the closure are overwritten by
      ;; the second LET.
      )
    (test-assert (equal (list 11 22 33 42) (closure)))))

(define-form eval/expand/bug/1/helper-form (val)
  `(zork ,val))

(define-test eval/expand/bug/1 ()
  ;; this bug is inherited from Piumarta's work, both eval.c and eval.l has them.
  ;; the bug is that expand mindlessly expands the bindings of a let form as if they were call forms
  ;; is this a bug to be fixed? or a semantics to live with?
  ;; maybe the fix is that expand and encode should be merged and descend recursively in one pass?
  (let ((zork 42)
        (eval/expand/bug/1/helper-form -1))
    (test-assert (= <long> (type-of eval/expand/bug/1/helper-form)))
    (test-assert (= 42 zork))
    (test-assert (= -1 eval/expand/bug/1/helper-form))))

(define-test eval/expand/bug/2 ()
  (test-assert (= 42 ((lambda (eval/expand/bug/1/helper-form y)
                        (+ eval/expand/bug/1/helper-form
                           y))
                      40 2))))

(define-symbol-form *symform* '(another-form))
(define-form another-form () 42)

(define-test eval/expand/bug/3 ()
  (test-assert (= 42 (expand '*symform*)))
  (test-assert (equal '(set 42 43) (expand '(set *symform* 43)))))

(define-constant a-global-constant 42)

(define-test eval/expand/symbol-macro-and-let ()
  (let ((a-global-constant 43))
    (test-assert (= 42 a-global-constant))))

(define-form place-for-set-test (str i)
  `(accessor-for-set-test ,str ,i))

(define-form accessor-for-set-test (str i)
  `(char-at ,str ,i))

(define-form set-accessor-for-set-test (str i v)
  `(set (char-at ,str ,i) ,(if (= i 1)
                               ?j ; a joker that writes ?j at index 1, no matter what
                             v)))

;; expand needs to check for a set-foo form at every step while expanding, and do
;; the set-conversion as early as a set-foo is available.
(define-test eval/expand/set-forms/1 ()
  (let ((str "abcd"))
    (test-assert (= ?c (place-for-set-test str 2)))
    (set (place-for-set-test str 2) ?x)
    (test-assert (= str "abxd"))
    (set (place-for-set-test str 1) ?x)
    (test-assert (= str "ajxd")) ; "axxd" if SET-ACCESSOR-FOR-SET-TEST is not picked up by EXPAND
    ))

;; TODO should this work? i think it should...
;; (define-form eval/expand/bug/4-helper (base-name)
;;   (with-forms ((name ((suffix) (concat-symbol base-name suffix))))
;;     `(begin ,(name bar))))

;; (define-test eval/expand/bug/4 ()
;;   (let ((foobar 42))
;;     (test-assert (= 42 (eval/expand/bug/4-helper foo)))))

;; FIXME when it's wrapped into a when-at-expand, then the form is not
;; visible at expansion time. IOW, losing toplevelness results in
;; losing serial evaluation.
;;
;; (when-at-expand true
;;   (define-form cond-expand-helper _
;;     true)
;;
;;   (define-test eval/expand/form-at-cond-condition ()
;;     (test-assert (cond
;;                    (false 0)
;;                    ((cond-expand-helper) 42)
;;                    (else 0))
;;                  42)))

(define *a-global-holding-42* 42)

(define-test eval/let/hiding-a-global ()
  (let ((*a-global-holding-42* 999))
    (test-assert (= 999 *a-global-holding-42*))
    (incr *a-global-holding-42*)
    (test-assert (= 1000 *a-global-holding-42*)))
  (test-assert (= 42 *a-global-holding-42*)))

(define-form %_eval-at-expand-time body
  (eval `(let ()
           ,@body)))

(define *a-global-visible-at-expand-time* 1)

(define-test eval/bug/eval-at-expand-time ()
  (%_eval-at-expand-time
   (if *a-global-visible-at-expand-time*
       (define-form eval/bug/at-expand-time/true ()
         43)
     (define-function eval/bug/at-expand-time/false ()
       42)))
  (test-assert (= 43 (eval/bug/at-expand-time/true)))
  (test-assert (= () eval/bug/at-expand-time/false)))

(define-test eval/if-at-expand/1 ()
  (let ((x 999)
        (< (lambda args (error "this should not be visible inside if-at-expand at expand time"))))
    (if-at-expand (< 5 4)
        (this form should be dropped as if it wasnt even here)
      (incr x))
    (test-assert (= x 1000))))

(define-generic test-generic)
(define-record <test-generic-1> () ())
(define-record <test-generic-2> <test-generic-1> ())

(define-multimethod test-generic ((<pair> a) (<long> b) (<long> c))
  (list <pair> a <long> b <long> c))

(define-multimethod test-generic ((<pair> a) b (<long> c))
  (list <pair> a () b <long> c))

(define-multimethod test-generic ((<pair> a) b (() c))
  (list <pair> a () b () c))

(define-multimethod test-generic ((<pair> a) (<pair> b) (() c))
  (list <pair> a <pair> b () c))

(define-multimethod test-generic ((<pair> a) (<test-generic-1> b) c)
  (list <pair> a <test-generic-1> b () c))

(define-multimethod test-generic ((<long> a) (<test-generic-1> b) (<long> c))
  (list <long> a <test-generic-1> b <long> c))

(define-multimethod test-generic (a (<test-generic-2> b) c)
  (list () a <test-generic-2> b () c))

(define-multimethod test-generic (a (<test-generic-2> b) (<long> c))
  (list () a <test-generic-2> b <long> c))

(define-multimethod test-generic ((<pair> a) (<test-generic-1> b) (<long> c))
  (list <pair> a <test-generic-1> b <long> c))

(define-multimethod test-generic ((<pair> a) (<test-generic-2> b) c)
  (list <pair> a <test-generic-2> b () c))

(define-test eval/multimethods/1 ()
  (test-assert (equal (list <pair> '(42) <long> 43    <long> 44)	(test-generic '(42) 43    44)))
  (test-assert (equal (list <pair> '(42) ()     "43"  <long> 44)	(test-generic '(42) "43"  44)))
  (test-assert (equal (list <pair> '(42) <pair> '(43) ()     44)	(test-generic '(42) '(43) 44)))
  (test-assert (equal (list <pair> '(42) <pair> '(43) ()     '(44))	(test-generic '(42) '(43) '(44))))
  (test-assert (equal (list <pair> '(42) ()     "43"  <long> 44)	(test-generic '(42) "43" 44)))

  (let ((tg1 (new <test-generic-1>))
        (tg2 (new <test-generic-2>)))
    (test-assert (equal (list <long>	42	<test-generic-1>	tg1	<long>	44)	(test-generic 42 tg1 44)))
    (test-assert (equal (list ()	42	<test-generic-2>	tg2	()	'(44))	(test-generic 42 tg2 '(44))))
    (test-assert (equal (list <long>	42	<test-generic-1>	tg2	<long>	44)	(test-generic 42 tg2 44)))
    (test-assert (equal (list ()	"42"	<test-generic-2>	tg2	<long>	44)	(test-generic "42" tg2 44)))
    (test-assert (equal (list <pair>	'(42)	<test-generic-2>	tg2	()	44)	(test-generic '(42) tg2 44)))
    (test-assert (equal (list <pair>	'(42)	<test-generic-1>	tg1	<long>	44)	(test-generic '(42) tg1 44)))
    ))

(define-type <a-type>)
(define-record <a-record-1> <a-type> (a b))
(define-record <a-record-2> <a-record-1> (c))

(define-method a-record-selector <a-record-1> ()
  (<a-record-1>-a self))

(define-method a-record-selector <a-record-2> ()
  (list (<a-record-1>-b self) (<a-record-2>-c self)))

(define-selector a-record-selector2)

(define-test eval/records/1 ()
  (test-assert (subtype? <a-record-2> <a-record-1>))
  (test-assert (subtype? <a-record-2> <a-type>))
  (let ((x (make <a-record-2>
             (a 'a)
             (b 'b)
             (c 'c))))
    (test-assert (equal 'a (<a-record-1>-a x)))
    (test-assert (equal 'b (<a-record-1>-b x)))
    (test-assert (equal 'c (<a-record-2>-c x)))
    (test-assert (equal 'a (a-record-selector (make <a-record-1>
                                                (a 'a)
                                                (b 'b)))))
    (test-assert (equal '(b c) (a-record-selector x)))
    ;; this should signal a proper error that no method was found, not die in some other way
    ;; (a-record-selector2 x)
    ))

(when-at-expand (defined? 'lower/array)
  (define-test lower/array/1 ()
    (let ((value 0x1122334455667788))
      ;; long - lower-cell conversion roundtrip
      (test-assert (= (lower-cell->long (long->lower-cell value))
                      value)))

    (let* ((arr	(lower/array 200))
           (x	(<lower/array>-elements arr)))

      ;; array is initialized to zero
      (test-assert (= (lower/array-at arr 0) 0))
      (test-assert (= (cell-at x 0) (long->lower-cell 0)))

      (set (cell-at x 0) 0x1122334455667788)
      (set (cell-at x 7) 0)

      ;; FIXME this assumes little endian
      (test-assert (= (cell-at x 0) (long->lower-cell 0x0022334455667788)))
      (test-assert (= (cell-at x 1) (long->lower-cell 0x0000223344556677)))
      (test-assert (= (cell-at x 2) (long->lower-cell 0x0000002233445566)))
      ))

  (define-test lower/array/2 ()
    (let ((x (lower/array 200))
          (limit 50000))
      (for (i 0 limit)
        (set (lower/array-at x i) 42))
      (test-assert (= limit (lower/array-length x)))
      (test-assert (= 42 (lower/array-at x 0)))
      (test-assert (= 42 (lower/array-at x (- limit 1))))
      )))

(define-function many-args (x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16)
  (+ x1 x10 x16))

(define-test arguments/many/1 ()
  (test-assert (= 27 (many-args 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16))))

(run-tests)
