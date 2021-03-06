;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/platforms/platform-c-based.l")

(define-constant fd/stdin  0)
(define-constant fd/stdout 1)
(define-constant fd/stderr 2)

;; define some llvm intrinsics as FFI calls
;; https://llvm.org/docs/LangRef.html#llvm-memcpy-intrinsic
;; (define-C-functions ()
;;   (void llvm.memcpy.p0i8.p0i8.i32 (* * int int))
;;   )
;; TODO turned off because this requires linking to something that defines memcpy. apparently llvm doesn't emit its own code for these.
;; (if (= (host-value *compiler-backend*) "llvm")
;;     (define-form copy-oops (from to wordcount)
;;       ;; TODO add align: https://llvm.org/docs/LangRef.html#attr-align
;;       `(llvm.memcpy.p0i8.p0i8.i32 ,to ,from (words-to-bytes ,wordcount) 1)))

;;;
;;; Platform API implementation when running on top of the Linux kernel.
;;;
(define-function platform/flush-streams ()
  (linux-syscall linux/fsync fd/stdout)
  (linux-syscall linux/fsync fd/stderr))

;; NOTE copy means it may not overlap. move means they may overlap.

;; TODO these two are exported into the evaluator to provide the same api in interpreted code. how shall this be?
(define-form copy-oops (from to wordcount)
  `(for (i 0 ,wordcount)
     (set (oop-at ,to   i)
          (oop-at ,from i))))

(define-form copy-bytes (from to count)
  `(for (i 0 ,count)
     (set (byte-at ,to   i)
          (byte-at ,from i))))

(define-form platform/move-oops (from to wordcount)
  `(cond
     ((< ,to ,from)
      (for (i 0 ,wordcount)
        (set (oop-at ,to   i)
             (oop-at ,from i))))
     ((< ,from ,to)
      (for (i (- ,wordcount 1) -1 -1)
        (set (oop-at ,to   i)
             (oop-at ,from i))))))

(define-form platform/move-bytes (from to count)
  `(cond
     ((< ,to ,from)
      (for (i 0 ,count)
        (set (byte-at ,to   i)
             (byte-at ,from i))))
     ((< ,from ,to)
      (for (i (- ,count 1) -1 -1)
        (set (byte-at ,to   i)
             (byte-at ,from i))))))

(define-form platform/clear-bytes (from count)
  `(for (i 0 ,count)
     (set (byte-at ,from i) 0)))

(begin-for-syntax
 (define-function string+length (str)
   (let ((len (string-length str)))
     (assert (< 0 len))
     `((string->C-string ,str) ,len))))

(define-form platform/print strs
  (let ((forms ()))
    (list-do str strs
      (push forms (if (is <string> str)
                      `(linux-syscall linux/write fd/stdout ,@(string+length str))
                    `(let ((x ,str))
                       (linux-syscall linux/write fd/stdout (string->C-string x) (C-string-length x))))))
    `(let ()
       ,@(list-reverse! forms)
       (linux-syscall linux/write fd/stderr ,@(string+length "\n")))))

(define-form platform/print-diag* strs
  (let ((forms ()))
    (list-do str strs
      (push forms (if (is <string> str)
                      `(linux-syscall linux/write fd/stderr ,@(string+length str))
                    `(let ((x ,str))
                       (linux-syscall linux/write fd/stderr (string->C-string x) (C-string-length x))))))
    `(let ()
       ,@(list-reverse! forms))))

(define-form platform/print-diag-fmt* (format . args)
  ;; this just prints the format string, unprocessed
  ;; TODO implement formatting within maru, and forget libc's printf
  (if (is <string> format)
      `(linux-syscall linux/write fd/stderr ,@(string+length format))
    `(let ((x ,format))
       (linux-syscall linux/write fd/stderr (string->C-string x) (C-string-length x)))))

(define-form platform/halt args
  `(linux-syscall linux/exit ,@(or args '(-1))))

(define *initial-break* 0)
(define *current-break* 0)

(define-form platform/acquire-memory (size)
  ;; https://gist.github.com/nikAizuddin/f4132721126257ec4345
  ;; TODO this really should be a function, but we don't yet have ERROR and ASSERT at this point
  `(let ()
     (unless *initial-break*
       (set *current-break* (set *initial-break* (linux-syscall linux/brk 0)))
       (assert (< 0 *current-break*)))
     (let ((new-break	(linux-syscall linux/brk (+ *current-break* ,size)))
           (result	*current-break*))
       (assert (= ,size (- new-break *current-break*)))
       (set *current-break* new-break)
       result)))
