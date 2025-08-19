---@module "denote.core.utils"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local log = require("denote.logging")
local M = {}

---Trim whitespace from both ends of string
---@param str string
---@return string
function M.trim(str)
	log.trace("trim: input =", str)
	if not str or str == "" then
		log.trace("trim: input is nil or empty, returning empty string")
		return ""
	end
	local from = str:match("^%s*()")
	local result = from > #str and "" or str:match(".*%S", from)
	log.trace("trim: result =", result)
	return result
end

---Sanitize string for denote filename (lowercase, remove special chars, normalize spaces)
---@param str string
---@return string
function M.sanitize(str)
	log.trace("sanitize: input =", str)
	if not str or str == "" then
		log.trace("sanitize: input is nil or empty, returning empty string")
		return ""
	end
	local original = str
	str = str:gsub("[^%w%s]", "")
	log.trace("sanitize: after removing special chars =", str)
	str = str:lower()
	log.trace("sanitize: after lowercasing =", str)
	str = M.trim(str)
	log.trace("sanitize: after trimming =", str)
	str = str:gsub("%s+", " ")
	log.trace("sanitize: final result =", str, "(from original:", original, ")")
	return str
end

---Format string for denote filename component
---@param str string
---@param separator string
---@return string
function M.format_component(str, separator)
	log.debug("format_component: formatting", str, "with separator", separator)
	str = M.trim(str)
	str = M.sanitize(str)
	if str == "" then
		log.debug("format_component: sanitized string is empty, returning empty")
		return ""
	end
	local result = separator .. separator .. str:gsub("%s", separator)
	log.debug("format_component: result =", result)
	return result
end

---Generate timestamp for denote file
---@param filename string?
---@return string
function M.generate_timestamp(filename)
	log.debug("generate_timestamp: called with filename =", filename)
	local time
	if filename then
		log.trace("generate_timestamp: using file timestamp for", filename)
		local abs_path = vim.fs.abspath(filename)
		log.trace("generate_timestamp: absolute path =", abs_path)
		local stat = vim.uv.fs_stat(abs_path)
		if not stat then
			log.error("generate_timestamp: unable to get file stats for", filename)
			error("Unable to get file stats for " .. filename)
		end
		local os_name = vim.uv.os_uname().sysname:lower()
		log.trace("generate_timestamp: detected OS =", os_name)
		if os_name == "windows" then
			time = stat.ctime.sec
			log.trace("generate_timestamp: using Windows ctime =", time)
		elseif os_name == "darwin" then
			time = (stat.birthtime and stat.birthtime.sec ~= 0) and stat.birthtime.sec or stat.ctime.sec
			log.trace("generate_timestamp: using Darwin birthtime/ctime =", time)
		else
			time = math.min(stat.mtime.sec, stat.ctime.sec, stat.atime.sec)
			log.trace("generate_timestamp: using Unix earliest time =", time)
		end
	else
		time = os.time()
		log.trace("generate_timestamp: using current time =", time)
	end
	local timestamp = os.date("%Y%m%dT%H%M%S", time)
	log.info("generate_timestamp: generated timestamp =", timestamp)
	return timestamp
end

---Convert identifier to readable date
---@param identifier string
---@return string?
function M.identifier_to_date(identifier)
	log.trace("identifier_to_date: converting", identifier)
	local pattern = "(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)"
	local matches = { string.match(identifier, pattern) }
	if #matches ~= 6 then
		log.trace("identifier_to_date: invalid identifier format, got", #matches, "matches")
		return nil
	end
	log.trace("identifier_to_date: parsed components =", matches)
	local timestamp = os.time({
		year = tonumber(matches[1]),
		month = tonumber(matches[2]),
		day = tonumber(matches[3]),
		hour = tonumber(matches[4]),
		min = tonumber(matches[5]),
		sec = tonumber(matches[6]),
	})
	local result = "[" .. os.date("%Y-%m-%d %a %T", timestamp) .. "]"
	log.trace("identifier_to_date: converted to readable date =", result)
	return result
end

return M
