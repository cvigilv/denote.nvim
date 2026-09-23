local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Frontmatter = require("denote.frontmatter")

local fields = {
  title = "Test note",
  date = "20250102T030405",
  keywords = { "Lua", "Neovim Plugin" },
  identifier = "20250102T030405",
  signature = "1a",
}

return {
  H.test("frontmatter generates and parses YAML", function()
    local directory = H.tmpdir()
    local path = directory .. "/note.md"
    local generated = Frontmatter.generate_frontmatter(fields, "markdown-yaml")
    H.write_file(path, vim.split(generated, "\n", { trimempty = true }))

    local parsed = Frontmatter.parse_frontmatter(path, "markdown")
    H.eq("Test note", parsed.title)
    H.eq("lua neovimplugin", parsed.keywords)
    H.eq("20250102T030405", parsed.identifier)
    H.remove(directory)
  end),

  H.test("frontmatter generates and parses Org metadata", function()
    local directory = H.tmpdir()
    local path = directory .. "/note.org"
    local generated = Frontmatter.generate_frontmatter(fields, "org")
    H.write_file(path, vim.split(generated, "\n", { trimempty = true }))

    local parsed = Frontmatter.parse_frontmatter(path, "org")
    H.eq("Test note", parsed.title)
    H.eq({ "lua", "neovimplugin" }, parsed.keywords)
    H.eq("1a", parsed.signature)
    H.remove(directory)
  end),

  H.test("frontmatter falls back to plain text", function()
    local generated = Frontmatter.generate_frontmatter(fields, "text")

    H.matches("^title:%s+Test note", generated)
    H.matches("tags:%s+lua%s+neovimplugin", generated)
    H.matches("identifier:%s+20250102T030405", generated)
  end),
}
