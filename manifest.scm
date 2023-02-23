;; This is the complete list of Guix packages necessary for building Maru.
;;
;; The following shell command will run the tests:
;;
;; guix shell -m manifest.scm --pure -- make test

(specifications->manifest
 '("coreutils"
   "llvm"
   "clang-toolchain"
   "glibc"
   "git"
   "libffi"
   "make"
   "findutils"
   "ncurses"
   "time"))
