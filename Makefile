# Makefile — Build, test, and check the Compass toolchain
#
# DEPS selects the dependency manager: ql (Quicklisp, default) or ocicl.

DEPS ?= ql
SBCL ?= sbcl
LISP = DEPS=$(DEPS) $(SBCL) --noinform --non-interactive --no-userinit --load build.lisp

.PHONY: build test check clean

build:
	$(LISP) --eval '(compass-build:build)'

test:
	$(LISP) --eval '(compass-build:test)'

check: build
	./bin/compass check

clean:
	rm -rf bin
