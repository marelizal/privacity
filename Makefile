PREFIX    ?= /usr/local
BINDIR     = $(PREFIX)/bin
COMPDIR    = $(PREFIX)/share/bash-completion/completions
ZSH_COMPDIR = $(PREFIX)/share/zsh/site-functions
SCRIPT     = privacity
BASH_COMP  = completions/privacity.bash
ZSH_COMP   = completions/privacity.zsh

.PHONY: help install uninstall completions uninstall-completions

help:
	@echo "Targets:"
	@echo "  make install             Install privacity to $(BINDIR)"
	@echo "  make uninstall           Remove privacity from $(BINDIR)"
	@echo "  make completions         Install bash and zsh completions"
	@echo "  make uninstall-completions  Remove completion files"

install: $(SCRIPT)
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 "$(SCRIPT)" "$(DESTDIR)$(BINDIR)/$(SCRIPT)"
	@echo "Installed $(SCRIPT) to $(DESTDIR)$(BINDIR)/$(SCRIPT)"

uninstall:
	rm -f "$(DESTDIR)$(BINDIR)/$(SCRIPT)"
	@echo "Removed $(DESTDIR)$(BINDIR)/$(SCRIPT)"

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
