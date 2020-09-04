;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Tests for the compiler backends.
;;;
;;; This file is compiled the same way as eval.l is compiled.
;;;

(define *tests* ())

(define-form failure (format . args)
  `(let ()
     (libc/printf ,(concat-strings "\n\n\033[1;31m*** FAILURE\033[0m " format "\n") ,@args)
     (set *exit-code* -1)))

(define-form define-test (name form expected-value)
  (push *tests* name)
  (let ((name-as-string (symbol->string name)))
    `(define-function ,name ()
       (libc/printf ,(concat-strings name-as-string ", "))
       (let ((expected ,expected-value)
             (actual ,form))
         (if (not (= actual expected))
           ;; TODO ',form cannot be compiled yet
           (failure "%s, expected: %ld, actual: %ld" ,name-as-string expected actual)))
       ())))

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
;;;
;;; Actual artifacts that are meant to be level-shifted into the target
;;;
;;;
(compile-begin)

(define-foreign-functions/libc)

(define *exit-code* 0)

(define uninitialized-global)
(define global42 42)
(define globaltmp)

(define-function identity (x) x)

(define-function sum-of-three (x y z) (+ (+ x y) z))

;; TODO this doesn't even compile
;; (define-function compile/bug/push-root/helper/1 (x)
;;   (let ((x x))
;;     (set x 99))
;;   x)

;; (define-function compile/bug/push-root/helper/2 (x)
;;   (set x 99)
;;   (let ((x x))
;;     (return x)))

;; (define-test compile/bug/push-root
;;     (+ (compile/bug/push-root/helper/1 40)
;;        (compile/bug/push-root/helper/2 2))
;;   42)

(define-test compile/if/1
    (if target-boolean/false 342 343)
  343)

(define-test compile/if/2
    (if target-boolean/true
        (if target-boolean/false
            242
          244)
      243)
  244)

(define-test compile/local-call/1
    (sum-of-three 10 30 2)
  42)

(define-test compile/local-call/2
    (let ((local sum-of-three))
      (local 10 30 2))
  42)

(define-test compile/local-call/3
    (let ((buf (libc/malloc 16)))
      (set (oop-at buf 0) sum-of-three)
      ((oop-at buf 0) 10 30 2))
  42)

(define-test compile/foreign-function/1
    (libc/strcmp "bigyo" "bigyo")
  0)

(define-test compile/foreign-function/2
    (< 0 (libc/strcmp "foo" "bar"))
  target-boolean/true)

(define-test compile/foreign-function/3
    (> 0 (libc/strcmp "bar" "foo"))
  target-boolean/true)

(define-test compile/load-store/1
    (let ((x 42))
      (set globaltmp x)
      globaltmp)
  42)

(define-test compile/address-of/1
    (let ((x 42))
      (oop-at (address-of x) 0))
  42)

(define-test compile/address-of/2
    (let ((x 42))
      (set (oop-at (address-of x) 0) 43)
      x)
  43)

(define-test compile/address-of/3
    (oop-at (address-of global42) 0)
  42)

(define-function compile/address-of/4/helper (arg)
  (oop-at (address-of arg) 0))

(define-test compile/address-of/4
    (compile/address-of/4/helper 142)
  142)

(define-test compile/and/1
    (and)
  target-boolean/true)

(define-test compile/and/2
    (and 42 43)
  43)

(define-test compile/and/3
    (and 42 () 43)
  ())

(define-test compile/and/4
    (let ((y 0))
      (and 999
           (< 3 (set y 4))
           (< 4 (set y 5))
           (< 6 (set y 6))
           (< 7 (set y 7)))
      y)
  6)

(define-test compile/or/1
    (or)
  target-boolean/false)

(define-test compile/or/2
    (or () 42 43)
  42)

(define-test compile/or/3
    (or () () 42 43)
  42)

(define-test compile/or/4
    (let ((y 0))
      (or ()
          (< 4 (set y 3))
          (< 5 (set y 4))
          (< 7 (set y 8))
          (< 1 (set y 2)))
      y)
  8)

(define-test compile/let/1
    (let ((y 0))
      (set y 3)
      y)
  3)

(define-test compile/while/1
    (let ((x 5)
          (sum 1))
      (while (and (> x 0)
                  sum)
        (set sum (+ sum x))
        (set x (- x 1)))
      (return sum))
  15)

(define-test compile/not/1
    (not ())
  target-boolean/true)

(define-test compile/not/2
    (not 42)
  target-boolean/false)

(define-test compile/neg/1
    (- 42)
  -42)

(define-test compile/neg/2
    (- 0)
  0)

(define-test compile/arithmetic/1
    (let ((x (+ 1 1)))
      (- (+ (/ (* (* x 2) 10) 20) 50) 10))
  42)

(define-test compile/bitwise-and/1
    (& 0xef 0xf0)
  0xe0)

(define-test compile/bitwise-or/1
    (| 0xe0 0x0f)
  0xef)

(define-test compile/bitwise-xor/1
    (^ 0xff 0xf0)
  0x0f)

(define-test compile/bitwise-shift-left/1
    (<< 0x0f 4)
  0xf0)

(define-test compile/bitwise-shift-right/1
    (>> 0x0f 2)
  0x3)

(define-test compile/bitwise-shift-right/2
    (>> -8 1)
  -4)

(define-test compile/string-at/1
    (string-at "alma" 2)
  ?m)

(define-test compile/set-string-at/1
    ;; NOTE if we just set-string-at on the constant, then LLVM optimizes it into oblivion without any notice
    (let* ((buf (libc/strdup "bogyo"))
           (value ?i))
      (set (string-at buf 1) value)
      (libc/strcmp buf "bigyo"))
  0)

;; NOTE one must be careful with those 0x123 constants when <long> is tagged, i.e. smaller than the target's word size
;; NOTE a 32 bit eval cannot read 64 bit numbers, so we need to >> everything by 32 bits there
;; NOTE shifting right is signed
(define-test compile/oop-at/1
    (>> (oop-at "0123456789abcdefghijklmnopqrst" 0)
        (- target/word-size-in-bits 32))
  (cond
    ((= 32 target/word-size-in-bits)
     (if target/little-endian? 0x33323130 0x30313233))
    ;; TODO add read-time eval for this?
    ;; ((= 64 target/word-size-in-bits)
    ;;  (if target/little-endian? 0x3736353433323130 0x303132334353637))
    ((= 64 target/word-size-in-bits)
     (if target/little-endian? 0x37363534 0x3031323))))

(define-test compile/oop-at/2
    (>> (oop-at "0z0000x01z1111x12z2222x23z3333x3" 1)
        (- target/word-size-in-bits 32))
  (cond
    ((= 32 target/word-size-in-bits)
     (if target/little-endian? 0x30783030 0x30307830))
    ((= 64 target/word-size-in-bits)
     (if target/little-endian? 0x31783131 0x317a3131))))

(define-test compile/set-oop-at/1
    (let* ((buf (libc/strdup "0123456789abcdefghijklmnopqrst"))
           (value 0x316b756b)) ; "1kuk"
      (set (oop-at buf 1) value)
      (libc/strcmp buf
                   (cond
                     ((= 32 target/word-size-in-bits)
                      (if target/little-endian?
                          "0123kuk189abcdefghijklmnopqrst"
                        "01231kuk89abcdefghijklmnopqrst"))
                     ((= 64 target/word-size-in-bits)
                      ;; NOTE the lower 32 bits are zero, so they end the cstr
                      (if target/little-endian?
                          "01234567kuk1"
                        "TODO fill me in")))))
  0)

(define-test compile/set-oop-at/2
    (let* ((buf (libc/strdup "0123456789abcdefghijklmnopqrst"))
           (value 0x316b756b)           ; "1kuk"
           (index 2))
      (set (oop-at buf index) value)
      (libc/puts buf)
      (libc/strcmp buf
                   (cond
                     ((= 32 target/word-size-in-bits)
                      (if target/little-endian?
                          "01234567kuk1cdefghijklmnopqrst"
                        "012345671kukcdefghijklmnopqrst"))
                     ((= 64 target/word-size-in-bits)
                      ;; NOTE the lower 32 bits are zero, so they end the cstr
                      (if target/little-endian?
                          "0123456789abcdefkuk1"
                        "TODO fill me in")))))
  0)

(define-test compile/set-oop-at/return-value
    (let* ((buf (libc/malloc 16))
           (value 999))
      (set (oop-at buf 0) value))
  999)

(define-test compile/set-oop-at/3
    (let* ((buf (libc/malloc 16)))
      (set (oop-at buf 0) 9940)
      (set (oop-at buf 1) 2)
      (+ (oop-at buf 0)
         (oop-at buf 1)))
  9942)

(define-test compile/set/bug/1
    (let ((argc 2))
      (< 0 (set argc (- argc 1))))
  target-boolean/true)

(define-test compile/set/bug/2
    (let ((argc 1))
      (< 0 (set argc (- argc 1))))
  target-boolean/false)

(define-function set-second-to-first (x y)
  (set x y)
  x)

(define-test compile/set/bug/3
    (set-second-to-first 33 99)
  99)

(define-function main (argc argv)
  (libc/printf "strcmp return value: %d\n" (libc/strcmp "bar" "foo"))

  (libc/printf "Printing command line args:\n")
  (for (i 0 argc)
    (libc/printf "  %.2d %s\n" i (oop-at argv i)))

  (let ((idx argc))
    (while (< 0 (set idx (- idx 1)))
      (libc/printf "--%.2d %s\n" idx (oop-at argv idx))))

  (while (< 0 (set argc (- argc 1)))
    (libc/printf "++%.2d %s\n" argc (oop-at argv argc)))

  (when uninitialized-global
    (failure "uninitialized-global is %d" uninitialized-global))
  (unless (= global42 42)
    (failure "global42 is %d" global42))

  (libc/printf "About to start running the compiled tests\n")
  (run-tests)
  (libc/printf "\nFinished running the compiled tests\n")

  (return *exit-code*))

(compile-end)
