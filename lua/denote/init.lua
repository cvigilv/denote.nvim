local M = {}

---Setup denote plugin
---@param user_config Denote.Config?
function M.setup(user_config)
	local log = require("denote.logging")
	log.info("setup: initializing denote plugin")

	_G.denote = {}

	local config = require("denote.config").setup(user_config)
	_G.denote.config = config
	log.debug("setup: configuration stored globally")

	if config.integrations.oil then
		log.debug("setup: initializing oil integration")
		require("denote.integrations.oil").setup(config)
	end

	if config.integrations.telescope and config.integrations.telescope.enabled then
		log.debug("setup: initializing telescope integration")
		require("denote.integrations.telescope").setup(config)
	end

	log.debug("setup: setting up commands")
	require("denote.commands").setup(config)

	log.info("setup: denote plugin initialization complete")
end

-- Export API functions
M.create_note = require("denote.api").create_note
M.update_title = require("denote.api").update_title
M.update_keywords = require("denote.api").update_keywords
M.update_signature = require("denote.api").update_signature
M.update_extension = require("denote.api").update_extension
M.rename_file = require("denote.api").rename_file
M.parse_file = require("denote.api").parse_file
M.is_denote_file = require("denote.api").is_denote_file

-- Export core modules for advanced usage
M.core = {
	filename = require("denote.core.filename"),
	frontmatter = require("denote.core.frontmatter"),
	file = require("denote.core.file"),
	utils = require("denote.core.utils"),
}

return M
