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
#  make TARGET_CPU=x86_64 TARGET_VENDOR=apple TARGET_OS=darwin test-bootstrap-llvm || beep
#  make TARGET_CPU=i686 TARGET_VENDOR=linux TARGET_OS=gnu test-bootstrap-llvm eval-llvm || beep
#  make TARGET_CPU=i686 TARGET_VENDOR=linux TARGET_OS=gnu PLATFORM=linux test-bootstrap-llvm || beep
#  make PROFILER=1 test-bootstrap-x86 || beep
# to force a full bootstrap cycle all the way down from the/a bottom stage:
#  make test-bootstrap-recursively || beep
#
# the makefile parallelism is mostly only between the backends. don't use it
# while bootstrapping all the way from a bottom stage, it's broken somewhere.

##
## configuration
##

# backends to build
BACKENDS		= x86 llvm
PLATFORMS		= libc linux
# use this backend of the previous stage when it needs to be built.
PREVIOUS_STAGE_BACKEND	= -llvm

HOST_OS		= $(shell uname -s)
TARGET_CPU	?= $(shell uname -m)
PLATFORM	?= libc

ifeq ($(HOST_OS),Linux)
#  LLVM_VERSION	= -10		# just try whichever version you have. it should work at least with these: 8, 10
  LLVM_VERSION	=
  TARGET_VENDOR	?= linux
  TARGET_OS	?= gnu
  TIME		= time --format='\n$(GREEN)user time: %U$(RESET)\n'
else ifeq ($(HOST_OS),Darwin)
  LLVM_VERSION	=
  TARGET_VENDOR	?= apple
  #TARGET_OS	?= darwin$(shell uname -r)
  TARGET_OS	?= darwin
  TIME		= time
endif

CFLAGS		+= -O3
CFLAGS_x86	+= $(CFLAGS)
CFLAGS_llvm	+= $(CFLAGS) -Qunused-arguments

ifeq ($(PLATFORM),linux)
  CFLAGS	+= -nostdlib -nostartfiles -Wl,-Bstatic
endif

TARGET_x86	= i386-$(TARGET_VENDOR)-$(TARGET_OS)

TARGET_llvm	?= $(TARGET_CPU)-$(TARGET_VENDOR)-$(TARGET_OS)
#TARGET_llvm	?= $(shell llvm-config$(LLVM_VERSION) --host-target)

# used when generating maru sources during the build process
# in the order of speed
#GEN_EVAL	= $(BUILD)/llvm/i686-$(TARGET_VENDOR)-$(TARGET_OS)/eval1
GEN_EVAL	= $(BUILD_llvm)/eval1
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

TARGET_CPU_x86	= $(word 1, $(subst -, ,$(TARGET_x86)))
TARGET_CPU_llvm	= $(word 1, $(subst -, ,$(TARGET_llvm)))

ifeq ($(TARGET_CPU_llvm),x86_64)
  BITCODE_DIR		= $(BUILD)/llvm-$(PLATFORM)/64bit-le
else ifeq ($(TARGET_CPU_llvm),i686)
  BITCODE_DIR		= $(BUILD)/llvm-$(PLATFORM)/32bit-le
else
  $(error "Couldn't extract the target's word size from TARGET_CPU_llvm '$(TARGET_CPU_llvm)'.")
endif

ifeq ($(TARGET_CPU_x86),x86_64)
else ifeq ($(TARGET_CPU_x86),i386)
  CFLAGS_x86	+= -m32
else
  $(error "Unexpected TARGET_CPU_x86 '$(TARGET_CPU_x86)'.")
endif

ifeq ($(TARGET_CPU_llvm),x86_64)
else ifeq ($(TARGET_CPU_llvm),i686)
  CFLAGS_llvm	+= -m32
else
  $(error "Unexpected TARGET_CPU_llvm '$(TARGET_CPU_llvm)'.")
endif

# see https://stackoverflow.com/a/20983251/14464
RED		= $(shell tput setaf 1)
GREEN		= $(shell tput setaf 2)
BLUE		= $(shell tput setaf 4)
RESET		= $(shell tput sgr0)

BACKDATE_FILE	= touch -t 200012312359

LLC		= llc$(LLVM_VERSION)
LLVM_OPT	= opt$(LLVM_VERSION)
CLANG		= clang$(LLVM_VERSION)
DIFF		= diff --unified --ignore-all-space
STRIP		= strip

ASM_FILE_EXT_x86	= s
ASM_FILE_EXT_llvm	= ll

BUILD		= build

BUILD_x86	= $(BUILD)/x86-$(PLATFORM)/$(TARGET_x86)
BUILD_llvm	= $(BUILD)/llvm-$(PLATFORM)/$(TARGET_llvm)
HOST_DIR	= $(BUILD)/$(PREVIOUS_STAGE)
SLAVE_DIR	= $(CURDIR)

#EVAL0_PHASE=1
ifdef EVAL0_PHASE
  # This way eval0 is built each time
  EVAL0_DIR	= $(SLAVE_DIR)
  EVAL0_BINARY	= eval0-llvm
  EVAL0		= $(BUILD_llvm)/eval0
else
  # This way eval0 is built from the latest commit, checked out as a
  # working dir in build/eval0 and 'make update-eval0' must be used to
  # update its git working tree. This mode requires more attention when
  # dealing with sensitive bootstrapping issues, but then you can just
  # switch to build eval0 each time.
  EVAL0_DIR	= $(CURDIR)/$(BUILD)/eval0
  EVAL0_BINARY	= eval0-llvm
  EVAL0		= $(EVAL0_DIR)/$(EVAL0_BINARY)
endif

EMIT_FILES_x86	= $(addprefix source/,emit-early.l emit-x86.l  emit-late.l)
EMIT_FILES_llvm	= $(addprefix source/,emit-early.l emit-llvm.l emit-late.l)

GENERATED_FILES = $(addprefix source/,parsing/peg.g.l assembler/asm-x86.l)

EVALUATOR_FILES	= $(addprefix source/platforms/$(PLATFORM)/,$(PLATFORM).l eval.l streams.l) \
 $(addprefix source/evaluator/,eval.l gc.l printer.l reader.l primitive-functions.l arrays.l vm-early.l vm-late.l) \
 $(addprefix source/,list-min.l env-min.l sequences-min.l selector.l generic.l types.l)

# for some optional C files, e.g. profiler.c
EVAL_OBJ_x86	=
EVAL_OBJ_llvm	=

ifdef PROFILER
  PROFILER	= 1
  EVAL_OBJ_x86	+= $(BUILD_x86)/profiler.o
  EVAL_OBJ_llvm	+= $(BUILD_llvm)/profiler.o
  PROFILER_ARG	= -p
else
  PROFILER	= 0
  PROFILER_ARG	=
endif

.SUFFIXES:					# disable all built-in rules

#.PRECIOUS: $(BUILD_x86)/eval1.s $(BITCODE_DIR)/eval1.ll

all: eval

eval: $(foreach backend,${BACKENDS},eval-$(backend))
# NOTE this way ./eval will be the last one in BACKENDS that actually got built, which is llvm as things are

# TODO $(foreach backend,${BACKENDS},stats-$(backend)): stats-%:
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
  $(GEN_EVAL) boot.l tools-for-build/file-list-from-require.l $(1)
endef

$(foreach backend,${BACKENDS},stats-$(backend)): stats-%:
	@$(call ensure-built,$(GEN_EVAL))
	@echo -e '\nBackend $(BLUE)$*$(RESET):\n'
	@files=`$(call collect-files,boot.l $(EMIT_FILES_$*))`;				$(call count-loc,"Compiler LoC: ",$$files)
	@files=`$(call collect-files,$(EVALUATOR_FILES))`;				$(call count-loc,"Evaluator LoC: ",$$files)
	@files=`$(call collect-files,boot.l $(EMIT_FILES_$*) $(EVALUATOR_FILES))`;	$(call count-loc,"Alltogether LoC: ",$$files)

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
	$(MAKE) --directory=$(BUILD)/$(PREVIOUS_STAGE) $(PREVIOUS_STAGE_EXTRA_TARGETS) eval$(PREVIOUS_STAGE_BACKEND)

update-eval0: $(EVAL0_DIR)
	cd $(EVAL0_DIR) && git reset --hard HEAD~30 && git pull ../..

# check out our latest commit into build/eval0/, and build the eval0 executable
# there, in a clean tree.
$(EVAL0_DIR):
	git worktree add --detach --force $@
# a git checkout doesn't do anything to file modification times, so we just touch everything that happens to be checked in under build/ to avoid unnecessary rebuilds
	-find $@/$(BUILD) -type f -exec touch {} \;

# "forward" this target to the makefile in build/eval0
# NOTE: we fix TARGET_CPU to i686 (and platform to linux) because 32 bit LLVM is the fastest version of us.
$(EVAL0_DIR)/$(EVAL0_BINARY): $(EVAL0_DIR)
	$(MAKE) --directory=$(EVAL0_DIR)		\
		TARGET_CPU=i686				\
		TARGET_VENDOR=$(TARGET_VENDOR)		\
		TARGET_OS=$(TARGET_OS)			\
		PLATFORM=linux				\
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
	$(TIME) $(HOST_DIR)/eval -v						\
		--define *host-directory* 	"$(HOST_DIR)"			\
		--define *slave-directory* 	"$(SLAVE_DIR)"			\
		source/bootstrapping/prepare.l					\
		boot.l								\
		$(SLAVE_DIR)/source/bootstrapping/host-ready.l			\
		source/bootstrapping/host-extras.l				\
		source/bootstrapping/early.l					\
		boot.l								\
		source/bootstrapping/slave-extras.l				\
		source/bootstrapping/late.l					\
		--define target/cpu 		$(TARGET_CPU_x86)		\
		--define target/vendor 		$(TARGET_VENDOR)		\
		--define target/os 		$(TARGET_OS)			\
		$(EMIT_FILES_x86)						\
		source/platforms/$(PLATFORM)/eval.l				\
		source/emit-finish.l						\
			>$@ || { $(BACKDATE_FILE) $@; exit 42; }

$(BITCODE_DIR)/eval0.ll: $(EVAL_OBJ_llvm) $(HOST_DIR)/eval source/bootstrapping/*.l $(EVALUATOR_FILES) $(EMIT_FILES_llvm) boot.l
	@mkdir -p $(BUILD_llvm) $(BITCODE_DIR)
	$(TIME) $(HOST_DIR)/eval -v						\
		--define *host-directory* 	"$(HOST_DIR)"			\
		--define *slave-directory* 	"$(SLAVE_DIR)"			\
		source/bootstrapping/prepare.l					\
		boot.l								\
		$(SLAVE_DIR)/source/bootstrapping/host-ready.l			\
		source/bootstrapping/host-extras.l				\
		source/bootstrapping/early.l					\
		--define feature/profiler  	$(PROFILER)			\
		boot.l								\
		source/bootstrapping/slave-extras.l				\
		source/bootstrapping/late.l					\
		--define target/cpu 		$(TARGET_CPU_llvm)		\
		--define target/vendor 		$(TARGET_VENDOR)		\
		--define target/os 		$(TARGET_OS)			\
		$(EMIT_FILES_llvm)						\
		source/platforms/$(PLATFORM)/eval.l				\
		source/emit-finish.l						\
			>$@ || { $(BACKDATE_FILE) $@; exit 42; }

# eval1 is the first version of us that gets built by our own compiler, from the latest sources.
$(BUILD_x86)/eval1.s: boot.l $(EMIT_FILES_x86) source/bootstrapping/*.l $(EVALUATOR_FILES)
	@mkdir -p $(BUILD_x86)
	$(call ensure-built,$(EVAL0))
	$(call compile-x86,$(EVAL0_DIR),$(EVAL0),source/platforms/$(PLATFORM)/eval.l,$@)
#	@-$(DIFF) $(BUILD_x86)/eval0.s $(BUILD_x86)/eval1.s >$(BUILD_x86)/eval1.s.diff

# eval2 is the second iteration of us that gets built by our own compiler, and animated by our own eval1 executable.
# eval2 is just a test: its output should be the exact same files as eval1.*
$(BUILD_x86)/eval2.s: $(BUILD_x86)/eval1 boot.l $(EMIT_FILES_x86) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-x86,$(SLAVE_DIR),$(BUILD_x86)/eval1,source/platforms/$(PLATFORM)/eval.l,$@)
	@-$(DIFF) $(BUILD_x86)/eval1.s $(BUILD_x86)/eval2.s >$(BUILD_x86)/eval2.s.diff

$(BITCODE_DIR)/eval1.ll: boot.l $(EMIT_FILES_llvm) source/bootstrapping/*.l $(EVALUATOR_FILES)
	@mkdir -p $(BUILD_llvm) $(BITCODE_DIR)
	$(call ensure-built,$(EVAL0))
	$(call compile-llvm,$(EVAL0_DIR),$(EVAL0),source/platforms/$(PLATFORM)/eval.l,$@)
#	@-$(DIFF) $(BITCODE_DIR)/eval0.ll $(BITCODE_DIR)/eval1.ll >$(BITCODE_DIR)/eval1.ll.diff

$(BITCODE_DIR)/eval2.ll: $(BUILD_llvm)/eval1 boot.l $(EMIT_FILES_llvm) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-llvm,$(SLAVE_DIR),$(BUILD_llvm)/eval1,source/platforms/$(PLATFORM)/eval.l,$@)
	@-$(DIFF) $(BITCODE_DIR)/eval1.ll $(BITCODE_DIR)/eval2.ll >$(BITCODE_DIR)/eval2.ll.diff

# a "function" to compile a maru .l file with a compiler backend
# TODO backend duplication: they only differ in $(backend). the solution may involve .SECONDEXPANSION: and foreach. see also the other occurrances of 'backend duplication'.
define compile-x86
  $(TIME) $(2) $(PROFILER_ARG) -O -v						\
	--define *host-directory* 	"$(1)"					\
	--define *slave-directory* 	"$(SLAVE_DIR)"				\
	source/bootstrapping/prepare.l						\
	boot.l									\
	$(SLAVE_DIR)/source/bootstrapping/host-ready.l				\
	source/bootstrapping/early.l						\
	--define feature/profiler 		$(PROFILER)			\
	boot.l									\
	source/bootstrapping/late.l						\
	--define target/cpu 			$(TARGET_CPU_x86)		\
	--define target/vendor 			$(TARGET_VENDOR)		\
	--define target/os 			$(TARGET_OS)			\
	$(EMIT_FILES_x86)							\
	$(3)									\
	source/emit-finish.l							\
		>$(4) || { $(BACKDATE_FILE) $(4); exit 42; }
endef

define compile-llvm
  $(TIME) $(2) $(PROFILER_ARG) -O -v						\
	--define *host-directory* 	"$(1)"					\
	--define *slave-directory* 	"$(SLAVE_DIR)"				\
	source/bootstrapping/prepare.l						\
	boot.l									\
	$(SLAVE_DIR)/source/bootstrapping/host-ready.l				\
	source/bootstrapping/early.l						\
	--define feature/profiler 		$(PROFILER)			\
	boot.l									\
	source/bootstrapping/late.l						\
	--define target/cpu 			$(TARGET_CPU_llvm)		\
	--define target/vendor 			$(TARGET_VENDOR)		\
	--define target/os 			$(TARGET_OS)			\
	$(EMIT_FILES_llvm)							\
	$(3)									\
	source/emit-finish.l							\
		>$(4) || { $(BACKDATE_FILE) $(4); exit 42; }
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
	$(TIME) $(GEN_EVAL) -O boot.l source/parsing/bootstrap-peg-parser.l >$@ \
		|| { $(BACKDATE_FILE) $@; exit 42; }
	cp $@ $@.$(shell date '+%Y%m%d.%H%M%S')

source/parsing/peg.g.l: $(BUILD)/generated/peg.g.l
	cp $< $@

# compile *.g PEG rules into maru parser implementations
%.g.l: %.g $(GEN_EVAL) source/parsing/parser.l source/parsing/peg.g.l source/parsing/compile-peg-grammar.l
	$(TIME) $(GEN_EVAL) -O boot.l source/parsing/compile-peg-grammar.l $< >$@ \
		|| { $(BACKDATE_FILE) $@; exit 42; }

###
### x86 assembler
###
$(BUILD)/generated/asm-x86.l: $(GEN_EVAL) source/assembler/gen-asm-x86.l source/repl.l source/parsing/parser.l source/parsing/peg-compile-forms.l source/parsing/peg.g.l
	@mkdir -p $(BUILD)/generated
#	$(call ensure-built,$(GEN_EVAL))
	$(TIME) $(GEN_EVAL) -O boot.l source/repl.l source/assembler/gen-asm-x86.l >$@ \
		|| { $(BACKDATE_FILE) $@; exit 42; }
	cp $@ $@.$(shell date '+%Y%m%d.%H%M%S')

source/assembler/asm-x86.l: $(BUILD)/generated/asm-x86.l
	cp $< $@

###
### Pattern rules
###
$(BUILD_x86)/%: $(BUILD_x86)/%.s
	@mkdir -p $(@D)
	$(CC) $(CFLAGS_x86) -o $@ $(EVAL_OBJ_x86) $<
	@-$(STRIP) $@ -o $@.stripped

$(BUILD_x86)/%.o: source/evaluator/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS_x86) -c -o $@ $<

$(BUILD_llvm)/%: $(BITCODE_DIR)/%.ll
	@mkdir -p $(@D)
# TODO shall we go through llc and link the .o file(s)? llc seems to
# generate different code. is it better or worse than clang's output?
	$(CLANG) $(CFLAGS_llvm) --target=$(TARGET_llvm) -o $@ $(EVAL_OBJ_llvm) $<
# the rest is just informational
	objdump --disassemble $@ >$@.dis.s
	@-$(STRIP) $@ -o $@.stripped
#	$(CLANG) $(CFLAGS_llvm) --target=$(TARGET_llvm) -S -o $@.clang.s $<
#	$(LLC) -O3 -mtriple=$(TARGET_llvm) -filetype=obj -o $@.o $<
#	@-$(LLC) -O3 -mtriple=$(TARGET_llvm) -filetype=asm -o $@.opt.s $<

$(BUILD_llvm)/%.o: source/evaluator/%.c
	@mkdir -p $(@D)
	$(CLANG) $(CFLAGS_llvm) --target=$(TARGET_llvm) -c -o $@ $<

###
### Tests
###
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
$(BUILD_x86)/compiler-test.$(ASM_FILE_EXT_x86): $(EVAL0_DIR)/$(EVAL0) tests/compiler-tests.l $(EMIT_FILES_x86)
	@mkdir -p $(BUILD_x86)
	$(call compile-x86,$(EVAL0_DIR),$(EVAL0_DIR)/$(EVAL0),tests/compiler-tests.l,$(BUILD_x86)/compiler-test.$(ASM_FILE_EXT_x86))

$(BITCODE_DIR)/compiler-test.$(ASM_FILE_EXT_llvm): $(EVAL0_DIR)/$(EVAL0) tests/compiler-tests.l $(EMIT_FILES_llvm)
	@mkdir -p $(BITCODE_DIR)
	@mkdir -p $(BUILD_llvm)
	$(call compile-llvm,$(EVAL0_DIR),$(EVAL0_DIR)/$(EVAL0),tests/compiler-tests.l,$(BITCODE_DIR)/compiler-test.$(ASM_FILE_EXT_llvm))

test-evaluator: $(TEST_EVAL) boot.l tests/evaluator-tests.l
	$(TEST_EVAL) boot.l tests/evaluator-tests.l

# NOTE test-elf needs the IA-32 eval-x86
test-elf: eval-x86 tests/test-elf.l source/assembler/asm-common.l source/assembler/asm-x86.l
	./eval-x86 boot.l tests/test-elf.l
	@chmod +x build/test-elf
	-readelf -el build/test-elf
	./build/test-elf

test-parser: $(TEST_EVAL) tests/parsing/gnu-bc.g.l tests/parsing/* source/parsing/*
	$(TEST_EVAL) boot.l tests/parsing/gnu-bc-test.l
