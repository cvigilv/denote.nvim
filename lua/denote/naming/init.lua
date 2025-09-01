---@module "denote.naming"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local String = require("denote.core.string")

local M = {}

--- Denote component regex patterns
---@type table<string,string>
M.PATTERNS = {
  identifier = "(%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)",
  signature = "==([a-zA-Z0-9=]+)",
  title = "%-%-([a-z0-9%-]+)",
  keywords = "__([a-z0-9_]+)",
  extension = "(%.[^%s%.]+)",
}

--- Denote component separator characters
---@type table<string,string>
M.SEPARATORS = {
  identifier = "@",
  signature = "=",
  title = "-",
  keywords = "_",
  extension = ".",
}

---Check is filename is a Denote file
---@param filename string
---@return boolean is_denote
function M.is_denote(filename)
  if string.match(filename, M.PATTERNS.identifier) then
    return true
  end
  return false
end

M.timestamp_to_date = function(timestamp)
  local pattern = "(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)"
  local matches = { string.match(timestamp, pattern) }
  if #matches ~= 6 then
    return nil
  end

  local time = os.time({
    year = tonumber(matches[1]) --[[@as number]],
    month = tonumber(matches[2]) --[[@as number]],
    day = tonumber(matches[3]) --[[@as number]],
    hour = tonumber(matches[4]),
    min = tonumber(matches[5]),
    sec = tonumber(matches[6]),
  })

  return "[" .. os.date("%Y-%m-%d %a %T", time) .. "]"
end

---Parse Denote file name to get components
---@param filename string
---@return table components
function M.parse_filename(filename, split)
  split = split or false
  local components = {
    identifier = "",
    signature = "",
    title = "",
    keywords = "",
    extension = "",
  }
  for name, pattern in pairs(M.PATTERNS) do
    for match in string.gmatch(filename, pattern) do
      if vim.tbl_contains(vim.tbl_keys(M.SEPARATORS), name) and split then
        components[name] = vim.split(match, M.SEPARATORS[name]) --[[@as string]]
      else
        components[name] = match
      end
    end
  end
  local ok, date = pcall(M.timestamp_to_date, components.identifier)
  if ok then
    components.date = date
  end

  return components
end

---Generate a Denote compliant filename from components
---@param components table Components to generate filename from
---@return string|nil Denote compliant filename or nil if an error occurs
function M.generate_filename(components)
  if not components then
    error("[denote] No components provided to generate Denote compliant filename")
    return nil
  end
  local filename = components.identifier
    .. M.as_component_string(components.signature or "", "signature")
    .. M.as_component_string(components.title or "", "title")
    .. M.as_component_string(components.keywords or "", "keywords")
    .. components.extension
  return filename
end

---Format the title/keywords/sig string of a Denote filename
---@param str string String to format as a Denote component
---@param type string Component type ("title", "keywords", "signature")
---@return string|nil Formatted component string or nil if an error occurs
function M.as_component_string(str, type)
  -- Format empty strings as empty
  if str == "" then
    return ""
  end
  -- Validate type
  if not vim.tbl_contains(vim.tbl_keys(M.SEPARATORS), type) then
    error("[denote] Invalid component type: " .. type)
    return nil
  end
  -- Plain format string and replace spaces with separator character
  local char = M.SEPARATORS[type]
  str = String.trim(str)
  str = String.sanitize(str)
  str = string.format("%s%s%s", char, char, str:gsub("%s", char))
  return str
end


---Generates a timestamp for a given file based on its creation or modification time. If no file is provided, generate for current time
---@param filename string? The path to the file
---@return string|nil Denote formatted timestamp or nil if an error occurs
function M.generate_timestamp(filename)
  local time
  if filename then
    ---@diagnostic disable-next-line: undefined-field
    local stat = vim.uv.fs_stat(vim.fs.abspath(filename))
    if not stat then
      error("[denote] [denote] Unable to get file stats for " .. filename)
      return nil
    end
    -- Check the operating system and get file creation time
    ---@diagnostic disable-next-line: undefined-field
    local os_name = vim.uv.os_uname().sysname:lower()
    if os_name == "windows" then
      -- Windows: Use ctime as it represents creation time
      time = stat.ctime.sec
    elseif os_name == "darwin" then
      -- macOS: Use birthtime if available, otherwise fall back to ctime
      time = (stat.birthtime and stat.birthtime.sec ~= 0) and stat.birthtime.sec
        or stat.ctime.sec
    else
      -- Linux and others: Use the earliest of mtime, ctime, and atime
      -- as birthtime is not reliably supported
      time = math.min(stat.mtime.sec, stat.ctime.sec, stat.atime.sec)
    end
  else
    time = os.time()
  end

  -- Return the formatted timestamp
  if time then
    return tostring(os.date("%Y%m%dT%H%M%S", time))
  end
end

return M
