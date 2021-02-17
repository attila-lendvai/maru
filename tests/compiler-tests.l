;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Tests for the compiler backends.
;;;
;;; This file is compiled the same way as eval.l is compiled.
;;;

(load "source/platforms/libc/libc.l")
(load "source/evaluator/vm-early.l")

;; turn off some stuff that would bring in more dependencies
(define-form assert (test . args) ())
(define-function error-prologue ()
  (platform/print-diag "\nERROR: "))
(define-function %error (arg)
  (platform/print-diag "%error reached"))

(load "source/evaluator/gc.l")
(load "source/evaluator/types.l")

(define-form assert (test . args)
  `(or ,test (failure ,@(or args (list "an assert failed")))))

(define *exit-code* 0)

(begin-for-syntax
 (define *tests* ()))

(define-form failure (format . args)
  `(let ()
     (platform/print-diag-fmt ,(concat-strings "\n\n\033[1;31m*** FAILURE\033[0m " format) ,@args)
     (set *exit-code* -1)))

(define-form define-test (name form expected-value)
  (push *tests* name)
  (let ((name-as-string (symbol->string name)))
    `(define-function ,name ()
       (platform/print-diag* ,(concat-strings name-as-string ", "))
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
      (push forms '(platform/flush-streams))
      (push forms `(,test))
      (set tests (rest tests)))
    `(let ()
       ,@forms)))

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

(define printf 10)
(define word 10)

(define-test compile/escaping/1
    (let ((ptr 22))
      (+ word (+ printf ptr)))
  42)

(define-test compile/if/1
    (if false 342 343)
  343)

(define-test compile/if/2
    (if true
        (if false
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
    (libc/strcmp (C-string "bigyo") (C-string "bigyo"))
  0)

(define-test compile/foreign-function/2
    (< 0 (libc/strcmp (C-string "foo") (C-string "bar")))
  true)

(define-test compile/foreign-function/3
    (> 0 (libc/strcmp (C-string "bar") (C-string "foo")))
  true)

(define-test compile/foreign-function/4
    (let* ((size	128)
           (buf		(libc/malloc size)))
      (libc/snprintf buf size (C-string "foo%sbaz%ld") (C-string "bar") 42)
      (let ((res (= 0 (libc/strcmp (C-string "foobarbaz42") buf))))
        (libc/free buf)
        res))
  true)

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
  true)

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
  false)

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

(define-function min (a b)
  (if (> a b) b a))

(let ()
  (define-function compile/let/2-helper (a b count)
    (let* ((count (- count 1)))
      count)))

(define-test compile/let/2
    (+ (compile/let/2-helper 1 1 41)
       (compile/let/2-helper 1 1 3))
  42)

(define-test compile/let/constant-prop
    (let ((y (+ 2 3)
             40))
      ;; the compiler must not turn 40 into a literal, because let needs temp locations
      (+ y 2))
  42)

(when-at-expand (host-value feature/redefinable-functions-in-target)
  (define-function returns-42 ()
    (return 42))

  (define-function returns-43 ()
    (return 43))

  (define-function returner ()
    (return -1))

  (define-test compile/redefinable-functions-in-target/1
      (let ((result 0))
        (set returner returns-42)
        (set result (returner))
        (set returner returns-43)
        (+ result (returner)))
    85))

(define-test compile/while/1
    (let ((x 5)
          (sum 1))
      (while (and (> x 0)
                  sum)
        (set sum (+ sum x))
        (set x (- x 1)))
      sum)
  16)

;; this is supposed to signal a compile time error instead of compiling a call to nil...
;; (define-test compile/call/1
;;     (() 42)
;;   ())

(define-test compile/not/1
    (not ())
  true)

(define-test compile/not/2
    (not 42)
  false)

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
    (bitwise-and 0xef 0xf0)
  0xe0)

(define-test compile/bitwise-or/1
    (bitwise-or 0xe0 0x0f)
  0xef)

(define-test compile/bitwise-xor/1
    (bitwise-xor 0xff 0xf0)
  0x0f)

(define-test compile/bitwise-not/1
    (bitwise-not -1)
  0)

;; (define-test compile/bitwise-shift-left/1
;;     (bitwise-shift 0x0f 4)
;;   0xf0)

;; (define-test compile/bitwise-shift-left/2
;;     (bitwise-shift 0xffffff0 1000)
;;   0)

;; (define-test compile/bitwise-shift-right/1
;;     (bitwise-shift 0x0f -2)
;;   0x3)

;; (define-test compile/bitwise-shift-right/2
;;     (bitwise-shift -8 -1)
;;   -4)

;; (define-test compile/bitwise-shift-right/3
;;     (bitwise-shift 0xffffff0 -1000)
;;   0)

;; (define-test compile/bitwise-shift/literal/1
;;     (bitwise-shift 0x0f 4)
;;   0xf0)

;; (define-test compile/bitwise-shift/literal/2
;;     (bitwise-shift 0xf0 -4)
;;   0x0f)

;; (define-test compile/bitwise-shift/literal/3
;;     (bitwise-shift 0x42 0)
;;   0x42)

;; (define-test compile/bitwise-shift/local/1
;;     (let ((shift (+ 2 2)))
;;       (bitwise-shift 0x0f shift))
;;   0xf0)

;; (define-test compile/bitwise-shift/local/2
;;     (let ((shift (- 0 4)))
;;       (bitwise-shift 0xf0 shift))
;;   0x0f)

;; (define-test compile/bitwise-shift/local/3
;;     (let ((shift 0))
;;       (bitwise-shift 0x42 shift))
;;   0x42)

(define-test compile/char-at/1
    (char-at (C-string "alma") 2)
  ?m)

(define-test compile/set-char-at/1
    ;; NOTE if we just set-char-at on the constant, then LLVM optimizes it into oblivion without any notice
    (let* ((buf (libc/strdup (C-string "bogyo")))
           (value ?i))
      (set (char-at buf 1) value)
      (libc/strcmp buf (C-string "bigyo")))
  0)

(define-test compile/set-char-at/2
    (let ((buf (libc/strdup (C-string "123"))))
      (set (char-at buf 0) ?x)
      (libc/strcmp buf (C-string "x23")))
  0)

(define-test compile/set-char-at/3
    (let* ((buf (libc/strdup (C-string "123")))
           (ret (set (char-at buf 1) ?x)))
      ;; let's not rely on the evaluation order of the args until
      ;; there's a commitment in the compiler.
      (+ ret
         (libc/strcmp buf (C-string "1x3")))) ; should return 0 upon match
  ?x)

;; NOTE one must be careful with those 0x123 constants when <long> is tagged, i.e. smaller than the target's word size
;; NOTE a 32 bit eval cannot read 64 bit numbers, so we need to >> everything by 32 bits there
;; NOTE shifting right is signed
(define-test compile/oop-at/1
    (bitwise-shift (oop-at (C-string "0123456789abcdefghijklmnopqrst") 0)
                   (- (- +word-size-in-bits+ 32)))
  (cond
    ((= 32 +word-size-in-bits+)
     (if +little-endian?+ 0x33323130 0x30313233))
    ;; TODO add read-time eval for this?
    ;; ((= 64 +word-size-in-bits+)
    ;;  (if +little-endian?+ 0x3736353433323130 0x303132334353637))
    ((= 64 +word-size-in-bits+)
     (if +little-endian?+ 0x37363534 0x3031323))))

(define-test compile/oop-at/2
    (bitwise-shift (oop-at (C-string "0z0000x01z1111x12z2222x23z3333x3") 1)
                   (- (- +word-size-in-bits+ 32)))
  (cond
    ((= 32 +word-size-in-bits+)
     (if +little-endian?+ 0x30783030 0x30307830))
    ((= 64 +word-size-in-bits+)
     (if +little-endian?+ 0x31783131 0x317a3131))))

(define-test compile/set-oop-at/1
    (let* ((buf (libc/strdup (C-string "0123456789abcdefghijklmnopqrst")))
           (value 0x316b756b)) ; "1kuk"
      (set (oop-at buf 1) value)
      (libc/strcmp buf
                   (cond
                     ((= 32 +word-size-in-bits+)
                      (if +little-endian?+
                          (C-string "0123kuk189abcdefghijklmnopqrst")
                        (C-string "01231kuk89abcdefghijklmnopqrst")))
                     ((= 64 +word-size-in-bits+)
                      ;; NOTE the lower 32 bits are zero, so they end the cstr
                      (if +little-endian?+
                          (C-string "01234567kuk1")
                        (C-string "TODO fill me in"))))))
  0)

(define-test compile/set-oop-at/2
    (let* ((buf (libc/strdup (C-string "0123456789abcdefghijklmnopqrst")))
           (value 0x316b756b)           ; "1kuk"
           (index 2))
      (set (oop-at buf index) value)
      (libc/strcmp buf
                   (cond
                     ((= 32 +word-size-in-bits+)
                      (if +little-endian?+
                          (C-string "01234567kuk1cdefghijklmnopqrst")
                        (C-string "012345671kukcdefghijklmnopqrst")))
                     ((= 64 +word-size-in-bits+)
                      ;; NOTE the lower 32 bits are zero, so they end the cstr
                      (if +little-endian?+
                          (C-string "0123456789abcdefkuk1")
                        (C-string "TODO fill me in"))))))
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

(define-test compile/set-oop-at/4
    (let* ((place (libc/malloc 16)))
      (set (oop-at place 0) 42))
  42)

(define-test compile/set-oop-at/5
    (let* ((place (libc/malloc 16))
           (value 42))
      (set (oop-at place 0) value))
  42)

(define-test compile/set/bug/1
    (let ((argc 2))
      (< 0 (set argc (- argc 1))))
  true)

(define-test compile/set/bug/2
    (let ((argc 1))
      (< 0 (set argc (- argc 1))))
  false)

(define-function set-second-to-first (x y)
  (set x y)
  x)

(define-test compile/set/bug/3
    (set-second-to-first 33 99)
  99)

;; this should error, explicitly noting that the lambda is capturing x, which is currently not supported.
;; the LLVM IR type system actually catches this bug, but the x86 backend silently miscompiles it currently
;; (define-test compile/closures/1
;;     (let ((a 40)
;;           (b 0))
;;       (+ ((lambda (y)
;;             (set b 42)
;;             (+ a y))
;;           2)
;;          b))
;;   (* 2 42))

(begin-for-syntax
 (define-function string+length (str)
   (let ((len (string-length str)))
     (assert (< 0 len))
     `((string->C-string ,str) ,len))))

(define-test compile/syscall/1
    (let ()
      ;; (eval-at-expand
      ;;  `(linux-syscall linux/write 2 ,@(string+length "\n\t*** compile/syscall/1 is printing this to fd 2\n")))
      (let ((fd (linux-syscall linux/open (C-string "/dev/null") linux/O_RDONLY)))
        (<= 0 fd)))
  true)

(define-test compile/syscall/2
    (let ((fd (linux-syscall linux/open
                             (C-string "/tmp/_maru-test")
                             (bitwise-or linux/O_RDWR
                                         linux/O_CREAT)
                             420 ; "rw-r--r--"
                             )))
      (or (= 4 (eval-at-expand
                `(linux-syscall linux/write fd ,@(string+length "1234"))))
          (failure "unexpected linux/write return code"))
      (or (= 2 (linux-syscall linux/lseek fd 2 linux/SEEK_SET))
          (failure "unexpected linux/lseek return code"))
      (let ((buf 0))
        (or (= 1 (linux-syscall linux/read fd (address-of buf) 1))
            (failure "unexpected linux/read return code"))
        (char-at (address-of buf) 0)))
  ?3)

(define-test compile/syscall/3
    (let ((fd (linux-syscall linux/open
                             (C-string "/tmp/_maru-test")
                             (bitwise-or linux/O_RDWR
                                         linux/O_CREAT)
                             420 ; "rw-r--r--"
                             )))
      (eval-at-expand
       `(linux-syscall linux/write fd ,@(string+length "1234")))
      (let ((char ?5))
        (linux-syscall linux/write fd (address-of char) 1))
      (linux-syscall linux/lseek fd 2 linux/SEEK_SET)
      (let ((buf 0)
            (char 0)
            (result 0))
        (linux-syscall linux/read fd (address-of buf) 1)
        (set char (char-at (address-of buf) 0))
        ;; TODO FIXME on llvm 64 bits it fails when the char is not printed?! probably due to some optimization.
        ;;(libc/fprintf libc/stdout "\n  *** char 1: %c\n" char)
        (incr result (- char ?0))
        (linux-syscall linux/lseek fd 4 linux/SEEK_SET)
        (linux-syscall linux/read fd (address-of buf) 1)
        (set char (char-at (address-of buf) 0))
        ;;(libc/fprintf libc/stdout "\n  *** char 2: %c\n" char)
        (incr result (- char ?0))))
  (+ 3 5))

(define-function main (argc argv)
  (platform/print-diag "Printing test command line args:\n")
  (for (i 0 argc)
    (platform/print-diag-fmt "  %.2d %s\n" i (oop-at argv i)))

  (let ((idx argc))
    (while (< 0 (set idx (- idx 1)))
      (platform/print-diag-fmt "--%.2d %s\n" idx (oop-at argv idx))))

  (while (< 0 (set argc (- argc 1)))
    (platform/print-diag-fmt "++%.2d %s\n" argc (oop-at argv argc)))

  (when uninitialized-global
    (failure "uninitialized-global is %ld" uninitialized-global))
  (unless (= global42 42)
    (failure "global42 is %ld" global42))

  (set libc/stdout (libc/fdopen 0 "w")) ; to test the SET'ting of a <C-variable>

  (platform/print-diag-fmt "\e[32mAbout to start running the compiled tests\e[m\n")
  (run-tests)
  (platform/print-diag-fmt "\n\e[32mFinished running the compiled tests\e[m\n")

  (return *exit-code*))
