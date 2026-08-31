;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO: targets to add: run run0 run-bare run-x86 run-llvm
;; test-bootstrap-recursively

;; TODO run-with-stage-1 and the run-with-* is ripe for a cleanup

(require "source/env-min.l")
(require "source/sequences.l")
(require "source/selector.l")
(require "source/generic.l")
(require "source/files.l")
(require "source/ansiterm.l")

;;;
;;; infra
;;;

;; non-standard naming convention, so that ./build.sh debug=true ... works
;; FIXME how not to confuse the debug of the build with the debug level compilation?
(define debug false)

(define-function debug-log args
  (when debug
    (print-all *debug-output* term/FG-BLUE args"\n" term/RESET)))

(define-function maybe-set-variable (env arg)
  ;; detect and evaluate foo=bar CLAs
  (let ((var (string))
        value)
    (string-do ch arg
      (if (= ch ?=)
          (set value (string))
        (string-append (or value var) ch)))
    (if value
        (let ((converted-value
                (case value
                  ("true" true)
                  (("false" "nil" "()") false)
                  ;; TODO numbers
                  (else (or (maybe-variable-value *globals* (string->symbol value))
                            value)))))
          (debug-log "maybe-set-variable: "var"="converted-value)
          (environment-define env (string->symbol var) converted-value)
          ())
      arg)))

(define-function string-trim-end (str)
  (let ((end (string-length str)))
    (while (begin
             (decr end)
             (member? (string-at str end) '(?\n ?\r ?  ?\t))))
    (set (string-length str) (+ end 1)))
  str)

(define-function concat-strings* args
  ;; this ignores nil elements and calls to-string on the rest
  (let ((result (if (car args)
                    (to-string (car args))
                  "")))
    (while (set args (cdr args))
      (when (car args)
        (set result (concat-string result (to-string (car args))))))
    result))

(define-function concat-strings-separated-by (separator args)
  (let ((result (car args)))
    (while (set args (cdr args))
      (when (car args)
        (set result (concat-string result
                                   (concat-string separator (car args))))))
    result))

(define-function absolute-path? (path)
  (= ?/ (string-at path 0)))

(define-function log-run-program (arg-string)
  (print-all *debug-output* term/FG-CYAN "-> " arg-string term/RESET "\n"))

(define-function run-program* (binary argv . rest)
  (log-run-program (concat-strings-separated-by " " (cons binary argv)))
  (run-program binary argv (pop rest) (pop rest) (pop rest) (pop rest)))

(define-function run-program/shell arg-strings
  (let ((arg-string (apply concat-strings* arg-strings)))
    (run-program* "/usr/bin/env" (list "sh" "-c" arg-string))))

(define $ run-program/shell)

(define-function run-program/shell/stdout arg-strings
  (let ((arg-string (apply concat-strings* arg-strings)))
    (string-trim-end
     (run-program* "/usr/bin/env" (list "sh" "-c" arg-string) () () 'string))))

;; normalize the uname(1) output into the components of an llvm-style
;; target triple. an unrecognized host is an error, rather than being
;; silently misclassified.
(define-function %host-os-name (uname-os)
  (case uname-os
    ("linux"	"linux")
    ("darwin"	"darwin")
    ("freebsd"	"freebsd")
    ("netbsd"	"netbsd")
    ("openbsd"	"openbsd")
    ("sunos"	"solaris")
    (else	(error "host-os-name: unexpected uname -s output '"uname-os"', please teach build.l about it"))))

(define-function %host-arch-name (uname-arch)
  (case uname-arch
    (("x86_64" "amd64")		"x86_64")
    (("aarch64" "arm64")	"aarch64")
    (("i386" "i686")		uname-arch)
    (else			(error "host-arch-name: unexpected uname -m output '"uname-arch"', please teach build.l about it"))))

(define host/os		(%host-os-name (run-program/shell/stdout "uname -s | tr '[:upper:]' '[:lower:]'")))
(define host/arch	(%host-arch-name (run-program/shell/stdout "uname -m")))
(define host/vendor	(case host/os ("darwin" "apple") (else "unknown")))
(define host/abi	(case host/os ("linux" "gnu") (else ())))

(define-function host-triple ()
  (concat-strings-separated-by
   "-" (list host/arch host/vendor host/os host/abi)))

(define-function canonicalize-path (path)
  (apply run-program/shell/stdout
         (list (case host/os
                 ("linux"	"readlink --canonicalize '")
                 ("darwin"	"realpath '")
                 (else		(error "canonicalize-path: unimplemented for '"host/os"'")))
               path
               "'")))

(define-function same-file-contents-or-die (file1 file2)
  ($ "cmp "file1" "file2))

(define-function file-exists? (path)
  ;; TODO this is lame, but...
  (let ((file (file-open path "r")))
    (when file
      (file-close file))
    (when file
      path)))

(define-function ensure-directory-exists (path)
  (unless (file-exists? path) ; FIXME
    ($ "mkdir -p '"path"'")))

(define-function load-dependency-file (output-path file-extension)
  (let ((deps-path (concat-string output-path file-extension)))
    (when (file-exists? deps-path)
      (with-open-file (file deps-path "r")
        (let* ((stream (file-stream file))
               (deps (read stream)))
          deps)))))

(define-function load-deps-for (output-path)
  (let ((deps (load-dependency-file output-path ".dep")))
    (debug-log output-path"\n  .dep dependencies: "deps)
    (when deps
      (cons "boot.l" deps))))

(define-function load-vars-for (output-path)
  (let ((vars (load-dependency-file output-path ".vars")))
    (debug-log output-path"\n  .vars dependencies: "vars)
    vars))

(define-function needs-recompile? (output-path . rest)
  (let ((deps (pop rest))
        (vars (pop rest)))
    (when deps
      (set deps (ensure-list deps)))
    (debug-log "needs-recompile?" output-path deps vars)
    (or (let ((result false))
          (while (and (not result)
                      (let ((entry (pop vars)))
                        (when entry
                          (let* ((var (pop entry))
                                 (expected-value (pop entry))
                                 ;; accept as good when var is missing from deps (?)
                                 (actual-value (or (maybe-variable-value *globals* var)
                                                   expected-value)))
                            (unless (= actual-value
                                       expected-value)
                              (debug-log "yes, due to variable "var", expected "expected-value", actual "actual-value)
                              (set result true))
                            true)))))
          result)
        (when (not (file-exists? output-path))
          (debug-log "yes, output file is missing")
          true)
        (let ((output-mtime (file-modification-time output-path))
              (result false))
          (while (and (not result)
                      (pair? deps))
            (let ((dep (pop deps)))
              (when (< output-mtime (file-modification-time dep))
                (debug-log "yes, due to file "dep)
                (set result true))))
          result))))

;; The emission type of the elf backends (the value is passed down to
;; the compiler as elf-emission-type; see load-platform.l). The CLI
;; key elf-emission-type= overrides it.
(define elf-emission-type ())

;; How the link phase links the c-obj: statically with libc.a
;; ('static), or dynamically against libc.so.6 ('dynamic; the
;; default). Only meaningful for C-based platforms; the linux platform
;; links freestanding (-nostdlib) regardless.
(define C-obj/link-type "dynamic")

(define *input-variables-for-build*
  ;; NOTE: default-backend and default-platform should not matter,
  ;; because they get encoded into the build output path.
  ;; Candidates:
  ;;  - ld.so but that gets set in effective-ld.so, leading to recompiles
  '(profiler elf-emission-type C-obj/link-type))

(define-function save-dep-vars (output-file variables)
  (let ((result ()))
    (list-do var variables
      (push result (list var (variable-value *globals* var))))
    (with-open-stream (stream (concat-string output-file ".vars") "w")
      (dump-all  stream result)
      (print-all stream "\n"))))

;;;
;;; backends and platforms
;;;

;; this is somewhat silly, but needed to use multimethods that
;; dispatch on the types.
(define-record <backend> () (name))

(define-print-method <backend>	(print-all -stream- self.name))

(define-record <x86>     <backend>)
(define-record <arm>     <backend>)
(define-record <llvm>    <backend>)


(define x86  (new <x86>  "x86"))
(define arm  (new <arm>  "arm"))
(define llvm (new <llvm> "llvm"))

(define *all-backends* (list x86 arm llvm))

(define-record <platform> () (name))

(define-print-method <platform>	(print-all -stream- self.name))

(define-record <libc>     <platform>)
(define-record <posix>    <platform>)
(define-record <linux>    <platform>)

;; The effective emission type: the CLI key if set, else the platform
;; default (c-obj for the C-based platforms, standalone for linux).
(define-function elf-emission-type/effective (platform)
  (or elf-emission-type
      (if (or (= (<platform>-name platform) "libc")
              (= (<platform>-name platform) "posix"))
          "c-obj"
        "standalone")))

(define libc  (new <libc>  "libc"))
(define posix (new <posix> "posix"))
(define linux (new <linux> "linux"))

(define *all-platforms* (list libc posix linux))

;; TODO it would be nice to call these platform and backen, so that we
;; can do ./build.sh platform=linux... but that would be very error
;; prone, unless we rename every backend and platform local variable
;; to something else.
(define default-backend		llvm)
(define default-platform	posix)

(define-method to-string <backend>	() self.name)
(define-method to-string <platform>	() self.name)
(define-method to-string <undefined>	() "false")
(define-method to-string <symbol>	() (symbol->string self)) ; this covers true

;;;
;;; the build stuff itself
;;;

(define *build*			"build")
(define *previous-stage*	"maru.10")
(define *host-dir*		(canonicalize-path (concat-strings* *build* "/" *previous-stage*))) ; aka (build-path *previous-stage*)
(define *slave-dir*		(working-directory))

(define target/arch	host/arch)
(define target/vendor	host/vendor)
(define target/os	host/os)
(define target/abi	host/abi)

(define-function target-triple ()
  (concat-strings-separated-by
   "-" (list target/arch target/vendor target/os target/abi)))

(define-function cross-compiling? ()
  (not (= target/arch host/arch)))

;; the ELF interpreter path to embed into the target binaries. it can
;; be overridden from the command line with ld.so=...; when not set,
;; effective-ld.so resolves a default based on target/arch at use time
;; and caches it here (the default cannot be computed at load time,
;; because target/arch may be set from the command line only after
;; this file is loaded).
(define ld.so ())

;; glibc: /lib[64]/ld-linux[-<arch>].so.<N>, where N is the loader's
;; own soname version, which froze at a different number per arch
;; (the 32-bit x86 name predates the convention, hence no arch
;; suffix; 64-bit x86 also lives under /lib64). musl is uniform:
;; /lib/ld-musl-<arch>.so.1
(define-function canonical-ld.so (arch)
  (case arch
    ("x86_64"		"/lib64/ld-linux-x86-64.so.2")
    (("i686" "i386")	"/lib/ld-linux.so.2")
    ("aarch64"		"/lib/ld-linux-aarch64.so.1")
    (else		(error "canonical-ld.so: unknown target/arch '"arch"', please set ld.so explicitly"))))

(define-function effective-ld.so ()
  (unless ld.so
    (set ld.so
         (cond
           ((cross-compiling?)
            ;; there's no local system to probe for the target's
            ;; loader; the canonical path is the best default
            (canonical-ld.so target/arch))
           ((= host/os "linux")
            ;; probing the host is the ground truth: it reflects the
            ;; libc in use (glibc, musl) and non-canonical layouts
            ;; (e.g. guix), regardless of the host arch
            (let ((probed (run-program/shell/stdout
                           "readelf -l /usr/bin/env | sed -n 's@.*Requesting program interpreter: \\(.*\\)]@\\1@p'"
                           ;; or alternatively:
                           ;;  "ldd /usr/bin/env | awk '/ld-linux/ {print ($3 ? $3 : $1)}'"
                           ;;  ll $(guix build --system=aarch64-linux glibc | tail -n 2 | head -n 1)/lib/ld-linux*
                           )))
              (if (< 0 (string-length probed))
                  probed
                (canonical-ld.so target/arch))))
           (else
            ;; e.g. darwin: Mach-O, no ELF interpreter
            ()))))
  ld.so)

;; eval0-phase check-outs the most recent commit into build/eval0, and
;; uses that as the source code for compiling the eval0 binary
;; (i.e. instead of the worktree). eval0 is never automatically
;; updated; see the update-eval0 target. this way we can get all the
;; benefits of the our most recent commits, plus the flexibility to
;; temporarily break stuff while making progress.
(define eval0-phase	true)

(define profiler	false)

(define clang		"clang")
(define strip		"llvm-strip")

;; NOTE: lld also can cross-compile, which would be nice, but it
;; produces a crashing eval0, even when not cross-compiling.
;; -fuse-ld=lld
(define cflags		"-O3 -fPIE")

(define-generic cflags-for (backend platform)
  cflags)

;; The elf backends emit non-PIC code with absolute addressing, so
;; their links must not produce a PIE. The static link type bakes
;; libc.a into the binary; the default dynamic link leaves libc.so.6
;; to ld.so.
(define-function elf-cflags ()
  (concat-strings cflags
                  " -fno-pie -no-pie"
                  (if (= C-obj/link-type "static") " -static" "")))

(define-multimethod cflags-for ((<x86> backend) (<libc> platform))
  (elf-cflags))

(define-multimethod cflags-for ((<x86> backend) (<posix> platform))
  (elf-cflags))

(define-multimethod cflags-for ((<arm> backend) (<libc> platform))
  (elf-cflags))

(define-multimethod cflags-for ((<arm> backend) (<posix> platform))
  (elf-cflags))

(define-multimethod cflags-for (backend (<linux> platform))
  ;; NOTE: -ffreestanding -fno-builtin-memset doesn't help, -O still
  ;; emits calls to memset; see:
  ;; https://clang.llvm.org/docs/UsersManual.html#freestanding-builds
  ;; -Wl,-no-pie is needed to produce an ELF without a dynamic linker
  ;; reference (clang -m32 on Guix even inserts a link to a
  ;; non-existent /gnu/store reference)
  (concat-string
   cflags
   " -nostdlib -nostartfiles -ffreestanding -Wl,-Bstatic,-no-pie -Qunused-arguments"))

(define-function build-output* (backend platform host-dir file . rest)
  (let ((dont-mkdir (pop rest))
        (dir (concat-strings* *build* "/" backend "-" platform "/" (target-triple))))
    (when host-dir
      (set dir (concat-strings host-dir "/" dir)))
    (unless dont-mkdir
      (ensure-directory-exists dir))
    (concat-strings* dir "/" file)))

(define-function build-output (backend platform file . rest)
  (build-output* backend platform () file (pop rest)))

(define-function build-path (file)
  (concat-strings* *build* "/" file))

(define-function build-path* (host-dir file)
  (concat-strings* host-dir "/" *build* "/" file))

(define-function slave-path (file)
  (concat-strings *slave-dir* "/" file))

(define-function host-path (file)
  (concat-strings *host-dir* "/" file))

(define-function run-with-host (argv . rest)
  (run-program* (concat-strings *host-dir*"/eval") argv
                (pop rest) (pop rest) (pop rest) (pop rest)))

(define-function run-with-host/shell args
  (apply run-program/shell (concat-list (list "cd '"*host-dir*"' && ./eval")
                                        args)))

(define-function run-with-stage (host-dir host-eval argv . rest)
  (let ((host-binary (concat-strings host-dir"/"host-eval)))
    (run-program* host-binary argv (pop rest) (pop rest) (pop rest) (pop rest))))

(define-function clean-backends args
  (let ((backend (pop args))
        (platform (pop args)))
    (cond
      ((not backend)
       (list-do backend *all-backends*
         (clean-backends backend platform)))
      ((not platform)
       (list-do platform *all-platforms*
         (clean-backends backend platform)))
      (else
       (let ((dir (build-output backend platform "" true)))
         ($ "test -e '"dir"' && rm -rI '"dir"' || true"))
       ))))

(define-function clean args
  (apply clean-backends args)
  ($ "rm -rf eval eval-* '"(build-path "generated")
     "' '"(build-path "asm-x86")"' '"(build-path "asm-arm")"'")
  ($ "git checkout --quiet '"*build*"' || true"))

(define-function distclean ()
  ($ "rm -rf '"*build*"'")
  (clean))

(define-function compile-host ()
  ;; after cloning, we must create the local branches ourselves; the
  ;; issue in detail:
  ;; https://stackoverflow.com/questions/40310932/git-hub-clone-all-branches-at-once
  (let* ((host-dir *host-dir*)
         (host-eval "eval")
         (host-eval-full-path (concat-strings host-dir "/" host-eval)))
    ;; no deps, i.e. it's only triggered when the file is missing.
    (when (needs-recompile? host-eval-full-path)
      ($ "git show-ref --verify --quiet refs/heads/"*previous-stage*" || \
git branch --quiet --track "*previous-stage*" remotes/origin/"*previous-stage*)
      ($ "test -d '"host-dir"' || git worktree add --detach --force '"host-dir"' '"*previous-stage*"'")
      ;; a git checkout doesn't do anything to file modification times.
      ;; to avoid recursive bootstrap, we touch everything that is
      ;; checked in under build/, so that it's newer than any of its
      ;; dependencies.
      ($ "find '"host-dir"/build' -type f -exec touch {} +")
      ($ "make --directory='"host-dir"' PLATFORM=posix eval-llvm"))

    ;; the host's source/c/cgrov.g.l is loaded by its
    ;; source/c/compile-cgrov.l, which we are exercising directly
    ;; later, so we must make sure that it's built. see
    ;; COMPILE-CGROV-FILE below.
    (when (needs-recompile? (concat-strings host-dir "/source/c/cgrov.g.l"))
      ($ "make --directory='"host-dir"' PLATFORM=posix source/c/cgrov.g.l"))

    (list host-dir host-eval)))

;;;
;;; C
;;;

(define-function compile-C-file (lcflags full-path output more-files)
  (when (needs-recompile? output (concat-list (list full-path) more-files))
    (let ((more-files-str
            (if more-files
                (concat-strings-separated-by " " more-files)
              "")))
      ($ clang" "lcflags
         " --target="(target-triple)
         " -o '"output"' '"full-path"' "more-files-str)))
  output)

;; Cuts the final, stripped artifact from an unstripped binary (the
;; linker records the input file names as STT_FILE symbols, so the
;; unstripped binaries are not reproducible)
(define-function strip-binary (slave-dir unstripped-path binary)
  (when (needs-recompile? binary (list unstripped-path))
    ($ "cd '"slave-dir"' && "strip" -o '"binary"' '"unstripped-path"'")
    ($ "cd '"slave-dir"' && chmod +x '"binary"'"))
  binary)

(define-function compile-cgrov-file (file-path)
  (assert (absolute-path? file-path))
  ;; NOTE if we call (compile-host) here, then it'll get triggered
  ;; while we are compiling eval0 in the build/eval0 dir; i.e. it
  ;; would unnecessarily compile the previous stage one more time.
  (let* ((c-file     (concat-strings file-path "." (target-triple) ".c"))
         (exe-file   (concat-strings c-file ".exe"))
         (final-file (concat-strings file-path "." (target-triple) ".l")))
    (when (needs-recompile? final-file (list file-path))
      ;; this is not ok, because this doesn't cd into the host-dir, so
      ;; the host loads slave source code.
      ;; (run-with-host
      ;;  *host-dir* "eval"
      ;;  (list (host-path "boot.l") (host-path "source/c/compile-cgrov.l") file-path)
      ;;  () () c-file)

      (run-with-host/shell " boot.l source/c/compile-cgrov.l '"
                           file-path "' >'"c-file"'")

      (compile-C-file cflags c-file exe-file ())
      ($ exe-file" >"final-file)
      ($ "rm "exe-file" "c-file))))

;;;
;;; Compile Maru
;;;

(define-function run-maru-compiler (host-dir host-eval slave-dir backend
                                             platform source output-path evolving?)

  (when (let ((abs-output-path (concat-strings slave-dir "/" output-path)))
          (needs-recompile? abs-output-path
                            (concat-list
                             (load-deps-for abs-output-path)
                             ;; FIXME why do i need to add this here?
                             (list source))
                            (load-vars-for abs-output-path)))

    (save-dep-vars output-path *input-variables-for-build*)

    (run-with-stage
     host-dir host-eval
     (list-remove
      ()
      (concat-lists
       (list "-O" "-v")
       (when profiler
         (list "-p"))
       ;; --define some globals
       (apply
        concat-lists
        (map (lambda (el)
               (list "--define"
                     (symbol->string (first el))
                     (or (second el) "")))
             `((*host-directory*	,host-dir)
               (*slave-directory*	,slave-dir)
               (*compiler-backend*	,(<backend>-name backend))
               (target/arch		,target/arch)
               (target/vendor		,target/vendor)
               (target/os		,target/os)
               (target/abi		,target/abi)
               (target/platform		,(<platform>-name platform))
               (feature/profiler/build	,(to-string profiler))
               (+ld.so-path+		,(effective-ld.so))
               (elf-emission-type	,(elf-emission-type/effective platform))
               )))
       ;; files to load
       `("source/bootstrapping/prepare.l"
         ;; cwd: host dir
         "boot.l"
         ;; cwd: slave dir
         ,(concat-string slave-dir "/source/bootstrapping/host-ready.l")
         ;; env: host
         ,(when evolving? "source/bootstrapping/host-extras.l")
         "source/bootstrapping/early.l"
         ;; env: slave
         "boot.l"
         ,(when evolving? "source/bootstrapping/slave-extras.l")
         "source/bootstrapping/late.l"
         ;; env: host
         "source/platforms/load-platform.l"
         ;; env: target
         ,source
         "source/platforms/run-compiler.l"
         ,output-path
         ))))))

(define-function %compile-maru (backend platform host-dir host-eval slave-dir input-file output-name evolving?)
  (let ((platform-name (to-string platform)))
    (compile-cgrov-file (concat-strings slave-dir "/source/platforms/"platform-name"/"platform-name".cgrov"))
    (cond
      ((= platform linux)
       ;; TODO maybe merge the elf/ and linux/ namespaces?
       (compile-cgrov-file (concat-strings slave-dir "/source/platforms/linux/elf.cgrov")))
      ((= platform posix)
       ;; posix "extends" the libc platform, so it also needs the libc cgrov entries.
       (compile-cgrov-file (concat-strings slave-dir "/source/platforms/libc/libc.cgrov")))))

  (let ((output (build-output backend platform output-name)))

    (run-maru-compiler
     host-dir host-eval slave-dir backend platform
     input-file output evolving?)

    output))

(define-function platform-source-file (platform filename)
  (concat-strings "source/platforms/"(<platform>-name platform)
                  "/" filename))

(define-function maru-C-files (backend platform)
  (let ((result ()))

    (let ((basename (concat-strings* platform ".c")))
      (awhen (file-exists?
              (platform-source-file platform basename))
        (push result (list basename it))))

    (when (= platform posix)
      ;; the posix platform also needs the stuff in libc.c
      (push result (list "libc.c" (platform-source-file libc "libc.c"))))

    (when profiler
      (let ((basename "profiler.c"))
        (aif (file-exists? (platform-source-file platform basename))
             (push result (list basename it))
          (warn basename" not found for platform "platform"\n"))))

    result))

(define-generic compile-maru args (apply %compile-maru args))

(define-function %compile-c-objects (backend platform cflags)
  ;; compiles the platform's C support files (libc.c etc.) into
  ;; object files, and returns their paths
  (map (lambda (entry)
         (let* ((c-file (first entry))
                (c-file-path (second entry))
                (c-file-sans-ext (concat-string c-file ""))) ; poor man's copy
           (decr (string-length c-file-sans-ext) 2) ; drop .c extension
           (compile-C-file (concat-strings cflags " -c")
                           c-file-path
                           (build-output backend platform
                                         (concat-string c-file-sans-ext ".o"))
                           ())))
       (maru-C-files backend platform)))

(define-function %compile-maru/elf (backend platform host-dir host-eval
                                    slave-dir input-file output-name evolving?)
  (if (= "c-obj" (elf-emission-type/effective platform))
      ;; emits the relocatable object (the output name gains a .o
      ;; suffix), links it with the platform's C support objects into
      ;; an executable binary, which is then stripped.
      (let* ((object (%compile-maru backend platform host-dir host-eval slave-dir
                                    input-file
                                    (concat-string output-name ".o")
                                    evolving?))
             (cflags (cflags-for backend platform))
             (obj-files (%compile-c-objects backend platform cflags))
             (unstripped-path (build-output backend platform
                                            (concat-string output-name ".unstripped")))
             (binary (build-output backend platform output-name)))
        (compile-C-file cflags object unstripped-path obj-files)
        (strip-binary slave-dir unstripped-path binary))
    (let ((output (%compile-maru backend platform host-dir host-eval slave-dir
                                 input-file output-name evolving?)))
      ($ "cd '"slave-dir"' && chmod +x " output)
      output)))

(define-multimethod compile-maru ((<x86> backend) platform
                                  host-dir host-eval
                                  slave-dir input-file output-name evolving?)
  (%compile-maru/elf backend platform host-dir host-eval
                     slave-dir input-file output-name evolving?))

(define-multimethod compile-maru ((<arm> backend) platform
                                  host-dir host-eval
                                  slave-dir input-file output-name evolving?)
  (%compile-maru/elf backend platform host-dir host-eval
                     slave-dir input-file output-name evolving?))

(define-multimethod compile-maru ((<llvm> backend) platform
                                  host-dir host-eval
                                  slave-dir input-file output-name evolving?)
  (let ((cflags (cflags-for backend platform))
        (obj-files ()))

    ;; compile C files
    (list-do entry (maru-C-files backend platform)
      (let* ((c-file (first entry))
             (c-file-path (second entry))
             (c-file-sans-ext (concat-string c-file ""))) ; poor man's copy
        (decr (string-length c-file-sans-ext) 2) ; drop .c extension
        (let ((output (build-output backend platform
                                    (concat-string c-file-sans-ext ".o"))))
          (compile-C-file (concat-string cflags " -c") c-file-path output ())
          (push obj-files output))))

    ;; compile maru
    (let* ((output-ll
             (%compile-maru backend platform host-dir host-eval
                            slave-dir
                            input-file
                            (concat-string output-name ".ll")
                            evolving?))
           (unstripped-path (build-output backend platform
                                          (concat-string output-name ".unstripped")))
           (binary          (build-output backend platform output-name)))

      (compile-C-file cflags
                      (concat-strings slave-dir "/" output-ll)
                      (concat-strings slave-dir "/" unstripped-path)
                      obj-files)

      (strip-binary slave-dir unstripped-path binary))))

(define-function checkout-eval0 ()
  ;; build-path returns relative path. without absolutizing it,
  ;; we would cd into build/previous-stage/build/eval0.
  (let ((eval0-dir (slave-path (build-path "eval0"))))
    (unless (file-exists? eval0-dir)
      ($ "git worktree add --detach --force '"eval0-dir"'")
      ;; a git checkout doesn't do anything to file modification
      ;; times, therefore we touch everything that happens to be
      ;; checked in under build/ to avoid unnecessary rebuilds
      ($ "find '"eval0-dir"/build' -type f -exec touch {} \\; || true"))
    eval0-dir))

(define-function update-eval0 ()
  (let ((eval0-dir (checkout-eval0)))
    (assert (< 10 (length eval0-dir)))
    ($ "cd '"eval0-dir"' && git reset --quiet --hard HEAD~50 &&
git pull --quiet ../.. &&
git --no-pager log --pretty=oneline -1")))

;; eval0 is a cache: we compile/bootstrap a recent-ish commit of this
;; stage, and then use that in the rest of the build.
(define-function compile-maru/stage-0 (backend platform)
  (debug-log "compile-maru/stage-0: "backend" "platform)
  (let* ((host		(compile-host))
         (host-dir 	(pop host))
         (host-eval	(pop host))
         (input-file	(concat-strings* "source/platforms/"platform"/eval.l"))
         (eval0-dir	(checkout-eval0)))

    (if eval0-phase
        (let ((eval0-backend	llvm)
              (eval0-platform	libc))
          (debug-log "compile-maru/stage-0: forking the eval0 build")
          ;; All we want here is an eval0 binary compiled from a
          ;; reasonably recent commit that works fast on the host to
          ;; exercise the rest of the machinery. In some way it's a
          ;; cache or workflow optimization: we get to enjoy the new
          ;; features without opening a new branch, or evolutionary
          ;; stage. Downside: delayed feedback when something breaks
          ;; the bootstrap when the host is the previous stage.
          (let* ((output (run-program/shell "cd '"eval0-dir"' &&
                           ./build.sh eval0-phase=false compile-maru/stage-0 "
                                            eval0-backend" "eval0-platform
                                            " | tail -2"))
                 ;; TODO read the path's from the fork's actual output
                 ;; (input (string-stream output))
                 ;; (results (read input))
                 (eval0 (concat-strings* *build* "/" eval0-backend "-" eval0-platform
                                         "/" (host-triple) "/eval0")))
            (debug-log "compile-maru/stage-0 is returning from the fork: "eval0-dir eval0)
            (list eval0-dir eval0)))
      (let ((eval0 (compile-maru backend platform host-dir host-eval *slave-dir*
                                 input-file "eval0" true)))
        ;; API: we print two specific lines as the last output to stdout
        ;; TODO pass the values to the parent
        ;;(println *slave-dir*)
        ;;(println eval0)
        (list *slave-dir* eval0)))))

(define-function compile-maru/stage-1 (backend platform)
  ;; eval0 is either in build/eval0/build/... or in our own build/
  ;; next to eval1 & eval2, depending on eval0-phase. we don't know
  ;; which one, hence the extra dance about the stage-0 return value.
  (debug-log "compile-maru/stage-1: "backend" "platform)
  (let* ((input-file (concat-strings* "source/platforms/"platform"/eval.l"))
         (res (compile-maru/stage-0 backend platform))
         (eval0-dir (pop res))
         (eval0 (pop res)))
    (compile-maru backend platform
                  eval0-dir eval0
                  *slave-dir* input-file "eval1" false)))

(define-function compile-maru/stage-2 (backend platform)
  ;; eval2 is always compiled using eval1.
  (debug-log "compile-maru/stage-2: "backend" "platform)
  (let ((eval1 (compile-maru/stage-1 backend platform))
        (input-file (concat-strings* "source/platforms/"platform"/eval.l")))
    (compile-maru backend platform
                  *slave-dir* eval1
                  *slave-dir* input-file "eval2" false)))

(define-function bootstrap args
  (let ((backend  (or (pop args) default-backend))
        (platform (or (pop args) default-platform)))
    (assert (subtype? (type-of backend) <backend>))
    (assert (subtype? (type-of platform) <platform>))
    (let ((eval1 (compile-maru/stage-1 backend platform))
          (eval2 (compile-maru/stage-2 backend platform)))
      ;; TODO add same-file-contents-or-die for the sources

      ;; Newer darwin refuses to run binaries without an uuid, so they
      ;; will never by byte-identical.
      (unless (= host/os "darwin")
        (same-file-contents-or-die eval1 eval2)))))

(define-function bootstrap-matrix ()
  ;; TODO finish it... it needs to skip cross compilation, etc. this
  ;; is more convoluted than i want to deal with right now.
  (list-do backend *all-backends*
    (list-do platform *all-platforms*

      (if (or (and (= backend x86) (not (= platform linux))) ; no C ffi support on x86
              (not (= )))

          (println "\n   NOT Bootstrapping on "backend" "platform"\n")

        (println "\n   Bootstrapping on "backend" "platform"\n")
        (bootstrap backend platform)))))

(define-function run-with-stage-1 (argv . rest)
  (let ((binary (compile-maru/stage-1 default-backend default-platform)))
    (run-program* binary argv (pop rest) (pop rest) (pop rest) (pop rest))))

(define-function repl args
  (let ((backend  (or (pop args) default-backend))
        (platform (or (pop args) default-platform)))
    (assert (subtype? (type-of backend) <backend>))
    (assert (subtype? (type-of platform) <platform>))
    ($ "rlwrap --no-warning "(compile-maru/stage-1 backend platform)
       " boot.l -")))

;;;
;;; PEG parser
;;;

(define-function bootstrap-peg ()
  (let* ((input		"source/parsing/bootstrap-peg-parser.l")
         (output	"source/parsing/peg.g.l")
         (deps		(list input
                              "source/parsing/peg.g"
                              "source/parsing/parser.l"
                              "source/parsing/peg-compile-forms.l")))
    (when (needs-recompile? output deps)
      ;; TODO when this fails it leaves an empty file that must be deleted
      ;; TODO convert to a /shell variant? that || rm's the file
      (run-with-stage-1 (list "-O" "boot.l" input)
                        () () output))

    output))

(define-function compile-peg-grammar (grammar)
  (let* ((compiled-peg	(bootstrap-peg))
         (input		(concat-string grammar ".g"))
         (output	(concat-string input ".l")) ; i.e. foo.g.l
         (compiler	"source/parsing/compile-peg-grammar.l")
         (deps		(list input
                              compiler
                              compiled-peg
                              "source/parsing/parser.l")))
    (when (needs-recompile? output deps)
      ;; TODO when this fails it leaves an empty file that must be deleted
      ;; TODO convert to a /shell variant? that || rm's the file
      (run-with-stage-1 (list "-O" "boot.l" compiler input)
                        () () output))

    output))

;;;
;;; tests
;;;

(define-function %test-jit ()
  (let ((dir (build-path "jit")))
    ($ "rm -f '"dir"/*'")
    (ensure-directory-exists dir)
    (run-with-stage-1 (list "boot.l" "--define" "target/triple" (target-triple)
                            "tests/jit.l"))))

(define-function test-jit ()
  (debug-log "test-jit is starting")
  (let ((prev-platform default-platform))

    (set default-platform linux)
    (%test-jit)

    (set default-platform posix)
    (%test-jit)

    (set default-platform prev-platform)))

(define-function test-elf ()
  (debug-log "test-elf is starting")
  (let ((run (lambda (file)
               (run-with-stage-1
                (list "boot.l"
                      "--define" "target/triple" (target-triple)
                      "--define" "+ld.so-path+" (effective-ld.so)
                      file))
               ($ "file=build/$(basename --suffix=.l '"file"') && chmod +x $file && ./$file"))))
    (run "tests/test-elf.x86-64.traditional.l")
    (run "tests/test-elf.x86-64.single-pass.l")
    (run "tests/test-elf.x86-64.segments.l")))

(define-function test-assembler-x86 ()
  (ensure-directory-exists (build-path "asm-x86"))
  (run-with-stage-1 (list "boot.l" "tests/test-assembler-x86.l")))

(define-function test-assembler-arm ()
  (ensure-directory-exists (build-path "asm-arm"))
  (run-with-stage-1 (list "boot.l" "tests/test-assembler-arm.l")))

(define-function test-assembler ()
  (debug-log "test-assembler is starting")
  (test-assembler-x86)
  (test-assembler-arm))

(define-function test-evaluator ()
  (debug-log "test-evaluator is starting")
  (run-with-stage-1 (list "boot.l" "tests/evaluator-tests.l")))

(define-function test-parser ()
  (debug-log "test-parser is starting")
  (compile-peg-grammar "tests/parsing/gnu-bc")
  (run-with-stage-1 (list "boot.l" "tests/parsing/gnu-bc-test.l")))

(define-generic test-compiler args
  (debug-log "test-compiler is starting")
  (let ((backend  (or (pop args) default-backend))
        (platform (or (pop args) default-platform)))

    (let* ((input-file	"tests/compiler-test.l")
           (output-name	"compiler-test")
           (stage0	(compile-maru/stage-0 backend platform))
           (host-dir	(pop stage0))
           (host-eval	(pop stage0)))

      (let ((binary (compile-maru backend platform host-dir host-eval *slave-dir*
                                  input-file output-name true)))
        ($ binary)))))

(define-function test ()
  (test-compiler llvm libc)
  (test-compiler llvm posix)
  (test-evaluator)
  (test-parser)

  (case host/os

    ("linux"
     (test-compiler llvm linux)
     (test-assembler)     ; uses x86_64-linux-gnu-objcopy and stuff...

     (case host/arch

       ("x86_64"
        (test-compiler x86 linux)
        (test-elf)
        (test-jit))

       ("aarch64"
        (test-compiler arm linux)))))
  )

;;;
;;; main
;;;

(define-function main ()
  (debug-log "*command-line-arguments*" *command-line-arguments*)

  ;; target/* is initialized to the host triple at load time; the
  ;; foo=bar CLAs below override it (e.g. target/arch=aarch64).

  (let* ((args (map (lambda (str)
                      ;; second: _ means false
                      (unless (= str "_")
                        ;; third: resolve it to a variable
                        (or (maybe-variable-value *globals* (string->symbol str))
                            (error "arg '"str"' doesn't denote a bound variable"))))
                    ;; first: resolve foo=42 forms
                    (list-remove () (map (lambda (str)
                                           (maybe-set-variable *globals* str))
                                         *command-line-arguments*)))))
    (debug-log "main is applying: "args)
    (if (or (is <expr>		(first args))
            (is <selector>	(first args))
            (is <generic>	(first args)))
        (apply (first args) (rest args))
      (error "usage: build.l fn-name arg1 arg2 arg3\n  where everything will be looked up in the *globals* env, and if defined then the value will be used instead of the name.")))
  (set *command-line-arguments* ())     ; we consumed it all
  0)

(main)
