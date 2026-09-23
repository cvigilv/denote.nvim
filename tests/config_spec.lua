local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Config = require("denote.config")

return {
  H.test("configuration applies defaults and normalizes the directory", function()
    local config = Config.update_config({ directory = "/tmp/denote-notes" })

    H.eq("/tmp/denote-notes/", config.directory)
    H.eq("markdown-toml", config.filetype)
    H.eq({ "title", "keywords" }, config.prompts)
    H.eq(false, config.integrations.oil)
    H.eq({ enabled = false, opts = {} }, config.integrations.telescope)
  end),

  H.test("configuration preserves telescope options", function()
    local telescope = { enabled = true, opts = { layout_strategy = "vertical" } }
    local config = Config.update_config({
      integrations = { telescope = telescope },
    })

    H.eq(telescope, config.integrations.telescope)
  end),
}
