(in-package :maru.eval)

;; The following state/types are shared between the implemented maru VM and the hosting lisp VM:
;; - Pair is CL cons cells
;; - String
;; - Long
;; - Double
;; - Array
;; - Symbol (maru symbols are all INTERN'd into the CL package called "MARU" (including the maru nil))
;; - other types are wrapped into CL structs
;; - the gc/memory model
;;
;; Anything else leaking into the maru universe is a bug.

(defvar *eval-context*)

;; helper for the debug output
(defparameter *depth* 0)

(defparameter *current-file* nil)

(defparameter *predefined-subr-names* (list))
(defparameter *predefined-fixed-names* (list))

(declaim (inline maru/cons maru/get-head maru/get-tail
                 maru/get-var maru/set-var
                 maru/append maru/length
                 maru/car maru/cdr maru/cddr maru/rest maru/first maru/second maru/third
                 maru/lookup
                 maru/bool))

#+nil
(hu.dwim.defclass-star:defclass* eval-context ()
  (;;(current-line 0)
   ;;(current-path)
   ;;(current-source)
   (locals-are-namespace? nil :type boolean)
   (global-namespace)
   (globals)
   (expanders)
   (evaluators)
   (applicators)))

;; macroexpansion of the above to lower dependencies
(defclass eval-context ()
  (;;(current-line :initform 0 :accessor current-line-of :initarg :current-line)
   ;;(current-path :accessor current-path-of :initarg :current-path)
   ;;(current-source :accessor current-source-of :initarg :current-source)
   (locals-are-namespace? :initform nil :accessor locals-are-namespace? :initarg :locals-are-namespace? :type boolean)
   (global-namespace :accessor global-namespace-of :initarg :global-namespace)
   (globals :accessor globals-of :initarg :globals)
   (expanders :accessor expanders-of :initarg :expanders)
   (evaluators :accessor evaluators-of :initarg :evaluators)
   (applicators :accessor applicators-of :initarg :applicators)))

(defun make-eval-context ()
  (make-instance 'eval-context))

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
    :until (is-nil? cell)
    :count t))

(defun maru/append (&rest lists)
  (loop
    :for list :in lists
    :append (loop
              :for cell = list :then (maru/cdr cell)
              :until (is-nil? cell)
              :collect (maru/car cell))))

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
  (if (is-nil? pair)
      (maru/intern "nil")
      (car pair)))

(defun maru/cdr (pair)
  (if (is-nil? pair)
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

;; FIXME rename to what? find-environment-entry?
(defun maru/find-environment (env &key otherwise)
  ;; TODO rewrite to something lispy
  (loop
    :with entry = env
    :while (typep entry 'maru/pair)
    :for ass = (maru/get-head entry)
    :do (if (and (typep ass 'maru/pair)
                 (eq (maru/get-tail ass) entry))
            (return-from maru/find-environment entry)
            (setf entry (maru/get-tail entry))))
  (handle-otherwise/value otherwise :default-message `("Failed to find environment ~S" ,env)))

(defun maru/find-variable-2 (env name)
  (eval.dribble "MARU/FIND-VARIABLE-2 for ~S in ~S" name env)
  (loop
    :until (is-nil? env)
    :do
    ;; (eval.dribble "MARU/FIND-VARIABLE-2 looking at env ~S" env)
    (let ((ass (maru/get-head env)))
      (if (eq name (maru/car ass))
          (progn
            (eval.dribble "MARU/FIND-VARIABLE-2 is returning with ~S" ass)
            (return-from maru/find-variable-2 ass))
          (setf env (maru/get-tail env)))))
  (eval.dribble "MARU/FIND-VARIABLE-2 is returning without a match")
  nil)

(defun maru/find-variable (env name &key otherwise)
  (loop
    :until (is-nil? env)
    :do (if (eq env (global-namespace-of *eval-context*))
            (let ((ass (maru/find-variable-2 env name)))
              (return-from maru/find-variable
                (or ass
                    (handle-otherwise/value otherwise :default-message `("Failed to find variable ~S" ,name)))))
            (let ((ass (maru/get-head env)))
              (if (eq name (maru/car ass))
                  (return-from maru/find-variable ass)
                  (setf env (maru/get-tail env))))))
  (handle-otherwise/value otherwise :default-message `("Failed to find variable ~S" ,name)))

(defun maru/find-namespace-variable (env name)
  (let ((beg (maru/find-environment env :otherwise :error))
        (end (maru/find-environment (maru/cdr env) :otherwise (maru/intern "nil"))))
    ;;(eval.dribble "MARU/FIND-NAMESPACE-VARIABLE beg ~S end ~S" beg end)
    (loop
      :until (eq beg end)
      :for ass = (maru/car beg)
      :do (if (eq name (maru/car ass))
              (return-from maru/find-namespace-variable ass)
              (setf beg (maru/get-tail beg)))))
  nil)

(defun maru/lookup (env name)
  (maru/cdr (maru/find-variable env name)))

(defun maru/get-var (thing)
  (maru/get-tail thing))

(defun maru/set-var (thing value)
  (maru/set-tail thing value))

(defun maru/define (env name value)
  (let* ((env (maru/find-environment env :otherwise :error))
         (binding (maru/cons nil (maru/get-tail env))))
    (maru/set-tail env binding)
    (setf binding (maru/set-head binding (maru/cons name value)))
    (eval.dribble "Defined new binding, name ~S, value ~S, in env ~S" name value env)
    binding))

(defmacro with-file-input ((var path) &body body)
  `(let ((*current-file* ,path))
     (with-open-file (,var *current-file*)
       ,@body)))

(defun maru/read-expression (input)
  (etypecase input
    (stream
     (with-standard-io-syntax
       (labels
           ((read-error (message &rest args)
              (apply 'error message args))
            (next (&optional (error-at-eof t))
              (let ((c (read-char input nil 'eof)))
                (when (and error-at-eof
                           (eq c 'eof))
                  (read-error "Unexpected end of file"))
                c))
            (unread (char)
              (unread-char char input))
            (next-non-whitespace (&optional (error-at-eof t))
              (loop
                :for c = (next error-at-eof)
                :do (unless (member c '(#\Return #\Newline #\Space #\Tab))
                      (return c))))
            (digit-value (char)
              (let ((code (char-code char)))
                (cond
                  ((<= (char-code #\0) code (char-code #\9))
                   (- code (char-code #\0)))
                  ((<= (char-code #\A) code (char-code #\Z))
                   (+ 10 (- code (char-code #\A))))
                  ((<= (char-code #\a) code (char-code #\z))
                   (+ 10 (- code (char-code #\a))))
                  (t
                   (read-error "Illegal digit in character escape: ~S" char)))))
            (start ()
              (reader.dribble "Reader starts")
              (let ((c (next-non-whitespace nil)))
                (reader.dribble "Reader dispatches on char ~S" c)
                (cond
                  ((eq c 'eof)
                   'done)
                  ((is-digit10? c)
                   (read-number c))
                  (t
                   (case c
                     (#\;
                      (comment))
                     (#\"
                      (string-literal))
                     (#\?
                      (character-literal))
                     (#\'
                      (quoted))
                     (#\`
                      (backquote))
                     (#\,
                      (unquote))
                     (#\(
                      (read-list #\) ))
                     (#\)
                      (unread #\))
                      'done)
                     (#\-
                      (let ((c (next)))
                        (unread c)
                        (cond
                          ((is-digit10? c)
                           (read-number #\-))
                          (t
                           (read-symbol #\-)))))
                     (t
                      (if (is-letter? c)
                          (read-symbol c)
                          (read-error "Illegal character ~S" c))))))))
            (read-list (delimiter)
              (let* ((obj (start))
                     (head (maru/intern "nil"))
                     (tail head))
                (reader.dribble "Reading a list starts with object ~S" obj)
                (flet ((process-eof ()
                         (let ((c (next)))
                           (reader.dribble "Reading a list is returning, last char is ~S" c)
                           (unless (eq c delimiter)
                             (read-error "Mismatched delimiter: expected '~S', found '~S'" delimiter c))
                           (return-from read-list head))))
                  (when (eq obj 'done)
                    (process-eof))
                  (setf head (maru/cons obj nil))
                  (setf tail head)
                  (loop
                    :for obj = (start)
                    :do
                    (reader.dribble "Reading a list continues with object ~S" obj)
                    (when (eq obj 'done)
                      (process-eof))
                    (when (eq obj (maru/intern "."))
                      (setf obj (start))
                      (when (eq obj 'done)
                        (read-error "Missing item after ."))
                      (setf tail (maru/set-tail tail obj))
                      (setf obj (start))
                      (unless (eq obj 'done)
                        (read-error "Extra item after ."))
                      (process-eof))
                    (setf obj (maru/cons obj nil))
                    (setf tail (maru/set-tail tail obj))))))
            (read-number (first-char)
              (reader.dribble "Reading a number")
              (let* ((c nil))
                (flet
                    ((slurp-digits (first-char predicate)
                       (with-output-to-string (buffer)
                         (write-char first-char buffer)
                         (loop
                           (setf c (next nil))
                           (reader.dribble "Next is ~S" c)
                           (unless (funcall predicate c)
                             (return))
                           (write-char c buffer)))))
                  (let ((body (slurp-digits first-char 'is-digit10?)))
                    (reader.dribble "Number body stopped at char ~S" c)
                    (cond
                      ((or (eql c #\.)
                           (eql c #\e))
                       (when (eql c #\.)
                         (reader.dribble "Number slurps the decimals")
                         (setf body (concatenate 'string body (slurp-digits c 'is-digit10?))))
                       (when (eql c #\e)
                         (not-yet-implemented)))
                      ((and (eql c #\x)
                            (or (= (length body) 1)
                                (and (= (length body) 2)
                                     (string= body "-"))))
                       (not-yet-implemented)))
                    (unread c)
                    (reader.dribble "About to call cl:read-from-string on ~S" body)
                    (let* ((*read-default-float-format* 'double-float)
                           (number (cl:read-from-string body)))
                      (reader.dribble "Read number ~S" number)
                      (assert (typep number '(or maru/long maru/double)))
                      number)))))
            (read-symbol (first-char)
              (reader.dribble "Reading a symbol")
              (let* ((name (with-output-to-string (buffer)
                             (write-char first-char buffer)
                             (loop
                               :with c = nil
                               :do
                               (setf c (next nil))
                               (cond
                                 ((eq c 'eof)
                                  (return))
                                 ((or (is-letter? c)
                                      (is-digit10? c))
                                  (write-char c buffer))
                                 (t
                                  (unread c)
                                  (return))))))
                     (symbol (maru/intern name)))
                (reader.dribble "Reader has read symbol ~S" symbol)
                symbol))
            (unquote ()
              (let* ((c (next))
                     (prefix (if (eql c #\@)
                                 (maru/intern "unquote-splicing")
                                 (progn
                                   (unread c)
                                   (maru/intern "unquote"))))
                     (object (maru/read-expression input)))
                (if (eq object 'done)
                    ;; shouldn't this just error instead?
                    prefix
                    (list prefix object))))
            (backquote ()
              (let ((object (maru/read-expression input))
                    (prefix (maru/intern "quasiquote")))
                (if (eq object 'done)
                    ;; shouldn't this just error instead?
                    prefix
                    (list prefix object))))
            (quoted ()
              (let ((object (maru/read-expression input))
                    (prefix (maru/intern "quote")))
                (if (eq object 'done)
                    ;; shouldn't this just error instead?
                    prefix
                    (list prefix object))))
            (character-literal ()
              (char-code (next)))
            (comment ()
              (reader.dribble "Reader starts reading a comment")
              (loop
                (let ((c (next nil)))
                  (case c
                    (eof
                     (return))
                    ((#\Return #\Newline)
                     (unread c)
                     (return)))))
              (start))
            (string-literal ()
              (with-output-to-string (buffer)
                (loop
                  (let ((c (next)))
                    (case c
                      (#\"
                       (return))
                      (#\\
                       (let ((char (next)))
                         (case char
                           (#\a (write-char (code-char #x0a)))
                           (#\b (write-char (code-char #x08)))
                           (#\f (write-char (code-char #x0c)))
                           (#\n (write-char (code-char #x0a)))
                           (#\r (write-char (code-char #x0d)))
                           (#\t (write-char (code-char #x09)))
                           (#\v (write-char (code-char #x0b)))
                           ((#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7)
                            (not-yet-implemented))
                           (#\x
                            (not-yet-implemented))
                           (#\u
                            (let ((a (next))
                                  (b (next))
                                  (c (next))
                                  (d (next)))
                              ;; TODO a CODE-CHAR call may very well not be comparible with whatever happens in C, which is probably UTF-16.
                              (write-char (code-char (+ (ash (digit-value a) 12)
                                                        (ash (digit-value b) 8)
                                                        (ash (digit-value c) 4)
                                                        (digit-value d)))
                                          buffer)))
                           (t
                            (when (alphanumericp char)
                              (read-error "Illelgal character escape: ~S" char))
                            char))))))))))
         (start))))
    (string
     (let ((*current-file* "from a string"))
       (with-input-from-string (stream input)
         (maru/read-expression stream))))
    (pathname
     (with-file-input (stream input)
       (maru/read-expression stream)))))

(defun maru/repl-on-stream (stream-designator)
  (etypecase stream-designator
    (stream
     (loop
       :with input = stream-designator
       :do
       (let ((expr (maru/read-expression input)))
         (when (eq expr 'eof)
           (return))
         (let* ((global-env (maru/get-var (globals-of *eval-context*)))
                (expanded (maru/expand expr global-env)))
           (let ((evaluated (maru/eval expanded global-env)))
             (eval.dribble "repl before printing, result is ~S" evaluated))))))
    (string
     (let ((*current-file* "from a string"))
       (with-input-from-string (stream stream-designator)
         (maru/repl-on-stream stream))))
    (pathname
     (with-file-input (stream stream-designator)
       (maru/repl-on-stream stream)))))

(defun maru/find-form-function (env var)
  ;; TODO shouldn't we fail early here instead of returning with nil?
  (when (typep var 'maru/symbol)
    (let ((var (maru/find-variable env var)))
      (when var
        (let ((value (maru/get-var var)))
          (when (maru/form? value)
            (maru/form/function value)))))))

(defun maru/find-form-symbol (env var)
  (assert (is-symbol? var))
  (let ((var (maru/find-variable env var)))
    (when var
      (let ((value (maru/get-var var)))
        (when (maru/form? value)
          (maru/form/symbol value))))))

(defun maru/expand-list (expression-list env)
  (if (is-pair? expression-list)
      (let ((head (maru/expand (maru/get-head expression-list) env))
            (tail (maru/expand-list (maru/get-tail expression-list) env)))
        (maru/cons head tail))
      (maru/expand expression-list env)))

(defun maru/eval-list (object env)
  (if (typep object 'maru/pair)
      (let ((head (maru/eval (maru/get-head object) env))
            (tail (maru/eval-list (maru/get-tail object) env)))
        (maru/cons head tail))
      object))

(defun maru/eval (object &optional (env (global-namespace-of *eval-context*)))
  (let ((*depth* (1+ *depth*))
        (type-index (maru/type-index-of object)))
    (eval.debug "EVAL~S> ~S" *depth* object)
    (check-type env maru/pair)
    (case type-index
      (#.(list +maru/type-index/undefined+
               +maru/type-index/long+
               +maru/type-index/double+
               +maru/type-index/string+
               +maru/type-index/form+
               +maru/type-index/subr+
               +maru/type-index/fixed+)
       object)
      (#.+maru/type-index/pair+
       (let ((head (maru/eval (maru/get-head object) env)))
         (if (maru/fixed? head)
             (progn
               (eval.dribble "applying fixed ~S" head)
               (setf head (maru/apply (maru/fixed/function head)
                                      (maru/get-tail object)
                                      env)))
             (let ((args (maru/eval-list (maru/get-tail object) env)))
               (setf head (maru/apply head args env))))
         (eval.debug "EVAL~S< yields ~S" *depth* head)
         head))
      (#.+maru/type-index/symbol+
       (let* ((ass (maru/find-variable env object :otherwise :error))
              (result (maru/get-tail ass)))
         (eval.debug "EVAL~S< yields ~S" *depth* result)
         result))
      (t
       (error "Don't know how to evaluate ~S, of type-index ~S" object type-index)))))

(defun maru/expand (expression &optional (env (global-namespace-of *eval-context*)))
  (let ((*depth* (1+ *depth*)))
    (expander.debug "EXPAND~S> ~S" *depth* expression)
    (let ((result expression))
      (cond
        ((typep expression 'maru/pair)
         (let* ((head (maru/expand (maru/get-head expression) env))
                (form (maru/find-form-function env head)))
           (expander.dribble "expand (of a pair) looked up ~S to form ~S" expression form)
           (when form
             (let* ((head (maru/apply form (maru/get-tail expression) env))
                    (expanded (maru/expand head env)))
               (eval.dribble "EXPAND~S< => ~S" *depth* expanded)
               (return-from maru/expand expanded)))
           (let ((tail (maru/get-tail expression)))
             (when (not (eq (maru/intern "quote") head))
               (setf tail (maru/expand-list tail env)))
             (when (and (eq (maru/intern "set") head)
                        (is-pair? (maru/car tail))
                        (is-symbol? (maru/car (maru/car tail))))
               (let* ((name (maru/get-head (maru/get-head tail)))
                      (setter-name (maru/intern (concatenate 'string "set-" (symbol-name name)))))
                 (setf head setter-name)
                 (setf tail (maru/append (maru/get-tail (maru/get-head tail))
                                         (maru/get-tail tail)))))
             (setf result (maru/cons head tail)))))
        ((typep expression 'maru/symbol)
         (let ((form (maru/find-form-symbol env expression)))
           (expander.dribble "expand (of a symbol) looked up ~S to form ~S" expression form)
           ;; FIXME there shouldn't be an AND there... smells fishy.
           (when (and form
                      (not (is-nil? form)))
             (let* ((args (maru/cons expression nil))
                    (applied (maru/apply form args (maru/intern "nil")))
                    (expanded (maru/expand applied env)))
               (setf result expanded))))))
      (expander.debug "EXPAND~S< ~S => ~S" *depth* expression result)
      result)))

(defun maru/apply (function arguments env)
  (let ((*depth* (1+ *depth*)))
    (eval.dribble "APPLY~S> ~S to ~S" *depth* function arguments)
    (cond
      ((maru/expr? function)
       (let* ((defn (maru/expr/definition function))
              (formals (maru/car defn))
              (actuals arguments)
              ;; (caller env)
              (callee (maru/expr/environment function)))
         (loop
           :while (is-pair? formals)
           :do
           (unless (is-pair? actuals)
             (error "Too few arguments while applying ~S to ~S" function arguments))
           (let ((tmp (maru/cons (maru/get-head formals)
                                 (maru/get-head actuals))))
             (setf callee (maru/cons tmp callee))
             (setf formals (maru/get-tail formals))
             (setf actuals (maru/get-tail actuals))))
         (when (is-symbol? formals)
           (let ((tmp (maru/cons formals actuals)))
             (setf callee (maru/cons tmp callee))
             (setf actuals (maru/intern "nil"))))
         (unless (is-nil? actuals)
           (error "Too many arguments applying ~S to ~S" function arguments))
         (when (locals-are-namespace? *eval-context*)
           (let ((tmp (maru/cons (maru/intern "*locals*")
                                 (maru/intern "nil"))))
             (setf callee (maru/cons tmp callee))
             (maru/set-tail tmp callee)))
         (let ((ans (maru/intern "nil"))
               (body (maru/cdr defn)))
           (loop
             :while (is-pair? body)
             :do
             (setf ans (maru/eval (maru/get-head body) callee))
             (setf body (maru/get-tail body)))
           (eval.dribble "APPLY~S< => ~S" *depth* ans)
           ans)))
      ((maru/fixed? function)
       (maru/apply (maru/fixed/function function) arguments env))
      ((maru/subr? function)
       (funcall (maru/subr/impl function) arguments env))
      (t
       (error "Don't know how to apply ~S" function)))))
