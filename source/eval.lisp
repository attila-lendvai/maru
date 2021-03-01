(in-package :maru.eval)

;; The following state/types are shared between the implemented maru VM and the hosting lisp VM:
;; - Pair is CL cons cells
;; - Symbol (maru symbols are all CL:INTERN'd into the CL package called "MARU" (including the nil and t symbols, which have no special meaning in maru))
;; - the maru nil concept/abstraction is mapped to CL:NIL and can be denoted in maru syntax using () (i.e. *not* by writing 'nil')
;; - String
;; - Long
;; - Double
;; - Array
;; - other maru types are wrapped into CL structs
;; - the gc/memory model
;;
;; Anything else leaking into the maru universe is a bug.

;; helper for the debug output
(defparameter *eval-depth* 0)
(defparameter *backtrace* (list))

(defparameter *current-file* nil)

(defmacro with-file-input ((var path) &body body)
  `(let ((*current-file* ,path))
     (with-open-file (,var *current-file*)
       ,@body)))

;; this is ugly and ought to be generated not hand written...
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
                     (head +maru/nil+)
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
                  (setf head (maru/cons obj +maru/nil+))
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
                    (setf obj (maru/cons obj +maru/nil+))
                    (setf tail (maru/set-tail tail obj))))))
            (read-number (first-char)
              (reader.dribble "Reading a number")
              (let* ((c nil))
                (flet
                    ((slurp-digits (first-char predicate)
                       (with-output-to-string (buffer)
                         (when first-char
                           (write-char first-char buffer))
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
                            (or (string= body "0")
                                (string= body "-0")))
                       (let ((hex-digits (slurp-digits nil 'is-digit16?))
                             (minus? (eql (elt body 0) #\-)))
                         (setf body "#x")
                         (when minus?
                           (setf body (concatenate 'string body "-")))
                         (setf body (concatenate 'string body hex-digits))
                         #+nil ; TODO delme
                         (iter (for digit :in-vector hex-digits)
                               (for position :downfrom (length hex-digits))
                               (incf number (* position 16 (digit-char-p digit 16)))))))
                    (unread c)
                    (reader.dribble "About to call cl:read-from-string on ~S" body)
                    ;; NOTE we don't care much about security here...
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
                    (maru/list prefix object))))
            (backquote ()
              (let ((object (maru/read-expression input))
                    (prefix (maru/intern "quasiquote")))
                (if (eq object 'done)
                    ;; shouldn't this just error instead?
                    prefix
                    (maru/list prefix object))))
            (quoted ()
              (let ((object (maru/read-expression input))
                    (prefix (maru/intern "quote")))
                (if (eq object 'done)
                    ;; shouldn't this just error instead?
                    prefix
                    (maru/list prefix object))))
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
              (with-output-to-string (*standard-output*)
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
                              ;; TODO a CODE-CHAR call may very well not be compatible with whatever happens in C, which is probably UTF-16.
                              (write-char (code-char (+ (ash (digit-value a) 12)
                                                        (ash (digit-value b) 8)
                                                        (ash (digit-value c) 4)
                                                        (digit-value d))))))
                           (t
                            (when (alphanumericp char)
                              (read-error "Illelgal character escape: ~S" char))
                            (write-char c)))))
                      (t
                       (write-char c))))))))
         (let ((result (start)))
           (unless (eq result 'done)
             (valid-maru-expression-or-die result))
           result))))
    (string
     (let ((*current-file* "from a string"))
       (with-input-from-string (stream input)
         (maru/read-expression stream))))
    (pathname
     (with-file-input (stream input)
       (maru/read-expression stream)))))

(defun maru/repl (input-stream-designator &key output-stream prompt)
  (etypecase input-stream-designator
    (stream
     (loop
       :with input = input-stream-designator
       :with output = (or output-stream
                          (make-broadcast-stream))
       :do
       (when prompt
         (write-string prompt output)
         (finish-output output))
       (let ((expr (maru/read-expression input)))
         (when (eq expr 'done)
           (return))
         (let* ((global-env (maru/get-var (globals-of *eval-context*)))
                (expanded (maru/expand expr global-env)))
           (let ((evaluated (maru/eval expanded global-env)))
             (eval.dribble "repl about to print, result is ~S" evaluated)
             (maru/print evaluated :stream output)
             (terpri output))))))
    (string
     (let ((*current-file* "from a string"))
       (with-input-from-string (stream input-stream-designator)
         (maru/repl stream))))
    (pathname
     (with-file-input (stream input-stream-designator)
       (maru/repl stream)))))

(defun maru/find-form-function (env var)
  ;; TODO shouldn't we fail early here instead of returning with nil?
  (when (typep var 'maru/symbol)
    (let ((var (maru/find-variable env var :otherwise nil)))
      (when var
        (let ((value (maru/get-var var)))
          (when (maru/form? value)
            (maru/form/function value)))))))

(defun maru/find-form-symbol (env var)
  (assert (maru/symbol? var))
  (let ((var (maru/find-variable env var :otherwise nil)))
    (when var
      (let ((value (maru/get-var var)))
        (when (maru/form? value)
          (maru/form/symbol value))))))

(defun maru/expand-list (expression-list env)
  (valid-maru-expression-or-die
   (if (maru/pair? expression-list)
       (let ((head (maru/expand (maru/get-head expression-list) env))
             (tail (maru/expand-list (maru/get-tail expression-list) env)))
         (maru/cons head tail))
       (maru/expand expression-list env))))

(defun maru/eval-list (object env)
  (if (typep object 'maru/pair)
      (let ((head (maru/eval (maru/get-head object) env))
            (tail (maru/eval-list (maru/get-tail object) env)))
        (maru/cons head tail))
      object))

(defun maru/eval (object &optional (env (global-namespace-of *eval-context*)))
  (let ((*eval-depth* (1+ *eval-depth*))
        (*backtrace* (list* (list :eval object :environment env) *backtrace*))
        (type-index (maru/type-of object)))
    (eval.debug "EVAL~S> ~S" *eval-depth* object)
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
         (eval.debug "EVAL~S< yields ~S" *eval-depth* head)
         head))
      (#.+maru/type-index/symbol+
       (let* ((ass (maru/find-variable env object :otherwise :error))
              (result (maru/get-tail ass)))
         (eval.debug "EVAL~S< yields ~S" *eval-depth* result)
         result))
      (t
       (error "Don't know how to evaluate ~S, of type-index ~S" object type-index)))))

(defun maru/expand (expression &optional (env (global-namespace-of *eval-context*)))
  (let ((*eval-depth* (1+ *eval-depth*))
        (*backtrace* (list* (list :expand expression :environment env) *backtrace*)))
    (expander.debug "EXPAND~S> ~S" *eval-depth* expression)
    (let ((result expression))
      (cond
        ((typep expression 'maru/pair)
         (let* ((head (maru/expand (maru/get-head expression) env))
                (form (maru/find-form-function env head)))
           (expander.dribble "expand (of a pair) looked up ~S to form ~S" expression form)
           (when form
             (let* ((head (maru/apply form (maru/get-tail expression) env))
                    (expanded (maru/expand head env)))
               (eval.dribble "EXPAND~S< => ~S" *eval-depth* expanded)
               (return-from maru/expand (valid-maru-expression-or-die expanded))))
           (let ((tail (maru/get-tail expression)))
             (when (not (eq (maru/intern "quote") head))
               (setf tail (maru/expand-list tail env)))
             (when (and (eq (maru/intern "set") head)
                        (maru/pair? (maru/car tail))
                        (maru/symbol? (maru/car (maru/car tail))))
               (let* ((name (maru/get-head (maru/get-head tail)))
                      (setter-name (maru/intern (concatenate 'string "set-" (symbol-name name)))))
                 (setf head setter-name)
                 (setf tail (maru/append (maru/get-tail (maru/get-head tail))
                                         (maru/get-tail tail)))))
             (setf result (maru/cons head tail)))))
        ((typep expression 'maru/symbol)
         (assert (maru/symbol? expression))
         (let ((form (maru/find-form-symbol env expression)))
           (expander.dribble "expand (of a symbol) looked up ~S to form ~S" expression form)
           ;; FIXME there shouldn't be an AND there... smells fishy.
           (when (and form
                      (not (maru/nil? form)))
             (let* ((args (maru/cons expression +maru/nil+))
                    (applied (maru/apply form args +maru/nil+))
                    (expanded (maru/expand applied env)))
               (setf result expanded))))))
      (expander.debug "EXPAND~S< ~S => ~S" *eval-depth* expression result)
      (valid-maru-expression-or-die result))))

(defun maru/apply (function arguments env)
  (let ((*eval-depth* (1+ *eval-depth*))
        (*backtrace* (list* (list :apply function :arguments arguments :environment env) *backtrace*)))
    (eval.dribble "APPLY~S> ~S to ~S" *eval-depth* function arguments)
    (cond
      ((maru/expr? function)
       (let* ((defn (maru/expr/definition function))
              (formals (maru/car defn))
              (actuals arguments)
              ;; (caller env)
              (callee (maru/expr/environment function)))
         (loop
           :while (maru/pair? formals)
           :do
           (unless (maru/pair? actuals)
             (error "Too few arguments while applying ~S to ~S" function arguments))
           (let ((tmp (maru/cons (maru/get-head formals)
                                 (maru/get-head actuals))))
             (setf callee (maru/cons tmp callee))
             (setf formals (maru/get-tail formals))
             (setf actuals (maru/get-tail actuals))))
         (when (maru/symbol? formals)
           (let ((tmp (maru/cons formals actuals)))
             (setf callee (maru/cons tmp callee))
             (setf actuals +maru/nil+)))
         (unless (maru/nil? actuals)
           (error "Too many arguments applying ~S to ~S" function arguments))
         (when (locals-are-namespace? *eval-context*)
           (let ((tmp (maru/cons (maru/intern "*locals*")
                                 +maru/nil+)))
             (setf callee (maru/cons tmp callee))
             (maru/set-tail tmp callee)))
         (let ((ans +maru/nil+)
               (body (maru/cdr defn)))
           (loop
             :while (maru/pair? body)
             :do
             (setf ans (maru/eval (maru/get-head body) callee))
             (setf body (maru/get-tail body)))
           (eval.dribble "APPLY~S< => ~S" *eval-depth* ans)
           ans)))
      ((maru/fixed? function)
       (maru/apply (maru/fixed/function function) arguments env))
      ((maru/subr? function)
       (funcall (maru/subr/impl function) arguments env))
      (t
       (let ((applicator (maru/array-at (maru/get-var (applicators-of *eval-context*))
                                        (maru/type-of function))))
         (if applicator
             (let ((result (maru/apply applicator (maru/cons function arguments) env)))
               (eval.dribble "APPLY~S< => ~S" *eval-depth* result)
               result)
             (error "Don't know how to apply ~S" function)))))))

(defun maru/print-backtrace (&key (stream *standard-output*))
  (with-standard-io-syntax
    (let ((*standard-output* stream)
          (*print-circle* t)
          (*print-readably* nil)
          (*print-pretty* t)
          (*print-level* 4)
          (*print-length* 10)
          (*print-escape* nil)
          (*package* (find-package :maru))
          ;; TODO factor out printing to somewhere somehow...
          (*readtable* (let ((table (with-standard-io-syntax
                                      (copy-readtable *readtable*))))
                         (setf (readtable-case table) :preserve)
                         table)))
      (iter
        (for frame :in *backtrace*)
        (for index :upfrom 0)
        (destructuring-bind
              (&key expand eval apply environment arguments)
            frame
          (declare (ignore environment))
          (format t "~&~3,'0D: " index)
          (handler-bind
              ((serious-condition (lambda (error)
                                    (format t "<error while printing frame, of type: ~S>~%" (type-of error))
                                    (next-iteration))))
            (cond
              (eval
               (format t "E ~S~%" eval))
              (expand
               (format t "X ~S~%" expand))
              (apply
               (format t "A ~A to ~S~%" apply arguments))
              (t
               (error "unexpected frame in backtrace")))))))))
