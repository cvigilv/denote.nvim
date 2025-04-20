---@module "denote.helpers.highlights"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

-- Define highlight groups related to Denote
M.setup = function()
  vim.cmd([[
  hi def link DenoteDate      Number
  hi def link DenoteSignature Special
  hi def link DenoteTitle     Title
  hi def link DenoteKeywords  Tag
  hi def link DenoteExtension Comment
  ]])
end

return M
