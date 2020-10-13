;;; -*- mode: lisp; coding: us-ascii -*-

(define-function compile-env (env -c-)
  (verbosity 1 (warn "begin compiling\n"))
  (emit-prelude -c-)
  (array-do var (<env>-bindings env)
    (let* ((name		(<variable>-name  var))
           (value		(<variable>-value var))
           (type-blacklist	(list <primitive-function> <fixed> <form> <array> <env> <module>))
           (name-blacklist	'(+end+ true)))
      (unless (or (member? (type-of value) type-blacklist)
                  (member? name name-blacklist))
        (emit COMMENT (list "defn " name))
        (verbosity 1 (warn name ", "))
        (compile-definition value name -c-))))
  (verbosity 1 (warn "\n"))
  (emit-gen-buffer -c-))

;;;
;;; API visible in the target
;;;
(set *module* *target-module*)

;; redefine DEFINE-CONSTANT so that it defines it both into the slave and into the target.
(define-form define-constant (name value-form)
  ;; NOTE as per the custom DEFINE-FORM above, we are expanded/encoded in the slave module,
  ;; but at apply time *module* will be the target module.
  ;; TODO the wizardry here smells like accidental complexity, or at least it's semantics with a high congnitive load.
  (let* ((value		(eval `(eval-in-module *slave-module* ',value-form)))
         (form-obj	(eval `(eval-in-module *slave-module* '(form () (lambda _ ',value)))))
         (definer-form	`(define ,name ',form-obj)))
    (eval `(eval-in-module *slave-module* ',definer-form))
    definer-form))

;; (define-constant +test+ 42)
;; (eval-in-module *slave-module* `(assert (= +test+ 42)))
;; (eval-in-module *slave-module* `(println "+test+ in target is " ,+test+))

;; redefine DEFINE-RECORD so that it defines both into the slave and the target.
(define-form define-record (name super slots)
  (let* ((definer-form	`(define-record ,name ,super ,slots))
         (type		(eval `(eval-in-module *slave-module* ',definer-form)))
         (accessors	(eval `(eval-in-module *slave-module* '(%make-record-accessors ,type)))))
    `(let ()
       (define ,name ,type)
       ,@accessors
       ())))

;; an alternative that almost works
;; (define-form define-record (name super slots)
;;   (eval `(eval-in-module *slave-module* '(encode (expand '(define-record ,name ,super ,slots))))))

(define-form define-foreign-function (maru-name return-type foreign-name parameter-types)
  (let ((ff (eval-in-host `(foreign-function ',return-type ,(symbol->string foreign-name) ',parameter-types))))
    `(define ,maru-name ,ff)))

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
     (size_t strlen (*)) (* strcpy (* *)) (* strncpy (* * size_t)) (int strcmp (* *)) (int strncmp (* * size_t)) (* strdup (*)) (unsigned-long strtoul (* * int)) (long strtol (* * int))
     )
    (define-constant libc/EOF -1)))
