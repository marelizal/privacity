PREFIX    ?= /usr/local
BINDIR     = $(PREFIX)/bin
LIBDIR     = $(PREFIX)/lib/privacity
COMPDIR    = $(PREFIX)/share/bash-completion/completions
ZSH_COMPDIR = $(PREFIX)/share/zsh/site-functions
SCRIPT     = privacity
LIBS       = lib/common.sh lib/net.sh lib/speed.sh lib/csv.sh lib/ovpn.sh
BASH_COMP  = completions/privacity.bash
ZSH_COMP   = completions/privacity.zsh

.PHONY: help install uninstall completions uninstall-completions

help:
	@echo "Targets:"
	@echo "  make install             Install privacity and lib modules"
	@echo "  make uninstall           Remove privacity and lib modules"
	@echo "  make completions         Install bash and zsh completions"
	@echo "  make uninstall-completions  Remove completion files"

install: $(SCRIPT) $(LIBS)
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 "$(SCRIPT)" "$(DESTDIR)$(BINDIR)/$(SCRIPT)"
	install -d "$(DESTDIR)$(LIBDIR)"
	install -m 644 $(LIBS) "$(DESTDIR)$(LIBDIR)/"
	@echo "Installed $(SCRIPT) to $(DESTDIR)$(BINDIR)/$(SCRIPT)"
	@echo "Installed lib modules to $(DESTDIR)$(LIBDIR)/"

uninstall:
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
