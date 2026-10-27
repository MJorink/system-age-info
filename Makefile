PREFIX ?= /usr/local
CFLAGS ?= -Os
LDFLAGS ?= -s

system-age-info: system-age-info.c

install: system-age-info
	install -Dm755 system-age-info $(DESTDIR)$(PREFIX)/bin/system-age-info

clean:
	rm -f system-age-info

.PHONY: install clean
