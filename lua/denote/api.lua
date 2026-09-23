---@module "denote.api"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Prompts = require("denote.ui.prompts")
local Naming = require("denote.naming")
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
  local opts = vim.g.denote
  -- Define base fields
  local identifier = Naming.generate_timestamp()
  local fields = {
    identifier = identifier,
    date = Naming.timestamp_to_date(identifier),
    extension = FILETYPE_TO_EXTENSION[opts.filetype],
  }

  Prompts.collect(nil, fields, opts.prompts, function(values)
    if values == nil then
      return
    end

    local filename = Naming.generate_filename(values) --[[@as string]]
    if not Naming.is_denote(filename) then
      error("[denote] The new filename doesn't look like a Denote filename")
    end

    vim.cmd("edit " .. opts.directory .. filename)
    vim.cmd("startinsert")
  end)
end

local function rename_component(filename, field, value)
  filename = filename or vim.fn.expand("%:p")
  if not Naming.is_denote(filename) then
    error("[denote] This doesn't look like a Denote file")
  end

  local components = Naming.parse_filename(filename, false)
  local function replace_file(new_value)
    if new_value == nil then
      return
    end

    components[field] = new_value
    local new_filename = Naming.generate_filename(components)
    local new_filepath = vim.g.denote.directory .. new_filename
    return Filesystem.replace_file(filename, new_filepath --[[@as string]])
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
---@param filename string? File to rename, defaults to current file.
function M.rename_file(filename)
  -- Parse filename to get current fields
  filename = filename or vim.fn.expand("%:p")
  -- Get file info and store as temporal fields
  local fields = vim.tbl_extend("force", {}, {
    identifier = Naming.generate_timestamp(filename) or "",
    title = Naming.as_component_string(vim.fn.fnamemodify(filename, ":t:r"), "title") or "",
    date = "",
    keywords = "",
    signature = "",
    extension = vim.fn.fnamemodify(filename, ":e"),
  }, Naming.parse_filename(filename, false))
  Prompts.collect(filename, fields, vim.g.denote.prompts, function(values)
    if values == nil then
      return
    end

    local new_filename = Naming.generate_filename(values) --[[@as string]]
    if not Naming.is_denote(new_filename) then
      error("[denote] The new filename doesn't look like a Denote filename")
    end

    Filesystem.replace_file(
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
