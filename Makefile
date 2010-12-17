CFLAGS = -Wall -g # -Os

all : eval

% : %.c gc.c gc.h buffer.c chartab.h

opt : .force
	$(MAKE) CFLAGS="$(CFLAGS) -O3 -fomit-frame-pointer -DNDEBUG"

debuggc : .force
	$(MAKE) CFLAGS="$(CFLAGS) -DDEBUGGC=1"

test : eval .force
	time ./emit.l eval.k > test.s && cc -c -o test.o test.s && size test.o && gcc -o test test.o && ./test

test-emit : eval .force
	./emit.l test-emit.l | tee test.s && cc -c -o test.o test.s && size test.o && cc -o test test.o && ./test

clean : .force
	rm -f *~ *.o main eval
	rm -rf *.dSYM

.force :
