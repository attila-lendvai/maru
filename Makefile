PREVIOUS_STAGE = maru.2
BUILD = build
BOOT_EVAL_PATH = $(BUILD)/$(PREVIOUS_STAGE)

CFLAGS += -m32

all: eval

eval: $(BUILD)/eval.s
	$(CC) $(CFLAGS) -c -o $(BUILD)/eval.o $(BUILD)/eval.s
	size $(BUILD)/eval.o
	$(CC) $(CFLAGS) -o ./eval $(BUILD)/eval.o

test-bootstrap: eval .force
	$(call bootstrap,./eval ,$(BUILD)/eval2.s)
	diff --unified --ignore-all-space $(BUILD)/eval.s $(BUILD)/eval2.s
# we don't need to go an extra round in this stage, our output is stable
#	$(CC) $(CFLAGS) -o $(BUILD)/eval2 $(BUILD)/eval2.s
#	$(call bootstrap,$(BUILD)/eval2 ,$(BUILD)/eval3.s)
#	diff --unified --ignore-all-space $(BUILD)/eval2.s $(BUILD)/eval3.s

$(BUILD)/eval.s: $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l $(BOOT_EVAL_PATH)/emit.l prepare-for-bootstrap.l boot.l eval.l
	$(call bootstrap,$(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/,$(BUILD)/eval.s)

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
	rm -f $(BUILD)/eval*.s $(BUILD)/eval.o $(BUILD)/eval

distclean:
	rm -rf $(BUILD) eval

.force:

#
# functions
#
define bootstrap
  time $(1)boot.l prepare-for-bootstrap.l boot.l -c switch-to-host-module emit.l eval.l >$(2) \
    || { touch -t 200011220102 $(2); exit 42; }
endef
