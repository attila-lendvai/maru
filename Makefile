PREVIOUS_STAGE = maru.0.c99
BUILD = build
BOOTEVAL = $(BUILD)/$(PREVIOUS_STAGE)/eval
EVAL = $(BUILD)/eval

all: eval

eval: $(BUILD)/eval.s *.l
	gcc -g -m32 -c -o $(BUILD)/eval.o $(BUILD)/eval.s
	size $(BUILD)/eval.o
	gcc -g -m32 -o $(BUILD)/eval $(BUILD)/eval.o

bootstrap: $(BUILD)/eval2.s
	diff $(BUILD)/eval.s $(BUILD)/eval2.s

$(BUILD)/eval.s: $(BOOTEVAL) *.l
	time $(BOOTEVAL) boot.l emit-ia32.l eval.l >$(BUILD)/eval.s

$(BUILD)/eval2.s: eval *.l
	time $(EVAL) boot.l emit-ia32.l eval.l >$(BUILD)/eval2.s

$(BOOTEVAL):
	echo Building $(BOOTEVAL)
	rm -rf $(BUILD)/$(PREVIOUS_STAGE)
	mkdir -p $(BUILD)
	git clone --branch $(PREVIOUS_STAGE) . $(BUILD)/$(PREVIOUS_STAGE)
	$(MAKE) -C $(BUILD)/$(PREVIOUS_STAGE)

stats:
	cat boot.l emit-ia32.l		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit-ia32.l eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean:
	rm -f $(BUILD)/eval*.s $(BUILD)/eval.o $(BUILD)/eval

distclean:
	rm -rf $(BUILD)
