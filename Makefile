CFLAGS = -Wall -std=c99 -D_ISOC99_SOURCE

all: eval

eval: eval.c
	$(CC) $(CFLAGS) -O3 -fomit-frame-pointer -DNDEBUG -o eval eval.c

eval-debug: eval.c
	$(CC) $(CFLAGS) -g -o eval eval.c

eval-debuggc: .force
	$(MAKE) CFLAGS="$(CFLAGS) -DDEBUGGC=1" eval-debug

clean:
	rm -f *~ *.o eval

.force:
