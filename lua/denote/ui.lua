---@module "denote.ui"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local filename = require("denote.core.filename")
local utils = require("denote.core.utils")

local M = {}

---Prompt user for input
---@param prompt string
---@param default string?
---@return string?
local function get_input(prompt, default)
	log.debug("get_input: prompting user with =", prompt, "default =", default)
	local result
	vim.ui.input({
		prompt = prompt,
		default = default or "",
	}, function(input)
		local trimmed = input and utils.trim(input) or nil
		log.trace("get_input: user input =", input, "trimmed =", trimmed)
		result = trimmed
	end)
	log.debug("get_input: final result =", result)
	return result
end

---Prompt for note title
---@param current_file string?
---@return string?
function M.prompt_title(current_file)
	local default = ""
	if current_file then
		local components = filename.parse(vim.fn.fnamemodify(current_file, ":t"))
		if components and components.title then
			default = components.title:gsub("-", " ")
		end
	end
	return get_input("[denote] Title: ", default)
end

---Prompt for note keywords
---@param current_file string?
---@return string?
function M.prompt_keywords(current_file)
	local default = ""
	if current_file then
		local components = filename.parse(vim.fn.fnamemodify(current_file, ":t"))
		if components and components.keywords then
			default = components.keywords:gsub("_", " ")
		end
	end
	return get_input("[denote] Keywords: ", default)
end

---Prompt for note signature
---@param current_file string?
---@return string?
function M.prompt_signature(current_file)
	local default = ""
	if current_file then
		local components = filename.parse(vim.fn.fnamemodify(current_file, ":t"))
		if components and components.signature then
			default = components.signature:gsub("=", " ")
		end
	end
	return get_input("[denote] Signature: ", default)
end

---Prompt for file extension
---@param current_file string?
---@return string?
function M.prompt_extension(current_file)
	local default = ".md"
	if current_file then
		local components = filename.parse(vim.fn.fnamemodify(current_file, ":t"))
		if components and components.extension then
			default = components.extension
		end
	end
	return get_input("[denote] Extension: ", default)
end

---Collect prompts based on configuration
---@param config Denote.Config
---@param current_file string?
---@return Denote.FileComponents
function M.collect_prompts(config, current_file)
	log.info("collect_prompts: collecting prompts for file =", current_file, "prompts =", config.prompts)
	local components = {}

	for _, prompt in ipairs(config.prompts) do
		log.debug("collect_prompts: processing prompt =", prompt)
		if prompt == "title" then
			components.title = M.prompt_title(current_file)
			log.trace("collect_prompts: collected title =", components.title)
		elseif prompt == "keywords" then
			components.keywords = M.prompt_keywords(current_file)
			log.trace("collect_prompts: collected keywords =", components.keywords)
		elseif prompt == "signature" then
			components.signature = M.prompt_signature(current_file)
			log.trace("collect_prompts: collected signature =", components.signature)
		elseif prompt == "extension" then
			components.extension = M.prompt_extension(current_file)
			log.trace("collect_prompts: collected extension =", components.extension)
		else
			log.warn("collect_prompts: unknown prompt type =", prompt)
		end
	end

	log.info("collect_prompts: final collected components =", components)
	return components
end

return M
