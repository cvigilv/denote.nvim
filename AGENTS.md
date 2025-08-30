# AGENTS.md - denote.nvim Development Guide

## Build/Test/Lint Commands
- **No automated tests**: This plugin has no test suite or build commands
- **Manual testing**: Use `:Denote note` in Neovim to test functionality
- **Linting**: No formal linter configured - follow Lua best practices

## Code Style Guidelines

### Language & Framework
- **Lua**: Neovim plugin written in pure Lua with Neovim's Lua API
- **No external dependencies**: Only uses built-in Neovim/Lua functionality

### Imports & Module Structure
- Use `local M = {}` pattern for module definition
- Return modules with `return M`
- Import with `local ModuleName = require("module.path")`
- Prefer short variable names for frequently used modules (e.g., `local I = require("denote.internal")`)

### Types & Documentation
- Use LuaLS annotations: `---@module`, `---@param`, `---@return`, `---@type`
- Define custom types with `---@class ClassName`
- Document all public functions with type annotations
- Include author and license headers: `---@author Carlos Vigil-Vásquez` and `---@license MIT 2025`

### Naming Conventions
- **Functions**: snake_case (e.g., `update_title`, `generate_timestamp`)
- **Variables**: snake_case (e.g., `new_filename`, `fields`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `PATTERNS`, `SEPARATORS`)
- **Classes**: PascalCase with dot notation (e.g., `Denote.Configuration`)

### Error Handling
- Use `vim.validate()` for input validation
- Throw errors with `error()` function and appropriate error levels
- Return boolean status from functions that can fail