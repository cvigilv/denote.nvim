local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Filesystem = require("denote.core.fs")

local function edit_file(path, directory)
  vim.g.denote = { directory = directory .. "/" }
  vim.cmd("edit! " .. vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

local function close_buffer(buffer)
  if vim.api.nvim_get_current_buf() == buffer then
    vim.cmd("enew!")
  end
  if vim.api.nvim_buf_is_valid(buffer) then
    vim.api.nvim_buf_delete(buffer, { force = true })
  end
end

return {
  H.test("replace_file treats shell metacharacters as filename text", function()
    local directory = H.tmpdir()
    local notes = directory .. "/notes with spaces"
    local old_path = notes .. "/20250102T030405--$(touch marker).md"
    local new_path = notes .. "/20250102T030405--new-title.md"
    local marker = directory .. "/marker"
    H.write_file(old_path, { "original contents" })

    local previous_directory = vim.fn.getcwd()
    vim.fn.chdir(directory)
    local buffer = edit_file(old_path, notes)
    local ok, err = pcall(Filesystem.replace_file, old_path, new_path)
    vim.fn.chdir(previous_directory)

    if not ok then
      close_buffer(buffer)
      H.remove(directory)
      error(err)
    end

    H.eq(nil, vim.uv.fs_stat(old_path))
    H.truthy(vim.uv.fs_stat(new_path))
    H.eq(nil, vim.uv.fs_stat(marker))
    H.eq({ "original contents" }, vim.fn.readfile(new_path))
    H.eq(vim.uv.fs_realpath(new_path), vim.api.nvim_buf_get_name(buffer))

    close_buffer(buffer)
    H.remove(directory)
  end),

  H.test("replace_file refuses to overwrite an existing file", function()
    local directory = H.tmpdir()
    local old_path = directory .. "/20250102T030405--old-title.md"
    local new_path = directory .. "/20250102T030405--new-title.md"
    H.write_file(old_path, { "source contents" })
    H.write_file(new_path, { "destination contents" })
    local buffer = edit_file(old_path, directory)

    local ok, err = pcall(Filesystem.replace_file, old_path, new_path)

    H.eq(false, ok)
    H.matches("already exists", err)
    H.eq({ "source contents" }, vim.fn.readfile(old_path))
    H.eq({ "destination contents" }, vim.fn.readfile(new_path))
    H.eq(vim.uv.fs_realpath(old_path), vim.api.nvim_buf_get_name(buffer))

    close_buffer(buffer)
    H.remove(directory)
  end),

  H.test("replace_file reports filesystem errors without removing the source", function()
    local directory = H.tmpdir()
    local old_path = directory .. "/20250102T030405--old-title.md"
    local new_path = directory .. "/missing/20250102T030405--new-title.md"
    H.write_file(old_path, { "source contents" })
    local buffer = edit_file(old_path, directory)

    local ok, err = pcall(Filesystem.replace_file, old_path, new_path)

    H.eq(false, ok)
    H.matches("Cannot rename", err)
    H.truthy(vim.uv.fs_stat(old_path))
    H.eq({ "source contents" }, vim.fn.readfile(old_path))
    H.eq(vim.uv.fs_realpath(old_path), vim.api.nvim_buf_get_name(buffer))

    close_buffer(buffer)
    H.remove(directory)
  end),
}
