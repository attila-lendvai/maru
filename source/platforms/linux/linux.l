;;; -*- mode: lisp; coding: us-ascii -*-

(define-constant fd/stdin  0)
(define-constant fd/stdout 1)
(define-constant fd/stderr 2)

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

(define-form platform/string-compare (a b)
  `(let ((i	0)
         (_a_	,a)
         (_b_	,b)
         (diff	0))
     (while (and (= 0 (set diff (- (char-at _a_ i)
                                   (char-at _b_ i))))
                 (char-at _a_ i))
       (incr i))
     diff))

;; TODO clean up this libc and cstring mess. if we use the same string representation in
;; our string payloads as libc, it doesn't mean that we should use libc stuff directly to
;; manipulate it.
(define-form platform/string-length (cstr)
  `(let ((i 0)
         (_cstr_ ,cstr))
     (while (char-at _cstr_ i)
       (incr i))
     i))

(begin-for-syntax
 (define-function string+length (str)
   (let ((len (string-length str)))
     (assert (< 0 len))
     (list str len))))

(define-form platform/print cstrs
  (let ((forms ()))
    (list-do cstr cstrs
      (push forms (if (is <string> cstr)
                      `(linux-syscall linux/write fd/stdout ,@(string+length cstr))
                    `(let ((x ,cstr))
                       (linux-syscall linux/write fd/stdout x (platform/string-length x))))))
    `(let ()
       ,@(list-reverse! forms))))

(define-form platform/print-diag cstrs
  (let ((forms ()))
    (list-do cstr cstrs
      (push forms (if (is <string> cstr)
                      `(linux-syscall linux/write fd/stderr ,@(string+length cstr))
                    `(let ((x ,cstr))
                       (linux-syscall linux/write fd/stderr x (platform/string-length x))))))
    `(let ()
       ,@(list-reverse! forms))))

(define-form platform/print-diag-fmt (format . args)
  ;; TODO implement formatting within maru, and forget libc's printf
  (if (is <string> format)
      `(linux-syscall linux/write fd/stderr ,@(string+length format))
    `(let ((x ,format))
       (linux-syscall linux/write fd/stderr x (platform/string-length x)))))

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
