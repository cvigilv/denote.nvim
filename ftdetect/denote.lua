---@module "after.ftdetect.denote"
---@author Carlos Vigil-Vásquez
---@license MIT 2026

--- Set current filetype as a denote note if (i) complies with naming convention or
--- (ii) is located inside the denote directory and complies with the naming convention.
local function set_as_denote()
    if vim.bo.filetype ~= "" then
        vim.bo.filetype = vim.bo.filetype .. ".denote"
    else
        vim.bo.filetype = "denote"
    end
end

--- Check if file hash denote ID in file name
---@param filepath string
---@return boolean
local function is_denote(filepath)
    local filename = vim.fs.basename(filepath)
    return filename:match("^%d%d%d%d%d%d%d%dT%d%d%d%d%d%d") ~= nil
end

--- Check if file is located inside a denote silo
---@param filepath string
---@return boolean
local function in_silo(filepath)
    return filepath:match(vim.fs.normalize(vim.g.denote.directory)) ~= nil
end

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = "*",
    group = vim.api.nvim_create_augroup("denote", { clear = true }),
    desc = "Detect if a file is a denote note and set the filetype accordingly",
    callback = function(ev)
        local logger = require("denote.core.logger")
        local filepath = vim.fs.abspath(ev.file)
        if (in_silo(filepath) and is_denote(filepath)) or (is_denote(filepath)) then
            set_as_denote()
            logger.debug("Set filetype to " .. vim.bo.filetype .. " for " .. ev.file)
            require("denote.ui.highlights").setup()
            logger.debug("Set up highlights for " .. ev.file)
        end
    end,
})
