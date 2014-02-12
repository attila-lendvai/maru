
;; enforce loading logger before maru to have the option for smarter logging

(defsystem :maru+hu.dwim.logger
  :defsystem-depends-on (:hu.dwim.logger)
  :depends-on (:maru))
