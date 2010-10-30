CFLAGS = -Wall -g # -Os

all : main eval

% : %.c gc.c gc.h buffer.c chartab.h

opt : .force
	$(MAKE) CFLAGS="$(CFLAGS) -O3 -fomit-frame-pointer -DNDEBUG"

debuggc : .force
	$(MAKE) CFLAGS="$(CFLAGS) -DDEBUGGC=1"

clean : .force
	rm -f *~ *.o main eval

.force :
