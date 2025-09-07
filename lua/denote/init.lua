---@module "denote"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

-- Create autocommand to
if not vim.g.loaded_denote_plugin then
  -- Update configuration and store in global state
  ---@diagnostic disable-next-line: undefined-field
  _G.denote = require("denote.config").update_config(_G.denote)

  require("denote.autocmd").setup()

  -- -- Initialize extensions
  -- if options.integrations.oil then
  --   require("denote.extensions.oil").setup(options)
  -- end
  -- if options.integrations.telescope.enabled then
  --   require("denote.extensions.telescope").setup(options)
  -- end
end
vim.g.loaded_denote_plugin = true
