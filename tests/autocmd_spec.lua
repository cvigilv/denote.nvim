local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Autocmd = require("denote.autocmd")
local Config = require("denote.config")
local Filesystem = require("denote.core.fs")
local Links = require("denote.links")
local uv = vim.uv or vim.loop

local function unload_plugin()
  pcall(vim.api.nvim_del_user_command, "Denote")
  pcall(vim.api.nvim_del_augroup_by_name, "denote")
  package.loaded["denote.ui.highlights"] = nil
  vim.g.loaded_denote_plugin = nil
end

local function with_plugin(config, highlights, run)
  local directory = H.tmpdir()
  local previous_config = vim.g.denote
  config.directory = directory
  unload_plugin()
  package.loaded["denote.ui.highlights"] = highlights
  vim.g.denote = config

  local ok, err = pcall(function()
    vim.cmd("runtime plugin/denote.lua")
    run()
  end)

  unload_plugin()
  vim.g.denote = previous_config
  H.remove(directory)
  if not ok then
    error(err)
  end
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

  H.test("disabled filename highlights skip setup", function()
    local setup_calls = 0
    local highlights = {
      setup = function()
        setup_calls = setup_calls + 1
      end,
    }

    with_plugin({ integrations = { highlights = false } }, highlights, function()
      H.eq(0, setup_calls)
    end)
  end),

  H.test("enabled filename highlights define syntax matches", function()
    with_plugin({ integrations = { highlights = true } }, nil, function()
      H.matches("Denote%s+xxx%s+match", vim.fn.execute("syntax list Denote"))
      H.matches("contained", vim.fn.execute("syntax list DenoteDate"))
    end)
  end),
}
