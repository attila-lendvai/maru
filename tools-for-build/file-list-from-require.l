;;; -*- mode: lisp; coding: us-ascii -*-

(define *files* ())

(define-function fake-require (path)
  (unless (member? path *files*)
    ;;(println "files: " *files*)
    ;;(println "Fake-loading: "path)
    (push *files* path)
    (let* ((file	(or (file-open path "r")
                            (error "failed to open file "path)))
           (stream	(file-stream file))
           form)
      (until (= +end+ (set form (read stream)))
        (when (and (pair? form)
                   (member? (first form) '(load require)))
          (let ((path (second form)))
            (when (pair? path)
              (set path (eval path)))
            (fake-require path))))
      (file-close file))))

(while *command-line-arguments*
  (fake-require (pop *command-line-arguments*)))

;;(println "Done with fake-loading, loaded "(list-length *load-history*)" files; cla is: "*command-line-arguments*)

(list-do path *files*
  (println path))
