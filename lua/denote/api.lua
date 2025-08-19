---@module "denote.api"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local config = require("denote.config")
local file = require("denote.core.file")
local filename = require("denote.core.filename")
local ui = require("denote.ui")
local utils = require("denote.core.utils")

local M = {}

---Create a new denote note
---@param user_components Denote.FileComponents?
---@return string? file_path
function M.create_note(user_components)
	log.info("create_note: starting note creation with user_components =", user_components)

	local cfg = config.get()
	if not cfg then
		log.error("create_note: plugin not configured")
		error("[denote] Plugin not configured. Call require('denote').setup() first.")
	end

	log.debug("create_note: using config =", { directory = cfg.directory, extension = cfg.extension })

	user_components = user_components or {}
	local components = {}

	if not user_components.identifier then
		components.identifier = utils.generate_timestamp()
		log.debug("create_note: generated identifier =", components.identifier)
	end

	if vim.tbl_isempty(user_components) then
		log.debug("create_note: no user components provided, collecting prompts")
		local prompt_components = ui.collect_prompts(cfg)
		components = vim.tbl_extend("force", components, prompt_components)
		log.trace("create_note: collected from prompts =", prompt_components)
	else
		log.debug("create_note: using provided user components")
		components = vim.tbl_extend("force", components, user_components)
	end

	components.extension = components.extension or cfg.extension
	log.info("create_note: final components =", components)

	local file_path = file.create(cfg, components)
	log.info("create_note: created file, opening in editor")
	file.open(file_path, true)
	log.info("create_note: successfully created and opened note =", file_path)
	return file_path
end

---Update note title
---@param file_path string?
---@param title string?
---@return string? new_path
function M.update_title(file_path, title)
	file_path = file_path or vim.fn.expand("%:p")
	log.info("update_title: updating title for file =", file_path, "new title =", title)

	local filename_only = vim.fn.fnamemodify(file_path, ":t")
	if not filename.is_denote_file(filename_only) then
		log.error("update_title: not a denote file =", filename_only)
		error("[denote] Not a denote file")
	end

	if not title then
		log.debug("update_title: no title provided, prompting user")
		title = ui.prompt_title(file_path)
		if not title then
			log.debug("update_title: user cancelled or provided empty title")
			return nil
		end
	end

	log.debug("update_title: proceeding with title =", title)

	local new_path = file.rename(file_path, { title = title })
	if new_path then
		log.info("update_title: file renamed to =", new_path, "updating frontmatter")
		file.update_frontmatter(new_path, config.get())
		log.info("update_title: successfully updated title")
	else
		log.error("update_title: rename failed")
	end
	return new_path
end

---Update note keywords
---@param file_path string?
---@param keywords string?
---@return string? new_path
function M.update_keywords(file_path, keywords)
	file_path = file_path or vim.fn.expand("%:p")

	if not filename.is_denote_file(vim.fn.fnamemodify(file_path, ":t")) then
		error("[denote] Not a denote file")
	end

	keywords = keywords or ui.prompt_keywords(file_path)
	if not keywords then
		return nil
	end

	local new_path = file.rename(file_path, { keywords = keywords })
	if new_path then
		file.update_frontmatter(new_path, config.get())
	end
	return new_path
end

---Update note signature
---@param file_path string?
---@param signature string?
---@return string? new_path
function M.update_signature(file_path, signature)
	file_path = file_path or vim.fn.expand("%:p")

	if not filename.is_denote_file(vim.fn.fnamemodify(file_path, ":t")) then
		error("[denote] Not a denote file")
	end

	signature = signature or ui.prompt_signature(file_path)
	if not signature then
		return nil
	end

	local new_path = file.rename(file_path, { signature = signature })
	if new_path then
		file.update_frontmatter(new_path, config.get())
	end
	return new_path
end

---Update note extension
---@param file_path string?
---@param extension string?
---@return string? new_path
function M.update_extension(file_path, extension)
	file_path = file_path or vim.fn.expand("%:p")

	if not filename.is_denote_file(vim.fn.fnamemodify(file_path, ":t")) then
		error("[denote] Not a denote file")
	end

	extension = extension or ui.prompt_extension(file_path)
	if not extension then
		return nil
	end

	local new_path = file.rename(file_path, { extension = extension })
	if new_path then
		file.update_frontmatter(new_path, config.get())
	end
	return new_path
end

---Rename file interactively
---@param file_path string?
---@return string? new_path
function M.rename_file(file_path)
	file_path = file_path or vim.fn.expand("%:p")

	if not filename.is_denote_file(vim.fn.fnamemodify(file_path, ":t")) then
		error("[denote] Not a denote file")
	end

	local cfg = config.get()
	local components = ui.collect_prompts(cfg, file_path)

	local new_path = file.rename(file_path, components)
	if new_path then
		file.update_frontmatter(new_path, cfg)
	end
	return new_path
end

---Parse denote filename
---@param file_path string?
---@return Denote.FileComponents?
function M.parse_file(file_path)
	file_path = file_path or vim.fn.expand("%:p")
	log.debug("parse_file: parsing file =", file_path)
	local filename_only = vim.fn.fnamemodify(file_path, ":t")
	local result = filename.parse(filename_only)
	if result then
		log.debug("parse_file: successfully parsed, components =", result)
	else
		log.debug("parse_file: failed to parse as denote file")
	end
	return result
end

---Check if file is denote format
---@param file_path string?
---@return boolean
function M.is_denote_file(file_path)
	file_path = file_path or vim.fn.expand("%:p")
	log.trace("is_denote_file: checking file =", file_path)
	local filename_only = vim.fn.fnamemodify(file_path, ":t")
	local result = filename.is_denote_file(filename_only)
	log.debug("is_denote_file:", file_path, "is denote file:", result)
	return result
end

return M
