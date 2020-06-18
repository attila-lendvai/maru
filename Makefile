PREVIOUS_STAGE = maru.2
BUILD = build
BOOT_EVAL_PATH = $(BUILD)/$(PREVIOUS_STAGE)

CFLAGS += -m32
DIFF = diff --unified --ignore-all-space

# disable all built-in rules
.SUFFIXES:

all: eval

eval: $(BUILD)/eval2
	cp $(BUILD)/eval2 ./eval

test-bootstrap: $(BUILD)/eval1 $(BUILD)/eval2 $(BUILD)/eval3
	$(DIFF) $(BUILD)/eval2.s $(BUILD)/eval3.s
	$(DIFF) $(BUILD)/eval2.stripped $(BUILD)/eval3.stripped

$(BUILD)/eval1.s: $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l $(BOOT_EVAL_PATH)/emit.l bootstrapping/*.l eval.l boot.l
	time $(BOOT_EVAL_PATH)/eval		\
		$(BOOT_EVAL_PATH)/boot.l	\
		bootstrapping/prepare.l		\
		bootstrapping/host-extras.l	\
		bootstrapping/early.l		\
		boot.l				\
		bootstrapping/slave-extras.l	\
		bootstrapping/late.l		\
		$(BOOT_EVAL_PATH)/emit.l	\
		eval.l				\
			>$(BUILD)/eval1.s || { touch --date=2000-01-01 $(BUILD)/eval1.s; exit 42; }

$(BUILD)/eval2.s: boot.l emit.l bootstrapping/*.l eval.l
	$(MAKE) $(BUILD)/eval1
	$(call bootstrap,$(BUILD)/eval1,$(BUILD)/eval2.s)
	$(DIFF) $(BUILD)/eval1.s $(BUILD)/eval2.s >$(BUILD)/eval2.diff || true

$(BUILD)/eval3.s: boot.l emit.l bootstrapping/*.l eval.l
	$(MAKE) $(BUILD)/eval2
	$(call bootstrap,$(BUILD)/eval2,$(BUILD)/eval3.s)
	$(DIFF) $(BUILD)/eval2.s $(BUILD)/eval3.s >$(BUILD)/eval3.diff || true

$(BUILD)/%: $(BUILD)/%.s
	$(CC) $(CFLAGS) -o $@ $<
	strip $@ -o $@.stripped

$(BOOT_EVAL_PATH)/eval:
	echo Building $(BUILD)/$(PREVIOUS_STAGE)
	mkdir -p $(BUILD)
# we need to create the local branches because git clone doesn't do that for us,
# and the makefile cannot locally git checkout the branches into build/.
# i know, this solution is nonsense! patches or suggestions are very welcome for a better alternative.
# the issue: https://stackoverflow.com/questions/40310932/git-hub-clone-all-branches-at-once
	@git show-ref --verify --quiet refs/heads/maru.0.c99 || git branch --quiet --track maru.0.c99 remotes/origin/maru.0.c99
	@git show-ref --verify --quiet refs/heads/maru.1     || git branch --quiet --track maru.1     remotes/origin/maru.1
	@git show-ref --verify --quiet refs/heads/maru.2     || git branch --quiet --track maru.2     remotes/origin/maru.2
	@git show-ref --verify --quiet refs/heads/maru.3     || git branch --quiet --track maru.3     remotes/origin/maru.3
	@git clone --local . $(BUILD)/$(PREVIOUS_STAGE) && \
		cd "$(BUILD)/$(PREVIOUS_STAGE)" && \
		git branch --quiet --track maru.0.c99 remotes/origin/maru.0.c99 && \
		git branch --quiet --track maru.1     remotes/origin/maru.1 && \
		git branch --quiet --track maru.2     remotes/origin/maru.2 && \
		git checkout --quiet $(PREVIOUS_STAGE)
	$(MAKE) -C $(BUILD)/$(PREVIOUS_STAGE)

stats:
	cat boot.l emit.l		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit.l eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean:
	rm -f $(BUILD)/eval*

distclean:
	rm -rf $(BUILD) eval

.force:

#
# functions
#
define bootstrap
 time $(1)				\
	boot.l				\
	bootstrapping/prepare.l		\
	bootstrapping/early.l		\
	boot.l				\
	bootstrapping/late.l		\
	emit.l	\
	eval.l				\
		>$(2) || { touch --date=2000-01-01 $(2); exit 42; }
endef
