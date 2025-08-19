local test_utils = require("tests.helpers.test_utils")
local config = require("denote.config")

describe("denote.config", function()
  before_each(function()
    test_utils.setup_test_env()
  end)
  
  after_each(function()
    test_utils.teardown_test_env()
  end)
  describe("setup", function()
    it("should use default configuration", function()
      local cfg = config.setup()
      assert.are.equal(".md", cfg.extension)
      assert.is_truthy(cfg.directory:match("notes/?$"))
      assert.are.same({ "title", "keywords" }, cfg.prompts)
      assert.is_false(cfg.frontmatter)
      assert.is_false(cfg.integrations.oil)
      assert.is_false(cfg.integrations.telescope.enabled)
    end)

    it("should merge user configuration", function()
      local user_config = {
        extension = ".org",
        frontmatter = true,
        prompts = { "title", "signature", "keywords" }
      }
      local cfg = config.setup(user_config)
      assert.are.equal(".org", cfg.extension)
      assert.is_true(cfg.frontmatter)
      assert.are.same({ "title", "signature", "keywords" }, cfg.prompts)
    end)

    it("should normalize directory path", function()
      local cfg = config.setup({ directory = "~/my-notes" })
      assert.is_truthy(cfg.directory:match("/$"))
    end)

    it("should normalize extension", function()
      local cfg = config.setup({ extension = "org" })
      assert.are.equal(".org", cfg.extension)
    end)

    it("should handle telescope configuration", function()
      local cfg = config.setup({
        integrations = {
          telescope = true
        }
      })
      assert.is_true(cfg.integrations.telescope.enabled)
      assert.are.same({}, cfg.integrations.telescope.opts)

      cfg = config.setup({
        integrations = {
          telescope = { enabled = true, opts = { theme = "dropdown" } }
        }
      })
      assert.is_true(cfg.integrations.telescope.enabled)
      assert.are.equal("dropdown", cfg.integrations.telescope.opts.theme)
    end)

    it("should validate configuration", function()
      assert.has_error(function()
        config.setup({ extension = ".invalid" })
      end)

      assert.has_error(function()
        config.setup({ prompts = { "invalid_prompt" } })
      end)
    end)
  end)
end)