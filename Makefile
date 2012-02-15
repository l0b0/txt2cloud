PREFIX = /usr/local/bin

SOURCE_FILE = $(wildcard $(notdir $(CURDIR)).*)
SOURCE_PATH = $(CURDIR)/$(SOURCE_FILE)
TARGET_FILE = $(basename $(SOURCE_FILE))
TARGET_PATH = $(PREFIX)/$(TARGET_FILE)
INSTALL_FILE_PATH = $(PREFIX)/$(basename $(SCRIPT))

test:
	$(CURDIR)/test.sh

.PHONY: install
install:
	cp $(SOURCE_PATH) $(TARGET_PATH)
	sed -i -e 's#\(\./\)\?$(SOURCE_FILE)#$(TARGET_FILE)#g' $(TARGET_PATH)

include tools.mk
