---@module "denote.ui.prompts"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local S = require("denote.core.string")

local function _prompt_factory(filename, components, field)
  filename = filename or vim.fn.expand("%:p")
  local v
  vim.ui.input({
    prompt = string.format("[denote] New %s: ", field),
    default = components[field] or "",
  }, function(e)
    v = S.trim(e)
  end)
  return v
end

local M = {}

M.signature = function(filename, components)
  return _prompt_factory(filename, components, "signature")
end

M.date = function(filename, components)
  return _prompt_factory(filename, components, "identifier")
end

M.keywords = function(filename, components)
  return _prompt_factory(filename, components, "keywords")
end

M.title = function(filename, components)
  return _prompt_factory(filename, components, "title")
end

M.extension = function(filename, components)
  return _prompt_factory(filename, components, "extension")
end

return M
