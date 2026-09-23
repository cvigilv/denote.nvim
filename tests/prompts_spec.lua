local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Prompts = require("denote.ui.prompts")

return {
  H.test("prompts pass the current value and trim input", function()
    local original_input = vim.ui.input
    local options
    vim.ui.input = function(opts, callback)
      options = opts
      callback("  Revised title  ")
    end

    local result = Prompts.title("note.md", { title = "Old title" })
    vim.ui.input = original_input

    H.eq("Revised title", result)
    H.eq("[denote] New title: ", options.prompt)
    H.eq("Old title", options.default)
  end),
}
