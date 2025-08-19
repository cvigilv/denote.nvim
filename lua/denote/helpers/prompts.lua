---@module "denote.helpers.prompts"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local U = require("denote.internal")

local function _prompt_factory(filename, field)
	filename = filename or vim.fn.expand("%:p")
	local fields = U.parse_filename(filename, false)
	local v
	vim.ui.input({
		prompt = string.format("[denote] New %s: ", field),
		default = string.gsub(fields[field] or "", "%" .. U.SEPARATORS[field], " "),
	}, function(e)
		v = U.trim(e)
	end)
	return v
end

local M = {}

function M.signature(filename)
	return _prompt_factory(filename, "signature")
end
function M.date(filename)
	return _prompt_factory(filename, "identifier")
end
function M.keywords(filename)
	return _prompt_factory(filename, "keywords")
end
function M.title(filename)
	return _prompt_factory(filename, "title")
end
function M.extension(filename)
	return _prompt_factory(filename, "extension")
end

return M
