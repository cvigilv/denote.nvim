---@module "denote.extensions.oil"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local function setup_highlights()
  vim.cmd([[
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

local M = {}

function M.setup(opts)
  -- Define highlight groups
  vim.cmd([[
  hi def link DenoteDate Number
  hi def link DenoteSignature Comment
  hi def link DenoteTitle Title
  hi def link DenoteKeywords Special
  hi def link DenoteExtension Comment
  ]])

  -- Add highlighting to denote file naming convention components in `opts.dir` Oil buffer
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "oil://" .. vim.fs.abspath(opts.dir) .. "*",
    group = vim.api.nvim_create_augroup("denote.extensions.oil", { clear = false }),
    desc = "Highlight denote-compliant filenames in `opts.dir` Oil buffer",
    callback = setup_highlights,
  })
end

return M
