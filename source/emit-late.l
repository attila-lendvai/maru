;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; API visible in the slave
;;;
(switch-to-slave-module)

(define-form compile-begin ()
  (set *force-trivial-accessors* true)
  `(set *globals* (eval-in-module host `(host:environment ,*globals*))))

(define-form compile-end ()
  (set *force-trivial-accessors* ())
  '(let ((env *globals*))
     (set *globals* (eval-in-module host `(host:<env>-parent ,env)))
     (eval-in-module host `(host:compile-env (host:quote ,env)))))

(define-form define-foreign-function (maru-name return-type foreign-name parameter-types)
  `(define ,maru-name (eval-in-module host (list 'host:foreign-function (list 'host:quote ',return-type) ,(symbol->string foreign-name) (list 'host:quote ',parameter-types)))))

(define-form define-foreign-functions (maru-prefix . entries)
  `(let ()
     ,@(map (lambda (entry)
              (let* ((foreign-name (second entry))
                     (maru-name (concat-symbol maru-prefix foreign-name)))
                `(define-foreign-function ,maru-name ,@entry)))
            entries)))

(define-form define-foreign-functions/libc ()
  '(let ()
    (define-foreign-functions libc/
     (void abort ()) (void exit (int))
     (* malloc (size_t)) (void free (*)) (* realloc (* size_t)) (* memset (* int size_t)) (* memcpy (* * size_t)) (* memmove (* * size_t))
     (int printf (* ...)) (int fprintf (* * ...)) (int sprintf (* * ...)) (int snprintf (* size_t * ...))
     (int puts (*)) (int fputc (* *)) (int fgetc (*)) (int ungetc (int *)) (* fopen (* *)) (* fdopen (int *))
     (int fclose (*)) (int fflush (*)) (int fscanf (* * ...)) (int feof (*)) (void setbuf (* *))
     (size_t strlen (*)) (* strcpy (* *)) (* strncpy (* * size_t)) (int strcmp (* *)) (int strncmp (* * size_t)) (* strdup (*)) (unsigned-long strtoul (* * int))
     )
    (define-constant libc/EOF -1)))
