(defsystem :maru+hu.dwim.logger
  :defsystem-depends-on (:hu.dwim.logger)
  :depends-on (:maru)
  :components ((:module "source"
                :components ((:file "logger")))))
