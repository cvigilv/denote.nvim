---@module "denote.autocmds"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

M.setup = function()
    local logger = require("denote.core.logger")
    local augroup = vim.api.nvim_create_augroup("denote", { clear = true })

    -- Set denote filetype
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = vim.g.denote.directory .. "*",
        group = augroup,
        desc = "Set Denote filetype",
        callback = function(args)
            local current_ft = vim.bo.filetype
            if not vim.endswith(current_ft, "denote") then
                logger.info(
                    "Setting buffer " .. args.buf .. " filetype to " .. current_ft .. ".denote"
                )
                vim.bo.filetype = table.concat({current_ft, "denote"}, ".")
            end
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
