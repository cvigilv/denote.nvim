---@module "denote"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

if not vim.g.loaded_denote_plugin then
  local logger = require("denote.core.logger")
  logger.info("Setting up plugin")
  -- Update configuration with defaults
  ---@diagnostic disable-next-line: undefined-field
  vim.g.denote = require("denote.config").update_config(vim.g.denote)
  _G.denote_cache_links = {}

  if vim.g.denote.integrations.telescope.enabled then
    require("telescope").load_extension("denote")
  end

  vim.api.nvim_create_user_command("Denote", function(opts)
    require("denote.api").dispatch(opts.fargs)
  end, {
    desc = "Manage Denote notes",
    nargs = "*",
    complete = function(arg_lead)
      return require("denote.api").complete(arg_lead)
    end,
  })

  require("denote.autocmd").setup()
end

vim.g.loaded_denote_plugin = true
