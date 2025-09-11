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

--- Gets `target` path relative to `base`, or `nil` if `base` is not an ancestor.
---@param base string? Base path (default: current path)
---@param target string
---@return string|nil relpath
function M.get_relative_path(base, target)
  base = base or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
  return vim.fs.relpath(vim.fs.normalize(base), vim.fs.normalize(target))
end

return M
