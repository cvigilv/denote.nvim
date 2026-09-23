---@module "after.ftdetect.denote"
---@author Carlos Vigil-Vásquez
---@license MIT 2026

--- Set current filetype as a denote note if it complies with the naming convention.
local function set_as_denote()
    if vim.bo.filetype ~= "" then
        vim.bo.filetype = vim.bo.filetype .. ".denote"
    else
        vim.bo.filetype = "denote"
    end
end

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = "*",
    group = vim.api.nvim_create_augroup("denote", { clear = true }),
    desc = "Detect if a file is a denote note and set the filetype accordingly",
    callback = function(ev)
        local logger = require("denote.core.logger")
        local filepath = vim.fs.abspath(ev.file)
        if require("denote.naming").is_denote(filepath) then
            set_as_denote()
            logger.debug("Set filetype to " .. vim.bo.filetype .. " for " .. ev.file)
            require("denote.ui.highlights").setup()
            logger.debug("Set up highlights for " .. ev.file)
        end
    end,
})
