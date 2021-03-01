BUILD = build

NOW = $(shell date '+%Y%m%d.%H%M')
SYS = $(shell uname)

OFLAGS = -O3 -fomit-frame-pointer -DNDEBUG
CFLAGS = -std=c99 -Wall -Wno-comment -g $(OFLAGS)
CC32 = $(CC) -m32

ifeq ($(findstring MINGW32,$(SYS)),MINGW32)
LIBS = -lm -lffi libw32dl.a
TIME =
else
LIBS = -lm -lffi -ldl
TIME = time
endif

ifeq ($(findstring Darwin,$(SYS)),Darwin)
SO = dylib
SOCFLAGS = -dynamiclib -Wl,-headerpad_max_install_names,-undefined,dynamic_lookup,-flat_namespace
else
SO = so
SOCFLAGS = -shared -msse -msse2
endif

.SUFFIXES :

all : eval

eval : $(BUILD)/eval1
	cp $(BUILD)/eval1 eval

run : eval
	rlwrap ./eval boot.l -

test-bootstrap : $(BUILD)/eval3 .force
	diff $(BUILD)/eval2.s $(BUILD)/eval3.s

$(BUILD)/eval1 : eval.c gc.c gc.h buffer.c chartab.h wcs.c osdefs.k
	mkdir -p $(BUILD)
	$(CC) -g $(CFLAGS) -o $(BUILD)/eval1 eval.c $(LIBS)
	@-test ! -x /usr/sbin/execstack || /usr/sbin/execstack -s $@

osdefs.k : $(BUILD)/mkosdefs
	$(BUILD)/mkosdefs > $@

$(BUILD)/mkosdefs : mkosdefs.c
	mkdir -p $(BUILD)
	$(CC) -o $@ $<

$(BUILD)/eval2 : $(BUILD)/eval1 emit.l eval.l osdefs.k
	$(TIME) $(BUILD)/eval1 -O emit.l eval.l > $(BUILD)/eval2.s && $(CC32) -c -o $(BUILD)/eval2.o $(BUILD)/eval2.s && size $(BUILD)/eval2.o && $(CC32) -o $(BUILD)/eval2 $(BUILD)/eval2.o

time : .force
	$(TIME) $(BUILD)/eval1 -O emit.l eval.l eval.l eval.l eval.l eval.l > /dev/null

$(BUILD)/eval3 : $(BUILD)/eval2
	$(TIME) $(BUILD)/eval2 -O boot.l emit.l eval.l > $(BUILD)/eval3.s

time2 : .force
	$(TIME) $(BUILD)/eval2 boot.l emit.l eval.l eval.l eval.l eval.l eval.l > /dev/null

stats : .force
	cat boot.l emit.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit.l eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean : .force
	rm --force $(BUILD)/eval* $(BUILD)/mkosdefs osdefs.k eval
	rm --dir --force $(BUILD) || true

.force :
