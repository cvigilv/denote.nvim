---@module "denote.ui.highlights"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

-- Define highlight groups related to Denote
M.setup = function()
  local logger = require("denote.core.logger")
  logger.info(
    "Setting up highlighting file names for buffer " .. vim.api.nvim_get_current_buf()
  )
  vim.cmd([[
  " Setup highlight groups
  hi def link DenoteDate      Number
  hi def link DenoteSignature Special
  hi def link DenoteTitle     Title
  hi def link DenoteKeywords  Tag
  hi def link DenoteExtension Comment

  " Match Denote file name patterns
  syn match Denote "\v(\d{4}\d{2}\d{2}T\d{2}\d{2}\d{2})(\=\=[a-zA-Z0-9=]+)?(--[a-z0-9-]+)?(__[a-z0-9_]+)?\..*$" contains=denoteDate,denoteSignature,denoteTitle,denoteKeywords,denoteExtension

  " Match individual components
  syn match DenoteDate "\v\d{4}\d{2}\d{2}T\d{2}\d{2}\d{2}" contained
  syn match DenoteSignature "\v\=\=[a-zA-Z0-9=]+" contained
  syn match DenoteTitle "\v--[a-z0-9-]+" contained
  syn match DenoteKeywords "\v__[a-z0-9_]+" contained
  syn match DenoteExtension "\v\..*$" contained
  ]])
end

return M
