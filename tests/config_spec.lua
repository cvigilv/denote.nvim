local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")
local Config = require("denote.config")
local Filesystem = require("denote.core.fs")

local function fails_with(pattern, opts)
  local ok, err = pcall(Config.update_config, opts)
  H.eq(false, ok)
  H.matches(pattern, err)
end

return {
  H.test("configuration applies defaults and normalizes the directory", function()
    local config = Config.update_config({ directory = "/tmp/denote-notes" })

    H.eq(Filesystem.canonical_path("/tmp/denote-notes") .. "/", config.directory)
    H.eq("markdown-toml", config.filetype)
    H.eq({ "title", "keywords" }, config.prompts)
    H.eq(false, config.integrations.oil)
    H.eq({ enabled = false, opts = {} }, config.integrations.telescope)
  end),

  H.test("configuration expands the home directory", function()
    local config = Config.update_config({ directory = "~/notes" })

    H.eq(Filesystem.canonical_path("~/notes") .. "/", config.directory)
  end),

  H.test("configuration preserves telescope options", function()
    local telescope = { enabled = true, opts = { layout_strategy = "vertical" } }
    local config = Config.update_config({
      integrations = { telescope = telescope },
    })

    H.eq(telescope, config.integrations.telescope)
  end),

  H.test("configuration accepts documented filetypes and prompts", function()
    local extensions = {
      org = ".org",
      neorg = ".norg",
      ["markdown-yaml"] = ".md",
      ["markdown-toml"] = ".md",
      text = ".txt",
    }

    for filetype, extension in pairs(extensions) do
      local config = Config.update_config({
        filetype = filetype,
        prompts = { "date", "title", "keywords", "signature", "extension" },
      })
      H.eq(extension, Config.filetype_extension(config.filetype))
    end
  end),

  H.test("configuration rejects unsupported filetypes and prompts", function()
    fails_with("denote%.filetype:.-got pdf", { filetype = "pdf" })
    fails_with("denote%.prompts%[2%]:.-got missing", { prompts = { "title", "missing" } })
  end),

  H.test("configuration rejects malformed telescope options", function()
    fails_with("telescope%.enabled:.-got string", {
      integrations = { telescope = { enabled = "yes", opts = {} } },
    })
    fails_with("telescope%.opts:.-got string", {
      integrations = { telescope = { enabled = true, opts = "vertical" } },
    })
  end),
}
