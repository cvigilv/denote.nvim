---@module "denote.core.fs"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

---Save new file, delete old file
---@param new_filename string
---@param old_filename string
function M.replace_file(old_filename, new_filename)
  if old_filename ~= new_filename then
    vim.cmd("saveas " .. new_filename)
    vim.cmd(string.format('silent !rm "%s"', old_filename))
  end
end

return M
