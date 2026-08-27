;;; -*- mode: lisp; coding: us-ascii -*-

;; this whole file is just a load-order KLUDGE waiting to be cleaned up...

;; This loads the emit-*-objects.l files that redefine a couple of
;; functions to emit literals as valid GC objects.
(when (feature emit-with-object-headers)
  (eval-in-host
   '(case *compiler-backend*
     (("x86" "arm")
      (load "source/compiler/emit-objects.l"))
     (else
      (load (concat-strings "source/compiler/emit-objects-"*compiler-backend*".l"))))))

;; write out a .dep file that contains a list of the
;; dependencies. used/read by build.l.
(eval-in-host
 `(let ((output-file (pop *command-line-arguments*)))
    (run-compiler ,*target-env* output-file)
    (with-open-stream (stream (concat-string output-file ".dep") "w")
      (dump-all  stream (concat-list ',*load-history* *load-history*))
      (print-all stream "\n"))))

;;;
;;; This prints LoC statistics
;;;

;; TODO currently it takes an extra 3 seconds with the LLVM backend,
;; and a lot more when compiled with the x86 backend.
(when (and () (and bootstrapping?
                   (not evolving?)))
  ;; let's take a snapshot before we load more files
  (let ((host-files (host-value *load-history*)))

    (eval-in-host
     '(let ()
       (require "source/sequences.l")
       (require "source/streams.l")
       (require "source/ansiterm.l")
       ))

    (eval-in-host
     `(let ((host-files ',host-files)
            (slave-files (slave-value *load-history*)))
        (let ((print-it
                (lambda (env-name file-list suffix)
                  (let ((loc (foldr + 0 (map count-maru-loc file-list))))
                    (print-all *debug-output* env-name " env loaded "
                               (list-length file-list) " files, "
                               term/FG-GREEN term/BOLD loc term/RESET" LoC "
                               suffix "\n")
                    loc))))
          (print-it "Host"  host-files  "(the compiler)")
          (print-it "Slave" slave-files "(the next eval)")
          (print-all *debug-output* "Host: "  host-files  "\n")
          (print-all *debug-output* "Slave: " slave-files "\n")
          ))))
  ())
