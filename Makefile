.PHONY: all lint install

all: lint

lint:
	shellcheck --shell=bash install_dev_tools.sh
	luacheck *.lua custom/*.lua

install:
	./install_dev_tools.sh
