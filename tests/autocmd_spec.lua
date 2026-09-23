local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Autocmd = require("denote.autocmd")
local Config = require("denote.config")

return {
  H.test("link cache scan retries after the note directory appears", function()
    local parent = H.tmpdir()
    local directory = parent .. "/notes"
    vim.g.denote = Config.update_config({ directory = directory })
    directory = vim.g.denote.directory:sub(1, -2)
    local note = directory .. "/20250102T030405--note.md"
    _G.denote_cache_links = {}

    local original_notify = vim.notify
    local notifications = {}
    vim.notify = function(message, level)
      notifications[#notifications + 1] = { message = message, level = level }
    end

    local ok, err = pcall(function()
      Autocmd.setup()
      vim.api.nvim_exec_autocmds("BufReadPost", { pattern = note })
      H.truthy(vim.wait(1000, function()
        return #notifications > 0
      end))

      H.write_file(note, { "# Note" })
      vim.api.nvim_exec_autocmds("BufReadPost", { pattern = note })
      H.truthy(vim.wait(1000, function()
        return _G.denote_cache_links[note] ~= nil
      end))

      H.matches("Failed to scan note directory", notifications[1].message)
      H.eq(vim.log.levels.ERROR, notifications[1].level)
      H.eq({}, _G.denote_cache_links[note])
    end)

    vim.notify = original_notify
    pcall(vim.api.nvim_del_augroup_by_name, "denote")
    H.remove(parent)
    if not ok then
      error(err)
    end
  end),
}
