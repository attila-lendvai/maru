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

# NOTE no -DNDEBUG: the typechecking accessors are the main safety net
# while the object layout is being ported.
OFLAGS	?= -O2
# -Wdangling-pointer misfires on the GC_PROTECT/GC_UNPROTECT pattern
CFLAGS	?= -std=c99 -Wall -Wno-comment -Wno-dangling-pointer -g $(OFLAGS)

# a maru.10 checkout, used by the tests
MARU10	?= ../maru.10

.SUFFIXES :

all : eval

eval : $(BUILD)/eval1
	cp $< $@

$(BUILD)/eval1 : eval.c gc.c gc.h buffer.c chartab.h
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

# Reader gate: every lisp file the bootstrap can see must be readable
# (and printable: -r reads and echoes without evaluating).
# gen-x86-instructions.l is a stale leftover in maru.10 whose embedded
# grammar is not lisp; upstream's reader rejects it too.
test-reader : eval
	cd $(MARU10) && for f in `git ls-files '*.l'`; do \
	  case $$f in source/assembler/gen-x86-instructions.l) continue;; esac; \
	  $(abspath $<) -r $$f >/dev/null || exit 1; \
	done
	@echo "reader: ok"

clean :
	rm --force $(BUILD)/eval1 eval
	rm --dir --force $(BUILD) || true
