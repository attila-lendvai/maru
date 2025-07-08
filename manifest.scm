;; This is the complete list of Guix packages necessary for building Maru.
;;
;; Usage:
;;
;; guix shell --pure
;; guix shell --pure -- make test

;; TODO -m32 does not work as of 2025-06:
;; cc -O3 -m32 -o build/x86-libc/i386-linux-gnu/eval1  build/x86-libc/i386-linux-gnu/eval1.s
;; ld: cannot find crtbeginS.o: No such file or directory
;; ld: cannot find -lgcc: No such file or directory
;; ld: cannot find -lgcc_s: No such file or directory
;; ld: skipping incompatible /gnu/store/hw6g2kjayxnqi8rwpnmpraalxi0djkxc-glibc-2.39/lib/libc.so when searching for -lc
;; ld: cannot find -lc: No such file or directory
;; ld: skipping incompatible /gnu/store/hw6g2kjayxnqi8rwpnmpraalxi0djkxc-glibc-2.39/lib/libc.so when searching for -lc
;; ld: cannot find -lgcc: No such file or directory
;; ld: cannot find -lgcc_s: No such file or directory
;; ld: cannot find crtendS.o: No such file or directory

(use-modules (gnu packages llvm))

(manifest
 (append
  (list
   ;; pick specific versions
   (package->manifest-entry
    clang-toolchain-20
    ))

  ;; get the latest from the channels you have pulled
  (manifest-entries
   (specifications->manifest
    '("coreutils"
      "diffutils"
      ;;"clang-toolchain"
      "glibc"
      ;; "libffi"
      "make"
      "time"
      "ncurses"        ; for clear, reset, tput (used by the Makefile)
      "git"
      "findutils"                       ; find is used in the Makefile

      ;;
      ;; the rest is only for convenience
      ;;
      "perf"
      "bash-completion"
      "gawk"
      "sed"
      "git:gui"
      "man-pages"
      "less"
      "gdb"
      )))))
