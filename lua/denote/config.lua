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
---@field integrations Denote.Integrations.Configuration? Extensions configuration

--@type Denote.Configuration
local defaults = {
  filetype = "md",
  directory = "~/notes/",
  integrations = {
    oil = false,
    telescope = false
  },
}

---Update configuration based on rules
---@param opts Denote.Configuration User provided configuration table
---@return Denote.Configuration opts Updated default configuration table with user configuration
local function update_auto_options(opts)
  -- Add trailing "/" to notes directory
  if opts.directory:sub(-1) ~= "/" then
    opts["directory"] = opts.directory .. "/"
  end

  if type(opts.integrations.telescope) == "boolean" then
    ---@diagnostic disable-next-line: assign-type-mismatch
    opts.integrations.telescope = { enabled = opts.integrations.telescope, opts = {} }
  end

  return opts
end

local M = {}

---Update defaults with user configuration
---@param opts Denote.Configuration|nil User provided configuration table
---@return Denote.Configuration opts Updated default configuration table with user configuration
M.update_config = function(opts)
  -- Merge-in user configuration to default configuration
  opts = opts and vim.tbl_deep_extend("force", {}, defaults, opts) or defaults

  -- Define automatic options
  opts = update_auto_options(opts)

  -- Validate setup
  vim.validate({
    ["filetype"] = { opts.filetype, "string" },
    ["directory"] = { opts.directory, "string" },
    ["integrations.oil"] = { opts.integrations.oil, "boolean" },
    ["integrations.telescope"] = { opts.integrations.telescope, "table" },
  })

  return opts
end

return M
