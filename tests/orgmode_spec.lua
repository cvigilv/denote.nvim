local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Filesystem = require("denote.core.fs")
local OrgLinkDenote = require("denote.extensions.orgmode")

return {
  H.test("Orgmode completes every supported note extension", function()
    local directory = H.tmpdir()
    local filenames = {
      "20250102T030405--markdown.md",
      "20250102T040506--neorg.norg",
      "20250102T050607--org.org",
      "20250102T060708--text.txt",
      "20250102T070809--unsupported.pdf",
      "ordinary.md",
    }
    for _, filename in ipairs(filenames) do
      H.write_file(directory .. "/" .. filename, { "Note" })
    end

    local source = OrgLinkDenote:new({ files = directory })
    local completions = source:autocomplete({
      base = "denote:20250102T0",
      matcher = function(value, pattern)
        return vim.startswith(value, pattern)
      end,
    })

    H.eq({
      "denote:20250102T030405",
      "denote:20250102T040506",
      "denote:20250102T050607",
      "denote:20250102T060708",
    }, completions)
    H.remove(directory)
  end),

  H.test("Orgmode validates its files option", function()
    local missing_ok, missing_error = pcall(OrgLinkDenote.new, OrgLinkDenote, {})
    local type_ok, type_error = pcall(OrgLinkDenote.new, OrgLinkDenote, { files = {} })

    H.eq(false, missing_ok)
    H.matches("denote%.orgmode%.files:.-got nil", missing_error)
    H.eq(false, type_ok)
    H.matches("denote%.orgmode%.files:.-got table", type_error)
  end),

  H.test("Orgmode follows Denote links in its files directory", function()
    local directory = H.tmpdir()
    local identifier = "20250102T030405"
    local path = directory .. "/" .. identifier .. "--org-link.md"
    H.write_file(path, { "# Linked note" })

    local command
    local original_cmd = vim.cmd
    vim.cmd = function(value)
      command = value
    end

    local source = OrgLinkDenote:new({ files = directory })
    local followed = source:follow("denote:" .. identifier)
    vim.cmd = original_cmd

    H.eq(true, followed)
    H.matches("^edit ", command)
    H.eq(Filesystem.canonical_path(path), Filesystem.canonical_path(command:sub(6)))
    H.remove(directory)
  end),

  H.test("Orgmode opens external files with Neovim", function()
    local directory = H.tmpdir()
    local identifier = "20250102T030405"
    local path = directory .. "/" .. identifier .. "--attachment.pdf"
    H.write_file(path, { "PDF" })
    local expected_path = Filesystem.canonical_path(path)

    local opened
    local notification
    local original_open = vim.ui.open
    local original_notify = vim.notify
    vim.ui.open = function(filepath)
      opened = filepath
      return {}
    end
    vim.notify = function(message, level)
      notification = { message = message, level = level }
    end

    local source = OrgLinkDenote:new({ files = directory })
    local followed = source:follow("denote:" .. identifier)
    vim.ui.open = original_open
    vim.notify = original_notify

    H.eq(true, followed)
    H.eq(expected_path, Filesystem.canonical_path(opened))
    H.eq({ message = "[denote] Opening " .. opened, level = vim.log.levels.INFO }, notification)
    H.remove(directory)
  end),

  H.test("Orgmode reports external file launcher failures", function()
    local directory = H.tmpdir()
    local identifier = "20250102T030405"
    local path = directory .. "/" .. identifier .. "--attachment.pdf"
    H.write_file(path, { "PDF" })
    local expected_path = Filesystem.canonical_path(path)

    local opened
    local notification
    local original_open = vim.ui.open
    local original_notify = vim.notify
    vim.ui.open = function(filepath)
      opened = filepath
      return nil, "no system opener"
    end
    vim.notify = function(message, level)
      notification = { message = message, level = level }
    end

    local source = OrgLinkDenote:new({ files = directory })
    local followed = source:follow("denote:" .. identifier)
    vim.ui.open = original_open
    vim.notify = original_notify

    H.eq(false, followed)
    H.eq(expected_path, Filesystem.canonical_path(opened))
    H.eq({
      message = "[denote] Failed to open " .. opened .. ": no system opener",
      level = vim.log.levels.ERROR,
    }, notification)
    H.remove(directory)
  end),
}
