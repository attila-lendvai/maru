(in-package :maru/test)

(defsuite (test :in root-suite))

(defmacro deftest (name args &body body)
  `(hu.dwim.stefil:deftest ,name ,args
     (let ((*print-circle* t)
           ;; delme? (*default-pathname-defaults* (asdf:system-relative-pathname :maru ""))
           )
       (with-new-maru-state
         ,@body))))

(defun read-and-run (expr)
  (maru/eval (maru/expand (maru/read-expression expr))))

(defixture stage-001
  (let ((dir (asdf:system-relative-pathname :maru "build/stage-001")))
    (unless (uiop:directory-exists-p dir)
      (ensure-directories-exist (asdf:system-relative-pathname :maru "build/"))
      (with-output-to-string (output)
        (uiop:run-program `("git" "clone" "--branch" "stage-001" ,(namestring (asdf:system-relative-pathname :maru "")) ,(namestring dir))
                          :output output :error-output output))))
  (-body-))

(defun stage-001-file-pathname (name)
  (uiop:merge-pathnames* name (asdf:system-relative-pathname :maru "build/stage-001/")))

(defun load-boot.l ()
  ;; boot.l unconditionally expects *arguments*
  (with-fixture stage-001
    (with-logger-level (maru +warn+)
      (maru/define (global-namespace-of *eval-context*)
                   (maru/intern "*arguments*")
                   +maru/nil+)
      (maru/repl (stage-001-file-pathname "boot.l")))))

(deftest (test/boot.l :auto-call nil) ()
  (finishes (load-boot.l)))
