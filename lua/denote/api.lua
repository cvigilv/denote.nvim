---@module "denote.api"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local I = require("denote.internal")
local Prompts = require("denote.helpers.prompts")

local M = {}

-- Create a new note interactively
---@param opts Denote.Configuration
function M.note(opts)
  -- Define base fields
  local fields = {
    date = I.generate_timestamp(),
    extension = I.FILETYPE_TO_EXTENSION[opts.filetype],
  }
  -- Prompt user for fields defined in `opts.prompts`
  for _, field in ipairs(opts.prompts) do
    fields[field] = Prompts[field]()
  end
  vim.print(fields)
  -- Create new note
  I.new_note(fields, opts)
end

-- Update title of file
---@param filename string? File to update
---@param title string? New title
function M.title(filename, title)
  filename = filename or vim.fn.expand("%:p")
  title = title or Prompts.title(filename)
  I.update_title(filename, title)
end

-- Update signature of file
---@param filename string? File to update
---@param signature string? New signature
function M.signature(filename, signature)
  filename = filename or vim.fn.expand("%:p")
  signature = signature or Prompts.signature(filename)
  I.update_signature(filename, signature)
end

-- Update keywords of file
---@param filename string? File to update
---@param keywords string? New keywords
function M.keywords(filename, keywords)
  filename = filename or vim.fn.expand("%:p")
  keywords = keywords or Prompts.keywords(filename)
  I.update_keyword(filename, keywords)
end

-- Update extension of file
---@param filename string? File to update
---@param extension string? New extension
function M.extension(filename, extension)
  filename = filename or vim.fn.expand("%:p")
  extension = extension or Prompts.extension(filename)
  I.update_extension(filename, extension)
end

---Rename file into a Denote compliant format. If no arguments are passed, it runs interactively.
---@param opts Denote.Configuration
---@param filename string? File to rename, defaults to current file.
---@param title string? New title
---@param signature string? New signature
---@param keywords string? New keywords
---@param extension string? New extension
---@return boolean status Whether the rename process was succesfully executed
function M.rename_file(opts, filename, identifier, title, signature, keywords, extension)
  opts = opts or _G.denote.config

  -- Parse filename to get current fields
  filename = filename or vim.fn.expand("%:p")
  local fields = I.parse_filename(filename, false)
  if not fields then
    error("[denote] Doesn't look like a Denote file", 4)
    return false
  end

  -- Prompt user for fields defined in `opts.prompts`
  for _, field in ipairs(opts.prompts) do
    fields[field] = Prompts[field]()
  end

  -- Load fields
  identifier = identifier or fields["identifier"] or ""
  title = title or fields["title"] or ""
  keywords = keywords or fields["keywords"] or ""
  signature = signature or fields["signature"] or ""
  extension = extension or fields["extension"] or ""

  -- Check if date is in Denote's format
  if not identifier:match(I.PATTERNS.identifier) then
    error("[denote] Doesn't look like a denote file", 4)
    return false
  end

  -- Generate new filename
  local new_filename = identifier
    .. I.format_denote_string(signature --[[@as string]], "=")
    .. I.format_denote_string(title --[[@as string]], "-")
    .. I.format_denote_string(keywords --[[@as string]], "_")
    .. extension

  -- Rename file
  I.replace_file(
    filename,
    vim.fs.normalize(vim.fs.dirname(vim.fs.abspath(filename)) .. "/" .. new_filename)
  )

  return true
end

---Populate a quickfix buffer with all files found in the Denote directory.
---@param opts Denote.Configuration
function M.search(opts)
  opts = opts or _G.denote.config
  local files = vim.split(vim.fn.globpath(opts.directory, "*"), "\n")
  local items = {}
  for _, path in ipairs(files) do
    table.insert(items, {
      filename = path,
      lnum = 1,
      col = 1,
      text = vim.fs.basename(path),
    })
  end
  vim.fn.setqflist(items)
  vim.cmd("copen")
  if vim.fn.exists(":Cfilter") ~= 2 then
    print("[denote] `Cfilter` not loaded, we recommend adding it for a better experience")
  end
end
return M
