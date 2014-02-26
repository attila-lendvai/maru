#!/bin/sh
#| -*- mode: lisp; coding: utf-8-unix -*-

# usage:
# LISP=~/workspace/sbcl/run-sbcl.sh ./build.sh
# or just ./build.sh if you have an sbcl in your path with a fresh enough ASDF

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
    #
    # get a recent enough ASDF
    #
    mkdir -p ${SCRIPT_DIR}/build/quicklisp/local-projects/
    cd ${SCRIPT_DIR}/build/quicklisp/local-projects/
    git clone git://common-lisp.net/projects/asdf/asdf.git
    cd asdf
    git checkout 3.1.0.65
    make
    cd ../../

    #
    # get quicklisp and load/install it under build/
    #
    wget http://beta.quicklisp.org/quicklisp.lisp
    ${LISP} --no-userinit --no-sysinit --load quicklisp.lisp --eval "(quicklisp-quickstart:install :path \"${SCRIPT_DIR}/build/quicklisp\")" --quit
fi

cd "${SCRIPT_DIR}"

export CL_SOURCE_REGISTRY="(:source-registry (:directory \"${SCRIPT_DIR}\") (:tree \"${SCRIPT_DIR}/build/quicklisp/local-projects/\") :ignore-inherited-configuration)"
export ASDF_OUTPUT_TRANSLATIONS="(:output-translations (t (\"${SCRIPT_DIR}/build/fasls/\" :implementation \"root/\")) :ignore-inherited-configuration)"

echo Building bootstrap executable using \'${LISP}\', CL_SOURCE_REGISTRY is \'${CL_SOURCE_REGISTRY}\', ASDF_OUTPUT_TRANSLATIONS is \'${ASDF_OUTPUT_TRANSLATIONS}\'

#${LISP} --no-sysinit --no-userinit --eval "(load \"build.lisp\")" --end-toplevel-options $*

ln -sf bootstrap/common-lisp/maru ../../eval.cl

# and now let's switch over to lisp...

exec ${LISP} --no-sysinit --no-userinit --script "$0" --end-toplevel-options $@

|#

(in-package :cl-user)

(let ((quicklisp-init "build/quicklisp/setup.lisp"))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(require :asdf)

;; initiate asdf upgrade
(asdf:load-system :asdf)
;; this is not strictly needed
(asdf:load-system :uiop)

(format t "Lips side speaking, will (asdf:load-system :maru) now and dump an executable image~%")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:load-system :maru)
  (ql:quickload :com.dvlsoft.clon))

(in-package :maru.eval)

(eval-when (:execute :load-toplevel :compile-toplevel)
  (com.dvlsoft.clon:nickname-package))

(setf uiop:*image-entry-point* 'maru-toplevel)

(clon:defsynopsis (:postfix "FILES...")
  (text :contents
	"Common Lisp implementation of maru.")
  (group (:header "Flags (non valued options):")
    (flag :short-name "h" :long-name "help"
	  :description "Print this help and exit.")
    (flag :short-name "v" ;; :long-name ""
	  :description "ignored, only here for compatibility")
    (flag :short-name "b" ;; :long-name ""
	  :description "Don't try to load boot.l")
    (flag :short-name "g" ;; :long-name ""
	  :description "ignored, only here for compatibility")
    (flag :short-name "O" ;; :long-name ""
	  :description "ignored, only here for compatibility")))

(defun maru-toplevel ()
  (with-new-maru-state
    (flet
        ((build-maru-args-list ()
           (let ((args (clon:cmdline))
                 (maru/args (maru/intern "nil")))
             (dolist (arg (reverse (rest args)))
               (setf maru/args (maru/cons arg maru/args)))
             (maru/define (global-namespace-of *eval-context*)
                          (maru/intern "*arguments*")
                          maru/args)))
         (load-boot ()
           (maru/repl #P"boot.l")))
      (let ((args-var (build-maru-args-list))
            (load-boot t)
            (repled nil))
        (loop
          :for cell = (maru/get-var args-var) :then (maru/cdr cell)
          :until (maru/nil? cell)
          :for arg = (maru/car cell)
          :do
          (cond
            ((member arg '("-v" "-g" "-O") :test 'equal)
             ;;noop
             )
            ((equal arg "-b")
             (setf load-boot nil))
            (t
             (when load-boot
               (load-boot))
             ;; NOTE the arg voodoo in eval.c is not mirrored perfectly here
             (maru/set-var args-var (maru/get-tail cell))
             (maru/repl (pathname arg))
             (setf repled t))))
        (unless repled
          (when load-boot
            (load-boot))
          (maru/repl *terminal-io* :output-stream *terminal-io* :prompt ".")
          (format t "morituri te salutant~%"))))))

(uiop:dump-image "maru" :executable t)
