PROG ?= mount
PREFIX ?= /usr
DESTDIR ?=
LIBDIR ?= $(PREFIX)/lib
SYSTEM_EXTENSION_DIR ?= $(LIBDIR)/password-store/extensions
MANDIR ?= $(PREFIX)/share/man

all:
	@echo "pass-$(PROG) is a shell script and does not need compilation, it can be simply executed."
	@echo ""
	@echo "To install it try \"make install\" instead."
	@echo
	@echo "To run pass $(PROG) one needs to have some tools installed on the system:"
	@echo "     password store"

install:
	@install -v -d "$(DESTDIR)$(MANDIR)/man1" && install -m 0644 -v pass-$(PROG).1 "$(DESTDIR)$(MANDIR)/man1/pass-$(PROG).1"
	@install -v -d "$(DESTDIR)$(SYSTEM_EXTENSION_DIR)/"
	@install -v -m0755 *.bash "$(DESTDIR)$(SYSTEM_EXTENSION_DIR)"
	@echo
	@echo "pass-$(PROG) is installed succesfully"
	@echo

uninstall:
	@rm -vrf \
		"$(DESTDIR)$(SYSTEM_EXTENSION_DIR)/$(PROG).bash" \
		"$(DESTDIR)$(MANDIR)/man1/pass-$(PROG).1"

lint:
	shellcheck -s bash *.bash

doc: pass-$(PROG).1

review-markdown: SHELL := /bin/bash
review-markdown: grip_PID := $(shell coproc grip { grip; } 2>&1 && echo $$grip_PID)
review-markdown: CHANGELOG.md README.md
	@sleep 1
	@xdg-open http://localhost:6419/CHANGELOG.md
	@xdg-open http://localhost:6419/README.md
	@read -p "Press <enter> when finished review"
	@pkill -TERM -P $(grip_PID)

pass-$(PROG).1: pass-$(PROG).1.rst
	@echo "Building pass-$(PROG) documentation"
	@rst2man < pass-$(PROG).1.rst > pass-$(PROG).1

.PHONY: install uninstall lint
