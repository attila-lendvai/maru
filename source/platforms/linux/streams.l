;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams-min.l")

;; TODO not sure whether this technique of (address-of char) is
;; digestable for LLVM. it's a KLUDGE anyway...

;;;
;;; files
;;;

;; TODO reaname these to file/open?
(define-primitive-function file-open ((path <string>) (mode <string>))
  (let ((fd (linux-syscall linux/open (string->C-string path)
                           (cond
                             ((or (not mode)
                                  (string= mode "r"))
                              linux/O_RDONLY)
                             ((string= mode "rw")
                              (bitwise-or linux/O_RDWR
                                          linux/O_CREAT))
                             ((string= mode "w")
                              (bitwise-or linux/O_WRONLY
                                          linux/O_CREAT))
                             (else
                              (error "file-open: unexpected mode "mode" while opening "path)))
                           420          ; "rw-r--r--"
                           )))
    (when (<= 0 fd)
      ;; TODO use <target-word> for boxing and unboxing
      (box <target-pointer> fd))))

(define-primitive-function file-close ((fd <target-pointer>))
  ;; FIXME exmplain why this is NOUNBOX, and investigate why things break if i delete it
  (when (= 0 (linux-syscall linux/close fd))
    symbol/true))

(define-primitive-function file-read-character ((fd <target-pointer>))
  (let ((char 0))
    (if (= 1 (linux-syscall linux/read fd (address-of char) 1))
        ;; TODO endianness, EAGAIN and stuff
        (box <long> char)
      ;;(error "file-read-character: syscall returned with error")
      ())))

(define-primitive-function file-write-character ((char <long>) (fd <target-pointer>))
  ;; TODO endianness? think this through...
  (when (= 1 (linux-syscall linux/write fd (address-of char) 1))
    symbol/true))

;; (define-primitive-function file-flush ((fd <target-pointer>))
;;   (unless (= 0 (linux-syscall linux/fsync fd))
;;     (error "file-flush: linux/fsync returned an error")))

;;;
;;; <fd-stream>
;;;

(define-record <fd-stream> <stream>
  (fd
   peeked-value))

(define-primitive-function file-stream ((fd <target-pointer> _ nounbox))
  (assert (is <target-pointer> fd))
  (make/opaque <fd-stream>
    ;; TODO boxing...
    (fd			(unbox <target-pointer> fd))
    (peeked-value	-1)))

(define-function %ensure-peeked (stream)
  (or (<= 0 (<fd-stream>-peeked-value stream))
      (let* ((fd	(<fd-stream>-fd stream))
             (char	0)
             (rc	(linux-syscall linux/read fd (address-of char) 1)))
        (set (<fd-stream>-peeked-value stream)
             (if (= 1 rc)
                 char ; FIXME needs to be boxed, no?
               -1)))))

(define-method $at-end? <fd-stream> ()
  (%ensure-peeked self)
  (< self.peeked-value 0))

(define-method $peek <fd-stream> ()
  (%ensure-peeked self)
  (if (<= 0 self.peeked-value)
      self.peeked-value
    +end+))

(define-method $next <fd-stream> ()
  (%ensure-peeked self)
  (if (<= 0 self.peeked-value)
      (let ((res self.peeked-value))
        (set self.peeked-value -1)
        res)
    +end+))

(define-method $put <fd-stream> (u/char)
  ;; FIXME endianness
  (unless (= 1 (linux-syscall linux/write self.fd (address-of u/char) 1))
    ;; TODO deal with EAGAIN and stuff...
    (error "<fd-stream> $put: write failed"))
  u/char)

;; TODO implemenet inheritance on compiled selectors
(define-method $put-all <fd-stream> (elements)
  (typecase elements
    (<string>
     (let ((buf		(string->C-string elements))
           (size	(string-length elements)))
       (unless (= size (linux-syscall linux/write self.fd buf size))
         ;; TODO deal with EAGAIN and stuff...
         (error "<fd-stream> $put-all: write failed"))))
    (else
     (error "<fd-stream> $put-all: unexpected elements: " elements)))
  elements)

(require "source/streams-min-late.l")
