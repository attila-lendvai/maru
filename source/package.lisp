(in-package :cl-user)

(defpackage :maru.eval
  (:use :common-lisp)
  (:shadow
   ;; shadow some stuff to avoid confusion
   #:eval
   )
  (:documentation "Package for the eval implementation."))

(defpackage :maru
  ;; let's see if the convenience will compensate for all the possible ways we can shoot ourselves in the foot with these...
  #+nil
  (:shadowing-import-from :common-lisp
                          #:nil)
  (:documentation "Package for interning into when reading maru code."))
