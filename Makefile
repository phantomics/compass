# Makefile — Build, test, and check the Compass toolchain
#
# DEPS selects the dependency manager: ql (Quicklisp, default) or ocicl.
# With ocicl, `make deps` installs the versions pinned in ocicl.csv.
# PREFIX and DESTDIR place `make install` (default ~/.local/bin/compass).
# `make hooks` installs scripts/pre-commit as this clone's pre-commit hook.

DEPS ?= ql
SBCL ?= sbcl
PREFIX ?= $(HOME)/.local
LISP = DEPS=$(DEPS) $(SBCL) --noinform --non-interactive --no-userinit --load build.lisp

.PHONY: deps build test check install uninstall hooks clean

deps:
ifeq ($(DEPS),ocicl)
	ocicl install
else
	@echo "Quicklisp loads dependencies as it builds; nothing to install."
endif

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

hooks:
	install -m 755 scripts/pre-commit "$$(git rev-parse --git-path hooks)/pre-commit"

clean:
	rm -rf bin
