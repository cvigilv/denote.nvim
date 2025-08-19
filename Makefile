.PHONY: test lint format check install-deps

# Test runner configuration
NVIM ?= nvim
BUSTED ?= busted

# Directories
LUA_DIR = lua
TEST_DIR = tests

# Find all Lua files
LUA_FILES = $(shell find $(LUA_DIR) -name "*.lua")
TEST_FILES = $(shell find $(TEST_DIR) -name "*_spec.lua")

# Default target
all: check

# Install dependencies
install-deps:
	@echo "Installing test dependencies..."
	@which luarocks > /dev/null || (echo "luarocks not found. Please install luarocks first." && exit 1)
	luarocks install busted --local
	luarocks install luacheck --local

# Run tests
test:
	@echo "Running tests..."
	$(BUSTED) $(TEST_DIR)

# Run specific test file
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=path/to/test_spec.lua"; \
		exit 1; \
	fi
	$(BUSTED) $(FILE)

# Lint Lua files
lint:
	@echo "Linting Lua files..."
	@which luacheck > /dev/null || (echo "luacheck not found. Run 'make install-deps' first." && exit 1)
	luacheck $(LUA_DIR) --globals vim

# Format Lua files (using stylua if available)
format:
	@if which stylua > /dev/null 2>&1; then \
		echo "Formatting Lua files with stylua..."; \
		stylua $(LUA_DIR) $(TEST_DIR); \
	else \
		echo "stylua not found. Install with: cargo install stylua"; \
	fi

# Check code quality
check: lint test
	@echo "All checks passed!"

# Run tests in Neovim (for plugin-specific functionality)
test-nvim:
	@echo "Running tests in Neovim..."
	$(NVIM) --headless -c "lua require('tests.runner').run_all()" -c "quit"

# Watch for file changes and run tests
watch:
	@if which entr > /dev/null 2>&1; then \
		find $(LUA_DIR) $(TEST_DIR) -name "*.lua" | entr -c make test; \
	else \
		echo "entr not found. Install with your package manager to enable watch mode."; \
	fi

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	find . -name "*.tmp" -delete
	find . -name ".DS_Store" -delete

# Help target
help:
	@echo "Available targets:"
	@echo "  test        - Run all tests"
	@echo "  test-file   - Run specific test file (usage: make test-file FILE=path/to/test)"
	@echo "  test-nvim   - Run tests in Neovim headless mode"
	@echo "  lint        - Lint all Lua files"
	@echo "  format      - Format all Lua files with stylua"
	@echo "  check       - Run lint and test"
	@echo "  watch       - Watch files and run tests on changes"
	@echo "  install-deps- Install required dependencies"
	@echo "  clean       - Clean temporary files"
	@echo "  help        - Show this help"