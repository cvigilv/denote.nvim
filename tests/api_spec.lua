local test_utils = require("tests.helpers.test_utils")
local api = require("denote.api")

describe("denote.api", function()
  before_each(function()
    test_utils.setup_test_env()
  end)
  
  after_each(function()
    test_utils.teardown_test_env()
  end)
  local temp_dir

  before_each(function()
    temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    
    _G.denote = {
      config = {
        extension = ".md",
        directory = temp_dir .. "/",
        prompts = { "title", "keywords" },
        frontmatter = false,
        integrations = {
          oil = false,
          telescope = { enabled = false, opts = {} }
        }
      }
    }
  end)

  after_each(function()
    vim.fn.delete(temp_dir, "rf")
    _G.denote = nil
  end)

  describe("create_note", function()
    it("should create note with components", function()
      local components = {
        title = "test note",
        keywords = "tag1 tag2"
      }
      
      -- Mock vim.cmd to avoid actual editor operations
      local original_cmd = vim.cmd
      vim.cmd = function() end
      
      local file_path = api.create_note(components)
      
      vim.cmd = original_cmd
      
      assert.is_truthy(file_path)
      assert.is_truthy(file_path:match("--test-note__tag1_tag2%.md$"))
      assert.are.equal(1, vim.fn.filereadable(file_path))
    end)

    it("should generate timestamp if not provided", function()
      local components = { title = "test" }
      
      local original_cmd = vim.cmd
      vim.cmd = function() end
      
      local file_path = api.create_note(components)
      
      vim.cmd = original_cmd
      
      assert.is_truthy(file_path:match("%d%d%d%d%d%d%d%dT%d%d%d%d%d%d"))
    end)
  end)

  describe("parse_file", function()
    it("should parse denote file", function()
      local file_path = temp_dir .. "/20240601T120000--test-note__tag1_tag2.md"
      vim.fn.writefile({}, file_path)
      
      local components = api.parse_file(file_path)
      assert.are.equal("20240601T120000", components.identifier)
      assert.are.equal("test-note", components.title)
      assert.are.equal("tag1_tag2", components.keywords)
    end)

    it("should return nil for non-denote file", function()
      local file_path = temp_dir .. "/regular-file.txt"
      vim.fn.writefile({}, file_path)
      
      local components = api.parse_file(file_path)
      assert.is_nil(components)
    end)
  end)

  describe("is_denote_file", function()
    it("should identify denote files", function()
      local file_path = temp_dir .. "/20240601T120000.md"
      vim.fn.writefile({}, file_path)
      
      assert.is_true(api.is_denote_file(file_path))
    end)

    it("should reject non-denote files", function()
      local file_path = temp_dir .. "/regular-file.txt"
      vim.fn.writefile({}, file_path)
      
      assert.is_false(api.is_denote_file(file_path))
    end)
  end)
end)