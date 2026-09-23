local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

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
}
