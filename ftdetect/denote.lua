---@module "after.ftdetect.denote"
---@author Carlos Vigil-Vásquez
---@license MIT 2026

--- Set the buffer filetype for a Denote filename in any directory.
---@param bufnr integer
---@return boolean changed
local function set_as_denote(bufnr)
  local filetype = vim.bo[bufnr].filetype
  if vim.tbl_contains(vim.split(filetype, ".", { plain = true }), "denote") then
    return false
  end

  vim.bo[bufnr].filetype = filetype == "" and "denote" or filetype .. ".denote"
  return true
end

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*",
  group = vim.api.nvim_create_augroup("denote_ftdetect", { clear = true }),
  desc = "Detect if a file is a denote note and set the filetype accordingly",
  callback = function(ev)
    local logger = require("denote.core.logger")
    local filepath = vim.fs.abspath(ev.file)
    if require("denote.naming").is_denote(filepath) and set_as_denote(ev.buf) then
      logger.debug("Set filetype to " .. vim.bo[ev.buf].filetype .. " for " .. ev.file)
      require("denote.ui.highlights").setup()
      logger.debug("Set up highlights for " .. ev.file)
    end
  end,
})
