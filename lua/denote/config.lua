---@module "denote.config"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

---@class Denote.Integrations.Configuration
---@field oil boolean Activate `stevearc/oil.nvim` extension
---@field telescope boolean Activate `nvim-telescope/telescope.nvim` extension

---@class Denote.Configuration
---@field filetype string? Default note file type
---@field directory string? Denote files directory
---@field add_heading boolean?
---@field retitle_heading boolean?
---@field heading_char string?
---@field integrations Denote.Integrations.Configuration? Extensions configuration

--@type Denote.Configuration
local defaults = {
  filetype = "md",
  directory = "~/notes/",
  add_heading = true,
  retitle_heading = true,
  heading_char = "auto",
  integrations = {
    oil = false,
    telescope = true,
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

  -- Define heading characters for supported filetypes
  if opts.heading_char == "auto" then
    if opts.filetype == "markdown" then
      opts.heading_char = "#"
    elseif opts.filetype == "org" or opts.filetype == "norg" then
      opts.heading_char = "*"
    end
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
    ["add_heading"] = { opts.add_heading, "boolean" },
    ["retitle_heading"] = { opts.add_heading, "boolean" },
    ["heading_char"] = { opts.heading_char, "string" },
    ["integrations.oil"] = { opts.integrations.oil, "boolean" },
    ["integrations.telescope"] = { opts.integrations.telescope, "boolean" },
  })

  return opts
end

return M
