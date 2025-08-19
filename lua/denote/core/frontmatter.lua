---@module "denote.core.frontmatter"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local filename = require("denote.core.filename")
local utils = require("denote.core.utils")

local M = {}

---@class Denote.FrontmatterConfig
---@field org table<string, string>
---@field markdown table<string, string>
---@field text table<string, string>

M.FIELD_MAPPING = {
	org = {
		title = "title",
		date = "date",
		keywords = "filetags",
		signature = "signature",
		identifier = "identifier",
	},
	markdown = {
		title = "title",
		date = "date",
		keywords = "tags",
		signature = "signature",
		identifier = "id",
	},
	text = {
		title = "title",
		date = "date",
		keywords = "keywords",
		signature = "signature",
		identifier = "id",
	},
}

---Generate org-mode frontmatter
---@param components Denote.FileComponents
---@return string[]
function M.generate_org(components)
	log.debug("generate_org: generating org frontmatter for components =", components)
	local lines = {}
	local mapping = M.FIELD_MAPPING.org

	if components.title and components.title ~= "" then
		local title_formatted = components.title:gsub("-", " ")
		local line = string.format("#+%s: %s", mapping.title, title_formatted)
		table.insert(lines, line)
		log.trace("generate_org: added title line =", line)
	end

	if components.date then
		local line = string.format("#+%s: %s", mapping.date, components.date)
		table.insert(lines, line)
		log.trace("generate_org: added date line =", line)
	end

	if components.keywords and components.keywords ~= "" then
		local keywords = components.keywords:gsub("_", " ")
		local line = string.format("#+%s: %s", mapping.keywords, keywords)
		table.insert(lines, line)
		log.trace("generate_org: added keywords line =", line)
	end

	if components.signature and components.signature ~= "" then
		local signature = components.signature:gsub("=", " ")
		local line = string.format("#+%s: %s", mapping.signature, signature)
		table.insert(lines, line)
		log.trace("generate_org: added signature line =", line)
	end

	local id_line = string.format("#+%s: %s", mapping.identifier, components.identifier)
	table.insert(lines, id_line)
	log.trace("generate_org: added identifier line =", id_line)

	table.insert(lines, "")
	log.info("generate_org: generated", #lines - 1, "frontmatter lines")

	return lines
end

---Generate markdown frontmatter (YAML)
---@param components Denote.FileComponents
---@return string[]
function M.generate_markdown(components)
	local lines = { "---" }
	local mapping = M.FIELD_MAPPING.markdown

	if components.title and components.title ~= "" then
		table.insert(lines, string.format('%s: "%s"', mapping.title, components.title:gsub("-", " ")))
	end

	if components.date then
		table.insert(lines, string.format("%s: %s", mapping.date, components.date))
	end

	if components.keywords and components.keywords ~= "" then
		local keywords = vim.split(components.keywords, "_")
		local formatted_keywords = table.concat(
			vim.tbl_map(function(k)
				return '"' .. k .. '"'
			end, keywords),
			", "
		)
		table.insert(lines, string.format("%s: [%s]", mapping.keywords, formatted_keywords))
	end

	if components.signature and components.signature ~= "" then
		table.insert(lines, string.format('%s: "%s"', mapping.signature, components.signature:gsub("=", " ")))
	end

	table.insert(lines, string.format("%s: %s", mapping.identifier, components.identifier))
	table.insert(lines, "---")
	table.insert(lines, "")

	return lines
end

---Generate text file frontmatter
---@param components Denote.FileComponents
---@return string[]
function M.generate_text(components)
	local lines = {}
	local mapping = M.FIELD_MAPPING.text

	if components.title and components.title ~= "" then
		table.insert(lines, string.format("%s: %s", mapping.title, components.title:gsub("-", " ")))
	end

	if components.date then
		table.insert(lines, string.format("%s: %s", mapping.date, components.date))
	end

	if components.keywords and components.keywords ~= "" then
		local keywords = components.keywords:gsub("_", " ")
		table.insert(lines, string.format("%s: %s", mapping.keywords, keywords))
	end

	if components.signature and components.signature ~= "" then
		table.insert(lines, string.format("%s: %s", mapping.signature, components.signature:gsub("=", " ")))
	end

	table.insert(lines, string.format("%s: %s", mapping.identifier, components.identifier))
	table.insert(lines, "")

	return lines
end

---Parse org frontmatter from file
---@param file_path string
---@return Denote.FileComponents?
function M.parse_org(file_path)
	if not vim.fn.filereadable(file_path) then
		return nil
	end

	local lines = vim.fn.readfile(file_path, "", 10)
	local components = {}
	local mapping = M.FIELD_MAPPING.org
	local reverse_mapping = {}
	for k, v in pairs(mapping) do
		reverse_mapping[v] = k
	end

	for _, line in ipairs(lines) do
		if line == "" then
			break
		end
		local field, value = line:match("^#+(%w+):%s*(.*)")
		if field and value then
			local denote_field = reverse_mapping[field:lower()]
			if denote_field then
				components[denote_field] = value
			end
		end
	end

	return next(components) and components or nil
end

---Generate frontmatter based on file extension
---@param components Denote.FileComponents
---@param extension string
---@return string[]
function M.generate(components, extension)
	log.debug("generate: generating frontmatter for extension =", extension)
	local result
	if extension == ".org" then
		log.trace("generate: using org-mode generator")
		result = M.generate_org(components)
	elseif extension == ".md" then
		log.trace("generate: using markdown generator")
		result = M.generate_markdown(components)
	elseif extension == ".txt" then
		log.trace("generate: using text generator")
		result = M.generate_text(components)
	else
		log.warn("generate: unsupported extension", extension, "returning empty frontmatter")
		result = {}
	end
	log.info("generate: generated frontmatter with", #result, "lines for", extension)
	return result
end

return M
