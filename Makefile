CFLAGS = -Wall -g # -Os
CC32 = $(CC) -m32

.SUFFIXES :

all : eval

run : eval
	rlwrap ./eval

eval : eval.c gc.c gc.h buffer.c chartab.h
	$(CC) -g $(CFLAGS) -o eval eval.c

opt : .force
	$(MAKE) CFLAGS="$(CFLAGS) -O3 -fomit-frame-pointer -DNDEBUG"

debuggc : .force
	$(MAKE) CFLAGS="$(CFLAGS) -DDEBUGGC=1"

profile : .force
	$(MAKE) clean eval CFLAGS="$(CFLAGS) -O3 -fno-inline-functions -DNDEBUG"
	shark -q -1 -i ./eval emit.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l > test.s

test : emit.l eval.l eval
	time ./emit.l eval.l > test.s && $(CC32) -c -o test.o test.s && size test.o && $(CC32) -o test test.o

time : .force
	time ./eval emit.l eval.l eval.l eval.l eval.l eval.l > /dev/null

test2 : test .force
	time ./test boot.l emit.l eval.l > test2.s
	diff test.s test2.s

time2 : .force
	time ./test boot.l emit.l eval.l eval.l eval.l eval.l eval.l > /dev/null

test-eval : test .force
	time ./test test-eval.l

test-boot : test .force
	time ./test boot-emit.l

test-emit : eval .force
	./emit.l test-emit.l | tee test.s && $(CC32) -c -o test.o test.s && size test.o && $(CC32) -o test test.o && ./test

peg.l : eval parser.l peg-compiler.l peg-boot.l peg.g
	-rm peg.l.new
	./eval parser.l peg-compiler.l peg-boot.l | tee peg.l.new
	-mv peg.l peg.l.bak
	mv peg.l.new peg.l

tee : tee.c
	$(CC) -o $@ $<

test-peg : eval peg.l .force
	./eval parser.l peg.l test-peg.l

stats : .force
	cat boot.l emit.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit.l eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean : .force
	rm -f *~ *.o main eval test *.s
	rm -rf *.dSYM *.mshark

#----------------------------------------------------------------

FILES = Makefile \
	buffer.c chartab.h eval.c gc.c gc.h \
	boot.l emit.l eval.l test-emit.l \
	parser.l peg-compiler.l peg-boot.l peg.l test-peg.l \
	peg.g

NOW = $(shell date '+%Y%m%d.%H%M')

DIST = maru-$(NOW)
DEST = ckpt/$(DIST)

dist : .force
	mkdir -p $(DEST)
	cp -p $(FILES) $(DEST)/.
	$(SHELL) -ec "cd ckpt; tar cvfz $(DIST).tar.gz $(DIST)"

.force :
