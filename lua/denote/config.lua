---@module "denote.config"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local M = {}

---@class Denote.TelescopeConfig
---@field enabled boolean
---@field opts table?

---@class Denote.IntegrationsConfig
---@field oil boolean
---@field telescope boolean|Denote.TelescopeConfig

---@class Denote.Config
---@field extension string Default file extension
---@field directory string Notes directory
---@field prompts string[] Prompts for note creation
---@field frontmatter boolean Generate frontmatter
---@field integrations Denote.IntegrationsConfig

---@type Denote.Config
local defaults = {
	extension = ".md",
	directory = "~/notes/",
	prompts = { "title", "keywords" },
	frontmatter = false,
	integrations = {
		oil = false,
		telescope = false,
	},
}

---Normalize configuration
---@param config Denote.Config
---@return Denote.Config
local function normalize_config(config)
	log.debug("normalize_config: normalizing config =", config)

	local original_dir = config.directory
	if config.directory:sub(-1) ~= "/" then
		config.directory = config.directory .. "/"
		log.trace("normalize_config: added trailing slash to directory")
	end

	config.directory = vim.fn.expand(config.directory)
	log.trace("normalize_config: expanded directory from", original_dir, "to", config.directory)

	local original_ext = config.extension
	if not config.extension:match("^%.") then
		config.extension = "." .. config.extension
		log.trace("normalize_config: added dot to extension from", original_ext, "to", config.extension)
	end

	if type(config.integrations.telescope) == "boolean" then
		local old_value = config.integrations.telescope
		config.integrations.telescope = {
			enabled = config.integrations.telescope,
			opts = {},
		}
		log.trace("normalize_config: converted telescope boolean", old_value, "to table", config.integrations.telescope)
	end

	log.debug("normalize_config: normalized config =", config)
	return config
end

---Validate configuration
---@param config Denote.Config
local function validate_config(config)
	log.debug("validate_config: validating config")

	local validation_spec = {
		extension = { config.extension, "string" },
		directory = { config.directory, "string" },
		prompts = { config.prompts, "table" },
		frontmatter = { config.frontmatter, "boolean" },
		["integrations.oil"] = { config.integrations.oil, "boolean" },
		["integrations.telescope"] = { config.integrations.telescope, "table" },
	}

	local success, err = pcall(vim.validate, validation_spec)
	if not success then
		log.error("validate_config: validation failed =", err)
		error("Configuration validation failed: " .. err)
	end

	local valid_prompts = { "title", "keywords", "signature", "date", "extension" }
	for _, prompt in ipairs(config.prompts) do
		if not vim.tbl_contains(valid_prompts, prompt) then
			log.error("validate_config: invalid prompt =", prompt, "valid prompts =", valid_prompts)
			error("Invalid prompt: " .. prompt)
		end
	end
	log.trace("validate_config: all prompts are valid")

	local supported_extensions = { ".md", ".org", ".txt", ".norg" }
	if not vim.tbl_contains(supported_extensions, config.extension) then
		log.error("validate_config: unsupported extension =", config.extension, "supported =", supported_extensions)
		error("Unsupported extension: " .. config.extension)
	end
	log.trace("validate_config: extension is supported")

	log.info("validate_config: configuration is valid")
end

---Setup configuration
---@param user_config Denote.Config?
---@return Denote.Config
function M.setup(user_config)
	log.info("setup: setting up denote configuration")
	log.debug("setup: user_config =", user_config)
	log.debug("setup: defaults =", defaults)

	local config = vim.tbl_deep_extend("force", {}, defaults, user_config or {})
	log.trace("setup: merged config =", config)

	config = normalize_config(config)
	validate_config(config)

	log.info("setup: configuration setup complete")
	return config
end

---Get current configuration
---@return Denote.Config?
function M.get()
	local config = _G.denote and _G.denote.config or nil
	if not config then
		log.warn("get: no configuration found - plugin may not be initialized")
	else
		log.trace("get: returning config =", config)
	end
	return config
end

return M
