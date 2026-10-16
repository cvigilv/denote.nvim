---@module "denote.api"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Prompts = require("denote.ui.prompts")
local Naming = require("denote.naming")
local Filesystem = require("denote.core.fs")
local Config = require("denote.config")
local Frontmatter = require("denote.frontmatter")
local Links = require("denote.links")
local uv = vim.uv or vim.loop

local M = {}

local SUBCOMMANDS = {
  ["backlinks"] = "backlinks",
  ["rename-file"] = "rename_file",
  ["rename-file-keywords"] = "rename_file_keywords",
  ["rename-file-signature"] = "rename_file_signature",
  ["rename-file-title"] = "rename_file_title",
}

local TELESCOPE_SUBCOMMANDS = {
  ["insert-link"] = "insert_link",
  ["search"] = "search",
}

local function telescope_enabled()
  return vim.g.denote.integrations.telescope.enabled
end

local RENAME_SUBCOMMANDS = {
  "rename-file",
  "rename-file-keywords",
  "rename-file-signature",
  "rename-file-title",
}

local function is_denote_file()
  return Naming.is_denote(vim.fn.expand("%:p"))
end

---Resolve the path Denote subcommands operate on. Oil buffers list directory
---contents under an `oil://` URL rather than visiting a file, so the entry
---under the cursor provides the path; other buffers use the visited file.
---@return string path
local function current_path()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname:sub(1, #"oil://") ~= "oil://" then
    return vim.fn.expand("%:p")
  end

  local ok, oil = pcall(require, "oil")
  if
    not ok
    or type(oil.get_cursor_entry) ~= "function"
    or type(oil.get_current_dir) ~= "function"
  then
    error("[denote] Renaming from an oil buffer requires oil.nvim")
  end

  -- `get_current_dir` returns nil for remote adapters, so only local
  -- entries end up here.
  local directory = oil.get_current_dir()
  local entry = oil.get_cursor_entry()
  if directory == nil or entry == nil then
    error("[denote] No local file under the cursor to rename")
  end

  return vim.fs.normalize(vim.fs.joinpath(directory, entry.name))
end

---Dispatch a Denote command.
---@param args string[]
---@return any
function M.dispatch(args)
  if #args == 0 then
    return M.denote()
  end
  if #args > 1 then
    error(string.format("[denote] Expected one subcommand, got %d arguments", #args))
  end

  local name = args[1]
  local handler = SUBCOMMANDS[name]
  local telescope_handler = telescope_enabled() and TELESCOPE_SUBCOMMANDS[name]
  if not handler and not telescope_handler then
    error("[denote] Unsupported subcommand: " .. name)
  end
  -- Renaming works on any file type, matching the Emacs implementation
  if
    not vim.tbl_contains(RENAME_SUBCOMMANDS, name)
    and not is_denote_file()
  then
    error("[denote] Subcommands require a Denote buffer")
  end
  if telescope_handler then
    return require("telescope").extensions.denote[telescope_handler]()
  end
  return M[handler]()
end

---Complete Denote subcommands.
---@param arg_lead string
---@return string[]
function M.complete(arg_lead)
  local matches = {}
  for name in pairs(SUBCOMMANDS) do
    -- Renaming subcommands are offered in every buffer, matching the Emacs
    -- implementation; the rest require the current file to be a Denote file
    if
      vim.startswith(name, arg_lead)
      and (vim.tbl_contains(RENAME_SUBCOMMANDS, name) or is_denote_file())
    then
      matches[#matches + 1] = name
    end
  end
  if telescope_enabled() then
    for name in pairs(TELESCOPE_SUBCOMMANDS) do
      if vim.startswith(name, arg_lead) then
        matches[#matches + 1] = name
      end
    end
  end
  table.sort(matches)
  return matches
end

-- Create a new note interactively
function M.denote()
  local opts = vim.g.denote
  -- Define base fields
  local identifier = Naming.generate_timestamp()
  local fields = {
    identifier = identifier,
    date = identifier,
    extension = Config.filetype_extension(opts.filetype),
  }

  Prompts.collect(nil, fields, opts.prompts, function(values)
    if values == nil then
      return
    end

    local filename = Naming.generate_filename(values) --[[@as string]]
    if not Naming.is_denote(filename) then
      error("[denote] The new filename doesn't look like a Denote filename")
    end

    local filepath = opts.directory .. filename
    local exists = uv.fs_stat(filepath) ~= nil
    vim.api.nvim_cmd({ cmd = "edit", args = { filepath } }, {})

    if not exists then
      local frontmatter = Frontmatter.generate_frontmatter(values, opts.filetype)
      local lines = vim.split(frontmatter, "\n", { plain = true })
      local buffer = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
      vim.api.nvim_win_set_cursor(0, { #lines, 0 })
    end

    vim.api.nvim_cmd({ cmd = "startinsert" }, {})
  end)
end

local function replace_note_file(old_filepath, new_filepath)
  local status = Filesystem.replace_file(old_filepath, new_filepath)
  if status then
    Links.rename_source(old_filepath, new_filepath)
  end
  return status
end

---Build Denote filename components for an arbitrary file. Denote files are
---parsed from their filename; other files get an identifier from the file's
---timestamps, a title from its basename and keep their own extension.
---@param filename string Path to the file
---@return table components
local function components_for_file(filename)
  if Naming.is_denote(filename) then
    local components = Naming.parse_filename(filename, false)
    local ok, date = pcall(Naming.timestamp_to_date, components.identifier)
    if ok then
      components.date = date
    end
    return components
  end

  local extension = vim.fn.fnamemodify(filename, ":e")
  return {
    identifier = Naming.generate_timestamp(filename) or "",
    title = Naming.as_component_string(vim.fn.fnamemodify(filename, ":t:r"), "title") or "",
    date = "",
    keywords = "",
    signature = "",
    extension = extension ~= "" and ("." .. extension) or "",
  }
end

---Prompt-friendly description of the current title, used as the fallback
---when the blank title prompt is answered with an empty string. The frontmatter
---title when the file carries one, the deslugified title component for Denote
---filenames without frontmatter, and the raw basename otherwise.
---@param filename string Path to the file
---@param components table Filename components
---@return string title
local function prompt_title(filename, components)
  local ok, frontmatter = pcall(
    Frontmatter.parse_frontmatter,
    filename,
    vim.filetype.match({ filename = filename })
  )
  if ok and frontmatter and frontmatter.title ~= nil and frontmatter.title ~= "" then
    return frontmatter.title
  end

  if Naming.is_denote(filename) then
    return Naming.deslugify(components.title or "", "title")
  end

  return vim.fn.fnamemodify(filename, ":t:r")
end

local function rename_component(filename, field, value)
  filename = filename or current_path()
  -- Build components for the current file, whatever its name or type
  local components = components_for_file(filename)
  -- The title prompt starts blank; empty answers keep the current title and
  -- entered prose is slugified when the rename runs
  local current_title = prompt_title(filename, components)
  if field == "title" then
    components.title = ""
  end
  local function replace_file(new_value)
    if new_value == nil then
      return
    end

    components[field] = (field == "title" and new_value == "") and current_title or new_value
    local new_filename = Naming.generate_filename(components)
    -- Keep the file in its current directory, matching the Emacs implementation
    local new_filepath = vim.fs.normalize(
      vim.fs.dirname(vim.fs.abspath(filename)) .. "/" .. new_filename
    )
    return replace_note_file(filename, new_filepath --[[@as string]])
  end

  if value ~= nil then
    return replace_file(value)
  end

  Prompts[field](filename, components, replace_file)
end

-- Update title of file
---@param filename string? File to update
---@param title string? New title
---@return boolean? status Whether the title update was succesfully executed
function M.rename_file_title(filename, title)
  return rename_component(filename, "title", title)
end

-- Update signature of file
---@param filename string? File to update
---@param signature string? New signature
---@return boolean? status Whether the signature update was succesfully executed
function M.rename_file_signature(filename, signature)
  return rename_component(filename, "signature", signature)
end

-- Update keywords of file
---@param filename string? File to update
---@param keywords string? New keywords
---@return boolean? status Whether the keywords update was succesfully executed
function M.rename_file_keywords(filename, keywords)
  return rename_component(filename, "keywords", keywords)
end

---Rename file into a Denote compliant format. If no arguments are passed, it runs interactively.
---Works on any file type, keeping the file in its current directory.
---@param filename string? File to rename, defaults to current file.
function M.rename_file(filename)
  -- Build components for the current file, whatever its name or type
  filename = filename or current_path()
  local fields = components_for_file(filename)
  -- The title prompt starts blank; empty answers keep the current title and
  -- entered prose is slugified when the rename runs
  local current_title = prompt_title(filename, fields)
  fields.title = ""
  Prompts.collect(filename, fields, vim.g.denote.prompts, function(values)
    if values == nil then
      return
    end
    values.title = (values.title == "") and current_title or values.title

    local new_filename = Naming.generate_filename(values) --[[@as string]]
    if not Naming.is_denote(new_filename) then
      error("[denote] The new filename doesn't look like a Denote filename")
    end

    replace_note_file(
      filename,
      vim.fs.normalize(vim.fs.dirname(vim.fs.abspath(filename)) .. "/" .. new_filename)
    )
  end)
end

---Populate loclist with backlinks of current buffer.
function M.backlinks()
  local filename = vim.fn.expand("%:p")
  -- {
  --   filename = "utils.lua",
  --   lnum = 20,
  --   col = 0,
  --   text = "Another message",
  --   type = "W",
  -- },
  local backlinks = require("denote.links").get_backlinks(filename)
  vim.fn.setloclist(vim.api.nvim_get_current_win(), backlinks, "r")
  vim.cmd("lopen")
end
return M
