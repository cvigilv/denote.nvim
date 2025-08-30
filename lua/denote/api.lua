---@module "denote.api"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Prompts = require("denote.ui.prompts")
local Naming = require("denote.naming")
local String = require("denote.core.string")
local Filesystem = require("denote.core.fs")

local FILETYPE_TO_EXTENSION = {
  org = ".org",
  neorg = ".norg",
  ["markdown-yaml"] = ".md",
  ["markdown-toml"] = ".md",
  text = ".txt",
}

local M = {}

-- Create a new note interactively
function M.denote()
  local opts = _G.denote.config
  -- Define base fields
  local identifier = Naming.generate_timestamp()
  local fields = {
    identifier = identifier,
    date = Naming.timestamp_to_date(identifier),
    extension = FILETYPE_TO_EXTENSION[opts.filetype],
  }
  -- Prompt user for fields defined in `opts.prompts`
  for _, field in ipairs(opts.prompts) do
    fields[field] = Prompts[field](nil, fields)
  end
  -- Create new note
  local filename = Naming.generate_filename(fields) --[[@as string]]
  if Naming.is_denote(filename) then
    vim.cmd("edit " .. opts.directory .. filename)
    vim.cmd("startinsert")
    return true
  else
    error("[denote] The new filename doesn't look like a Denote filename")
    return false
  end
end

-- Update title of file
---@param filename string? File to update
---@param title string? New title
---@return boolean status Whether the title update was succesfully executed
function M.rename_file_title(filename, title)
  filename = filename or vim.fn.expand("%:p")
  if not Naming.is_denote(filename) then
    error("[denote] This doesn't look like a Denote file")
    return false
  end

  local components = Naming.parse_filename(filename, false)
  components.title = title or Prompts.title(filename, components)
  components.title = Naming.as_component_string(components.title, "title")
  local new_filename = Naming.generate_filename(components)

  if filename ~= nil then
    Filesystem.replace_file(filename, new_filename --[[@as string]])
    return true
  else
    error("[denote] Failed to change title of file")
    return false
  end
end

-- Update signature of file
---@param filename string? File to update
---@param signature string? New signature
---@return boolean status Whether the signature update was succesfully executed
function M.rename_file_signature(filename, signature)
  filename = filename or vim.fn.expand("%:p")
  if not Naming.is_denote(filename) then
    error("[denote] This doesn't look like a Denote file")
    return false
  end

  local components = Naming.parse_filename(filename, false)
  components.signature = signature or Prompts.signature(filename, components)
  components.signature = Naming.as_component_string(components.signature, "signature")
  local new_filename = Naming.generate_filename(components)

  if filename ~= nil then
    Filesystem.replace_file(filename, new_filename --[[@as string]])
    return true
  else
    error("[denote] Failed to change signature of file")
    return false
  end
end

-- Update keywords of file
---@param filename string? File to update
---@param keywords string? New keywords
---@return boolean status Whether the keywords update was succesfully executed
function M.rename_file_keywords(filename, keywords)
  filename = filename or vim.fn.expand("%:p")
  if not Naming.is_denote(filename) then
    error("[denote] This doesn't look like a Denote file")
    return false
  end

  local components = Naming.parse_filename(filename, false)
  components.keywords = keywords or Prompts.keywords(filename, components)
  components.keywords = Naming.as_component_string(components.keywords, "keywords")
  local new_filename = Naming.generate_filename(components)

  if filename ~= nil then
    Filesystem.replace_file(filename, new_filename --[[@as string]])
    return true
  else
    error("[denote] Failed to change keywords of file")
    return false
  end
end

---Rename file into a Denote compliant format. If no arguments are passed, it runs interactively.
---@param filename string? File to rename, defaults to current file.
---@return boolean status Whether the rename process was succesfully executed
function M.rename_file(filename)
  -- Parse filename to get current fields
  filename = filename or vim.fn.expand("%:p")
  -- Get file info and store as temporal fields
  local fields = vim.tbl_extend(
    "force",
    {},
    {
      identifier = Naming.generate_timestamp(filename) or "",
      title = Naming.as_component_string(vim.fn.fnamemodify(filename, ":t:r"), "title") or "",
      date = "",
      keywords = "",
      signature = "",
      extension = vim.fn.fnamemodify(filename, ":e"),
    },
    Naming.parse_filename(filename, false)
  )
  -- Prompt user for fields
  for _, field in ipairs(_G.denote.config.prompts) do
    fields[field] = Naming.as_component_string(Prompts[field](filename, fields), field)
  end
  -- Generate new filename
  local new_filename = Naming.generate_filename(fields) --[[@as string]]
  -- Rename file if new filename is Denote compliant
  if Naming.is_denote(new_filename) then
    Filesystem.replace_file(
      filename,
      vim.fs.normalize(vim.fs.dirname(vim.fs.abspath(filename)) .. "/" .. new_filename)
    )
    return true
  else
    error("[denote] The new filename doesn't look like a Denote filename")
    return false
  end
end

return M
