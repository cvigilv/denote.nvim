local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

return {
  H.test("the Denote command dispatches note creation", function()
    pcall(vim.api.nvim_del_user_command, "Denote")
    vim.g.loaded_denote_plugin = nil
    local directory = H.tmpdir()
    vim.g.denote = {
      directory = directory .. "/",
      prompts = {},
      integrations = { oil = false, telescope = false },
    }

    local called = false
    package.loaded["denote.api"] = {
      denote = function()
        called = true
      end,
    }

    vim.cmd("runtime plugin/denote.lua")
    vim.cmd("Denote")

    H.truthy(vim.api.nvim_get_commands({ builtin = false }).Denote)
    H.eq(true, called)
    package.loaded["denote.api"] = nil
    H.remove(directory)
  end),

  H.test("rename title builds the destination inside the note directory", function()
    local directory = H.tmpdir()
    local old_path = directory .. "/20250102T030405--old-title.md"
    H.write_file(old_path, { "old contents" })
    vim.g.denote = { directory = directory .. "/", prompts = {} }

    local Filesystem = require("denote.core.fs")
    local original_replace_file = Filesystem.replace_file
    local replaced = {}
    Filesystem.replace_file = function(old_filename, new_filename)
      replaced = { old_filename, new_filename }
      return true
    end

    local ok = require("denote.api").rename_file_title(old_path, "New title")
    Filesystem.replace_file = original_replace_file

    H.eq(true, ok)
    H.eq(old_path, replaced[1])
    H.eq(directory .. "/20250102T030405--new-title.md", replaced[2])
    H.remove(directory)
  end),
}
