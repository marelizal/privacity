PREFIX    ?= /usr/local
BINDIR     = $(PREFIX)/bin
LIBDIR     = $(PREFIX)/lib/privacity
COMPDIR    = $(PREFIX)/share/bash-completion/completions
ZSH_COMPDIR = $(PREFIX)/share/zsh/site-functions
MANDIR     = $(PREFIX)/share/man/man1
SCRIPT     = privacity
LIBS       = lib/common.sh lib/net.sh lib/speed.sh lib/csv.sh lib/ovpn.sh
BASH_COMP  = completions/privacity.bash
ZSH_COMP   = completions/privacity.zsh
MAN_PAGE   = completions/privacity.1

.PHONY: help install uninstall completions uninstall-completions man uninstall-man hooks

help:
	@echo "Targets:"
	@echo "  make install             Install privacity and lib modules"
	@echo "  make uninstall           Remove privacity and lib modules"
	@echo "  make completions         Install bash and zsh completions"
	@echo "  make uninstall-completions  Remove completion files"
	@echo "  make man                 Install man page"
	@echo "  make uninstall-man       Remove man page"
	@echo "  make hooks               Enable git pre-commit hook (shellcheck + tests)"

install: $(SCRIPT) $(LIBS) man
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 "$(SCRIPT)" "$(DESTDIR)$(BINDIR)/$(SCRIPT)"
	install -d "$(DESTDIR)$(LIBDIR)"
	install -m 644 $(LIBS) "$(DESTDIR)$(LIBDIR)/"
	@echo "Installed $(SCRIPT) to $(DESTDIR)$(BINDIR)/$(SCRIPT)"
	@echo "Installed lib modules to $(DESTDIR)$(LIBDIR)/"

uninstall: uninstall-man
	rm -f "$(DESTDIR)$(BINDIR)/$(SCRIPT)"
	rm -rf "$(DESTDIR)$(LIBDIR)"
	@echo "Removed $(SCRIPT) and lib modules"

completions: $(BASH_COMP) $(ZSH_COMP)
	install -d "$(DESTDIR)$(COMPDIR)"
	install -m 644 "$(BASH_COMP)" "$(DESTDIR)$(COMPDIR)/$(SCRIPT)"
	install -d "$(DESTDIR)$(ZSH_COMPDIR)"
	install -m 644 "$(ZSH_COMP)" "$(DESTDIR)$(ZSH_COMPDIR)/_$(SCRIPT)"
	@echo "Completions installed"

uninstall-completions:
	rm -f "$(DESTDIR)$(COMPDIR)/$(SCRIPT)"
	rm -f "$(DESTDIR)$(ZSH_COMPDIR)/_$(SCRIPT)"
	@echo "Completions removed"

man: $(MAN_PAGE)
	install -d "$(DESTDIR)$(MANDIR)"
	install -m 644 "$(MAN_PAGE)" "$(DESTDIR)$(MANDIR)/$(SCRIPT).1"
	@echo "Man page installed to $(DESTDIR)$(MANDIR)/$(SCRIPT).1"

uninstall-man:
	rm -f "$(DESTDIR)$(MANDIR)/$(SCRIPT).1"
	@echo "Man page removed"

hooks:
	git config core.hooksPath .githooks
	@echo "Git hooks enabled (pre-commit: shellcheck + bats)"
