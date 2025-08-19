-- Luacheck configuration for denote.nvim

-- Set standard to luajit for better compatibility
std = "luajit"

-- Add vim global
globals = {
  "vim",
  "_G"
}

-- Exclude certain directories
exclude_files = {
  "lua/denote/integrations/**",
  ".luarocks/**",
  ".install/**"
}

-- Ignore certain warnings
ignore = {
  "212", -- unused argument
  "213", -- unused local variable
  "631", -- line too long
}

-- Allow maximum line length
max_line_length = 120

-- Allow maximum cyclomatic complexity
max_cyclomatic_complexity = 10