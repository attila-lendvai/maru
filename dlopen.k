(require "osdefs.k")

(define *dlopen-path* (list "." "/lib" "/usr/lib" "/usr/local/lib" "/opt/X11/lib" "/opt/local/lib" "/usr/X11/lib"))

(define *dlopen-suffix*
  (cond
    ((defined? '__APPLE__)	".dylib")
    ((defined? '__WIN32__)	".dll")
    (else			".so")))

(define-function init-dlopen ()
  (define %dlopen  (subr "dlopen" "si"))
  (define %dlerror (subr "dlerror" "")))

(define-function dlopen (name)
  (let ((filename (concat-string name *dlopen-suffix*))
	(dirnames *dlopen-path*)
	(lib      0))
    (while (and (= 0 lib) dirnames)
      (let ((pathname (concat-strings (car dirnames) "/" filename)))
	(set lib (%dlopen pathname RTLD_NOW))
	(set dirnames (cdr dirnames))))
    (and (= 0 lib) (error "could not load: "name))
    lib))
