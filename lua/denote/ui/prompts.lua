---@module "denote.ui.prompts"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local S = require("denote.core.string")

local function prompt_factory(components, field, callback)
  vim.ui.input({
    prompt = string.format("[denote] New %s: ", field),
    default = components[field] or "",
  }, function(input)
    if input == nil then
      callback(nil)
      return
    end

    callback(S.trim(input))
  end)
end

local M = {}

M.signature = function(_, components, callback)
  prompt_factory(components, "signature", callback)
end

M.date = function(_, components, callback)
  prompt_factory(components, "identifier", callback)
end

M.keywords = function(_, components, callback)
  prompt_factory(components, "keywords", callback)
end

M.title = function(_, components, callback)
  prompt_factory(components, "title", callback)
end

M.extension = function(_, components, callback)
  prompt_factory(components, "extension", callback)
end

-- Start each prompt only after the previous callback completes.
function M.collect(filename, components, fields, callback)
  local function prompt_next(index)
    local field = fields[index]
    if field == nil then
      callback(components)
      return
    end

    M[field](filename, components, function(value)
      if value == nil then
        callback(nil)
        return
      end

      components[field] = value
      prompt_next(index + 1)
    end)
  end

  prompt_next(1)
end

return M
