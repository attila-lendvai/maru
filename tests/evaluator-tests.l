;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")
(require "source/streams.l")

(define *tests* ())

(define-form define-test (name args . body)
  (push *tests* name)
  `(define-function ,name ,args
     ,@body))

(define-form test-assert (condition . printing)
  `(unless ,condition
     (println "\n\n\033[1;31m*** FAILURE\033[0m form: " ',condition " " ,@printing)
     (println)))

(define-form run-tests ()
  (let ((tests *tests*)
        (test)
        (forms ()))
    (while (set test (first tests))
      (push forms `(,test))
      (set tests (rest tests)))
    `(let ()
       ,@forms)))

;;;
;;; Tests
;;;
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
  (test-assert (= 5   (/ 1000 20 10))))

(define-test eval/arithmetic/* ()
  (test-assert (= 1   (*)))
  (test-assert (= 42  (* 42)))
  (test-assert (= 24  (* 1 2 3 4))))

(define-test eval/arithmetic/shift ()
  (test-assert (= 0xffffff	(bitwise-shift 0xffffff0 -4)))
  (test-assert (= 1		(bitwise-shift 0xfffffff -27)))
  (test-assert (= 0		(bitwise-shift 0xfffffff -28)))
  (test-assert (= 0xffffff0	(bitwise-shift 0xffffff 4)))
  (test-assert (= 0		(bitwise-shift 0xffffff0 10000)))
  (test-assert (= 0		(bitwise-shift 0xffffff0 -10000)))
  (test-assert (= -1		(bitwise-shift -1 -100)))
  ;; shifting a positive number into the sign bit
  ;; FIXME
  (test-assert (< 0		(bitwise-shift 0xfffffff 4)))
  (test-assert (< 0		(bitwise-shift 0xfffffff 68))))

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
  (let ((closure (let ((x 42))
                   (lambda ()
                     x))))
    ;;(println (closure))
    (test-assert (= 42 (closure)))
    (let ((y -200))
      ;;(println (closure))
      (test-assert (= 42 (closure))))))

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

(define-function run-tests ()
  (println "\nAbout to run the interpreter tests.")
  (let ((tests *tests*)
        (test))
    (while (set test (pop tests))
      (print test ", ")
      (eval `(,test)))
    (println "\nFinished running the interpreter tests.")))

(run-tests)
