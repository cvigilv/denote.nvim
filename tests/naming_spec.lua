local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Naming = require("denote.naming")

return {
  H.test("naming generates a complete Denote filename", function()
    local filename = Naming.generate_filename({
      identifier = "20250102T030405",
      signature = "1a",
      title = "Crème brûlée",
      keywords = "Food Recipes",
      extension = ".md",
    })

    H.eq("20250102T030405==1a--creme-brulee__food_recipes.md", filename)
    H.truthy(Naming.is_denote(filename))
  end),

  H.test("naming parses filename components", function()
    local components = Naming.parse_filename(
      "/notes/20250102T030405==1a--creme-brulee__food_recipes.md",
      false
    )

    H.eq("20250102T030405", components.identifier)
    H.eq("1a", components.signature)
    H.eq("creme-brulee", components.title)
    H.eq("food_recipes", components.keywords)
    H.eq(".md", components.extension)
    H.matches("^%[2025%-01%-02 ", components.date)
  end),

  H.test("naming rejects filenames without an identifier", function()
    H.eq(false, Naming.is_denote("ordinary-note.md"))
  end),
}
