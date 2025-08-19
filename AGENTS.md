# AGENTS.md - Development Guide for denote.nvim

## Build/Test Commands
- `make test` - Run all unit tests with busted
- `make test-file FILE=tests/filename_spec.lua` - Run single test file
- `make lint` - Lint Lua files with luacheck
- `make format` - Format code with stylua (if available)
- `make check` - Run lint + test
- `make install-deps` - Install luarocks dependencies
- `make watch` - Watch files and run tests on changes

## Code Style Guidelines

### Architecture
- Core modules in `lua/denote/core/` (utils, filename, frontmatter, file)
- API layer in `lua/denote/api.lua` with clean public interface
- Configuration in `lua/denote/config.lua` with validation
- UI prompts in `lua/denote/ui.lua`
- Commands in `lua/denote/commands.lua`
- Tests in `tests/` with `_spec.lua` suffix

### Lua Conventions
- Use LuaLS type annotations: `---@param`, `---@return`, `---@class`
- Module headers with `---@module`, `---@author`, `---@license MIT`
- Snake_case for functions and variables
- PascalCase for types/classes (e.g., `Denote.Config`, `Denote.FileComponents`)
- Local functions prefixed with `_` or `M.` for module exports
- Use `vim.validate()` for parameter validation
- Store global state in `_G.denote.config`
- Use `vim.tbl_deep_extend()` for merging configs
- Prefer `vim.fn` and `vim.fs` functions for file operations
- Error handling with descriptive messages
- Comprehensive unit tests for all core functionality