#!/bin/sh
#| -*- mode: lisp; coding: utf-8-unix -*-

# usage:
# ./build.sh
# LISP=~/workspace/sbcl/run-sbcl.sh ./build.sh

# this is not too tied to SBCL, but it won't work out of the box on anything else as is.

SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`readlink -f ${SCRIPT_DIR}`

if [ -z $LISP ]; then
    LISP=sbcl
    # LISP=../sbcl/run-sbcl.sh
    # LISP=`readlink -f ${LISP}`
fi

# make quicklisp available below in the lisp code.
# and get a fresh enough ASDF also.
if [ ! -d build ]; then
    mkdir -p ${SCRIPT_DIR}/build/quicklisp/local-projects/

    #
    # get a recent enough ASDF
    #
    cd ${SCRIPT_DIR}/build/quicklisp/local-projects/
    git clone git@common-lisp.net:asdf/asdf.git
    cd asdf
    git checkout 3.3.4
    make

    #
    # get a recent slime/swank
    #
    cd ${SCRIPT_DIR}/build/quicklisp/local-projects/
    git clone https://github.com/slime/slime.git
    cd slime
    git checkout faa0c6a0b7c77f6a2db8d3244f24563106857944

    #
    # get quicklisp and load/install it under build/
    #
    cd ${SCRIPT_DIR}/build/
    wget http://beta.quicklisp.org/quicklisp.lisp
    ${LISP} --no-userinit --no-sysinit --load quicklisp.lisp --eval "(quicklisp-quickstart:install :path \"${SCRIPT_DIR}/build/quicklisp\" :dist-url \"http://beta.quicklisp.org/dist/quicklisp/2020-03-25/distinfo.txt\")" --quit
fi

cd "${SCRIPT_DIR}"

export CL_SOURCE_REGISTRY="(:source-registry (:directory \"${SCRIPT_DIR}\") (:tree \"${SCRIPT_DIR}/build/quicklisp/local-projects/\") :ignore-inherited-configuration)"
export ASDF_OUTPUT_TRANSLATIONS="(:output-translations (t (\"${SCRIPT_DIR}/build/fasls/\" :implementation \"root/\")) :ignore-inherited-configuration)"

echo Building bootstrap executable using \'${LISP}\', CL_SOURCE_REGISTRY is \'${CL_SOURCE_REGISTRY}\', ASDF_OUTPUT_TRANSLATIONS is \'${ASDF_OUTPUT_TRANSLATIONS}\'

ln -sf bootstrap/common-lisp/maru ../../eval.cl

# and now let's switch over to lisp...

exec ${LISP} --no-sysinit --no-userinit --script "$0" --end-toplevel-options $@

# let's quit the shell part in case the shell interpreter accidentally runs on the lisp stuff below
exit 0

|#

(in-package :cl-user)

(let ((quicklisp-init "build/quicklisp/setup.lisp"))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(require :asdf)

(format t "~2&Running on ~A ~A, using ASDF ~A, Quicklisp dist version ~A~%"
        (lisp-implementation-type)
        (lisp-implementation-version)
        (asdf:asdf-version)
        (or #+quicklisp (ql:dist-version "quicklisp")
            "n/a"))

;; initiate asdf upgrade
(asdf:load-system :asdf)
;; this is not strictly needed
(asdf:load-system :uiop)

(format t "Lisp side speaking, will (asdf:load-system :maru) now and dump an executable image~%")

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; quicklisp doesn't hook into :defsystem-depends-on (?), so we need to quickload it explicitly
  (ql:quickload :hu.dwim.logger)
  (ql:quickload :maru+hu.dwim.logger)
  (asdf:load-system :swank)
  (ql:quickload :net.didierverna.clon))

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; this is an arbitrary list of pretty much everything. without this swank would try to load them when connecting
  ;; which would not work.
  (swank:swank-require (append '("SWANK-TRACE-DIALOG" "SWANK-PACKAGE-FU" "SWANK-ARGLISTS" "SWANK-REPL" "SWANK-SPROF"
                                 "SWANK-CLIPBOARD" "SWANK-PRESENTATIONS" "SWANK-INDENTATION" "SWANK-FUZZY" "SWANK-C-P-C"
                                 "SWANK-FANCY-INSPECTOR" "SWANK-UTIL" "SB-CLTL2"
                                 "SWANK-ASDF" "asdf" "ASDF")
                               #+sbcl
                               '("SB-SPROF" "SB-GROVEL" "SWANK-SBCL-EXTS")))
  (ql:quickload :net.didierverna.clon))

(in-package :maru.eval)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (net.didierverna.clon:nickname-package))

(defun invoke-slime-debugger (condition previous-hook)
  (declare (ignore previous-hook))
  (maru.error "There was an error: ~A" condition)
  (maru/print-backtrace :stream *debug-io*)
  (finish-output *debug-io*)
  (maru.error "Waiting for a slime/swank connection to present the error in the slime debugger. Press C-c to exit.")
  (format *debug-io* "Waiting for a Slime/Swank connection to present the error in SLDB.~%")
  (loop
    :until (or swank::*emacs-connection*
               (swank::default-connection))
    :do
    (write-string "." *debug-io*)
    (finish-output *debug-io*)
    (sleep 1))
  (let (#+sbcl(sb-debug:*stack-top-hint* (sb-di:top-frame)))
    (swank:swank-debugger-hook condition nil)))

(defun install-debugger-hook ()
  (declare (optimize debug))
  #+sbcl ;; --script also disables the debugger, so let's turn it back on
  (sb-ext:enable-debugger)
  (setf *debugger-hook* 'invoke-slime-debugger)
  #+nil ;; TODO delme?
  (progn
    (sb-ext:disable-debugger)
    (setf sb-ext:*invoke-debugger-hook* invoke-slime-debugger)))

(clon:defsynopsis (:postfix "FILES...")
  (text :contents
        "Common Lisp implementation of maru.")
  (group (:header "Flags:")
         (flag :short-name "h" :long-name "help"
               :description "Print this help and exit.")
         (flag :short-name "v" ;; :long-name ""
               :description "ignored, only for compatibility")
         (flag :short-name "b" ;; :long-name ""
               :description "Don't try to load boot.l")
         (flag :short-name "g" ;; :long-name ""
               :description "ignored, only for compatibility")
         (flag :short-name "O" ;; :long-name ""
               :description "ignored, only for compatibility"))
  (group (:header "Options with arguments:")
         (stropt :long-name "swank-port"
                 :argument-name "4005"
                 :description "Start swank on this port, defaulting to 4005. Zero means don't start swank.")))

(defun toplevel ()
  (restart-case
      (let ((swank-port 4005)
            (logger (hu.dwim.logger:find-logger 'maru)))
        (setf (hu.dwim.logger:log-level/runtime logger) hu.dwim.logger:+info+)
        (clon:make-context)
        (when (or (clon:getopt :long-name "help")
                  (not (clon:cmdline-p)))
          (clon:help)
          (clon:exit))
        #+sbcl
        (flet ((signal-handler (signal code scp)
                 (declare (ignore signal code scp))
                 (format *error-output* "~%SIGTERM/SIGINT was received, initiating shutdown~%")
                 (uiop:quit)))
          (sb-sys:enable-interrupt sb-unix:sigterm #'signal-handler)
          (sb-sys:enable-interrupt sb-unix:sigint #'signal-handler))
        (awhen (clon:getopt :long-name "swank-port")
          (setf swank-port (parse-integer it :junk-allowed t))
          (unless swank-port
            (error "Invalid swank port ~S" it)))
        (unless (zerop swank-port)
          (maru.debug "Starting a swank server on port ~S" swank-port)
          (let ((swank::*loopback-interface* "127.0.0.1"))
            (swank:create-server :port swank-port
                                 :style :spawn
                                 :dont-close t)))
        (install-debugger-hook)
        (maru.debug "Remainder arguments are ~S" (clon:remainder))
        (with-new-maru-state
          (let ((load-boot? (not (clon:getopt :short-name "b")))
                (repled nil))
            (flet
                ((build-maru-args-list ()
                   (let ((args (clon:remainder))
                         (maru/args +maru/nil+))
                     (dolist (arg (reverse args))
                       (setf maru/args (maru/cons arg maru/args)))
                     (maru/define (global-namespace-of *eval-context*)
                                  (maru/intern "*arguments*")
                                  maru/args)))
                 (maybe-load-boot ()
                   (when load-boot?
                     (maru.debug "Loading boot.l")
                     (maru/repl #P"boot.l")
                     (setf load-boot? nil))))
              (loop
                :with args-var = (build-maru-args-list)
                :for cell = (maru/get-var args-var) :then (maru/cdr cell)
                :until (maru/nil? cell)
                :for arg = (maru/car cell)
                :do (progn
                      (maybe-load-boot)
                      ;; NOTE the arg voodoo in eval.c is not mirrored perfectly here
                      (maru/set-var args-var (maru/get-tail cell))
                      (maru.debug "About to REPL file ~S" arg)
                      (maru/repl (pathname arg))
                      (setf repled t)))
              (unless repled
                (maybe-load-boot)
                (maru.debug "Entering interactive REPL on *terminal-io*")
                (maru/repl *terminal-io* :output-stream *terminal-io* :prompt ".")
                (format t "morituri te salutant~%"))))))
    (abort ()
      :report "Exit the lisp vm."
      (uiop:die 42 "Game over."))))

(setf uiop:*image-entry-point* 'toplevel)

(uiop:dump-image "maru" :executable t)
