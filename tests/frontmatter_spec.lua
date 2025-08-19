local test_utils = require("tests.helpers.test_utils")
local frontmatter = require("denote.core.frontmatter")

describe("denote.core.frontmatter", function()
  before_each(function()
    test_utils.setup_test_env()
  end)
  
  after_each(function()
    test_utils.teardown_test_env()
  end)
  local test_components = {
    identifier = "20240601T120000",
    title = "my-test-note",
    keywords = "tag1_tag2_tag3",
    signature = "sig=test",
    date = "[2024-06-01 Sat 12:00:00]",
    extension = ".md"
  }

  describe("generate_org", function()
    it("should generate org-mode frontmatter", function()
      local result = frontmatter.generate_org(test_components)
      assert.are.equal("#+title: my test note", result[1])
      assert.are.equal("#+date: [2024-06-01 Sat 12:00:00]", result[2])
      assert.are.equal("#+filetags: tag1 tag2 tag3", result[3])
      assert.are.equal("#+signature: sig test", result[4])
      assert.are.equal("#+identifier: 20240601T120000", result[5])
      assert.are.equal("", result[6])
    end)

    it("should handle minimal components", function()
      local minimal = { identifier = "20240601T120000" }
      local result = frontmatter.generate_org(minimal)
      assert.are.equal("#+identifier: 20240601T120000", result[1])
    end)
  end)

  describe("generate_markdown", function()
    it("should generate markdown YAML frontmatter", function()
      local result = frontmatter.generate_markdown(test_components)
      assert.are.equal("---", result[1])
      assert.are.equal('title: "my test note"', result[2])
      assert.are.equal("date: [2024-06-01 Sat 12:00:00]", result[3])
      assert.are.equal('tags: ["tag1", "tag2", "tag3"]', result[4])
      assert.are.equal('signature: "sig test"', result[5])
      assert.are.equal("id: 20240601T120000", result[6])
      assert.are.equal("---", result[7])
      assert.are.equal("", result[8])
    end)
  end)

  describe("generate_text", function()
    it("should generate text frontmatter", function()
      local result = frontmatter.generate_text(test_components)
      assert.are.equal("title: my test note", result[1])
      assert.are.equal("date: [2024-06-01 Sat 12:00:00]", result[2])
      assert.are.equal("keywords: tag1 tag2 tag3", result[3])
      assert.are.equal("signature: sig test", result[4])
      assert.are.equal("id: 20240601T120000", result[5])
      assert.are.equal("", result[6])
    end)
  end)

  describe("generate", function()
    it("should generate appropriate frontmatter by extension", function()
      local org_result = frontmatter.generate(test_components, ".org")
      assert.is_truthy(org_result[1]:match("^#+title:"))

      local md_result = frontmatter.generate(test_components, ".md")
      assert.are.equal("---", md_result[1])

      local txt_result = frontmatter.generate(test_components, ".txt")
      assert.is_truthy(txt_result[1]:match("^title:"))

      local unknown_result = frontmatter.generate(test_components, ".unknown")
      assert.are.equal(0, #unknown_result)
    end)
  end)
end)