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
    H.eq("1a", parsed.signature)
    H.remove(directory)
  end),

  H.test("frontmatter generates and parses TOML", function()
    local directory = H.tmpdir()
    local path = directory .. "/note.md"
    local generated = Frontmatter.generate_frontmatter(fields, "markdown-toml")
    H.write_file(path, vim.split(generated, "\n", { trimempty = true }))

    local parsed = Frontmatter.parse_frontmatter(path, "markdown")
    H.eq("Test note", parsed.title)
    H.eq("lua neovimplugin", parsed.keywords)
    H.eq("20250102T030405", parsed.identifier)
    H.eq("1a", parsed.signature)
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

  H.test("frontmatter generates and parses Neorg metadata", function()
    local directory = H.tmpdir()
    local path = directory .. "/note.norg"
    local generated = Frontmatter.generate_frontmatter(fields, "neorg")
    H.write_file(path, vim.split(generated, "\n", { trimempty = true }))

    local parsed = Frontmatter.parse_frontmatter(path)
    H.eq("Test note", parsed.title)
    H.eq("lua neovimplugin", parsed.keywords)
    H.eq("20250102T030405", parsed.identifier)
    H.eq("1a", parsed.signature)
    H.remove(directory)
  end),

  H.test("Neorg metadata parses multi-line categories", function()
    local directory = H.tmpdir()
    local path = directory .. "/note.norg"
    H.write_file(path, {
      "@document.meta",
      "title: Test note",
      "categories: [",
      "  lua",
      "  neovim",
      "]",
      "created: 2025-01-02",
      "@end",
      "",
      "body: not metadata",
    })

    local parsed = Frontmatter.parse_frontmatter(path)
    H.eq("lua neovim", parsed.keywords)
    H.eq("2025-01-02", parsed.date)
    H.eq(nil, parsed.body)
    H.remove(directory)
  end),

  H.test("frontmatter supports Neorg and plain text", function()
    local neorg = Frontmatter.generate_frontmatter(fields, "neorg")
    local text = Frontmatter.generate_frontmatter(fields, "text")

    H.matches("^@document%.meta", neorg)
    H.matches("categories:%s+lua%s+neovimplugin", neorg)
    H.matches("identifier:%s+20250102T030405", neorg)
    H.matches("^title:%s+Test note", text)
    H.matches("tags:%s+lua%s+neovimplugin", text)
    H.matches("identifier:%s+20250102T030405", text)
    H.matches("signature:%s+1a", neorg)
    H.matches("signature:%s+1a", text)
  end),

  H.test("frontmatter omits an empty signature", function()
    local unsigned = vim.tbl_extend("force", fields, { signature = "" })
    for _, filetype in ipairs({ "org", "markdown-yaml", "markdown-toml", "neorg", "text" }) do
      local generated = Frontmatter.generate_frontmatter(unsigned, filetype)
      H.eq(nil, generated:find("signature", 1, true))
    end
  end),

  H.test("frontmatter signature matches the filename component", function()
    local spaced = vim.tbl_extend("force", fields, { signature = "1 a" })
    H.matches("#%+signature:%s+1=a\n", Frontmatter.generate_frontmatter(spaced, "org"))
    H.matches('signature%s+= "1=a"', Frontmatter.generate_frontmatter(spaced, "markdown-toml"))
  end),
}
