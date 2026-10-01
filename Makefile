# gsw Makefile
# Copyright (c) 2026 Donghyuk Lee

.PHONY: all help install uninstall test test-quick lint ci-test release-check

VERSION := $(shell grep 'readonly VERSION=' bin/gsw | cut -d'"' -f2)
PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

all: help

help:
	@echo "gsw v$(VERSION) - Git Smart Switch"
	@echo
	@echo "Targets:"
	@echo "  install        Install gsw to $(BINDIR) (override with PREFIX=...)"
	@echo "  uninstall      Remove gsw from $(BINDIR)"
	@echo "  test           Run the full test suite"
	@echo "  test-quick     Smoke-test --version and --help"
	@echo "  lint           Run ShellCheck on all scripts"
	@echo "  ci-test        lint + test (what CI runs)"
	@echo "  release-check  Verify the tree is ready to tag v$(VERSION)"

install:
	@mkdir -p $(BINDIR)
	@install -m 0755 bin/gsw $(BINDIR)/gsw
	@echo "✓ gsw v$(VERSION) installed to $(BINDIR)/gsw"

uninstall:
	@rm -f $(BINDIR)/gsw
	@echo "✓ gsw removed from $(BINDIR)"

test:
	@./tests/test_gsw.sh

test-quick:
	@./bin/gsw --version >/dev/null && echo "✓ --version works"
	@./bin/gsw --help >/dev/null && echo "✓ --help works"

lint:
	@command -v shellcheck >/dev/null 2>&1 || (echo "ShellCheck not installed" && exit 1)
	@shellcheck bin/gsw install.sh uninstall.sh tests/test_gsw.sh
	@echo "✓ ShellCheck passed"

ci-test: lint test

release-check:
	@test -z "$$(git status --porcelain)" || (echo "✗ Working tree not clean" && exit 1)
	@grep -q "## \[$(VERSION)\]" CHANGELOG.md || (echo "✗ CHANGELOG.md has no entry for $(VERSION)" && exit 1)
	@echo "✓ Ready to tag v$(VERSION)"
