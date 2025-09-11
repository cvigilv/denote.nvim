---@module "denote"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

-- Create autocommand to
if not vim.g.loaded_denote_plugin then
  local logger = require("denote.core.logger")
  logger.info("Setting up plugin")
  -- Update configuration with defaults
  ---@diagnostic disable-next-line: undefined-field
  vim.g.denote = require("denote.config").update_config(vim.g.denote)
  _G.denote_cache_links = {}

  vim.api.nvim_create_user_command("Denote", function()
    require("denote.api").denote()
  end, {})

  require("denote.autocmd").setup()
end

vim.g.loaded_denote_plugin = false

