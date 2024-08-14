local M = {}

local internal = require("simple-denote.internal")

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
  if not title or not keywords then return end
  internal.note(options, title, keywords)
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
  if not title then return end
  internal.title(options, filename, title)
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
  if not keywords then return end
  internal.keyword(filename, keywords)
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
  if not sig then return end
  internal.signature(filename, sig)
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
  if not ext then return end
  internal.extension(filename, ext)
end


return M
