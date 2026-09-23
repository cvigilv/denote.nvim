local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Filesystem = require("denote.core.fs")
local Links = require("denote.links")

return {
  H.test("links cache uses canonical file paths as keys", function()
    local directory = H.tmpdir()
    local note = directory .. "/20250102T030405--note.md"
    H.write_file(note, { "# Note" })
    _G.denote_cache_links = {}

    local previous_directory = vim.fn.getcwd()
    vim.fn.chdir(directory)
    local ok, err = pcall(Links.get_links, "./20250102T030405--note.md")
    vim.fn.chdir(previous_directory)

    if not ok then
      H.remove(directory)
      error(err)
    end

    H.eq({}, _G.denote_cache_links[Filesystem.canonical_path(note)])
    H.eq(nil, _G.denote_cache_links["./20250102T030405--note.md"])
    H.remove(directory)
  end),

  H.test("links cache produces backlink locations and titles", function()
    local directory = H.tmpdir()
    local target = directory .. "/20250102T030405--target.md"
    local source = directory .. "/20250102T040506--source.md"
    H.write_file(target, { "# Target" })
    H.write_file(source, {
      "---",
      'title: "Source note"',
      "---",
      string.format("[Target](%s)", target),
    })
    _G.denote_cache_links = {}

    local links = Links.get_links(source)
    local backlinks = Links.get_backlinks(target)

    H.eq({ { path = target, linenr = 4 } }, links)
    H.eq(1, #backlinks)
    H.eq(Filesystem.canonical_path(source), backlinks[1].filename)
    H.eq(4, backlinks[1].lnum)
    H.eq("Source note", backlinks[1].text)
    H.remove(directory)
  end),
}
