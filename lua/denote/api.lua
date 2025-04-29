---@module "denote.api"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local I = require("denote.internal")

local M = {}
---@param options table
---@param title string|nil
---@param keywords string|nil
function M.note(options, title, keywords)
  if not title then
    vim.ui.input({ prompt = "Note title: " }, function(input)
      title = input
    end)
  end
  if not keywords then
    vim.ui.input({ prompt = "Keywords: " }, function(input)
      keywords = input
    end)
  end
  if not title or not keywords then
    return
  end
  I.note(options, title, keywords)
end

---@param options table
---@param filename string|nil
---@param title string|nil
function M.title(options, filename, title)
  if not filename then
    filename = vim.fn.expand("%")
  end
  if not title then
    vim.ui.input({ prompt = "New title: " }, function(input)
      title = input
    end)
  end
  if not title then
    return
  end
  I.title(options, filename, title)
end

---@param filename string|nil
---@param keywords string|nil
function M.keywords(filename, keywords)
  if not filename then
    filename = vim.fn.expand("%")
  end
  if not keywords then
    vim.ui.input({ prompt = "New keywords: " }, function(input)
      keywords = input
    end)
  end
  if not keywords then
    return
  end
  I.keyword(filename, keywords)
end

---@param filename string|nil
---@param sig string|nil
function M.signature(filename, sig)
  filename = filename or vim.fn.expand("%")
  if not sig then
    vim.ui.input({ prompt = "Signature: " }, function(input)
      sig = input
    end)
  end
  if not sig then
    return
  end
  I.signature(filename, sig)
end

---@param filename string|nil
---@param ext string|nil
function M.extension(filename, ext)
  filename = filename or vim.fn.expand("%")
  if not ext then
    vim.ui.input({ prompt = "Extension: " }, function(input)
      ext = input
    end)
  end
  if not ext then
    return
  end
  I.extension(filename, ext)
end

--- Rename file into a Denote compliant format
---@param filename string?
---@param title string?
---@param signature string?
---@param keywords string?
---@param extension string?
function M.rename_file(filename, date, title, signature, keywords, extension)
  -- Parse filename to get current components
  filename = filename or vim.fn.expand("%:p")
  local components = I.parse_filename(filename, false)

  -- Get/generate timestamp and ask for title, signature, keywords, and extension
  -- TODO: Move to vim.ui.input eventually, since it's the new standard and is more UX friendly
  if components.date == nil then
    date = I.generate_timestamp(filename)
  else
    date = components.date
  end
  if not title then
    title = vim.fn.input("[denote.nvim] Title: ", components.title or "")
  end
  if not signature then
    signature = vim.fn.input("[denote.nvim] Signature: ", components.signature or "")
  end
  if not keywords then
    keywords = vim.fn.input("[denote.nvim] Keywords: ", components.keywords or "")
  end
  if not extension then
    extension = vim.fn.input("[denote.nvim] Extension: ", components.extension or "")
  end

  -- Generate new filename
  local new_filename = date
    .. I.format_denote_string(signature --[[@as string]], "=")
    .. I.format_denote_string(title --[[@as string]], "-")
    .. I.format_denote_string(keywords --[[@as string]], "_")
    .. extension

  -- Rename file
  I.replace_file(
    filename,
    vim.fs.normalize(vim.fs.dirname(vim.fs.abspath(filename)) .. "/" .. new_filename)
  )
end


return M
