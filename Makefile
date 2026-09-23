NVIM ?= nvim

.PHONY: test
test:
	$(NVIM) --headless --noplugin -u tests/minimal_init.lua -l tests/run.lua
