local test_utils = require("tests.helpers.test_utils")
local filename = require("denote.core.filename")

describe("denote.core.filename", function()
  before_each(function()
    test_utils.setup_test_env()
  end)
  
  after_each(function()
    test_utils.teardown_test_env()
  end)
  describe("parse", function()
    it("should parse complete denote filename", function()
      local components = filename.parse("20240601T120000==sig--title__tag1_tag2.md")
      assert.are.equal("20240601T120000", components.identifier)
      assert.are.equal("sig", components.signature)
      assert.are.equal("title", components.title)
      assert.are.equal("tag1_tag2", components.keywords)
      assert.are.equal(".md", components.extension)
    end)

    it("should parse filename with only identifier and extension", function()
      local components = filename.parse("20240601T120000.txt")
      assert.are.equal("20240601T120000", components.identifier)
      assert.are.equal("", components.signature)
      assert.are.equal("", components.title)
      assert.are.equal("", components.keywords)
      assert.are.equal(".txt", components.extension)
    end)

    it("should parse filename with title but no keywords", function()
      local components = filename.parse("20240601T120000--my-note.org")
      assert.are.equal("20240601T120000", components.identifier)
      assert.are.equal("my-note", components.title)
      assert.are.equal("", components.keywords)
      assert.are.equal(".org", components.extension)
    end)

    it("should return nil for non-denote filename", function()
      local components = filename.parse("regular-file.txt")
      assert.is_nil(components)
    end)
  end)

  describe("is_denote_file", function()
    it("should identify denote files", function()
      assert.is_true(filename.is_denote_file("20240601T120000.md"))
      assert.is_true(filename.is_denote_file("20240601T120000--title.org"))
      assert.is_true(filename.is_denote_file("20240601T120000==sig--title__tags.txt"))
    end)

    it("should reject non-denote files", function()
      assert.is_false(filename.is_denote_file("regular-file.txt"))
      assert.is_false(filename.is_denote_file("2024-06-01-note.md"))
    end)
  end)

  describe("build", function()
    it("should build complete denote filename", function()
      local components = {
        identifier = "20240601T120000",
        signature = "sig",
        title = "my note",
        keywords = "tag1 tag2",
        extension = ".md"
      }
      local result = filename.build(components)
      assert.are.equal("20240601T120000==sig--my-note__tag1_tag2.md", result)
    end)

    it("should build minimal denote filename", function()
      local components = {
        identifier = "20240601T120000",
        extension = ".txt"
      }
      local result = filename.build(components)
      assert.are.equal("20240601T120000.txt", result)
    end)

    it("should handle missing extension", function()
      local components = {
        identifier = "20240601T120000",
        title = "test"
      }
      local result = filename.build(components)
      assert.are.equal("20240601T120000--test.md", result)
    end)
  end)

  describe("update_component", function()
    it("should update title component", function()
      local result = filename.update_component("20240601T120000--old-title.md", "title", "new title")
      assert.are.equal("20240601T120000--new-title.md", result)
    end)

    it("should update keywords component", function()
      local result = filename.update_component("20240601T120000__old_tags.md", "keywords", "new tags")
      assert.are.equal("20240601T120000__new_tags.md", result)
    end)

    it("should return nil for non-denote file", function()
      local result = filename.update_component("regular-file.txt", "title", "new title")
      assert.is_nil(result)
    end)
  end)
end)