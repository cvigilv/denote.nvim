---@module "denote.autocmds"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local logger = require("denote.core.logger")
local uv = vim.uv or vim.loop

local M = {}

M.setup = function()
  local augroup = vim.api.nvim_create_augroup("denote", { clear = false })
  local directory = vim.g.denote.directory --[[@as string]]
  local scanning = false
  local scan_autocmd

  -- Populate links cache
  scan_autocmd = vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = directory .. "*",
    group = augroup,
    desc = "Populate links cache",
    callback = function()
      if scanning then
        return
      end
      scanning = true

      uv.fs_scandir(directory, function(err, req)
        if err or not req then
          scanning = false
          vim.schedule(function()
            local message = string.format(
              "Failed to scan note directory %s: %s",
              directory,
              err or "unknown error"
            )
            logger.error(message)
            vim.notify("[denote] " .. message, vim.log.levels.ERROR)
          end)
          return
        end

        local files = {}
        while true do
          local name, typ = uv.fs_scandir_next(req)
          if not name then
            break
          end
          if typ == "file" then
            local ext = name:match("%.([^.]+)$")
            if ext and vim.tbl_contains({"txt", "md", "org", "norg"}, ext) then
              table.insert(files, vim.fs.joinpath(directory, name))
            end
          end
        end

        vim.schedule(function()
          scanning = false
          for _, filepath in ipairs(files) do
            require("denote.links").get_links(filepath)
          end
          vim.api.nvim_del_autocmd(scan_autocmd)
          local count = #vim.tbl_keys(_G.denote_cache_links or {})
          logger.info("Populated Denote links cache with " .. count .. " links")
        end)
      end)
    end,
  })

  -- Update cached links for current file
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = directory .. "*.{org,md,norg}",
    group = augroup,
    desc = "Update cached links for current file",
    callback = function(args)
      logger.info("Updating cached links for file " .. args.file)
      require("denote.links").get_links(args.file)
    end,
  })

  -- Oil highlighting
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "oil://" .. directory,
    group = augroup,
    desc = "Add file path highlighting to current Oil buffer",
    callback = function()
      logger.info("Setting up Oil highlighting")
      require("denote.ui.highlights").setup()
    end,
  })
end

return M
