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

    H.eq({ { path = Filesystem.canonical_path(target), linenr = 4 } }, links)
    H.eq(1, #backlinks)
    H.eq(Filesystem.canonical_path(source), backlinks[1].filename)
    H.eq(4, backlinks[1].lnum)
    H.eq("Source note", backlinks[1].text)
    H.remove(directory)
  end),

  H.test("relative link targets resolve from their source notes", function()
    local directory = H.tmpdir()
    local target = directory .. "/20250102T030405--target.md"
    local sources = {
      {
        path = directory .. "/markdown/20250102T040506--source.md",
        link = "[Target](../20250102T030405--target.md)",
      },
      {
        path = directory .. "/org/20250102T050607--source.org",
        link = "[[file:../20250102T030405--target.md][Target]]",
      },
      {
        path = directory .. "/neorg/20250102T060708--source.norg",
        link = "{../20250102T030405--target.md}",
      },
    }
    H.write_file(target, { "# Target" })
    _G.denote_cache_links = {}

    for _, source in ipairs(sources) do
      H.write_file(source.path, { source.link })
      H.eq({
        { path = Filesystem.canonical_path(target), linenr = 1 },
      }, Links.get_links(source.path))
    end

    H.eq(3, #Links.get_backlinks(target))
    H.remove(directory)
  end),

  H.test("Denote links still resolve identifiers in the note directory", function()
    local directory = H.tmpdir()
    local identifier = "20250102T030405"
    local target = directory .. "/" .. identifier .. "--target.md"
    local source = directory .. "/nested/20250102T040506--source.org"
    H.write_file(target, { "# Target" })
    H.write_file(source, { string.format("[[denote:%s][Target]]", identifier) })
    _G.denote_cache_links = {}

    local previous_config = vim.g.denote
    local config = vim.deepcopy(previous_config or {})
    config.directory = directory .. "/"
    vim.g.denote = config
    local ok, links = pcall(Links.get_links, source)
    vim.g.denote = previous_config

    if not ok then
      H.remove(directory)
      error(links)
    end

    H.eq({ { path = Filesystem.canonical_path(target), linenr = 1 } }, links)
    H.eq(1, #Links.get_backlinks(target))
    H.remove(directory)
  end),
}
