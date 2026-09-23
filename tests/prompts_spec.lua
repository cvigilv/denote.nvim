local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Prompts = require("denote.ui.prompts")

return {
  H.test("prompts wait for input and handle cancellation", function()
    local original_input = vim.ui.input
    local requests = {}
    vim.ui.input = function(options, callback)
      requests[#requests + 1] = { options = options, callback = callback }
    end

    local result = "pending"
    Prompts.title("note.md", { title = "Old title" }, function(value)
      result = value
    end)
    local result_before_input = result
    requests[1].callback("  Revised title  ")
    local revised_title = result

    local cancellation_received = false
    Prompts.title("note.md", { title = "Old title" }, function(value)
      cancellation_received = value == nil
    end)
    requests[2].callback(nil)
    vim.ui.input = original_input

    H.eq("pending", result_before_input)
    H.eq("Revised title", revised_title)
    H.eq("[denote] New title: ", requests[1].options.prompt)
    H.eq("Old title", requests[1].options.default)
    H.eq(true, cancellation_received)
  end),
}
