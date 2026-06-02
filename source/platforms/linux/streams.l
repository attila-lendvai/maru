;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams-min.l")

;; TODO not sure whether this technique of (address-of char) is
;; digestable for LLVM. it's a KLUDGE anyway...

(define-function posix/open (path flags mode)
  (syscall linux/SYS_openat linux/AT_FDCWD path
           flags mode))

;; We define a posix API, so we need to export some constants. They
;; are not guaranteed to be the same between the kernel and the libc
;; (which is implementing posix), but these are.
(define-constant posix/O_WRONLY linux/O_WRONLY)
(define-constant posix/O_CREAT  linux/O_CREAT)

(define-function posix/close (fd)
  (syscall* linux/SYS_close fd))

(define-function posix/read-byte (fd)
  (let ((byte 0)
        rc)
    ;; man 2 read
    (while (= (- linux/EINTR)
              (set rc (syscall linux/SYS_read fd (address-of byte) 1)))
      ;; then try again
      )
    (case rc
      (0	-1)
      (1	byte)
      (else	(- rc)))))

(define-function posix/write (fd buf length)
  (let (rc)
    (while (= (- linux/EINTR)
              (set rc (syscall linux/SYS_write fd buf length)))
      ;; then try again
      )
    rc))

;;;
;;; files
;;;

;; TODO reaname these to file/open?
(define-vm-function file-open ((path <string>) (mode <string>))
  (let ((fd (posix/open (string->C-string path)
                        (cond
                          ((or (not mode)
                               (string= mode "r"))
                           linux/O_RDONLY)
                          ((string= mode "rw")
                           (bitwise-or linux/O_RDWR
                                       (bitwise-or linux/O_CREAT
                                                   linux/O_TRUNC)))
                          ((string= mode "w")
                           (bitwise-or linux/O_WRONLY
                                       (bitwise-or linux/O_CREAT
                                                   linux/O_TRUNC)))
                          (else
                           (error "file-open: unexpected mode "mode" while opening "path)))
                        posix/default-umask)))
    (when (<= 0 fd)
      (debug (platform/diag-print "file-open will box fd "(long fd)"\n"))
      (box <lower-cell> fd))))

(define-vm-function file-close ((fd <lower-cell>))
  (to-upper-boolean
   (= 0 (syscall linux/SYS_close fd))))

(define-vm-function file-read-byte ((fd <lower-cell>))
  (let ((char 0)
        result)
    ;; man 2 read
    (while (begin
             (set result (syscall linux/SYS_read fd (address-of char) 1))
             (= result (- linux/EINTR)))
      ;; then try again
      )
    (if (= 1 result)
        (box <long> char)
      ;; TODO EAGAIN=EWOULDBLOCK, EINTR and stuff
      ;;(error "file-read-byte: syscall returned with error")
      ())))

(define-vm-function file-write-byte ((char <long>) (fd <lower-cell>))
  ;; TODO endianness? think this through...
  (to-upper-boolean
   (= 1 (posix/write fd (address-of char) 1))))

;; (define-vm-function file-flush ((fd <lower-cell>))
;;   (unless (= 0 (syscall linux/SYS_fsync fd))
;;     (error "file-flush: linux/SYS_fsync returned an error")))

;; FIXME groveler limitation
(define-constant linux/sizeof-statx 256)

(define-vm-function file-modification-time ((path <string>))
  ;; TODO use stack allocation
  (let ((st (allocate-data linux/sizeof-statx)))
    (syscall* linux/SYS_statx linux/AT_FDCWD (string->C-string path) 0
              linux/STATX_BASIC_STATS st)
    ;; KLUDGE FIXME this should be groveled
    ;; 0x70 is st.stx_mtime.tv_sec, the value is i64
    (box <long> (cell-at st 0x70))))

;;;
;;; <fd-stream> used in the lower (i.e. only the vm-function's need to
;;; box return values, the rest is called within the lower)
;;;

(define-record <fd-stream> <stream>
  (fd
   peeked-value))

(define-vm-function file-stream ((fd <lower-cell>))
  ;; when the entire object is an opaque, then we can freely store
  ;; unboxed values in it. not sure if this is ideologically the right
  ;; way, because the upper can get hold of unboxed values using the
  ;; accessors.
  (make/opaque <fd-stream>
    (fd			fd)
    (peeked-value	-1)))

(define-function %ensure-peeked (stream)
  (or (<= 0 (<fd-stream>-peeked-value stream))
      (let* ((fd	(<fd-stream>-fd stream))
             (char	0)
             (rc	(syscall linux/SYS_read fd (address-of char) 1)))
        (set (<fd-stream>-peeked-value stream)
             (if (= 1 rc)
                 char
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
  ;; TODO endianness? think this through...
  (unless (= 1 (posix/write self.fd (address-of u/char) 1))
    (error "<fd-stream> $put: write failed"))
  u/char)

(define-function %put-all (fd buf size)
  (let ((rc (posix/write fd buf size)))
    (unless (= rc size)
      (debug (platform/diag-print "<fd-stream> $put-all: write returned with "(long rc)"\n"))
      ;; TODO deal with EAGAIN and stuff...
      (error "<fd-stream> $put-all: write failed"))))

;; TODO implemenet inheritance on compiled selectors
(define-method $put-all <fd-stream> (obj)
  (typecase obj
    (<string>
     (%put-all self.fd (string->C-string obj) (string-length obj)))
    (when-at-expand (feature lower/array)
      (<lower/array>
       (%put-all self.fd (slot-value <lower/array> elements obj) (lower/array-length obj))))
    (else
     (error "<fd-stream> $put-all: unexpected elements: " obj)))
  obj)

;; (define-method $close <fd-stream> ()
;;   (syscall* linux/SYS_close self.fd))

(require "source/streams-min-late.l")
