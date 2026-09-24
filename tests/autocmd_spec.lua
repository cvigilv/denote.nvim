local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Autocmd = require("denote.autocmd")
local Config = require("denote.config")
local Filesystem = require("denote.core.fs")
local Links = require("denote.links")
local uv = vim.uv or vim.loop

local function oil_autocmds()
  local result = {}
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = "denote" })) do
    if autocmd.desc == "Add file path highlighting to current Oil buffer" then
      result[#result + 1] = autocmd
    end
  end
  return result
end

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
      H.eq(1, #notifications)
      H.eq({}, _G.denote_cache_links[note])
    end)

    vim.notify = original_notify
    pcall(vim.api.nvim_del_augroup_by_name, "denote")
    H.remove(parent)
    if not ok then
      error(err)
    end
  end),

  H.test("text note writes refresh the links cache", function()
    local directory = H.tmpdir()
    vim.g.denote = Config.update_config({ directory = directory })
    directory = vim.g.denote.directory:sub(1, -2)
    local note = directory .. "/20250102T030405--note.txt"
    H.write_file(note, { "Plain text" })
    _G.denote_cache_links = {}

    local ok, err = pcall(function()
      Autocmd.setup()
      vim.api.nvim_exec_autocmds("BufWritePost", { pattern = note })
      H.eq({}, _G.denote_cache_links[note])
    end)

    pcall(vim.api.nvim_del_augroup_by_name, "denote")
    H.remove(directory)
    if not ok then
      error(err)
    end
  end),

  H.test("closing a deleted note removes its cache entry", function()
    local directory = H.tmpdir()
    vim.g.denote = Config.update_config({ directory = directory })
    directory = vim.g.denote.directory:sub(1, -2)
    local note = directory .. "/20250102T030405--note.md"
    H.write_file(note, { "# Note" })
    local cache_path = Filesystem.canonical_path(note)
    _G.denote_cache_links = {}

    local buffer
    local ok, err = pcall(function()
      Autocmd.setup()
      Links.get_links(note)
      buffer = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buffer, note)
      H.truthy(uv.fs_unlink(note))
      vim.api.nvim_buf_delete(buffer, { force = true })
      H.eq(nil, _G.denote_cache_links[cache_path])
    end)

    if buffer and vim.api.nvim_buf_is_valid(buffer) then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
    pcall(vim.api.nvim_del_augroup_by_name, "denote")
    H.remove(directory)
    if not ok then
      error(err)
    end
  end),

  H.test("disabled Oil integration registers no autocmd", function()
    local directory = H.tmpdir()
    vim.g.denote = Config.update_config({
      directory = directory,
      integrations = { oil = false },
    })

    local ok, err = pcall(function()
      Autocmd.setup()
      H.eq({}, oil_autocmds())
    end)

    pcall(vim.api.nvim_del_augroup_by_name, "denote")
    H.remove(directory)
    if not ok then
      error(err)
    end
  end),

  H.test("enabled Oil integration matches the canonical directory", function()
    local directory = H.tmpdir()
    vim.g.denote = Config.update_config({
      directory = directory .. "/.",
      integrations = { oil = true },
    })
    local expected_pattern = "oil://" .. vim.g.denote.directory
    local original_highlights = package.loaded["denote.ui.highlights"]
    local setup_calls = 0
    package.loaded["denote.ui.highlights"] = {
      setup = function()
        setup_calls = setup_calls + 1
      end,
    }

    local ok, err = pcall(function()
      Autocmd.setup()
      local autocmds = oil_autocmds()
      H.eq(1, #autocmds)
      H.eq(expected_pattern, autocmds[1].pattern)

      vim.api.nvim_exec_autocmds("BufReadPost", { pattern = expected_pattern })
      H.eq(1, setup_calls)
    end)

    package.loaded["denote.ui.highlights"] = original_highlights
    pcall(vim.api.nvim_del_augroup_by_name, "denote")
    H.remove(directory)
    if not ok then
      error(err)
    end
  end),
}
