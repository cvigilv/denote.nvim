---@module "denote.autocmds"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local logger = require("denote.core.logger")

local M = {}

M.setup = function()
  local augroup = vim.api.nvim_create_augroup("denote", { clear = true })

  -- Set denote filetype
  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    pattern = vim.g.denote.directory .. "*",
    group = augroup,
    desc = "Set Denote filetype",
    callback = function(args)
      local current_ft = vim.bo[args.buf].filetype
      if not vim.endswith(current_ft, ".denote") then
        logger.info("Setting buffer " .. args.buf .. " filetype to " .. current_ft .. ".denote")
        vim.bo[args.buf].filetype = current_ft .. ".denote"
      end
    end,
  })

  -- Populate links cache
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = vim.g.denote.directory .. "*",
    group = augroup,
    desc = "Populate links cache",
    once = true,
    callback = function()
      local dir = vim.g.denote.directory --[[@as string]]
      local uv = vim.loop
      uv.fs_scandir(dir, function(err, req)
        if err or not req then
          vim.schedule(function()
            require("denote.core.logger").info(
              "Failed to scan directory: " .. (err or "unknown error"),
              vim.log.levels.ERROR
            )
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
              table.insert(files, dir .. name)
            end
          end
        end

        -- Process files on main thread (for Lua module safety)
        vim.schedule(function()
          for _, filepath in ipairs(files) do
            require("denote.links").get_links(filepath)
          end
          vim.notify("pop")
          local count = #vim.tbl_keys(_G.denote_cache_links or {})
          require("denote.core.logger").info(
            "Populated Denote links cache with " .. count .. " links"
          )
        end)
      end)
    end,
  })

  -- Update cached links for current file
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = vim.g.denote.directory .. "*.{org,md,norg}",
    group = augroup,
    desc = "Update cached links for current file",
    callback = function(args)
      logger.info("Updating cached links for file " .. args.file)
      require("denote.links").get_links(args.file)
    end,
  })

  -- Oil highlighting
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "oil://" .. vim.g.denote.directory,
    group = augroup,
    desc = "Add file path highlighting to current Oil buffer",
    callback = function()
      logger.info("Setting up Oil highlighting")
      require("denote.ui.highlights").setup()
    end,
  })
end

return M
