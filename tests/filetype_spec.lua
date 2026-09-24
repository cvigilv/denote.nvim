local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Autocmd = require("denote.autocmd")
local Config = require("denote.config")

return {
  H.test("filetype detection marks Denote notes", function()
    local directory = H.tmpdir()
    local path = directory .. "/20250102T030405--detected.md"
    H.write_file(path, { "# Detected" })
    vim.g.denote = { directory = directory .. "/" }

    vim.cmd("runtime ftdetect/denote.lua")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.bo.filetype = "markdown"
    vim.api.nvim_exec_autocmds("BufRead", { buffer = 0, modeline = false })

    H.eq("markdown.denote", vim.bo.filetype)
    H.remove(directory)
  end),

  H.test("filetype detection leaves ordinary files unchanged", function()
    local directory = H.tmpdir()
    local path = directory .. "/ordinary.md"
    H.write_file(path, { "# Ordinary" })
    vim.g.denote = { directory = directory .. "/" }

    vim.cmd("runtime ftdetect/denote.lua")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.bo.filetype = "markdown"
    vim.api.nvim_exec_autocmds("BufRead", { buffer = 0, modeline = false })

    H.eq("markdown", vim.bo.filetype)
    H.remove(directory)
  end),

  H.test("filetype detection rejects malformed Denote names", function()
    local directory = H.tmpdir()
    local path = directory .. "/20250102T030405--title.md.bak"
    H.write_file(path, { "# Malformed" })
    vim.g.denote = { directory = directory .. "/" }

    vim.cmd("runtime ftdetect/denote.lua")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.bo.filetype = "markdown"
    vim.api.nvim_exec_autocmds("BufRead", { buffer = 0, modeline = false })

    H.eq("markdown", vim.bo.filetype)
    H.remove(directory)
  end),

  H.test("filetype detection works before setup", function()
    local directory = H.tmpdir()
    local path = directory .. "/20250102T030405--unconfigured.md"
    H.write_file(path, { "# Unconfigured" })
    vim.g.denote = nil

    vim.cmd("runtime ftdetect/denote.lua")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.bo.filetype = "markdown"
    vim.api.nvim_exec_autocmds("BufRead", { buffer = 0, modeline = false })

    H.eq("markdown.denote", vim.bo.filetype)
    H.remove(directory)
  end),

  H.test("filetype detection is idempotent outside the note directory", function()
    local directory = H.tmpdir()
    local path = directory .. "/archive/20250102T030405--outside.md"
    H.write_file(path, { "# Outside" })
    vim.g.denote = { directory = directory .. "/notes/" }

    vim.cmd("runtime ftdetect/denote.lua")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.bo.filetype = "markdown"

    local detection = vim.api.nvim_get_autocmds({ group = "denote_ftdetect" })[1].callback
    local event = { buf = vim.api.nvim_get_current_buf(), file = path }
    detection(event)
    detection(event)

    H.eq("markdown.denote", vim.bo.filetype)
    H.remove(directory)
  end),

  H.test("reloading filetype detection preserves plugin autocommands", function()
    local directory = H.tmpdir()
    vim.g.denote = Config.update_config({ directory = directory })
    Autocmd.setup()

    local before = vim.tbl_map(function(autocmd)
      return autocmd.id
    end, vim.api.nvim_get_autocmds({ group = "denote" }))

    vim.cmd("runtime ftdetect/denote.lua")
    vim.cmd("runtime ftdetect/denote.lua")

    local after = vim.tbl_map(function(autocmd)
      return autocmd.id
    end, vim.api.nvim_get_autocmds({ group = "denote" }))

    H.eq(before, after)
    pcall(vim.api.nvim_del_augroup_by_name, "denote")
    H.remove(directory)
  end),
}
