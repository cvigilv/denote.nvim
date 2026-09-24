local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

local root = vim.g.denote_test_root
local help_path = vim.fs.joinpath(root, "docs", "denote.txt")
local tags_path = vim.fs.joinpath(root, "docs", "tags")

return {
  H.test("documentation states the supported Neovim version", function()
    local requirement = "Neovim 0.11 or newer"
    local readme = table.concat(vim.fn.readfile(vim.fs.joinpath(root, "README.md")), "\n")
    local help = table.concat(vim.fn.readfile(help_path), "\n")

    H.truthy(readme:find(requirement, 1, true))
    H.truthy(help:find(requirement, 1, true))
  end),

  H.test("help tags are current", function()
    local expected = {}
    for _, line in ipairs(vim.fn.readfile(help_path)) do
      for tag in line:gmatch("%*([^%s*]+)%*") do
        expected[#expected + 1] = string.format("%s\tdenote.txt\t/*%s*", tag, tag)
      end
    end
    table.sort(expected)

    H.eq(expected, vim.fn.readfile(tags_path))
  end),

  H.test("internal help links resolve", function()
    local tags = {}
    for _, line in ipairs(vim.fn.readfile(tags_path)) do
      tags[line:match("^[^\t]+") or ""] = true
    end

    local missing = {}
    for _, line in ipairs(vim.fn.readfile(help_path)) do
      for link in line:gmatch("|([^|%s]+)|") do
        if vim.startswith(link, "denote") and not tags[link] then
          missing[#missing + 1] = link
        end
      end
    end

    H.eq({}, missing)
  end),
}
