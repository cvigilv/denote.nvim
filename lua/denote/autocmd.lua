---@module "denote.aucmds"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

---@param opts Denote.Configuration User configuration
M.setup = function()
  local opts = _G.denote
  local augroup = vim.api.nvim_create_augroup("denote", { clear = true })

  -- File detection
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    pattern = opts.directory .. "*",
    group = augroup,
    callback = function(args)
      print("[denote.nvim] Setting buffer "..args.buf .. " filetype to as " .. vim.bo[args.buf].filetype .. ".denote")
      vim.bo[args.buf].filetype = vim.bo[args.buf].filetype .. ".denote"
    end,
  })

  -- File cache
end

return M
