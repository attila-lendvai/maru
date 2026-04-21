;;; -*- mode: lisp; coding: us-ascii -*-

;; this whole file is just a load-order KLUDGE waiting to be cleaned up...

;; This loads the emit-*-objects.l files that redefine a couple of
;; functions to emit literals as valid GC objects.
(when (feature emit-with-object-headers)
  (eval-in-host
   '(case *compiler-backend*
     (("i686" "x86-64")
      (load "source/compiler/emit-objects-x86.l"))
     (else
      (load (concat-strings "source/compiler/emit-objects-"*compiler-backend*".l"))))))

(eval-in-host
 `(run-compiler ,*target-env*))

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
     `(let ()
        (let ((print-it (lambda (env-name file-list)
                          (let ((loc (foldr + 0 (map count-maru-loc file-list))))
                            (print-all *error-output* env-name " env loaded "
                                       (list-length file-list) " files, " loc " LoC\n")
                            loc))))
          (print-all
           *error-output*
           "Total: " term/BOLD
           (+ (print-it "Host" ',host-files)
              (print-it "Slave" (slave-value *load-history*)))
           term/RESET" LoC\n")))))
  ())
