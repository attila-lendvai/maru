PREVIOUS_STAGE = maru.0.c99
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
	time ./eval boot.l emit.l eval.l >$(BUILD)/eval2.s 
	diff -u $(BUILD)/eval.s $(BUILD)/eval2.s

$(BUILD)/eval.s: $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l $(BOOT_EVAL_PATH)/emit.l eval.l
	time $(BOOT_EVAL_PATH)/eval $(BOOT_EVAL_PATH)/boot.l $(BOOT_EVAL_PATH)/emit.l eval.l >$(BUILD)/eval.s || touch -t 200011220102 $(BUILD)/eval.s

$(BOOT_EVAL_PATH)/eval:
	echo Building $(BUILD)/$(PREVIOUS_STAGE)
	mkdir -p $(BUILD)
# after cloning, we must create the local branches ourselves; the issue in detail: https://stackoverflow.com/questions/40310932/git-hub-clone-all-branches-at-once
	@git show-ref --verify --quiet refs/heads/$(PREVIOUS_STAGE) || git branch --quiet --track $(PREVIOUS_STAGE) remotes/origin/$(PREVIOUS_STAGE)
	test -d $(BUILD)/$(PREVIOUS_STAGE) || git worktree add --detach --force $(BUILD)/$(PREVIOUS_STAGE) $(PREVIOUS_STAGE)
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
