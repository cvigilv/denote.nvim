---@module "denote.commands"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local api = require("denote.api")

local M = {}

---Setup Denote commands
---@param config Denote.Config
function M.setup(config)
	log.info("setup: setting up Denote user commands")

	vim.api.nvim_create_user_command("Denote", function(opts)
		local subcommand = opts.fargs[1]
		log.info("command: executing Denote subcommand =", subcommand)

		local success, err = pcall(function()
			if subcommand == "note" then
				log.debug("command: calling create_note")
				api.create_note()
			elseif subcommand == "title" then
				log.debug("command: calling update_title")
				api.update_title()
			elseif subcommand == "keywords" then
				log.debug("command: calling update_keywords")
				api.update_keywords()
			elseif subcommand == "signature" then
				log.debug("command: calling update_signature")
				api.update_signature()
			elseif subcommand == "extension" then
				log.debug("command: calling update_extension")
				api.update_extension()
			elseif subcommand == "rename" then
				log.debug("command: calling rename_file")
				api.rename_file()
			elseif subcommand == "search" and config.integrations.telescope.enabled then
				log.debug("command: calling telescope search")
				require("denote.integrations.telescope").search()
			elseif subcommand == "link" and config.integrations.telescope.enabled then
				log.debug("command: calling telescope insert_link")
				require("denote.integrations.telescope").insert_link()
			else
				local msg = "[denote] Unknown subcommand: " .. (subcommand or "")
				log.error("command:", msg)
				vim.notify(msg, vim.log.levels.ERROR)
			end
		end)

		if not success then
			log.error("command: failed to execute subcommand =", subcommand, "error =", err)
			vim.notify("[denote] Error: " .. err, vim.log.levels.ERROR)
		else
			log.info("command: successfully executed subcommand =", subcommand)
		end
	end, {
		nargs = 1,
		complete = function()
			local commands = { "note", "title", "keywords", "signature", "extension", "rename" }

			if config.integrations.telescope.enabled then
				vim.list_extend(commands, { "search", "link" })
				log.trace("command: added telescope commands to completion")
			end

			log.trace("command: providing completion options =", commands)
			return commands
		end,
	})

	log.info("setup: Denote user commands configured successfully")
end

return M
