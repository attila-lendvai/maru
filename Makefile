#
# Welcome to the usual makefile mess. It will hopefully be bootstrapped away sooner than later...
#
# it's possible to invoke stuff like:
#  make -j eval
#  make eval-llvm
#
#  alias beep='paplay some-file.ogg'
#  make -j test-bootstrap || beep
#  make test-bootstrap-llvm || beep
#  make -j test-compiler || beep
#  make -j test-compiler-llvm || beep
#  make TARGET_llvm=i686-pc-linux-gnu test-bootstrap-llvm || beep
#
# the makefile parallelism is mostly only between the backends.

##
## configuration
##

# backends to build
BACKENDS		= x86 llvm
# use this backend of the previous stage when it needs to be built.
PREVIOUS_STAGE_BACKEND	= llvm

LLVM_VERSION	= 8
LLVM_ARGS	= -O3

TARGET_VENDOR	= pc-linux
TARGET_OS	= gnu

TARGET_x86	= i386-$(TARGET_VENDOR)-$(TARGET_OS)

#TARGET_llvm	?= i686-$(TARGET_VENDOR)-$(TARGET_OS)
TARGET_llvm	?= $(shell llvm-config-$(LLVM_VERSION) --host-target)

# use this eval to execute any tests or code generation from the makefile.
# in order of speed, as of this writing.
#TEST_EVAL	= build/llvm/i686-pc-linux-gnu/eval2
TEST_EVAL	= $(BUILD_llvm)/eval2
#TEST_EVAL	= $(BUILD_x86)/eval2

##
## internal variables
##
PREVIOUS_STAGE	= maru.5

MAKEFLAGS	+= --warn-undefined-variables --output-sync

TARGET_CPU_llvm	= $(firstword $(subst -, ,$(TARGET_llvm)))

ifeq ($(TARGET_CPU_llvm),x86_64)
  TARGET_WORD_SIZE_llvm	= 64
  BITCODE_DIR		= $(BUILD)/llvm/libc-64bit-le
else ifeq ($(TARGET_CPU_llvm),i686)
  TARGET_WORD_SIZE_llvm	= 32
  BITCODE_DIR		= $(BUILD)/llvm/libc-32bit-le
else
  $(error "Couldn't extract the target's word size from the llvm triplet '$(TARGET_llvm)'. Extracted CPU: '$(TARGET_CPU_llvm)'")
endif


# see https://stackoverflow.com/a/20983251/14464
RED		= $(shell tput setaf 1)
GREEN		= $(shell tput setaf 2)
BLUE		= $(shell tput setaf 4)
RESET		= $(shell tput sgr0)

LLC		= llc-$(LLVM_VERSION) $(LLVM_ARGS)
LLVM_OPT	= opt-$(LLVM_VERSION) $(LLVM_ARGS)
CLANG		= clang-$(LLVM_VERSION) $(LLVM_ARGS)
DIFF		= diff --unified --ignore-all-space
STRIP		= strip
TIME		= time --format='\n$(GREEN)user time: %U$(RESET)\n'

ASM_FILE_EXT_x86	= s
ASM_FILE_EXT_llvm	= ll

BUILD		= build

BUILD_x86	= $(BUILD)/x86/$(TARGET_x86)
BUILD_llvm	= $(BUILD)/llvm/$(TARGET_llvm)
HOST_DIR	= $(BUILD)/$(PREVIOUS_STAGE)

EMIT_FILES_x86	= $(addprefix source/,emit-early.l emit-x86.l  emit-late.l)
EMIT_FILES_llvm	= $(addprefix source/,emit-early.l emit-llvm.l emit-late.l)

EVALUATOR_FILES	= $(addprefix source/evaluator/,buffer.l eval.l gc.l printer.l reader.l subrs.l arrays.l)

.SUFFIXES:					# disable all built-in rules

all: eval

clean:
	rm -rf $(BUILD)/x86 $(BUILD)/llvm eval $(foreach backend,${BACKENDS},eval-$(backend))
	git checkout $(BUILD) || true

distclean: clean
	rm -rf $(BUILD)
	git checkout $(BUILD) || true

stats: $(foreach backend,${BACKENDS},stats-$(backend))

$(foreach backend,${BACKENDS},stats-$(backend)): stats-%:
	@echo -e '\nBackend $(BLUE)$*$(RESET):\n'
	cat boot.l $(EMIT_FILES_$*)			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat $(EVALUATOR_FILES)				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l $(EMIT_FILES_$*) $(EVALUATOR_FILES)	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

###
### eval and bootstrapping
###
eval: $(foreach backend,${BACKENDS},eval-$(backend))
# NOTE this way ./eval will be the last one in BACKENDS that actually got built, which is llvm as things are

eval-x86: $(BUILD_x86)/eval2
	cp $< $@
	cp $< eval

eval-llvm: $(BUILD_llvm)/eval2
	cp $< $@
	cp $< eval

# eval1 is the first version of us that gets built by the previous stage.
# some functionality may be broken in this one. this is when we are 'evolving'.
$(BUILD_x86)/eval1.s: $(HOST_DIR)/eval source/bootstrapping/*.l $(EVALUATOR_FILES) boot.l
	@mkdir --parents $(BUILD_x86)
	$(TIME) $(HOST_DIR)/eval					\
		$(HOST_DIR)/boot.l					\
		source/bootstrapping/prepare.l				\
		source/bootstrapping/host-extras.l			\
		source/bootstrapping/early.l				\
		boot.l							\
		source/bootstrapping/slave-extras.l			\
		source/bootstrapping/late.l				\
		--define makefile/target-triplet   $(TARGET_x86)	\
		--define makefile/target/word-size-in-bits 32		\
		$(EMIT_FILES_x86)					\
		source/evaluator/eval.l					\
			>$@ || { touch --date=2000-01-01 $@; exit 42; }

$(BITCODE_DIR)/eval1.ll: $(HOST_DIR)/eval source/bootstrapping/*.l $(EVALUATOR_FILES) boot.l
	@mkdir --parents $(BUILD_llvm) $(BITCODE_DIR)
	$(TIME) $(HOST_DIR)/eval					\
		$(HOST_DIR)/boot.l					\
		source/bootstrapping/prepare.l				\
		source/bootstrapping/host-extras.l			\
		source/bootstrapping/early.l				\
		boot.l							\
		source/bootstrapping/slave-extras.l			\
		source/bootstrapping/late.l				\
		--define makefile/target-triplet   $(TARGET_llvm)	\
		--define makefile/target/word-size-in-bits $(TARGET_WORD_SIZE_llvm)	\
		$(EMIT_FILES_llvm)					\
		source/evaluator/eval.l					\
			>$@ || { touch --date=2000-01-01 $@; exit 42; }

# eval2 is the bootstrapped version of this stage, self-built by this stage (i.e. by eval1).
# eval2 should implement the semantics encoded by the sources of this stage.
$(BUILD_x86)/eval2.s: $(BUILD_x86)/eval1 boot.l $(EMIT_FILES_x86) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-x86,$(BUILD_x86)/eval1,source/evaluator/eval.l,$(BUILD_x86)/eval2.s)
	@-$(DIFF) $(BUILD_x86)/eval1.s $(BUILD_x86)/eval2.s >$(BUILD_x86)/eval2.s.diff

$(BITCODE_DIR)/eval2.ll: $(BUILD_llvm)/eval1 boot.l $(EMIT_FILES_llvm) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-llvm,$(BUILD_llvm)/eval1,source/evaluator/eval.l,$(BITCODE_DIR)/eval2.ll)
	@-$(DIFF) $(BITCODE_DIR)/eval1.ll $(BITCODE_DIR)/eval2.ll >$(BITCODE_DIR)/eval2.ll.diff

# eval3 is just a test, it's the result of yet another bootstrap iteration, based off of eval2 this time.
# eval3.s should be the exact same file as the output of the previous iteration, namely eval2.s.
$(BUILD_x86)/eval3.s: $(BUILD_x86)/eval2 boot.l $(EMIT_FILES_x86) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-x86,$(BUILD_x86)/eval2,source/evaluator/eval.l,$(BUILD_x86)/eval3.s)
	@-$(DIFF) $(BUILD_x86)/eval2.s $(BUILD_x86)/eval3.s >$(BUILD_x86)/eval3.s.diff

$(BITCODE_DIR)/eval3.ll: $(BUILD_llvm)/eval2 boot.l $(EMIT_FILES_llvm) source/bootstrapping/*.l $(EVALUATOR_FILES)
	$(call compile-llvm,$(BUILD_llvm)/eval2,source/evaluator/eval.l,$(BITCODE_DIR)/eval3.ll)
	@-$(DIFF) $(BITCODE_DIR)/eval2.ll $(BITCODE_DIR)/eval3.ll >$(BITCODE_DIR)/eval3.ll.diff

$(HOST_DIR)/eval:
	echo Building $(BUILD)/$(PREVIOUS_STAGE)
	@mkdir --parents $(BUILD)
# after cloning, we must create the local branches ourselves; the issue in detail: https://stackoverflow.com/questions/40310932/git-hub-clone-all-branches-at-once
	@git show-ref --verify --quiet refs/heads/$(PREVIOUS_STAGE) || git branch --quiet --track $(PREVIOUS_STAGE) remotes/origin/$(PREVIOUS_STAGE)
	test -d $(BUILD)/$(PREVIOUS_STAGE) || git worktree add --detach --force $(BUILD)/$(PREVIOUS_STAGE) $(PREVIOUS_STAGE)
# a git checkout doesn't do anything to file modification times, so we just touch everything that happens to be checked in under build/ to avoid unnecessary rebuilds
	-find $(BUILD)/$(PREVIOUS_STAGE)/$(BUILD) -type f -exec touch {} \;
	$(MAKE) --directory=$(BUILD)/$(PREVIOUS_STAGE) eval-$(PREVIOUS_STAGE_BACKEND)

# a "function" to compile a maru .l file with a compiler backend
# TODO backend duplication: they only differ in $(backend). the solution may involve .SECONDEXPANSION: and foreach. see also the other occurrances of 'backend duplication'.
define compile-x86
  $(TIME) $(1)									\
	boot.l									\
	source/bootstrapping/prepare.l						\
	source/bootstrapping/early.l						\
	boot.l									\
	source/bootstrapping/late.l						\
	--define makefile/target-triplet $(TARGET_x86)				\
	--define makefile/target/word-size-in-bits 32				\
	$(EMIT_FILES_x86)							\
	$(2)									\
		>$(3) || { touch --date=2000-01-01 $(3); exit 42; }
endef

define compile-llvm
  $(TIME) $(1)									\
	boot.l									\
	source/bootstrapping/prepare.l						\
	source/bootstrapping/early.l						\
	boot.l									\
	source/bootstrapping/late.l						\
	--define makefile/target-triplet   $(TARGET_llvm)			\
	--define makefile/target/word-size-in-bits $(TARGET_WORD_SIZE_llvm)	\
	$(EMIT_FILES_llvm)							\
	$(2)									\
		>$(3) || { touch --date=2000-01-01 $(3); exit 42; }
endef

# This "function" is useful when you need an eval executable, but you don't want to
# have it rebuilt each time when you are working on e.g. the compiler.
define ensure-built
  test -e $(1) || $(MAKE) $(1)
endef

###
### PEG parser
###
$(BUILD)/peg.l: source/parsing/peg.g source/parsing/peg-bootstrap.l source/parsing/parser.l source/parsing/peg-compile.l
	$(call ensure-built,$(TEST_EVAL))
	$(TIME) $(TEST_EVAL) boot.l source/parsing/peg-bootstrap.l >$(BUILD)/peg.l \
		|| { touch --date=2000-01-01 $(BUILD)/peg.l; exit 42; }
#	mv peg.l peg.l.$(shell date '+%Y%m%d.%H%M%S')

source/parsing/peg.l: $(BUILD)/peg.l
	cp $(BUILD)/peg.l source/parsing/peg.l

###
### Pattern rules
###
$(BUILD)/%: $(BUILD)/%.s
	@mkdir --parents $(@D)
	$(CC) -m32 -o $@ $<
	@-$(STRIP) $@ -o $@.stripped

$(BUILD_llvm)/%: $(BITCODE_DIR)/%.ll
	@mkdir --parents $(@D)
	$(LLC) -mtriple=$(TARGET_llvm) -filetype=obj -o $@.o $<
	$(CLANG) --target=$(TARGET_llvm) -o $@ $@.o
# the rest is just informational
	@-$(STRIP) $@ -o $@.stripped
	@-$(LLC) -mtriple=$(TARGET_llvm) -filetype=asm -o $@.opt.s $<
#	$(CLANG) --target=$(TARGET_llvm) -S -o $@.clang.s $<

###
### Tests
###
run: $(TEST_EVAL)
	rlwrap $(TEST_EVAL) boot.l -

test-bootstrap: $(foreach backend,${BACKENDS},test-bootstrap-$(backend)) test-evaluator

# TODO backend duplication
test-bootstrap-x86: $(BUILD_x86)/eval3
	$(DIFF) $(BUILD_x86)/eval2.$(ASM_FILE_EXT_x86) $(BUILD_x86)/eval3.$(ASM_FILE_EXT_x86)
	$(DIFF) $(BUILD_x86)/eval2.stripped $(BUILD_x86)/eval3.stripped
	echo "(and (print () \"i'm alive!\") "") (exit 0)" | $(BUILD_x86)/eval2 boot.l -

test-bootstrap-llvm: $(BUILD_llvm)/eval3
	$(DIFF) $(BITCODE_DIR)/eval2.$(ASM_FILE_EXT_llvm) $(BITCODE_DIR)/eval3.$(ASM_FILE_EXT_llvm)
	$(DIFF) $(BUILD_llvm)/eval2.stripped $(BUILD_llvm)/eval3.stripped
	echo "(and (print () \"i'm alive!\") "") (exit 0)" | $(BUILD_llvm)/eval2 boot.l -

test-compiler: $(foreach backend,${BACKENDS},test-compiler-$(backend))

# TODO backend duplication
test-compiler-x86: $(BUILD_x86)/compiler-test
	$(BUILD_x86)/compiler-test

test-compiler-llvm: $(BUILD_llvm)/compiler-test
	$(BUILD_llvm)/compiler-test

# TODO backend duplication
$(BUILD_x86)/compiler-test.$(ASM_FILE_EXT_x86): tests/compiler-tests.l $(EMIT_FILES_x86)
	$(call ensure-built,$(TEST_EVAL))
	$(call compile-x86,$(TEST_EVAL),tests/compiler-tests.l,$(BUILD_x86)/compiler-test.$(ASM_FILE_EXT_x86))

$(BITCODE_DIR)/compiler-test.$(ASM_FILE_EXT_llvm): tests/compiler-tests.l $(EMIT_FILES_llvm)
	@mkdir --parents $(BUILD_llvm)
	$(call ensure-built,$(TEST_EVAL))
	$(call compile-llvm,$(TEST_EVAL),tests/compiler-tests.l,$(BITCODE_DIR)/compiler-test.$(ASM_FILE_EXT_llvm))

test-evaluator: $(TEST_EVAL) boot.l tests/evaluator-tests.l
	$(TEST_EVAL) boot.l tests/evaluator-tests.l
