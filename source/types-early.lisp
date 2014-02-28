(in-package :maru.eval)

;; if you change anything here, then make sure that the assumptions in boot.l are in sync (e.g. predefined type indexes)

(declaim (inline maru/pair? maru/symbol? maru/string? maru/nil? maru/long?
                 maru/intern
                 maru/cons maru/get-head maru/get-tail maru/append maru/length
                 maru/car maru/cdr maru/cddr maru/rest maru/first maru/second maru/third
                 maru/bool))

(defun maru/intern (symbol-name)
  (check-type symbol-name string)
  (values (intern symbol-name :maru)))

(define-symbol-macro +maru/nil+ 'maru::|nil|)

(define-compiler-macro maru/intern (&whole form name)
  (if (stringp name)
      `(quote ,(intern name :maru))
      form))

;; map some maru types to cl types, foo -> maru/foo
;; when changing don't forget to update the type-of subr!
(macrolet ((frob (&rest entries)
             `(progn
                ,@(loop
                    :for entry :in entries
                    :collect `(deftype ,(symbolicate '#:maru/ (first entry)) ()
                                ,(second entry))))))
  (frob
   ;; (undefined 'null)
   (double    'double-float)
   (long      '(signed-byte 64))
   (string    'string)
   ;; (character 'character)
   (pair      'cons)
   (symbol    'symbol)
   (array     'array)))

;; define CL constants for type indexes of the predefined types
(macrolet
    ((frob (&rest types)
       `(progn
          ,@(loop
              :for type :in types
              :for index :upfrom 0
              :collect `(defconstant ,(symbolicate "+MARU/TYPE-INDEX/" type "+") ,index)))))
  (frob #:undefined #:data #:long #:double #:string #:symbol #:pair #:_array #:array #:expr #:form #:fixed #:subr))

(defun maru/pair? (thing)
  (typep thing 'maru/pair))

(defun maru/string? (thing)
  (typep thing 'maru/string))

(defun maru/symbol? (thing)
  (and (symbolp thing)
       (progn
         (assert (eq (symbol-package thing) (find-package :maru)))
         t)))

(defun maru/nil? (thing)
  (eq thing (maru/intern "nil")))

(defun maru/long? (thing)
  (if (typep thing 'maru/long)
      thing
      nil))

(defun maru/bool (value)
  (if value
      (maru/intern "t")
      (maru/intern "nil")))

(defun maru/cons (car cdr)
  (cons (or car (maru/intern "nil"))
        (or cdr (maru/intern "nil"))))

(defun maru/length (object)
  (loop
    :for cell = object :then (maru/cdr cell)
    :until (maru/nil? cell)
    :count t))

(defun maru/append (&rest lists)
  ;; TODO there's room to optimize, and this may be fragile, too?
  (let ((result (loop
                  :for list :in lists
                  :nconc (loop
                           :for cell = list :then (maru/cdr cell)
                           :until (maru/nil? cell)
                           :collect (maru/car cell)))))
    (setf (cdr (last result)) +maru/nil+)
    result))

(defmacro maru/list (&rest things)
  `(list* ,@things ',+maru/nil+))

(defun maru/get-head (pair)
  (check-type pair maru/pair)
  (car pair))

(defun maru/set-head (pair value)
  (check-type pair maru/pair)
  (setf value (or value (maru/intern "nil")))
  (setf (car pair) value)
  value)

(defun maru/get-tail (pair)
  (check-type pair maru/pair)
  (cdr pair))

(defun maru/set-tail (pair value)
  (check-type pair maru/pair)
  (setf value (or value (maru/intern "nil")))
  (setf (cdr pair) value)
  value)

(defun maru/car (pair)
  (if (maru/nil? pair)
      (maru/intern "nil")
      (car pair)))

(defun maru/cdr (pair)
  (if (maru/nil? pair)
      (maru/intern "nil")
      (cdr pair)))

(defun maru/cddr (pair)
  (maru/cdr (maru/cdr pair)))

(defun maru/rest (pair)
  (maru/cdr pair))

(defun maru/first (pair)
  (maru/car pair))

(defun maru/second (pair)
  (maru/car (maru/cdr pair)))

(defun maru/third (pair)
  (maru/car (maru/cdr (maru/cdr pair))))

(defun valid-maru-expression-or-die (thing)
  (labels
      ((recurse (form)
         (etypecase form
           (cons
            (recurse (car form))
            (recurse (cdr form))
            form)
           (symbol
            (assert (eq (symbol-package form)
                        (load-time-value (find-package :maru))))
            form)
           ((or maru/long
                maru/double
                maru/string)
            form))))
    (recurse thing))
  thing)
