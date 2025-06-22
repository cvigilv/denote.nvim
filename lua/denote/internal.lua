---@module "denote.internal"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

M.PATTERNS = {
  identifier = "(%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)",
  signature = "==([a-zA-Z0-9=]+)",
  title = "%-%-([a-z0-9%-]+)",
  keywords = "__([a-z0-9_]+)",
  extension = "(%.[^%s%.]+)",
}
M.SEPARATORS = {
  identifier = "@",
  signature = "=",
  title = "-",
  keywords = "_",
  extension = ".",
}
M.FILETYPE_TO_EXTENSION = {
  org = ".org",
  neorg = ".norg",
  ["markdown-yaml"] = ".md",
  ["markdown-toml"] = ".md",
  text = ".txt",
}

--- UTILS
---@param str string
---Trim whitespace on either end of string
function M.trim(str)
  local from = str:match("^%s*()")
  return from > #str and "" or str:match(".*%S", from)
end

---@param str string
---Make lowercase, remove special chars, remove extraneous spaces
function M.plain_format(str)
  if str == nil then
    return ""
  end
  str = str:gsub("[^%w%s]", "")
  str = str:lower()
  str = M.trim(str)
  str = str:gsub("%s+", " ")
  return str
end

---@param str string
---@param char string delimiter that replaces spaces (- for titles, _ for keywords, = for sigs)
---Format the title/keywords/sig string of a Denote filename
function M.format_denote_string(str, char)
  str = M.trim(str)
  str = M.plain_format(str)
  if str == "" then
    return ""
  end
  str = char .. char .. str:gsub("%s", char)
  return str
end

---@param new_filename string
---@param old_filename string
---Save new file, delete old file
function M.replace_file(old_filename, new_filename)
  if old_filename ~= new_filename then
    vim.cmd("saveas " .. new_filename)
    vim.cmd(string.format('silent !rm "%s"', old_filename))
  end
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
      error("Error: Unable to get file stats for " .. filename)
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

--- GENERATORS
---@param options table
---@param title string
---@param keywords string
---Edit a new note with a Denote filename
function M.note(options, title, keywords)
  title = M.trim(title)
  keywords = M.format_denote_string(keywords, "_")
  title = M.format_denote_string(title, "-")
  local file = options.directory .. os.date("%Y%m%dT%H%M%S")
  file = file .. title .. keywords .. "." .. options.filetype
  vim.cmd("edit " .. file)
  vim.cmd("startinsert")
end

---@param fields table
---@param options Denote.Configuration
---Edit a new note with a Denote filename
function M.new_note(fields, options)
  -- Load fields
  local date = fields["date"] or ""
  local title = fields["title"] or ""
  local keywords = fields["keywords"] or ""
  local signature = fields["signature"] or ""
  local extension = fields["extension"] or ""

  -- Check if date is in Denote's format
  if not date:match(M.PATTERNS.identifier) then
    error("Can't create a denote file without the date timestamp")
    return nil
  end

  -- Create note with provided fields
  local filename = options.directory
    .. date
    .. M.format_denote_string(signature --[[@as string]], "=")
    .. M.format_denote_string(title --[[@as string]], "-")
    .. M.format_denote_string(keywords --[[@as string]], "_")
    .. extension

  vim.cmd("edit " .. filename)
  vim.cmd("startinsert")
end

---@param filename string
---@param title string
--- Retitles the filename
function M.update_title(filename, title)
  local prefix, ext = filename:match("^(.-%d%d%d%d%d%d%d%dT%d%d%d%d%d%d).*(%..+)")
  if not prefix then
    error("This doesn't look like a Denote filename")
  end
  local sig = filename:match(".-(==[^%-%_%.]*)")
  local keywords = filename:match(".-(__.*)%..*")
  if not keywords then
    keywords = ""
  end
  if not sig then
    sig = ""
  end
  title = M.trim(title)
  title = M.format_denote_string(title, "-")
  local new_filename = prefix .. sig .. title .. keywords .. ext
  M.replace_file(filename, new_filename)
end

---@param filename string
---@param keywords string
---Replaces the __keywords in filename
function M.update_keyword(filename, keywords)
  local prefix, ext = filename:match("^(.*)__.*(%..+)$")
  if not prefix then
    prefix, ext = filename:match("^(.*)(%..+)$")
  end
  if not prefix:match("%d%d%d%d%d%d%d%dT%d%d%d%d%d%d") then
    error("This doesn't look like a Denote filename")
  end
  keywords = M.format_denote_string(keywords, "_")
  local new_filename = prefix .. keywords .. ext
  M.replace_file(filename, new_filename)
end

---@param filename string
---@param signature string
---Add/change the ==signature in the filename
function M.update_signature(filename, signature)
  local prefix, suffix = filename:match("^(.-%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)(.*)")
  if not prefix then
    error("This doesn't look like a Denote filename")
  end
  suffix = suffix:gsub("==[^%-%_%.]*", "")
  signature = M.format_denote_string(signature, "=")
  local new_filename = prefix .. signature .. suffix
  M.replace_file(filename, new_filename)
end

---@param filename string
---@param ext string
---Replace the extension in the file with ext
function M.update_extension(filename, ext)
  local prefix, _ = filename:match("^(.-%d%d%d%d%d%d%d%dT%d%d%d%d%d%d.*%.)(.+)$")
  if not prefix then
    error("This doesn't look like a Denote file")
  end
  local new_filename = prefix .. ext
  M.replace_file(filename, new_filename)
end

--- PARSERS
--- TODO: Add early return based on if it has timestamp in filename
---@param filename string
---@return table components
function M.parse_filename(filename, split)
  local function __id2date(identifier)
    local pattern = "(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)"
    local matches = { string.match(identifier, pattern) }
    if #matches ~= 6 then return nil end

    local timestamp = os.time({
      year = tonumber(matches[1]) --[[@as number]],
      month = tonumber(matches[2]) --[[@as number]],
      day = tonumber(matches[3]) --[[@as number]],
      hour = tonumber(matches[4]),
      min = tonumber(matches[5]),
      sec = tonumber(matches[6]),
    })

    return "[" .. os.date("%Y-%m-%d %a %T", timestamp) .. "]"
  end
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
  local ok, date = pcall(__id2date,components.identifier)
  if ok then components.date = date end

  return components
end

return M
