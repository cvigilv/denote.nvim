---@module "denote.core.fs"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local uv = vim.uv or vim.loop

local M = {}

local function absolute_path(path)
  return vim.fs.normalize(vim.fs.abspath(path), { expand_env = false })
end

local function canonical_path(path)
  path = absolute_path(path)
  local resolved = uv.fs_realpath(path)
  if resolved then
    return absolute_path(resolved)
  end

  local parent = uv.fs_realpath(vim.fs.dirname(path))
  if parent then
    return vim.fs.joinpath(absolute_path(parent), vim.fs.basename(path))
  end

  return path
end

local function buffer_for_path(path)
  local target = canonical_path(path)
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buffer)
    if name ~= "" and canonical_path(name) == target then
      return buffer
    end
  end
  return -1
end

---Rename a file without overwriting an existing destination.
---@param old_filename string
---@param new_filename string
---@return boolean status
function M.replace_file(old_filename, new_filename)
  old_filename = absolute_path(old_filename)
  new_filename = absolute_path(new_filename)

  if old_filename == new_filename then
    return true
  end

  -- Issue #9: pass paths straight to libuv so shell metacharacters stay filename text.
  local destination_stat, stat_error, stat_code = uv.fs_lstat(new_filename)
  if destination_stat then
    error(string.format("[denote] Cannot rename %q: destination %q already exists", old_filename, new_filename))
  elseif stat_code ~= "ENOENT" then
    error(string.format("[denote] Cannot inspect destination %q: %s", new_filename, stat_error))
  end

  local source_buffer = buffer_for_path(old_filename)
  local destination_buffer = buffer_for_path(new_filename)
  if destination_buffer >= 0 and destination_buffer ~= source_buffer then
    error(string.format("[denote] Cannot rename to %q: another buffer uses that name", new_filename))
  end

  local renamed, rename_error = uv.fs_rename(old_filename, new_filename)
  if not renamed then
    error(string.format("[denote] Cannot rename %q to %q: %s", old_filename, new_filename, rename_error))
  end

  if source_buffer >= 0 then
    vim.api.nvim_buf_set_name(source_buffer, new_filename)
  end

  return true
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
