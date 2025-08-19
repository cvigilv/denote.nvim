---@module "denote.core.file"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local filename = require("denote.core.filename")
local frontmatter = require("denote.core.frontmatter")
local utils = require("denote.core.utils")

local M = {}

---Create new denote file
---@param config Denote.Config
---@param components Denote.FileComponents
---@return string file_path
function M.create(config, components)
	log.info("create: creating new denote file with components =", components)
	log.debug(
		"create: using config =",
		{ directory = config.directory, extension = config.extension, frontmatter = config.frontmatter }
	)

	if not components.identifier then
		components.identifier = utils.generate_timestamp()
		log.debug("create: generated new identifier =", components.identifier)
	end

	if not components.extension then
		components.extension = config.extension
		log.debug("create: using default extension =", components.extension)
	end

	local file_name = filename.build(components)
	local file_path = config.directory .. file_name
	log.info("create: building file at path =", file_path)

	local content = {}
	if config.frontmatter then
		log.debug("create: generating frontmatter for extension =", components.extension)
		local fm_lines = frontmatter.generate(components, components.extension)
		vim.list_extend(content, fm_lines)
		log.trace("create: added frontmatter lines =", #fm_lines)
	else
		log.debug("create: frontmatter disabled, creating empty file")
	end

	log.trace("create: writing", #content, "lines to", file_path)
	local success, err = pcall(vim.fn.writefile, content, file_path)
	if not success then
		log.error("create: failed to write file =", file_path, "error =", err)
		error("Failed to create file: " .. err)
	end

	log.info("create: successfully created file =", file_path)
	return file_path
end

---Rename existing file
---@param old_path string
---@param new_components Denote.FileComponents
---@return string? new_path
function M.rename(old_path, new_components)
	log.info("rename: renaming file =", old_path, "with new components =", new_components)

	local old_filename = vim.fn.fnamemodify(old_path, ":t")
	local old_components = filename.parse(old_filename)
	if not old_components then
		log.error("rename: failed to parse old filename =", old_filename)
		return nil
	end

	log.debug("rename: parsed old components =", old_components)
	local components = vim.tbl_deep_extend("force", old_components, new_components)
	log.debug("rename: merged components =", components)

	local new_name = filename.build(components)
	local new_path = vim.fn.fnamemodify(old_path, ":h") .. "/" .. new_name
	log.info("rename: new path =", new_path)

	if old_path ~= new_path then
		log.debug("rename: paths differ, performing rename operation")
		local rename_result = vim.fn.rename(old_path, new_path)
		if rename_result == 0 then
			log.info("rename: file system rename successful")
			local bufnr = vim.fn.bufnr(old_path)
			if bufnr ~= -1 then
				log.debug("rename: updating buffer name for bufnr =", bufnr)
				vim.api.nvim_buf_set_name(bufnr, new_path)
				vim.cmd("checktime")
			else
				log.trace("rename: no buffer found for old path")
			end
			return new_path
		else
			log.error("rename: file system rename failed with code =", rename_result)
			return nil
		end
	else
		log.debug("rename: paths are the same, no rename needed")
	end

	return new_path
end

---Update file frontmatter
---@param file_path string
---@param config Denote.Config
function M.update_frontmatter(file_path, config)
	if not config.frontmatter then
		return
	end

	local components = filename.parse(vim.fn.fnamemodify(file_path, ":t"))
	if not components then
		return
	end

	local lines = vim.fn.readfile(file_path)
	local new_frontmatter = frontmatter.generate(components, components.extension)

	local start_line = 1
	if components.extension == ".org" then
		while start_line <= #lines and lines[start_line]:match("^#+%w+:") do
			start_line = start_line + 1
		end
	elseif components.extension == ".md" then
		if lines[1] == "---" then
			start_line = 2
			while start_line <= #lines and lines[start_line] ~= "---" do
				start_line = start_line + 1
			end
			start_line = start_line + 1
		end
	elseif components.extension == ".txt" then
		while start_line <= #lines and lines[start_line]:match("^%w+:") do
			start_line = start_line + 1
		end
	end

	local new_content = vim.list_extend(new_frontmatter, vim.list_slice(lines, start_line))
	vim.fn.writefile(new_content, file_path)
end

---Open denote file in editor
---@param file_path string
---@param insert_mode boolean?
function M.open(file_path, insert_mode)
	log.info("open: opening file =", file_path, "insert_mode =", insert_mode)
	local escaped_path = vim.fn.fnameescape(file_path)
	log.trace("open: escaped path =", escaped_path)

	local success, err = pcall(vim.cmd, "edit " .. escaped_path)
	if not success then
		log.error("open: failed to open file =", file_path, "error =", err)
		error("Failed to open file: " .. err)
	end

	if insert_mode then
		log.debug("open: entering insert mode")
		vim.cmd("startinsert")
	end

	log.info("open: successfully opened file =", file_path)
end

return M
