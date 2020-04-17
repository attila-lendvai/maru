PREVIOUS_STAGE=stage-000-c99
BOOTEVAL = build/$(PREVIOUS_STAGE)/eval
BUILD=build/

all: eval2

previous-stage: .force
	echo Building $(PREVIOUS_STAGE)
	rm -rf ./$(BUILD)/$(PREVIOUS_STAGE)
	mkdir -p $(BUILD)
	git clone --branch $(PREVIOUS_STAGE) . ./$(BUILD)/$(PREVIOUS_STAGE)
	$(MAKE) -C ./$(BUILD)/$(PREVIOUS_STAGE)

eval: *.l
	time $(BOOTEVAL) boot.l emit.l eval.l >$(BUILD)/eval.s
	gcc -g -m32 -c -o $(BUILD)/eval.o $(BUILD)/eval.s
	size $(BUILD)/eval.o
	gcc -g -m32 -o eval $(BUILD)/eval.o

eval2: eval
	time ./eval boot.l emit.l eval.l >$(BUILD)/eval2.s
	diff $(BUILD)/eval.s $(BUILD)/eval2.s

stats : .force
	cat boot.l emit.l 	 | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l        	 | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit.l eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean : .force
	rm -f $(BUILD)/eval*.s $(BUILD)/eval.o eval

.force :
