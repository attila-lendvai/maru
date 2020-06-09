PREVIOUS_STAGE = maru.1
BUILD = build
BOOT_EVAL_PATH = $(BUILD)/$(PREVIOUS_STAGE)

all: eval

eval: $(BUILD)/eval.s
	$(CC) -g -m32 -c -o $(BUILD)/eval.o $(BUILD)/eval.s
	size $(BUILD)/eval.o
	$(CC) -g -m32 -o ./eval $(BUILD)/eval.o

$(BUILD)/eval.s: $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l $(BOOT_EVAL_PATH)/emit.l eval.l
	time $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l $(BOOT_EVAL_PATH)/emit.l eval.l >$(BUILD)/eval.s || touch -t 200011220102 $(BUILD)/eval.s

$(BOOT_EVAL_PATH)/eval:
	echo Building $(BUILD)/$(PREVIOUS_STAGE)
	mkdir -p $(BUILD)
# we need to create the local branches because git clone doesn't do that for us...
	@git show-ref --verify --quiet refs/heads/maru.0.c99 || git branch --quiet --track maru.0.c99 remotes/origin/maru.0.c99
	@git show-ref --verify --quiet refs/heads/maru.1     || git branch --quiet --track maru.1     remotes/origin/maru.1
	@git show-ref --verify --quiet refs/heads/maru.2     || git branch --quiet --track maru.2     remotes/origin/maru.2
	@git clone --local . $(BUILD)/$(PREVIOUS_STAGE) && \
		cd "$(BUILD)/$(PREVIOUS_STAGE)" && \
		git branch --quiet --track maru.0.c99 remotes/origin/maru.0.c99 && \
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
