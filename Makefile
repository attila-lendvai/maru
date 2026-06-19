#
# Welcome to the usual makefile mess. It will hopefully be bootstrapped away sooner than later...
#
# it's possible to invoke stuff like:
#  make -j eval
#  make eval-llvm
#
#  alias beep='(paplay some-file.ogg &)'
#  make -j test-bootstrap || beep
#  make test-bootstrap-llvm || beep
#  make test-bootstrap-x86 || beep
#  make PLATFORM=linux test-bootstrap-x86 || beep
#  make -j test-compiler || beep
#  make -j test-compiler-llvm || beep
#  make TARGET_ARCH=x86_64 TARGET_VENDOR=apple TARGET_OS=darwin test-bootstrap-llvm || beep
#  make PLATFORM=linux TARGET_ARCH=aarch64 TARGET_ABI=gnu TARGET_OS=linux eval-llvm || beep
#  make TARGET_ARCH=i686 TARGET_ABI=gnu TARGET_OS=linux test-bootstrap-llvm eval-llvm || beep
#  make TARGET_ARCH=i686 TARGET_ABI=gnu TARGET_OS=linux test-bootstrap-llvm eval-llvm || beep
#  make PLATFORM=linux TARGET_ARCH=i686 TARGET_ABI=gnu TARGET_OS=linux test-bootstrap-llvm || beep
#  make PROFILER=1 test-bootstrap-x86 || beep
# to force a full bootstrap cycle all the way down from the/a bottom stage:
#  make test-bootstrap-recursively || beep
#
# the makefile parallelism is mostly only between the backends. don't use it
# while bootstrapping all the way from a bottom stage, it's broken somewhere.

# The tee redirect stuff needs something better than Dash (which is
# the default in Ubuntu in the CI).
# SHELL := $(shell command -v bash)

##
## configuration
##

# backends to build
BACKENDS		= x86 llvm
PLATFORMS		= libc posix linux
# use this backend of the previous stage when it needs to be built.
PREVIOUS_STAGE_BACKEND	= -llvm

HOST_OS		= $(shell uname -s)
TARGET_ARCH	?= $(shell uname -m)
PLATFORM	?= linux
VERBOSITY	?= -v #-v -v

# see https://stackoverflow.com/a/20983251/14464
RED		= $(shell tput setaf 1)
GREEN		= $(shell tput setaf 2)
BLUE		= $(shell tput setaf 4)
RESET		= $(shell tput sgr0)

ifeq ($(HOST_OS),Linux)
  TARGET_VENDOR	?= unknown
  TARGET_OS	?= linux
  TARGET_ABI	?= gnu
  # `command time` forces bash to use the external time command
  # setarch --addr-no-randomize improves debuggability of lowlevel
  # issues (but it's problematic in containers/CI).
  TIME		= time --format="\n$(GREEN)user time: %U$(RESET)"
  EVAL_WRAPPER	:= $(shell if setarch --addr-no-randomize true 2>/dev/null; then echo 'setarch --addr-no-randomize $(TIME)'; else echo 'command $(TIME)'; fi)
  # This should be something that prints the file size, but otherwise
  # fails gracefully when something is not available.
  define print_file_size
    { echo && echo -n "$(1): $(GREEN)" && stat -c%s $(1) | numfmt --grouping && echo "$(RESET)" || echo "$(RESET)"; }
  endef
else ifeq ($(HOST_OS),Darwin)
  TARGET_VENDOR	?= apple
  #TARGET_OS	?= darwin$(shell uname -r)
  TARGET_OS	?= darwin
  TARGET_ABI	=
  CFLAGS	+= -Wl,-no_uuid
  EVAL_WRAPPER	:= time
endif

print_file_size ?= true

# if you want to use the perf tool to profile the binary then also
# include -g and the rest. -O3 may remain.
CFLAGS		+= -O3
#CFLAGS		+= -g -fno-omit-frame-pointer -fno-inline
#CFLAGS		+= -Wl,--build-id=none

ifeq ($(PLATFORM),linux)
# NOTE: -ffreestanding -fno-builtin-memset doesn't help, -O still emits memset calls
# https://clang.llvm.org/docs/UsersManual.html#freestanding-builds
# -Wl,-no-pie is needed to produce an ELF without a dynamic linker
# reference (clang -m32 even inserts a link to a non-existent /gnu/store
# reference on Guix)
  CFLAGS	+= -nostdlib -nostartfiles -ffreestanding -Wl,-Bstatic,-no-pie
endif

# Some hardened kernels need a linker script that makes the .text
# section writable, so that relocation of non-PIC code can happen (our
# generated assembly is not PIC as of this writing). This hapened on
# Guix, but it's typically not the case in containers, like in the
# CI. But this linker script can derail the setup of the stack (or
# something like that, ask an LLM), which then leads to a sigsegv at
# 0x0 very early at start.  CFLAGS_x86 += $(CFLAGS)
# -Wl,-T,tools-for-build/linker-script.ld
CFLAGS_x86	+= $(CFLAGS) -fPIE

CFLAGS_llvm	+= $(CFLAGS) -Qunused-arguments

LLVM_VERSION	?=
TARGET		?= $(TARGET_ARCH)-$(TARGET_VENDOR)-$(TARGET_OS)$(if $(TARGET_ABI),-$(TARGET_ABI))
#TARGET		?= $(shell llvm-config$(LLVM_VERSION) --host-target)

# Used when generating maru sources during the build process.
GEN_EVAL	= $(BUILD_llvm)/eval1
# can't really use any of these in the current setup, because the make
# targets are generated based on the variables, so stuff like
# $(BUILD)/llvm-posix will only work when PLATFORM=posix.
#GEN_EVAL	= $(BUILD)/llvm/i686-$(TARGET_VENDOR)-$(TARGET_OS)/eval1
#GEN_EVAL	= $(BUILD)/llvm-posix/$(TARGET)/eval1
#GEN_EVAL	= $(BUILD_x86)/eval1

# used when executing tests
TEST_EVAL	= $(GEN_EVAL)

##
## internal variables
##
PREVIOUS_STAGE	= maru.9
#PREVIOUS_STAGE	= maru.10.c99

PREVIOUS_STAGE_EXTRA_TARGETS ?=

MAKEFLAGS	+= --warn-undefined-variables --output-sync

TARGET_ARCH	?= $(word 1, $(subst -, ,$(TARGET)))

ifeq ($(TARGET_ARCH),x86_64)
else ifeq ($(TARGET_ARCH),i686)
  CFLAGS_x86	+= -m32
  CFLAGS_llvm	+= -m32
else ifeq ($(TARGET_ARCH),aarch64)
else ifeq ($(TARGET_ARCH),arm)
  TARGET_ABI	= gnueabihf
else ifeq ($(TARGET_ARCH),arm64)
  # darwin uname -m returns arm64, but life is simpler withtout that anomaly.
  TARGET_ARCH=aarch64
else
  $(error "Unexpected TARGET_ARCH '$(TARGET_ARCH)'.")
endif

BACKDATE_FILE	= touch -t 200012312359

LLC		= llc$(LLVM_VERSION)
CLANG		= clang$(LLVM_VERSION)
DIFF		= diff --brief --ignore-all-space
STRIP		= strip

ASM_FILE_EXT_x86	= s
ASM_FILE_EXT_llvm	= ll

BUILD		= build

BUILD_x86	= $(BUILD)/x86-$(PLATFORM)/$(TARGET)
BUILD_llvm	= $(BUILD)/llvm-$(PLATFORM)/$(TARGET)
BITCODE_DIR	= $(BUILD_llvm)
HOST_DIR	= $(BUILD)/$(PREVIOUS_STAGE)
SLAVE_DIR	= $(CURDIR)

# $(info $$BUILD_llvm is [${BUILD_llvm}])
# $(info $$BITCODE_DIR is [${BITCODE_DIR}])

#EVAL0_PHASE=1
ifdef EVAL0_PHASE
  # This way eval0 is built each time
  EVAL0_DIR	?= $(SLAVE_DIR)
  EVAL0_BINARY	?= eval0-llvm
  EVAL0		?= $(BUILD_llvm)/eval0
else
  # This way eval0 is built from the latest commit, checked out as a
  # working dir in build/eval0 and 'make update-eval0' must be used to
  # update its git working tree. This mode requires more attention when
  # dealing with sensitive bootstrapping issues, but then you can just
  # switch to build eval0 each time.
  EVAL0_DIR	?= $(CURDIR)/$(BUILD)/eval0
  EVAL0_BINARY	?= eval0-llvm
  EVAL0		?= $(EVAL0_DIR)/$(EVAL0_BINARY)
endif

EMIT_FILES_x86	= $(addprefix source/compiler/,emit-early.l emit-x86-common.l emit-objects-x86.l emit-i686.l emit-x86-64.l emit-late.l) source/platforms/run-compiler.l
EMIT_FILES_llvm	= $(addprefix source/compiler/,emit-early.l emit-llvm.l emit-objects-llvm.l emit-late.l) source/platforms/run-compiler.l

GENERATED_FILES = $(addprefix source/,parsing/peg.g.l assembler/x86-instructions.l)

# We can only list files in souce/platforms/$(PLATFORM) that are
# universally available in each platform.
EVALUATOR_FILES	= $(addprefix source/platforms/$(PLATFORM)/,$(PLATFORM).l $(PLATFORM).cgrov.$(TARGET).l eval.l vm-functions.l) \
 $(addprefix source/platforms/,load-platform.l platform-c-based.l platform-common.l libc/libc.cgrov.$(TARGET).l) \
 $(addprefix source/evaluator/,eval.l gc.l printer.l reader.l vm-functions.l arrays.l vm-early.l vm.l vm-late.l vm-with-file-support.l types.l) \
 $(addprefix source/,list-min.l env-min.l sequences-min.l selector.l generic.l types.l debug-min.l)

# for some optional C files, e.g. profiler.c
EVAL_OBJ_x86	=
EVAL_OBJ_llvm	=

ifneq (,$(filter $(PLATFORM),libc posix))
  EVAL_OBJ_x86	+= $(BUILD_x86)/libc.o
  EVAL_OBJ_llvm	+= $(BUILD_llvm)/libc.o
endif

ifneq (,$(filter $(PLATFORM),posix))
  EVAL_OBJ_x86	+= $(BUILD_x86)/posix.o
  EVAL_OBJ_llvm	+= $(BUILD_llvm)/posix.o
endif

PROFILER ?= false

ifneq ($(filter yes on true 1,$(PROFILER)),)
  PROFILER_MARU		:= true
  EVAL_OBJ_x86		+= $(BUILD_x86)/profiler.o
  EVAL_OBJ_llvm		+= $(BUILD_llvm)/profiler.o
  PROFILER_ARG		= -p
else
  ifneq ($(filter no off false 0,$(PROFILER)),)
    PROFILER_MARU	:= false
    PROFILER_ARG	=
  else
    $(error "Unexpected value for PROFILER: '$(PROFILER)'.")
  endif
endif

.SUFFIXES:					# disable all built-in rules

#.PRECIOUS: $(BUILD_x86)/eval1.s $(BITCODE_DIR)/eval1.ll

all: eval

eval: $(foreach backend,${BACKENDS},eval-$(backend))
# NOTE this way ./eval will be the last one in BACKENDS that actually got built, which is llvm as things are

eval-x86: $(BUILD_x86)/eval1
	cp $< $@
	cp $< eval

eval-llvm: $(BUILD_llvm)/eval1
	cp $< $@
	cp $< eval

eval0-x86: $(BUILD_x86)/eval0
	cp $< $@
	cp $< eval

eval0-llvm: $(BUILD_llvm)/eval0
	cp $< $@
	cp $< eval

clean:
	rm -rf $(foreach plat,${PLATFORMS},$(foreach back,${BACKENDS},$(BUILD)/$(back)-$(plat) eval-$(back) eval0-$(back))) \
		eval $(BUILD)/generated/
# NOTE this is an endless loop when EVAL0_PHASE is enabled
#	test -d $(EVAL0_DIR) && $(MAKE) --directory=$(EVAL0_DIR) clean
	-git checkout --quiet $(BUILD)

distclean: clean
	rm -rf $(BUILD)
	-git checkout --quiet $(BUILD)

veryclean:
	rm -rf $(BUILD) $(GENERATED_FILES)

stats: $(foreach backend,${BACKENDS},stats-$(backend))

define count-loc
  echo -n $(1); cat $(2) | sed 's/.*debug.*//;s/.*assert.*//;s/;.*//' | grep -v '^$$' | wc -l; echo "Files:" $(2); echo
endef

define collect-files
  $(GEN_EVAL) --define *compiler-backend* $(1) boot.l tools-for-build/file-list-from-require.l $(2)
endef

$(foreach backend,${BACKENDS},stats-$(backend)): stats-%:
	@$(call ensure-built,$(GEN_EVAL))
	@echo -e '\nBackend $(BLUE)$*$(RESET):\n'
	@files=`$(call collect-files,$*,boot.l "source/emit-$*.l")`;	$(call count-loc,"Compiler LoC: ",$$files)
	@files=`$(call collect-files,$*,$(EVALUATOR_FILES))`;		$(call count-loc,"Evaluator LoC: ",$$files)
	@files=`$(call collect-files,$*,boot.l $(EVALUATOR_FILES))`;	$(call count-loc,"Alltogether LoC: ",$$files)

###
### eval and bootstrapping
###

$(HOST_DIR)/eval:
	echo Building $@
	@mkdir -p $(BUILD)
# after cloning, we must create the local branches ourselves; the issue in detail: https://stackoverflow.com/questions/40310932/git-hub-clone-all-branches-at-once
	@git show-ref --verify --quiet refs/heads/$(PREVIOUS_STAGE) || git branch --quiet --track $(PREVIOUS_STAGE) remotes/origin/$(PREVIOUS_STAGE)
	test -d $(BUILD)/$(PREVIOUS_STAGE) || git worktree add --detach --force $(BUILD)/$(PREVIOUS_STAGE) $(PREVIOUS_STAGE)
# a git checkout doesn't do anything to file modification times, so we just touch everything that happens to be checked in under build/ to avoid unnecessary rebuilds
	-find $(BUILD)/$(PREVIOUS_STAGE)/$(BUILD) -type f -exec touch {} \;
	$(MAKE) --directory=$(BUILD)/$(PREVIOUS_STAGE) PLATFORM=linux $(PREVIOUS_STAGE_EXTRA_TARGETS) eval$(PREVIOUS_STAGE_BACKEND)

update-eval0: $(EVAL0_DIR)
	cd $(EVAL0_DIR) && git reset --hard HEAD~30 && git pull ../.. && make clean

# check out our latest commit into build/eval0/, and build the eval0 executable
# there, in a clean tree.
$(EVAL0_DIR):
	git worktree add --detach --force $@
# a git checkout doesn't do anything to file modification times, so we just touch everything that happens to be checked in under build/ to avoid unnecessary rebuilds
	-find $@/$(BUILD) -type f -exec touch {} \;

# "forward" this target to the makefile in build/eval0
# NOTE: some of the reasons we fix some of these values for our bootstrap host:
#  - libc is the most compatible platform
#  - the 32 bit llvm target yields the fastest binary
$(EVAL0_DIR)/$(EVAL0_BINARY): $(EVAL0_DIR)
	$(MAKE) --directory=$(EVAL0_DIR)		\
		TARGET_ARCH=$(TARGET_ARCH)		\
		TARGET_VENDOR=$(TARGET_VENDOR)		\
		TARGET_OS=$(TARGET_OS)			\
		TARGET_ABI=$(TARGET_ABI)		\
		PLATFORM=libc				\
		$(EVAL0_BINARY)

# eval0 is the first version of us that gets built by the compiler of
# the host. this binary may be incomplete and/or differ from eval1,
# but it already contains e.g. all the primfn's or backtrace smartness
# of our stage, and with that it helps development.
#
# to speed up the development cycle, the latest commit is checked out
# into ./build/eval0/, and the eval0 executable is built there.

# TODO actually do this: wrap emit files below with
# --eval "(set-working-directory \"$(SLAVE_DIR)\")"
# --eval "(set-working-directory \"$(HOST_DIR)\")"
$(BUILD_x86)/eval0.s: $(EVAL_OBJ_x86) $(HOST_DIR)/eval source/bootstrapping/*.l $(EVALUATOR_FILES) $(EMIT_FILES_x86) boot.l
	@mkdir -p $(BUILD_x86)
	$(EVAL_WRAPPER) $(HOST_DIR)/eval $(VERBOSITY)				\
		--define *host-directory*	"$(HOST_DIR)"			\
		--define *slave-directory*	"$(SLAVE_DIR)"			\
		--define *compiler-backend*	"x86"				\
		--define target/arch		"$(TARGET_ARCH)"		\
		--define target/vendor		"$(TARGET_VENDOR)"		\
		--define target/os		"$(TARGET_OS)"			\
		--define target/abi		"$(TARGET_ABI)"			\
		--define target/platform	"$(PLATFORM)"			\
		--define feature/profiler/build	"$(PROFILER_MARU)"		\
		source/bootstrapping/prepare.l					\
		boot.l								\
		$(SLAVE_DIR)/source/bootstrapping/host-ready.l			\
		source/bootstrapping/host-extras.l				\
		source/bootstrapping/early.l					\
		boot.l								\
		source/bootstrapping/slave-extras.l				\
		source/bootstrapping/late.l					\
		source/platforms/load-platform.l				\
		source/platforms/$(PLATFORM)/eval.l				\
		source/platforms/run-compiler.l					\
			>$@ || { $(BACKDATE_FILE) $@; exit 42; }

$(BITCODE_DIR)/eval0.ll: $(EVAL_OBJ_llvm) $(HOST_DIR)/eval source/bootstrapping/*.l $(EVALUATOR_FILES) $(EMIT_FILES_llvm) boot.l
	@mkdir -p $(BUILD_llvm) $(BITCODE_DIR)
	$(EVAL_WRAPPER) $(HOST_DIR)/eval $(VERBOSITY)				\
		--define *host-directory* 	"$(HOST_DIR)"			\
		--define *slave-directory* 	"$(SLAVE_DIR)"			\
		--define *compiler-backend* 	"llvm"				\
		--define target/arch 		"$(TARGET_ARCH)"		\
		--define target/vendor 		"$(TARGET_VENDOR)"		\
		--define target/os 		"$(TARGET_OS)"			\
		--define target/abi 		"$(TARGET_ABI)"			\
		--define target/platform	"$(PLATFORM)"			\
		--define feature/profiler/build	"$(PROFILER_MARU)"		\
		source/bootstrapping/prepare.l					\
		boot.l								\
		$(SLAVE_DIR)/source/bootstrapping/host-ready.l			\
		source/bootstrapping/host-extras.l				\
		source/bootstrapping/early.l					\
		boot.l								\
		source/bootstrapping/slave-extras.l				\
		source/bootstrapping/late.l					\
		source/platforms/load-platform.l				\
		source/platforms/$(PLATFORM)/eval.l				\
		source/platforms/run-compiler.l					\
			>$@ || { $(BACKDATE_FILE) $@; exit 42; }

# eval1 is the first version of us that gets built by our own compiler, from the latest sources.
$(BUILD_x86)/eval1.s: $(EVAL_OBJ_x86) boot.l $(EMIT_FILES_x86) source/bootstrapping/*.l $(EVALUATOR_FILES)
	@mkdir -p $(BUILD_x86)
	$(call ensure-built,$(EVAL0))
	$(call compile-x86,$(EVAL0_DIR),$(EVAL0),source/platforms/$(PLATFORM)/eval.l,$@)
#	@-$(DIFF) $(BUILD_x86)/eval0.s $(BUILD_x86)/eval1.s >$(BUILD_x86)/eval1.s.diff

# eval2 is the second iteration of us that gets built by our own compiler, and animated by our own eval1 executable.
# eval2 is just a test: its output should be the exact same files as eval1.*
$(BUILD_x86)/eval2.s: $(EVAL_OBJ_x86) $(BUILD_x86)/eval1 boot.l $(EMIT_FILES_x86) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-x86,$(SLAVE_DIR),$(BUILD_x86)/eval1,source/platforms/$(PLATFORM)/eval.l,$@)
	@-$(DIFF) $(BUILD_x86)/eval1.s $(BUILD_x86)/eval2.s >$(BUILD_x86)/eval2.s.diff

$(BITCODE_DIR)/eval1.ll: $(EVAL_OBJ_llvm) boot.l $(EMIT_FILES_llvm) source/bootstrapping/*.l $(EVALUATOR_FILES)
	@mkdir -p $(BUILD_llvm) $(BITCODE_DIR)
	$(call ensure-built,$(EVAL0))
	$(call compile-llvm,$(EVAL0_DIR),$(EVAL0),source/platforms/$(PLATFORM)/eval.l,$@)
#	@-$(DIFF) $(BITCODE_DIR)/eval0.ll $(BITCODE_DIR)/eval1.ll >$(BITCODE_DIR)/eval1.ll.diff

$(BITCODE_DIR)/eval2.ll: $(EVAL_OBJ_llvm) $(BUILD_llvm)/eval1 boot.l $(EMIT_FILES_llvm) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-llvm,$(SLAVE_DIR),$(BUILD_llvm)/eval1,source/platforms/$(PLATFORM)/eval.l,$@)
	@-$(DIFF) $(BITCODE_DIR)/eval1.ll $(BITCODE_DIR)/eval2.ll >$(BITCODE_DIR)/eval2.ll.diff

# a "function" to compile a maru .l file with a compiler backend
define compile
  $(EVAL_WRAPPER) $(2) $(PROFILER_ARG) -O $(VERBOSITY)				\
	--define *host-directory* 	"$(1)"					\
	--define *slave-directory* 	"$(SLAVE_DIR)"				\
	--define *compiler-backend* 	"$(3)"					\
	--define target/arch 		"$(TARGET_ARCH)"			\
	--define target/vendor 		"$(TARGET_VENDOR)"			\
	--define target/os 		"$(TARGET_OS)"				\
	--define target/abi 		"$(TARGET_ABI)"				\
	--define target/platform	"$(PLATFORM)"				\
	--define feature/profiler/build	"$(PROFILER_MARU)"			\
	source/bootstrapping/prepare.l						\
	boot.l									\
	$(SLAVE_DIR)/source/bootstrapping/host-ready.l				\
	source/bootstrapping/early.l						\
	boot.l									\
	source/bootstrapping/late.l						\
	source/platforms/load-platform.l					\
	$(4)									\
	source/platforms/run-compiler.l						\
	>$(5) && $(call print_file_size,$(5)) || { $(BACKDATE_FILE) $(5); exit 42; }
endef
#	>$(5) 2> >(tee $(5).build-log >&2) || { $(BACKDATE_FILE) $(5); exit 42; }

define compile-x86
  $(call compile,$(1),$(2),x86,$(3),$(4))
endef

define compile-llvm
  $(call compile,$(1),$(2),llvm,$(3),$(4))
endef

# This "function" is useful when you need an eval executable, but you don't want to
# have it rebuilt each time when you are working on e.g. the compiler.
define ensure-built
  test -e $(1) || $(MAKE) $(1)
endef

###
### PEG parser
###
$(BUILD)/generated/peg.g.l: $(GEN_EVAL) source/parsing/peg.g source/parsing/bootstrap-peg-parser.l source/parsing/parser.l source/parsing/peg-compile-forms.l
	@mkdir -p $(BUILD)/generated
	$(EVAL_WRAPPER) $(GEN_EVAL) -O boot.l source/parsing/bootstrap-peg-parser.l >$@ \
		|| { $(BACKDATE_FILE) $@; exit 42; }
	cp $@ $@.$(shell date '+%Y%m%d.%H%M%S')

source/parsing/peg.g.l: $(BUILD)/generated/peg.g.l
	cp $< $@

# compile *.g PEG rules into maru parser implementations
%.g.l: %.g $(GEN_EVAL) source/parsing/parser.l source/parsing/peg.g.l source/parsing/compile-peg-grammar.l
	$(EVAL_WRAPPER) $(GEN_EVAL) -O boot.l source/parsing/compile-peg-grammar.l $< >$@ \
		|| { $(BACKDATE_FILE) $@; exit 42; }

# compile *.cgrov files into *.cgrov.l
# Must use the host eval if we want to use its output while building this stage.
%.cgrov.$(TARGET).l: %.cgrov $(HOST_DIR)/eval
	cd $(HOST_DIR) && make TARGET_ARCH=$(shell uname -m) PLATFORM=libc source/c/cgrov.g.l && ./eval boot.l source/c/compile-cgrov.l $(SLAVE_DIR)/$< > $(SLAVE_DIR)/$<.c
	$(CLANG) --target=$(TARGET) -o $<.exe $<.c
	echo ";; target triple: $$($(CC) -dumpmachine)" > $@.new
	./$<.exe >> $@.new
	mv $@.new $@
	rm -f $<.exe $<.c

# a debug version of the above that uses our stage to run the cgrov
# %.cgrov.l: %.cgrov $(GEN_EVAL) source/c/cgrov.g.l source/c/compile-cgrov.l
# 	$(GEN_EVAL) boot.l source/c/compile-cgrov.l $< > $<.c
# 	$(CC) -o $<.exe $<.c
# 	./$<.exe > $@.new
# 	mv $@.new $@
# 	rm -f $<.exe $<.c

###
### x86 assembler
###
$(BUILD)/generated/x86-instructions.l: $(GEN_EVAL) source/assembler/gen-x86-instructions.l source/repl.l source/parsing/parser.l source/parsing/peg-compile-forms.l source/parsing/peg.g.l
	@mkdir -p $(BUILD)/generated
# KLUDGE, gc/mark-and-sweep is not tailcall for now, so we need more stack space
	ulimit -s unlimited
#	$(call ensure-built,$(GEN_EVAL))
	$(EVAL_WRAPPER) $(GEN_EVAL) -O boot.l source/repl.l source/assembler/gen-x86-instructions.l >$@ \
		|| { $(BACKDATE_FILE) $@; exit 42; }
	cp $@ $@.$(shell date '+%Y%m%d.%H%M%S')

###
### Pattern rules
###
$(BUILD_x86)/%: $(BUILD_x86)/%.s
	@mkdir -p $(@D)
	$(CC) $(CFLAGS_x86) -o $@ $(EVAL_OBJ_x86) $<
	@$(call print_file_size,$@)
	@-$(STRIP) $@ -o $@.stripped

$(BUILD_x86)/%.o: source/platforms/$(PLATFORM)/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS_x86) -c -o $@ $<

# KLUDGE for compat-wrapper.c
$(BUILD_x86)/%.o: source/platforms/libc/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS_x86) -c -o $@ $<

$(BUILD_llvm)/%: $(BITCODE_DIR)/%.ll
	@mkdir -p $(@D)
# TODO shall we go through llc and link the .o file(s)? llc seems to
# generate different code. is it better or worse than clang's output?
	$(CLANG) $(CFLAGS_llvm) --target=$(TARGET) -o $@ $(EVAL_OBJ_llvm) $<
# the rest is just informational
	@$(call print_file_size,$@)
	objdump --disassemble $@ >$@.ll.s
	@-$(STRIP) $@ -o $@.stripped
#	$(CLANG) $(CFLAGS_llvm) --target=$(TARGET) -S -o $@.clang.s $<
#	$(LLC) -O3 -mtriple=$(TARGET) -filetype=obj -o $@.o $<
#	@-$(LLC) -O3 -mtriple=$(TARGET) -filetype=asm -o $@.opt.s $<

$(BUILD_llvm)/%.o: source/platforms/$(PLATFORM)/%.c
	@mkdir -p $(@D)
	$(CLANG) $(CFLAGS_llvm) --target=$(TARGET) -c -o $@ $<

# KLUDGE for compat-wrapper.c
$(BUILD_llvm)/%.o: source/platforms/libc/%.c
	@mkdir -p $(@D)
	$(CLANG) $(CFLAGS_llvm) --target=$(TARGET) -c -o $@ $<

###
### Tests
###
repl: run

run: $(TEST_EVAL)
	rlwrap --no-warning $(TEST_EVAL) boot.l -

run0: $(BUILD_x86)/eval0
	rlwrap --no-warning $(BUILD_x86)/eval0 boot.l -

run-bare: $(TEST_EVAL)
	rlwrap --no-warning $(TEST_EVAL) -

run-x86: $(BUILD_x86)/eval1
	rlwrap --no-warning $(BUILD_x86)/eval1 boot.l -

run-llvm: $(BUILD_llvm)/eval1
	rlwrap --no-warning $(BUILD_llvm)/eval1 boot.l -

test: test-evaluator test-bootstrap test-parser test-elf

test-bootstrap: $(foreach backend,${BACKENDS},test-bootstrap-$(backend)) test-evaluator

# don't use any compiled output that was checked into the repo,
# i.e. run the entire bootstrap process all the way from stage 0
test-bootstrap-recursively:
	$(MAKE) PREVIOUS_STAGE_EXTRA_TARGETS=veryclean veryclean test-bootstrap

# TODO backend duplication
test-bootstrap-x86: $(BUILD_x86)/eval2
	$(DIFF) $(BUILD_x86)/eval1.$(ASM_FILE_EXT_x86) $(BUILD_x86)/eval2.$(ASM_FILE_EXT_x86)
	$(DIFF) $(BUILD_x86)/eval1.stripped $(BUILD_x86)/eval2.stripped
	echo "(and (print () \"i'm alive!\") "") (exit 0)" | $(BUILD_x86)/eval1 boot.l -

test-bootstrap-llvm: $(BUILD_llvm)/eval2
	$(DIFF) $(BITCODE_DIR)/eval1.$(ASM_FILE_EXT_llvm) $(BITCODE_DIR)/eval2.$(ASM_FILE_EXT_llvm)
	$(DIFF) $(BUILD_llvm)/eval1.stripped $(BUILD_llvm)/eval2.stripped
	echo "(and (print () \"i'm alive!\") "") (exit 0)" | $(BUILD_llvm)/eval1 boot.l -

test-compiler: $(foreach backend,${BACKENDS},test-compiler-$(backend))

# TODO backend duplication
test-compiler-x86: $(BUILD_x86)/compiler-test
	$(BUILD_x86)/compiler-test

test-compiler-llvm: $(BUILD_llvm)/compiler-test
	$(BUILD_llvm)/compiler-test

# TODO backend duplication
$(BUILD_x86)/compiler-test.$(ASM_FILE_EXT_x86): $(EVAL0) tests/compiler-test.l $(EVAL_OBJ_x86) $(EMIT_FILES_x86)
	@mkdir -p $(BUILD_x86)
	$(call compile-x86,$(EVAL0_DIR),$(EVAL0),tests/compiler-test.l,$(BUILD_x86)/compiler-test.$(ASM_FILE_EXT_x86))

$(BITCODE_DIR)/compiler-test.$(ASM_FILE_EXT_llvm): $(EVAL0) tests/compiler-test.l $(EVAL_OBJ_llvm) $(EMIT_FILES_llvm)
	@mkdir -p $(BITCODE_DIR)
	@mkdir -p $(BUILD_llvm)
	$(call compile-llvm,$(EVAL0_DIR),$(EVAL0),tests/compiler-test.l,$(BITCODE_DIR)/compiler-test.$(ASM_FILE_EXT_llvm))

test-evaluator: $(TEST_EVAL) boot.l tests/evaluator-tests.l
	$(TEST_EVAL) boot.l tests/evaluator-tests.l

# make PLATFORM=linux test-elf.IA-32
test-elf.IA-32: $(TEST_EVAL) tests/test-elf.IA-32.l source/assembler/x86-instructions.l
	$(TEST_EVAL) boot.l tests/test-elf.IA-32.l
	@chmod +x build/test-elf.IA-32
	-readelf -el build/test-elf.IA-32
	./build/test-elf.IA-32

# make PLATFORM=linux test-elf.x86-64
test-elf.x86-64: $(TEST_EVAL) \
		tests/test-elf.x86-64.traditional.l \
		tests/test-elf.x86-64.single-pass.l \
		tests/test-elf.x86-64.segments.l \
		source/assembler/x86-instructions.l \
		source/platforms/linux/linux.cgrov.$(TARGET).l \
		source/platforms/linux/elf.cgrov.$(TARGET).l
	$(TEST_EVAL) boot.l --define +target-triple+ "$(TARGET)" tests/test-elf.x86-64.traditional.l
#	cmp build/test-elf.x86-64 build/test-elf.x86-64-single-pass

	-readelf -el build/test-elf.x86-64.traditional
	@chmod +x build/test-elf.x86-64.traditional
	./build/test-elf.x86-64.traditional
	@$(call print_file_size,./build/test-elf.x86-64.traditional)

	$(TEST_EVAL) boot.l --define +target-triple+ "$(TARGET)" tests/test-elf.x86-64.single-pass.l
	-readelf -el build/test-elf.x86-64.single-pass
	@chmod +x build/test-elf.x86-64.single-pass
	./build/test-elf.x86-64.single-pass
	@$(call print_file_size,./build/test-elf.x86-64.single-pass)

	$(TEST_EVAL) boot.l --define +ld.so-path+ "$$(ldd /usr/bin/env | awk '/ld-linux/ {print ($$3 ? $$3 : $$1)}')" --define +target-triple+ "$(TARGET)" tests/test-elf.x86-64.segments.l
	-readelf -el build/test-elf.x86-64.segments
	@chmod +x build/test-elf.x86-64.segments
	./build/test-elf.x86-64.segments
	@$(call print_file_size,./build/test-elf.x86-64.segments)

# make PLATFORM=linux test-elf
test-elf: test-elf.x86-64

# make PLATFORM=linux test-jit
test-jit: $(TEST_EVAL) tests/jit.l source/assembler/x86-instructions.l
	@rm -rf $(BUILD)/jit/*
	@mkdir -p $(BUILD)/jit
	rm -f $(BUILD)/jit/*
	$(TEST_EVAL) boot.l --define +target-triple+ "$(TARGET)" tests/jit.l

test-parser: $(TEST_EVAL) tests/parsing/gnu-bc.g.l tests/parsing/* source/parsing/*
	$(TEST_EVAL) boot.l tests/parsing/gnu-bc-test.l
