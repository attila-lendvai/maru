# -*- makefile -*-
#
# The C implementation of the maru.10 VM.
#
# This is the bottom of the bootstrap chain: `make` produces an `eval`
# binary that animates maru.10's lisp sources (its type system, its
# compiler, its platform layer). The lisp is deliberately not copied
# into this branch: point the build at a maru.10 checkout instead. See
# README.md and doc/agent/maru-10-c99.txt.

CC	?= cc
BUILD	?= build

OFLAGS	?= -O3 -fomit-frame-pointer -DNDEBUG
CFLAGS	?= -std=c99 -Wall -Wno-comment -g $(OFLAGS)
LIBS	?= -lm -lffi -ldl

# a maru.10 checkout, used by the tests
MARU10	?= ../maru.10

.SUFFIXES :

all : eval

eval : $(BUILD)/eval1
	cp $< $@

$(BUILD)/eval1 : eval.c gc.c gc.h buffer.c chartab.h wcs.c
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -o $@ eval.c $(LIBS)
	@-test ! -x /usr/sbin/execstack || /usr/sbin/execstack -s $@

run : eval
	rlwrap --no-warning ./eval $(MARU10)/boot.l -

# The semantic gate while porting: run maru.10's evaluator tests with
# this eval. The cwd matters, maru.10's boot.l and its requires are
# resolved relative to it.
test-evaluator : eval
	cd $(MARU10) && $(abspath $<) boot.l tests/evaluator-tests.l

test : test-evaluator

clean :
	rm --force $(BUILD)/eval1 eval
	rm --dir --force $(BUILD) || true
