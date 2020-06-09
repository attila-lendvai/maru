PREVIOUS_STAGE = maru.1
BUILD = build
BOOT_EVAL_PATH = $(BUILD)/$(PREVIOUS_STAGE)

all: eval

eval: $(BUILD)/eval.s
	$(CC) -g -m32 -c -o $(BUILD)/eval.o $(BUILD)/eval.s
	size $(BUILD)/eval.o
	$(CC) -g -m32 -o ./eval $(BUILD)/eval.o

# run the compiler once again, but this time using the bootstrapped eval executable
# (as opposed to eval compiled from eval.c), and see if there's any difference in their outputs.
test-bootstrap: eval .force
	time ./eval boot.l prepare-for-bootstrap.l boot.l -c switch-to-host-module emit-ia32.l eval.l >$(BUILD)/eval2.s 
	diff -u $(BUILD)/eval.s $(BUILD)/eval2.s

$(BUILD)/eval.s: $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l $(BOOT_EVAL_PATH)/emit-ia32.l prepare-for-bootstrap.l boot.l eval.l
	time $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l prepare-for-bootstrap.l boot.l -c switch-to-host-module $(BOOT_EVAL_PATH)/emit-ia32.l eval.l >$(BUILD)/eval.s

$(BOOT_EVAL_PATH)/eval:
	echo Building $(BUILD)/$(PREVIOUS_STAGE)
	mkdir -p $(BUILD)
# we need to create local the branches because git clone doesn't do that for us...
	@git show-ref --verify --quiet refs/heads/maru.0.c99 || git branch --quiet --track maru.0.c99 remotes/origin/maru.0.c99
	@git show-ref --verify --quiet refs/heads/maru.1     || git branch --quiet --track maru.1     remotes/origin/maru.1
	@git show-ref --verify --quiet refs/heads/maru.2     || git branch --quiet --track maru.2     remotes/origin/maru.2
	@git clone --local . $(BUILD)/$(PREVIOUS_STAGE) && \
		cd "$(BUILD)/$(PREVIOUS_STAGE)" && \
		git branch --quiet --track maru.0.c99 remotes/origin/maru.0.c99 && \
		git branch --quiet --track maru.1     remotes/origin/maru.1 && \
		git checkout --quiet $(PREVIOUS_STAGE)
	$(MAKE) -C $(BUILD)/$(PREVIOUS_STAGE)

stats:
	cat boot.l emit-ia32.l		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit-ia32.l eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean:
	rm -f $(BUILD)/eval*.s $(BUILD)/eval.o $(BUILD)/eval

distclean:
	rm -rf $(BUILD) eval

.force:
