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
#
# the makefile parallelism is mostly only between the backends.

##
## configuration
##
BACKENDS	= x86 llvm

LLVM_VERSION	= 8
LLVM_ARGS	= -O3

TARGET_VENDOR	= pc-linux
TARGET_OS	= gnu

TARGET_x86	= i386-$(TARGET_VENDOR)-$(TARGET_OS)

# The LLVM target's word size must be in sync with the constant in emit-early.l!
#TARGET_llvm	?= i686-$(TARGET_VENDOR)-$(TARGET_OS)
TARGET_llvm	?= $(shell llvm-config-$(LLVM_VERSION) --host-target)

##
## internal variables
##
PREVIOUS_STAGE	= maru.4

MAKEFLAGS	+= --warn-undefined-variables --output-sync

TARGET_CPU_llvm	= $(firstword $(subst -, ,$(TARGET_llvm)))

ifeq ($(TARGET_CPU_llvm),x86_64)
  TARGET_WORD_SIZE_llvm = 64
else ifeq ($(TARGET_CPU_llvm),i686)
  TARGET_WORD_SIZE_llvm = 32
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
BOOT_EVAL_PATH	= $(BUILD)/$(PREVIOUS_STAGE)

EMIT_FILES_x86	= emit-early.l emit-x86.l emit-late.l
EMIT_FILES_llvm	= emit-early.l emit-llvm.l emit-late.l

.SUFFIXES:					# disable all built-in rules

all: eval

clean:
	rm -rf $(BUILD)/x86 $(BUILD)/llvm eval $(foreach backend,${BACKENDS},eval-$(backend))

distclean: clean
	rm -rf $(BUILD)

stats: $(foreach backend,${BACKENDS},stats-$(backend))

$(foreach backend,${BACKENDS},stats-$(backend)): stats-%:
	@echo -e '\nBackend $(BLUE)$*$(RESET):\n'
	cat boot.l $(EMIT_FILES_$*)		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l $(EMIT_FILES_$*) eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

###
### eval and bootstrapping
###
eval: $(foreach backend,${BACKENDS},$(BUILD_$(backend))/eval2)
# NOTE ./eval will be the last one in BACKENDS that actually got built, which is llvm as of now
	@for x in $(foreach backend,${BACKENDS},$(BUILD_$(backend))/eval2); do	\
		cp $${x} eval;								\
	done

# eval1 is the first version of us that was built by the previous stage.
# some functionality may be broken in this one.
$(BUILD_x86)/eval1.s: $(BOOT_EVAL_PATH)/eval bootstrapping/*.l eval.l boot.l
	@mkdir --parents $(BUILD_x86)
	$(TIME) $(BOOT_EVAL_PATH)/eval		\
		$(BOOT_EVAL_PATH)/boot.l	\
		bootstrapping/prepare.l		\
		bootstrapping/host-extras.l	\
		bootstrapping/early.l		\
		boot.l				\
		bootstrapping/slave-extras.l	\
		bootstrapping/late.l		\
		$(BOOT_EVAL_PATH)/emit.l	\
		eval.l				\
			>$(BUILD_x86)/eval1.s || { touch --date=2000-01-01 $(BUILD_x86)/eval1.s; exit 42; }

# eval2 is the bootstrapped version of this stage, self-built by this stage (i.e. by eval1).
# eval2 should implement the semantics encoded by the sources of this stage.
$(BUILD_x86)/eval2.s: $(BUILD_x86)/eval1 boot.l $(EMIT_FILES_x86) bootstrapping/*.l eval.l
	$(call compile-x86,$(BUILD_x86)/eval1,eval.l,$(BUILD_x86)/eval2.s)
	@-$(DIFF) $(BUILD_x86)/eval1.s $(BUILD_x86)/eval2.s >$(BUILD_x86)/eval2.s.diff

# TODO change eval1 to llvm in the next stage (grep token: bootstrapping?)
$(BUILD_llvm)/eval2.ll: $(BUILD_x86)/eval1 boot.l $(EMIT_FILES_llvm) bootstrapping/*.l eval.l
	@mkdir --parents $(BUILD_llvm) # delme, too
	$(call compile-llvm,$(BUILD_x86)/eval1,eval.l,$(BUILD_llvm)/eval2.ll)
	@-$(DIFF) $(BUILD_llvm)/eval1.ll $(BUILD_llvm)/eval2.ll >$(BUILD_llvm)/eval2.ll.diff

# eval3 is just a test, it's the result of yet another bootstrap iteration, based off of eval2 this time.
# eval3.s should be the exact same file as the output of the previous iteration, namely eval2.s.
$(BUILD_x86)/eval3.s: $(BUILD_x86)/eval2 boot.l $(EMIT_FILES_x86) bootstrapping/*.l eval.l
	$(call compile-x86,$(BUILD_x86)/eval2,eval.l,$(BUILD_x86)/eval3.s)
	@-$(DIFF) $(BUILD_x86)/eval2.s $(BUILD_x86)/eval3.s >$(BUILD_x86)/eval3.s.diff

$(BUILD_llvm)/eval3.ll: $(BUILD_llvm)/eval2 boot.l $(EMIT_FILES_llvm) bootstrapping/*.l eval.l
	$(call compile-llvm,$(BUILD_llvm)/eval2,eval.l,$(BUILD_llvm)/eval3.ll)
	@-$(DIFF) $(BUILD_llvm)/eval2.ll $(BUILD_llvm)/eval3.ll >$(BUILD_llvm)/eval3.ll.diff

$(BOOT_EVAL_PATH)/eval:
	echo Building $(BUILD)/$(PREVIOUS_STAGE)
	@mkdir --parents $(BUILD)
# after cloning, we must create the local branches ourselves; the issue in detail: https://stackoverflow.com/questions/40310932/git-hub-clone-all-branches-at-once
	@git show-ref --verify --quiet refs/heads/$(PREVIOUS_STAGE) || git branch --quiet --track $(PREVIOUS_STAGE) remotes/origin/$(PREVIOUS_STAGE)
	test -d $(BUILD)/$(PREVIOUS_STAGE) || git worktree add --detach --force $(BUILD)/$(PREVIOUS_STAGE) $(PREVIOUS_STAGE)
	$(MAKE) --jobs=1 --directory=$(BUILD)/$(PREVIOUS_STAGE)

# a "function" to compile a maru .l file with a compiler backend
# TODO backend duplication: they only differ in $(backend). the solution may involve .SECONDEXPANSION: and foreach. see also the other occurrances of 'backend duplication'.
define compile-x86
  $(TIME) $(1)				\
	boot.l				\
	bootstrapping/prepare.l		\
	bootstrapping/early.l		\
	boot.l				\
	bootstrapping/late.l		\
	--define makefile/target-triplet   $(TARGET_x86)	\
	--define makefile/target-word-size 32			\
	$(EMIT_FILES_x86)		\
	$(2)				\
	>$(3) || { touch --date=2000-01-01 $(3); exit 42; }
endef

define compile-llvm
  $(TIME) $(1)				\
	boot.l				\
	bootstrapping/prepare.l		\
	bootstrapping/early.l		\
	boot.l				\
	bootstrapping/late.l		\
	--define makefile/target-triplet   $(TARGET_llvm)		\
	--define makefile/target-word-size $(TARGET_WORD_SIZE_llvm)	\
	$(EMIT_FILES_llvm)		\
	$(2)				\
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
$(BUILD)/peg.l: eval source/parsing/peg.g source/parsing/peg-bootstrap.l source/parsing/parser.l source/parsing/peg-compile.l
	./eval boot.l source/parsing/peg-bootstrap.l >$(BUILD)/peg.l \
		|| { touch --date=2000-01-01 $(BUILD)/peg.l; exit 42; }
#	mv peg.l peg.l.$(shell date '+%Y%m%d.%H%M%S')

source/parsing/peg.l: $(BUILD)/peg.l
	cp $(BUILD)/peg.l source/parsing/peg.l

###
### Pattern rules
###
$(BUILD)/%: $(BUILD)/%.s
	$(CC) -m32 -o $@ $<
	@-$(STRIP) $@ -o $@.stripped

$(BUILD)/%: $(BUILD)/%.ll
	$(LLC) -filetype=obj -o $@.o $@.ll
	$(CLANG) --target=$(TARGET_llvm) -o $@ $@.o
# the rest is just informational
	@-$(STRIP) $@ -o $@.stripped
	@-$(LLC) -filetype=asm -o $@.opt.s $@.ll
#	$(CLANG) --target=$(TARGET_llvm) -S -o $@.clang.s $<

###
### Tests
###
TEST_EVAL	= $(BUILD_llvm)/eval2

test-bootstrap: $(foreach backend,${BACKENDS},test-bootstrap-$(backend))

# TODO backend duplication
test-bootstrap-x86: $(BUILD_x86)/eval3
	$(DIFF) $(BUILD_x86)/eval2.$(ASM_FILE_EXT_x86) $(BUILD_x86)/eval3.$(ASM_FILE_EXT_x86)
	$(DIFF) $(BUILD_x86)/eval2.stripped $(BUILD_x86)/eval3.stripped
	echo "(and (print () \"i'm alive!\") "") (exit 0)" | $(BUILD_x86)/eval2 boot.l -

test-bootstrap-llvm: $(BUILD_llvm)/eval3
	$(DIFF) $(BUILD_llvm)/eval2.$(ASM_FILE_EXT_llvm) $(BUILD_llvm)/eval3.$(ASM_FILE_EXT_llvm)
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

$(BUILD_llvm)/compiler-test.$(ASM_FILE_EXT_llvm): tests/compiler-tests.l $(EMIT_FILES_llvm)
	@mkdir --parents $(BUILD_llvm)
	$(call ensure-built,$(TEST_EVAL))
	$(call compile-llvm,$(TEST_EVAL),tests/compiler-tests.l,$(BUILD_llvm)/compiler-test.$(ASM_FILE_EXT_llvm))

test-interpreter: $(TEST_EVAL) boot.l tests/interpreter-tests.l
	$(TEST_EVAL) boot.l tests/interpreter-tests.l
