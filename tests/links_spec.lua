local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Links = require("denote.links")

return {
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
    H.eq(source, backlinks[1].filename)
    H.eq(4, backlinks[1].lnum)
    H.eq("Source note", backlinks[1].text)
    H.remove(directory)
  end),
}
