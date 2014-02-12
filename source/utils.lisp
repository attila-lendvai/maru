(in-package :maru.eval)

(defun not-yet-implemented (&optional (datum "Not yet implemented." datum?) &rest args)
  (when datum?
    (setf datum (concatenate 'string "Not yet implemented: " datum)))
  (apply #'cerror "Ignore and continue" datum args))

(defun not-yet-implemented/crucial-api (name)
  (warn "~S is not implemented on your platform! This may lead to runtime errors later..." name)
  `(error "~S is not implemented on your platform, sorry..." ',name))

(defun if-symbol-exists (package name)
  (if (and (find-package (string package))
           (find-symbol (string name) (string package)))
      '(:and)
      '(:or)))

;;;
;;; from alexandria
;;;
(defun maybe-intern (name package)
  (values
   (if package
       (intern name (if (eq t package) *package* package))
       (make-symbol name))))

(defun format-symbol (package control &rest arguments)
  "Constructs a string by applying ARGUMENTS to string designator CONTROL as
if by FORMAT within WITH-STANDARD-IO-SYNTAX, and then creates a symbol named
by that string.

If PACKAGE is NIL, returns an uninterned symbol, if package is T, returns a
symbol interned in the current package, and otherwise returns a symbol
interned in the package designated by PACKAGE."
  (maybe-intern (with-standard-io-syntax
                  (apply #'format nil (string control) arguments))
                package))

(defun symbolicate (&rest things)
  "Concatenate together the names of some strings and symbols,
producing a symbol in the current package."
  (let* ((length (reduce #'+ things
                         :key (lambda (x) (length (string x)))))
         (name (make-array length :element-type 'character)))
    (let ((index 0))
      (dolist (thing things (values (intern name)))
        (let* ((x (string thing))
               (len (length x)))
          (replace name x :start1 index)
          (incf index len))))))

(defun ensure-list (list)
  "If LIST is a list, it is returned. Otherwise returns the list designated by LIST."
  (if (listp list)
      list
      (list list)))

#+nil
(defun make-gensym-list (length &optional (x "G"))
  "Returns a list of LENGTH gensyms, each generated as if with a call to MAKE-GENSYM,
using the second (optional, defaulting to \"G\") argument."
  (let ((g (if (typep x '(integer 0)) x (string x))))
    (loop repeat length
          collect (gensym g))))

#+nil
(defmacro once-only (specs &body forms)
  "Evaluates FORMS with symbols specified in SPECS rebound to temporary
variables, ensuring that each initform is evaluated only once.

Each of SPECS must either be a symbol naming the variable to be rebound, or of
the form:

  (symbol initform)

Bare symbols in SPECS are equivalent to

  (symbol symbol)

Example:

  (defmacro cons1 (x) (once-only (x) `(cons ,x ,x)))
  (let ((y 0)) (cons1 (incf y))) => (1 . 1)
"
  (let ((gensyms (make-gensym-list (length specs) "ONCE-ONLY"))
        (names-and-forms (mapcar (lambda (spec)
                                   (etypecase spec
                                     (list
                                      (destructuring-bind (name form) spec
                                        (cons name form)))
                                     (symbol
                                      (cons spec spec))))
                                 specs)))
    ;; bind in user-macro
    `(let ,(mapcar (lambda (g n) (list g `(gensym ,(string (car n)))))
                   gensyms names-and-forms)
       ;; bind in final expansion
       `(let (,,@(mapcar (lambda (g n)
                           ``(,,g ,,(cdr n)))
                         gensyms names-and-forms))
          ;; bind in user-macro
          ,(let ,(mapcar (lambda (n g) (list (car n) g))
                         names-and-forms gensyms)
             ,@forms)))))

#+nil
(defmacro with-open-file* ((stream filespec &key direction element-type
                                   if-exists if-does-not-exist external-format)
                           &body body)
  "Just like WITH-OPEN-FILE, but NIL values in the keyword arguments mean to use
the default value specified for OPEN."
  (once-only (direction element-type if-exists if-does-not-exist external-format)
    `(with-open-stream
         (,stream (apply #'open ,filespec
                         (append
                          (when ,direction
                            (list :direction ,direction))
                          (when ,element-type
                            (list :element-type ,element-type))
                          (when ,if-exists
                            (list :if-exists ,if-exists))
                          (when ,if-does-not-exist
                            (list :if-does-not-exist ,if-does-not-exist))
                          (when ,external-format
                            (list :external-format ,external-format)))))
       ,@body)))

#+nil
(defmacro with-input-from-file ((stream-name file-name &rest args
                                             &key (direction nil direction-p)
                                             &allow-other-keys)
                                &body body)
  "Evaluate BODY with STREAM-NAME to an input stream on the file
FILE-NAME. ARGS is sent as is to the call to OPEN except EXTERNAL-FORMAT,
which is only sent to WITH-OPEN-FILE when it's not NIL."
  (declare (ignore direction))
  (when direction-p
    (error "Can't specifiy :DIRECTION for WITH-INPUT-FROM-FILE."))
  `(with-open-file* (,stream-name ,file-name :direction :input ,@args)
     ,@body))

;;;
;;; from hu.dwim.util
;;;
(defun handle-otherwise/value (otherwise &key default-message)
  (setf default-message (ensure-list default-message))
  (case otherwise
    (:error  (apply #'error (or default-message (list "Otherwise assertion failed"))))
    (:cerror (apply #'cerror "Continue" (or default-message (list "Otherwise assertion failed"))))
    (:warn   (apply #'warn (or default-message (list "Otherwise assertion failed"))))
    (t (cond
         ((and (consp otherwise)
               (member (first otherwise) '(:error error :cerror cerror :warn warn) :test #'eq))
          (assert (not (null (rest otherwise))))
          (ecase (first otherwise)
            ((error :error)   (apply #'error  (rest otherwise)))
            ((cerror :cerror) (apply #'cerror (list* "Continue by returning (VALUES)" (rest otherwise))))
            ((warn :warn)     (apply #'warn   (rest otherwise))))
          (values))
         ((functionp otherwise)
          (funcall otherwise))
         (t
          otherwise)))))
