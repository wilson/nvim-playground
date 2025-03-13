CC = clang
CFLAGS = -Wall -Wextra -pedantic -O2 -x objective-c -fobjc-arc -Wno-c++11-long-long
LDFLAGS = -framework Foundation -framework Cocoa -framework Carbon
PLUGIN_NAME = libKeyRepeatFix.dylib

all: $(PLUGIN_NAME)

$(PLUGIN_NAME): keyrepeat-fix.mm
	$(CC) $(CFLAGS) -dynamiclib -o $@ $< $(LDFLAGS)

install: $(PLUGIN_NAME)
	mkdir -p $(HOME)/Library/KeyRepeatFix
	cp $(PLUGIN_NAME) $(HOME)/Library/KeyRepeatFix/
	@echo "Installation complete!"
	@echo "Add this to your nvim-qt function in ~/.zshrc:"
	@echo "DYLD_INSERT_LIBRARIES=$(HOME)/Library/KeyRepeatFix/$(PLUGIN_NAME)"

clean:
	rm -f $(PLUGIN_NAME)

.PHONY: all install clean
