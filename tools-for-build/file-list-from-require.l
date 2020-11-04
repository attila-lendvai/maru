;;; -*- mode: lisp; coding: us-ascii -*-

(define *files* ())

(define-function fake-require (path)
  (unless (member? path *files*)
    ;;(println "files: " *files*)
    ;;(println "Fake-loading: "path)
    (push *files* path)
    (let ((forms (or (read path)
                     (error "file not found or empty: "path))))
      (list-do form forms
        (when (and (pair? form)
                   (member? (first form) '(load require)))
          (fake-require (second form)))))))

(while *command-line-arguments*
  (fake-require (pop *command-line-arguments*)))

;;(println "Done with fake-loading, loaded "(list-length *load-history*)" files; cla is: "*command-line-arguments*)

(list-do path *files*
  (println path))
