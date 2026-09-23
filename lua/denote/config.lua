---@module "denote.config"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

---@class Denote.Integrations.Telescope.Configuration
---@field enabled boolean
---@field opts table?

---@class Denote.Integrations.Configuration
---@field oil boolean Activate `stevearc/oil.nvim` extension
---@field telescope boolean|Denote.Integrations.Telescope.Configuration

---@class Denote.Configuration
---@field filetype string? Default note file type
---@field directory string? Denote files directory
---@field prompts string[]? File creation/renaming prompt order
---@field integrations Denote.Integrations.Configuration? Extensions configuration

---@type table<string, string>
local FILETYPE_EXTENSIONS = {
  org = ".org",
  neorg = ".norg",
  ["markdown-yaml"] = ".md",
  ["markdown-toml"] = ".md",
  text = ".txt",
}

local PROMPT_NAMES = {
  date = true,
  extension = true,
  keywords = true,
  signature = true,
  title = true,
}

--@type Denote.Configuration
local defaults = {
  filetype = "markdown-toml",
  directory = "~/notes/",
  prompts = { "title", "keywords" }, -- "date", "title", "keywords", "signature", "extension"
  integrations = {
    oil = false,
    telescope = false,
  },
}

---@param opts Denote.Configuration
local function validate_config(opts)
  vim.validate("denote.filetype", opts.filetype, function(value)
    return type(value) == "string" and FILETYPE_EXTENSIONS[value] ~= nil
  end, "supported filetype")
  vim.validate("denote.directory", opts.directory, "string")
  vim.validate("denote.prompts", opts.prompts, function(value)
    return type(value) == "table" and vim.islist(value)
  end, "list")

  for index, prompt in ipairs(opts.prompts) do
    vim.validate(string.format("denote.prompts[%d]", index), prompt, function(value)
      return type(value) == "string" and PROMPT_NAMES[value] == true
    end, "supported prompt name")
  end

  vim.validate("denote.integrations", opts.integrations, "table")
  vim.validate("denote.integrations.oil", opts.integrations.oil, "boolean")
  vim.validate(
    "denote.integrations.telescope",
    opts.integrations.telescope,
    { "boolean", "table" }
  )

  if type(opts.integrations.telescope) == "table" then
    vim.validate(
      "denote.integrations.telescope.enabled",
      opts.integrations.telescope.enabled,
      "boolean"
    )
    vim.validate(
      "denote.integrations.telescope.opts",
      opts.integrations.telescope.opts,
      "table",
      true
    )
  end
end

---@param opts Denote.Configuration
---@return Denote.Configuration
local function normalize_config(opts)
  if opts.directory:sub(-1) ~= "/" then
    opts.directory = opts.directory .. "/"
  end

  if type(opts.integrations.telescope) == "boolean" then
    ---@diagnostic disable-next-line: assign-type-mismatch
    opts.integrations.telescope = { enabled = opts.integrations.telescope, opts = {} }
  else
    opts.integrations.telescope.opts = opts.integrations.telescope.opts or {}
  end

  return opts
end

local M = {}

---@param filetype string
---@return string?
function M.filetype_extension(filetype)
  return FILETYPE_EXTENSIONS[filetype]
end

---Update defaults with user configuration
---@param opts Denote.Configuration|nil User provided configuration table
---@return Denote.Configuration opts Updated default configuration table with user configuration
M.update_config = function(opts)
  vim.validate("denote", opts, "table", true)
  opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  validate_config(opts)
  return normalize_config(opts)
end

return M
