# Makefile — Build, test, and check the Compass toolchain
#
# DEPS selects the dependency manager: ql (Quicklisp, default) or ocicl.
# PREFIX and DESTDIR place `make install` (default ~/.local/bin/compass).

DEPS ?= ql
SBCL ?= sbcl
PREFIX ?= $(HOME)/.local
LISP = DEPS=$(DEPS) $(SBCL) --noinform --non-interactive --no-userinit --load build.lisp

.PHONY: build test check install uninstall clean

build:
	$(LISP) --eval '(compass-build:build)'

test:
	$(LISP) --eval '(compass-build:test)'

check: build
	./bin/compass check

install: build
	install -d "$(DESTDIR)$(PREFIX)/bin"
	install -m 755 bin/compass "$(DESTDIR)$(PREFIX)/bin/compass"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/compass"

clean:
	rm -rf bin
