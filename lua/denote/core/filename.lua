---@module "denote.core.filename"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local utils = require("denote.core.utils")

local M = {}

M.PATTERNS = {
	identifier = "(%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)",
	signature = "==([a-zA-Z0-9=]+)",
	title = "%-%-([a-z0-9%-]+)",
	keywords = "__([a-z0-9_]+)",
	extension = "(%.[^%s%.]+)",
}

M.SEPARATORS = {
	signature = "=",
	title = "-",
	keywords = "_",
}

---@class Denote.FileComponents
---@field identifier string
---@field signature string
---@field title string
---@field keywords string
---@field extension string
---@field date string?

---Parse denote filename into components
---@param filename string
---@param split_keywords boolean?
---@return Denote.FileComponents?
function M.parse(filename, split_keywords)
	log.debug("parse: parsing filename =", filename, "split_keywords =", split_keywords)
	split_keywords = split_keywords or false

	local components = {
		identifier = "",
		signature = "",
		title = "",
		keywords = "",
		extension = "",
	}

	for name, pattern in pairs(M.PATTERNS) do
		local match = string.match(filename, pattern)
		if match then
			log.trace("parse: found", name, "=", match)
			if name == "keywords" and split_keywords then
				components[name] = vim.split(match, M.SEPARATORS.keywords)
				log.trace("parse: split keywords =", components[name])
			else
				components[name] = match
			end
		else
			log.trace("parse: no match for", name, "pattern")
		end
	end

	if components.identifier and components.identifier ~= "" then
		components.date = utils.identifier_to_date(components.identifier)
		log.trace("parse: converted identifier to date =", components.date)
	end

	local result = components.identifier ~= "" and components or nil
	if result then
		log.info("parse: successfully parsed filename, components =", components)
	else
		log.warn("parse: failed to parse filename - no identifier found")
	end
	return result
end

---Validate if filename follows denote format
---@param filename string
---@return boolean
function M.is_denote_file(filename)
	log.trace("is_denote_file: checking", filename)
	local has_identifier = string.match(filename, M.PATTERNS.identifier) ~= nil
	log.debug("is_denote_file:", filename, "is denote file:", has_identifier)
	return has_identifier
end

---Build denote filename from components
---@param components Denote.FileComponents
---@return string
function M.build(components)
	log.debug("build: building filename from components =", components)
	local filename = components.identifier or ""
	log.trace("build: starting with identifier =", filename)

	if components.signature and components.signature ~= "" then
		local sig_formatted = utils.format_component(components.signature, "=")
		filename = filename .. sig_formatted
		log.trace("build: added signature, now =", filename)
	end

	if components.title and components.title ~= "" then
		local title_formatted = utils.format_component(components.title, "-")
		filename = filename .. title_formatted
		log.trace("build: added title, now =", filename)
	end

	if components.keywords and components.keywords ~= "" then
		local keywords_formatted = utils.format_component(components.keywords, "_")
		filename = filename .. keywords_formatted
		log.trace("build: added keywords, now =", filename)
	end

	filename = filename .. (components.extension or ".md")
	log.info("build: final filename =", filename)

	return filename
end

---Update specific component in filename
---@param filename string
---@param component string
---@param value string
---@return string?
function M.update_component(filename, component, value)
	log.debug("update_component: updating", component, "to", value, "in", filename)
	local components = M.parse(filename)
	if not components then
		log.warn("update_component: failed to parse filename", filename)
		return nil
	end

	local old_value = components[component]
	components[component] = value
	log.trace("update_component: changed", component, "from", old_value, "to", value)

	local result = M.build(components)
	log.info("update_component: updated filename =", result)
	return result
end

return M
