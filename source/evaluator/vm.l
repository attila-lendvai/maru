;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; error handling
;;; ----------------------------------------------------------------

;;
;; ERROR (and ASSERT!) goes through the maru printing facility
;; (i.e. it must not get called with an unboxed .asciz, nor before
;; streams and the VM is properly initialized).
;;
(define *error-level* 0)

(define-function error-prologue ()
  (incr *error-level*)
  (unless (and *symbols* *error-output*)
    (platform/diag-print "WARNING: error-prologue was reached too early in init. We'll most probably crash before printing the actual error message.\n"))
  (cond
    ((= 2 *error-level*)
     (platform/diag-print "NESTED ERROR 1, attempting to print a limited backtrace\n")
     (abort))
    ((< 2 *error-level*)
     (platform/diag-print "NESTED ERROR 2, giving up...\n")
     (platform/halt)))
  (platform/diag-print "\nERROR: "))

(define-function error-epilogue ()
  (platform/diag-print "\n")
  (abort))

(define-function %error (arg)
  (do-print *error-output* arg false))

(define-form error args
  `(let ()
     (error-prologue)
     ;; FIXME decide whether this can only be called with tagged or
     ;; untagged, and then adapt accordingly
     ,@(map (lambda (arg)
              `(%error ,arg))
            args)
     (error-epilogue)))

(define-form warn args
  `(let ()
     (platform/diag-print "\nWARNING: ")
     ,@(map (lambda (arg)
              `(%error ,arg))
            args)))

;;;
;;; vm-function infrasrtucture, i.e. exposing lower functions to the
;;; upper realm being implemented
;;; ----------------------------------------------------------------

(begin-for-syntax
 (define *vm-function-registry* ())
 (define *vm-function-type-accessors*
     '((<long>			(long?)				(unbox <long>))
       (<string>		(string?))
       (<lower-cell>		(is <lower-cell>)		(unbox <lower-cell>))
       (<symbol>		(symbol?))
       (<pair>			(pair?))
       (<array>			(array?)))))

(define-function %not-enough-arguments (name args)
  (error name": not enough arguments: "args))

(define-function %too-many-arguments (name args)
  (error name": too many arguments: "args))

;; defines a function that will be exposed to the VM. as such, it
;; needs to do some conversion of the values that are crossing the
;; boundary between the VM and the lower/target domain.
;;
;; TODO this is convoluted and needs better documentation
(define-form define-vm-function (name-and-props args . body)
  ;; NAME: optionally a list of (upper-name (or level-shifted-name null) . (properties: fixed))
  ;; ARGS: may be _ to skip arg parsing
  ;;       otherwise a list of entries like:
  ;;         (arg-name (or arg-type null) (or default-value _) . (properties: nounbox))
  ;;
  ;; it generates two functions: NAME and NAME/EVALUATOR-STUB. the
  ;; latter does some extra to deal with the crossing of the boundary
  ;; between the VM and the target domains.
  ;;
  ;; the function in the target domain does not do any magic, it's
  ;; really just a plain ,@body.
  (set name-and-props (ensure-list name-and-props))
  (let ((upper-name	(pop name-and-props))
        impl-name
        impl-name?
        fixed?)
    (when (pair? name-and-props)
      (set impl-name (pop name-and-props))
      (set impl-name? true))
    (list-do prop name-and-props
      (case prop
        (fixed	(set fixed? true))
        (else	(error "define-vm-function: unexpected property "prop))))
    (let* ((stub-name		(concat-symbol upper-name '/evaluator-stub))
           (arg-names		())
           (binders		()))
      ;; TODO what about redefining a function? e.g. number->string in libc.l
      (push *vm-function-registry* (list upper-name fixed?))
      (let ((entries args))
        (while (pair? entries)
          (let* ((entry		(ensure-list (first entries)))
                 (arg-name	(pop entry))
                 (type		(pop entry))
                 (unbox?	true)
                 default-value
                 default-value?)
            (when (= '_ type)
              (set type ()))
            (when (pair? entry)
              (set default-value (pop entry))
              (if (= '_ default-value)
                  (set default-value ())
                (set default-value? true)))
            (list-do prop entry
              (case prop
                (nounbox	(set unbox? ()))
                (else		(error "define-vm-function: unexpected property "prop))))
            (assert (or (not type) (symbol? type)))
            (push arg-names arg-name)
            (let* ((type-entry		(when type
                                          (or (assq type *vm-function-type-accessors*)
                                              `(,type (is ,type) ()))))
                   (type-checker	(second type-entry))
                   (unboxer		(third type-entry)))
              (push binders `(if (pair? __args)
                                 (let ()
                                   (set ,arg-name (get/head __args))
                                   ,@(when type-checker
                                       ;; TODO this emits quite some redundancy
                                       `((safety 1 (assert (,@type-checker ,arg-name) ,(symbol->string upper-name)": arg '",(symbol->string arg-name)"' is not of type ",(symbol->string type)))))
                                   ,@(when (and unbox?
                                                unboxer)
                                       ;; qq is broken... `((set ,arg-name (,unboxer arg-name)))
                                       (list (list 'set arg-name (concat-list unboxer (cons arg-name ())))))
                                   (set __args (get/tail __args)))
                               ,(if default-value?
                                    `(set ,arg-name ,default-value)
                                  `(%not-enough-arguments ,(symbol->string upper-name) -args-))))))
          (set entries (cdr entries)))
        ;; handle &rest arg
        (unless (= '_ entries)
          (push binders (if entries    ; i.e. it was in a cdr position
                            `(set ,entries __args)
                          `(safety 1 (when __args (%too-many-arguments ,(symbol->string upper-name) -args-)))))
          (when entries
            (push arg-names entries))))
      (set binders	(list-reverse! binders))
      (set arg-names	(list-reverse! arg-names))
      (let* ((effective-impl-name (if body
                                      (if impl-name? impl-name upper-name)
                                    upper-name))
             (impl (when (and body
                              effective-impl-name)
                     `((define-function ,effective-impl-name ,arg-names
                         ;; TODO add these: (safety 1 (assert (is <env> env) "environment-define: env is not of type <env>: "env))
                         ,@body)))))
        `(let ()
           ,@impl
           (define-function ,stub-name (-args- -ctx-)
             ;; bind the args
             (let (,@(when binders `((__args -args-)))
                   ,@arg-names)
               ,@binders
               ,@(if effective-impl-name
                     `((,effective-impl-name ,@arg-names))
                   body))))))))

(define-function print-backtrace ()
  (platform/diag-print "print-backtrace is not available in this build\n"))

(define-vm-function abort _
  (when (<= 3 *error-level*)
    (fatal "ABORTING at error level " *error-level*))
  (print-backtrace)
  (platform/flush-streams)
  (platform/halt))
