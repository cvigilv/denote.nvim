---@module "denote.internal"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

-- CONSTANTS

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

--- Filetype to extension mapping table
---@type table<string,string>
M.FILETYPE_TO_EXTENSION = {
  org = ".org",
  neorg = ".norg",
  ["markdown-yaml"] = ".md",
  ["markdown-toml"] = ".md",
  text = ".txt",
}

--- UTILS

--- Normalizes diacritics (accented characters) in a string by replacing them with their base ASCII
--- equivalents. Handles common diacritics for vowels (a, e, i, o, u, y) and consonants (c, n, s, z),
--- as well as special characters like æ, œ, and ß. Both lowercase and uppercase variants are supported.
--- @param str string|nil The input string to normalize
--- @return string|nil normalized The normalized string
function M.normalize_diacritics(str)
  if not str then
    return str
  end
  local diacritic_map = {
    -- Vowels
    ["à"] = "a",
    ["á"] = "a",
    ["â"] = "a",
    ["ã"] = "a",
    ["ä"] = "a",
    ["å"] = "a",
    ["ā"] = "a",
    ["ă"] = "a",
    ["ą"] = "a",
    ["À"] = "A",
    ["Á"] = "A",
    ["Â"] = "A",
    ["Ã"] = "A",
    ["Ä"] = "A",
    ["Å"] = "A",
    ["Ā"] = "A",
    ["Ă"] = "A",
    ["Ą"] = "A",
    ["è"] = "e",
    ["é"] = "e",
    ["ê"] = "e",
    ["ë"] = "e",
    ["ē"] = "e",
    ["ĕ"] = "e",
    ["ė"] = "e",
    ["ę"] = "e",
    ["ě"] = "e",
    ["È"] = "E",
    ["É"] = "E",
    ["Ê"] = "E",
    ["Ë"] = "E",
    ["Ē"] = "E",
    ["Ĕ"] = "E",
    ["Ė"] = "E",
    ["Ę"] = "E",
    ["Ě"] = "E",
    ["ì"] = "i",
    ["í"] = "i",
    ["î"] = "i",
    ["ï"] = "i",
    ["ĩ"] = "i",
    ["ī"] = "i",
    ["ĭ"] = "i",
    ["į"] = "i",
    ["ı"] = "i",
    ["Ì"] = "I",
    ["Í"] = "I",
    ["Î"] = "I",
    ["Ï"] = "I",
    ["Ĩ"] = "I",
    ["Ī"] = "I",
    ["Ĭ"] = "I",
    ["Į"] = "I",
    ["İ"] = "I",
    ["ò"] = "o",
    ["ó"] = "o",
    ["ô"] = "o",
    ["õ"] = "o",
    ["ö"] = "o",
    ["ø"] = "o",
    ["ō"] = "o",
    ["ŏ"] = "o",
    ["ő"] = "o",
    ["Ò"] = "O",
    ["Ó"] = "O",
    ["Ô"] = "O",
    ["Õ"] = "O",
    ["Ö"] = "O",
    ["Ø"] = "O",
    ["Ō"] = "O",
    ["Ŏ"] = "O",
    ["Ő"] = "O",
    ["ù"] = "u",
    ["ú"] = "u",
    ["û"] = "u",
    ["ü"] = "u",
    ["ũ"] = "u",
    ["ū"] = "u",
    ["ŭ"] = "u",
    ["ů"] = "u",
    ["ű"] = "u",
    ["ų"] = "u",
    ["Ù"] = "U",
    ["Ú"] = "U",
    ["Û"] = "U",
    ["Ü"] = "U",
    ["Ũ"] = "U",
    ["Ū"] = "U",
    ["Ŭ"] = "U",
    ["Ů"] = "U",
    ["Ű"] = "U",
    ["Ų"] = "U",
    ["ý"] = "y",
    ["ÿ"] = "y",
    ["ỳ"] = "y",
    ["ỹ"] = "y",
    ["ȳ"] = "y",
    ["ŷ"] = "y",
    ["Ý"] = "Y",
    ["Ÿ"] = "Y",
    ["Ỳ"] = "Y",
    ["Ỹ"] = "Y",
    ["Ȳ"] = "Y",
    ["Ŷ"] = "Y",

    -- Consonants
    ["ç"] = "c",
    ["ć"] = "c",
    ["ĉ"] = "c",
    ["ċ"] = "c",
    ["č"] = "c",
    ["Ç"] = "C",
    ["Ć"] = "C",
    ["Ĉ"] = "C",
    ["Ċ"] = "C",
    ["Č"] = "C",
    ["ń"] = "n",
    ["ņ"] = "n",
    ["ň"] = "n",
    ["ŉ"] = "n",
    ["ŋ"] = "n",
    ["ñ"] = "n",
    ["Ń"] = "N",
    ["Ņ"] = "N",
    ["Ň"] = "N",
    ["Ŋ"] = "N",
    ["Ñ"] = "N",
    ["ś"] = "s",
    ["ŝ"] = "s",
    ["ş"] = "s",
    ["š"] = "s",
    ["Ś"] = "S",
    ["Ŝ"] = "S",
    ["Ş"] = "S",
    ["Š"] = "S",
    ["ž"] = "z",
    ["ź"] = "z",
    ["ż"] = "z",
    ["Ž"] = "Z",
    ["Ź"] = "Z",
    ["Ż"] = "Z",

    -- Special characters
    ["æ"] = "ae",
    ["œ"] = "oe",
    ["ß"] = "ss",
    ["Æ"] = "AE",
    ["Œ"] = "OE",
  }
  local normalized = str
  for diacritic, replacement in pairs(diacritic_map) do
    normalized = normalized:gsub(diacritic, replacement)
  end

  return normalized
end

---Trim whitespace on either end of string
---@param str string
function M.trim(str)
  local from = str:match("^%s*()")
  return from > #str and "" or str:match(".*%S", from)
end

---Make lowercase, remove special chars & diacritics, remove extraneous spaces
---@param str string
---@return string str Plain string
function M.plain_format(str)
  if str == nil then
    return ""
  end
  str = M.normalize_diacritics(str) --[[@as string]]
  str = str:gsub("[^%w%s]", "")
  str = str:lower()
  str = M.trim(str)
  str = str:gsub("%s+", " ")
  return str
end

---Format the title/keywords/sig string of a Denote filename
---@param str string
---@param char string delimiter that replaces spaces (- for titles, _ for keywords, = for sigs)
function M.format_denote_string(str, char)
  str = M.trim(str)
  str = M.plain_format(str)
  if str == "" then
    return ""
  end
  str = char .. char .. str:gsub("%s", char)
  return str
end

---Save new file, delete old file
---@param new_filename string
---@param old_filename string
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

---Edit a new note with a Denote filename
---@param options table
---@param title string
---@param keywords string
function M.note(options, title, keywords)
  title = M.trim(title)
  keywords = M.format_denote_string(keywords, "_")
  title = M.format_denote_string(title, "-")
  local file = options.directory .. os.date("%Y%m%dT%H%M%S")
  file = file .. title .. keywords .. "." .. options.filetype
  vim.cmd("edit " .. file)
  vim.cmd("startinsert")
end

---Edit a new note with a Denote filename
---@param fields table
---@param options Denote.Configuration
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

  -- Generate frontmatter first
  local frontmatter = require("denote.helpers.frontmatter")
  local fm_fields = {
    title = title ~= "" and title or nil,
    date = date,
    keywords = keywords ~= "" and keywords or nil,
    signature = signature ~= "" and signature or nil,
    identifier = date,
  }

  local fm_content = frontmatter.generate_frontmatter(fm_fields, options.filetype)

  -- Write file with frontmatter to avoid empty file issues with autocmds
  if fm_content then
    local lines = vim.split(fm_content, "\n")
    -- Remove empty line at end if present
    if lines[#lines] == "" then
      table.remove(lines)
    end
    vim.fn.writefile(lines, filename)
  else
    -- Create empty file if no frontmatter
    vim.fn.writefile({}, filename)
  end

  -- Now safely edit the populated file
  vim.cmd("edit " .. filename)

  -- Position cursor after frontmatter
  if fm_content then
    local lines = vim.split(fm_content, "\n")
    local cursor_line = math.min(#lines, vim.api.nvim_buf_line_count(0))
    if cursor_line > 0 then
      vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
    end
  end

  vim.cmd("startinsert")
end

---Retitles the filename
---@param filename string
---@param title string
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
  local clean_title = M.trim(title)
  title = M.format_denote_string(clean_title, "-")
  local new_filename = prefix .. sig .. title .. keywords .. ext

  -- Update frontmatter if it exists
  M.update_frontmatter_field(filename, "title", clean_title)

  M.replace_file(filename, new_filename)
end

---Replaces the __keywords in filename
---@param filename string
---@param keywords string
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

  -- Update frontmatter if it exists
  M.update_frontmatter_field(filename, "keywords", keywords:gsub("__", ""):gsub("_", " "))

  M.replace_file(filename, new_filename)
end

---Add/change the ==signature in the filename
---@param filename string
---@param signature string
function M.update_signature(filename, signature)
  local prefix, suffix = filename:match("^(.-%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)(.*)")
  if not prefix then
    error("This doesn't look like a Denote filename")
  end
  suffix = suffix:gsub("==[^%-%_%.]*", "")
  signature = M.format_denote_string(signature, "=")
  local new_filename = prefix .. signature .. suffix

  -- Update frontmatter if it exists
  M.update_frontmatter_field(filename, "signature", signature:gsub("==", ""):gsub("=", " "))

  M.replace_file(filename, new_filename)
end

---Replace the extension in the file with ext and convert frontmatter accordingly
---@param filename string
---@param ext string
function M.update_extension(filename, ext)
  local prefix, old_ext = filename:match("^(.-%d%d%d%d%d%d%d%dT%d%d%d%d%d%d.*%.)(.+)$")
  if not prefix then
    error("This doesn't look like a Denote file")
  end

  local new_filename = prefix .. ext

  -- Map extensions to filetypes
  local ext_to_filetype = {
    org = "org",
    md = "markdown",
    txt = "text",
    norg = "text",
  }

  -- Reverse mapping for known Denote extensions
  local denote_extensions = {
    org = "org",
    md = "markdown-yaml", -- Default to YAML for .md
    txt = "text",
    norg = "text",
  }

  local old_filetype = ext_to_filetype[old_ext] or "unknown"
  local new_filetype = denote_extensions[ext]

  -- If target extension is not a known Denote filetype, remove frontmatter
  if not new_filetype then
    M.remove_frontmatter(filename, old_filetype)
    -- Rename the file if needed
    if filename ~= new_filename then
      vim.fn.rename(filename, new_filename)
    end
    return
  end

  -- If both are Denote filetypes, convert frontmatter
  if old_filetype ~= "unknown" then
    -- Parse current frontmatter
    local frontmatter = require("denote.helpers.frontmatter")
    local current_fm = frontmatter.parse_frontmatter(filename, old_filetype)

    if current_fm then
      -- For markdown files, detect if we need YAML or TOML
      local target_filetype = new_filetype
      if new_filetype == "markdown-yaml" and ext == "md" then
        -- Check if user wants TOML (could be enhanced with a prompt)
        -- For now, default to YAML
        target_filetype = "markdown-yaml"
      end

      -- Read all content first
      local all_lines = vim.fn.readfile(filename)

      -- Find content start (after frontmatter)
      local content_start = 1
      if old_filetype == "org" then
        for i, line in ipairs(all_lines) do
          if not line:match("^#+") and line ~= "" then
            content_start = i
            break
          elseif line == "" and i > 1 then
            content_start = i + 1
            break
          end
        end
      elseif old_filetype == "markdown" then
        local first_line = all_lines[1] or ""
        if first_line == "---" then
          local yaml_count = 0
          for i, line in ipairs(all_lines) do
            if line == "---" then
              yaml_count = yaml_count + 1
              if yaml_count == 2 then
                content_start = i + 1
                break
              end
            end
          end
        elseif first_line == "+++" then
          local toml_count = 0
          for i, line in ipairs(all_lines) do
            if line == "+++" then
              toml_count = toml_count + 1
              if toml_count == 2 then
                content_start = i + 1
                break
              end
            end
          end
        end
      else -- text
        for i, line in ipairs(all_lines) do
          if line:match("^%-+$") then
            content_start = i + 1
            break
          elseif line == "" and i > 1 then
            content_start = i
            break
          end
        end
      end

      -- Extract content (everything after frontmatter)
      local content_lines = {}
      for i = content_start, #all_lines do
        table.insert(content_lines, all_lines[i])
      end

      -- Generate new frontmatter in target format
      local new_fm_content = frontmatter.generate_frontmatter(current_fm, target_filetype)

      -- Combine new frontmatter with content
      local final_lines = {}
      if new_fm_content then
        local new_fm_lines = vim.split(new_fm_content, "\n")
        -- Remove empty line at end if present
        if new_fm_lines[#new_fm_lines] == "" then
          table.remove(new_fm_lines)
        end

        -- Add frontmatter lines
        for _, line in ipairs(new_fm_lines) do
          table.insert(final_lines, line)
        end
      end

      -- Add content lines
      for _, line in ipairs(content_lines) do
        table.insert(final_lines, line)
      end

      -- Write the complete converted file to the new filename
      vim.fn.writefile(final_lines, new_filename)
      -- Remove the original file if it's different
      if filename ~= new_filename then
        vim.fn.delete(filename)
      end
      return -- Don't call rename since we already wrote to new file
    else
      -- No frontmatter found, just copy content
      local all_lines = vim.fn.readfile(filename)
      vim.fn.writefile(all_lines, new_filename)
      if filename ~= new_filename then
        vim.fn.delete(filename)
      end
      return
    end
  else
    -- Source file has no frontmatter but target is a Denote filetype
    -- Generate frontmatter from filename components
    local components = M.parse_filename(filename)
    if components.identifier then
      local frontmatter = require("denote.helpers.frontmatter")
      local fm_fields = {
        title = components.title ~= "" and components.title:gsub("%-%-", ""):gsub("%-", " ")
          or nil,
        date = components.identifier,
        keywords = components.keywords ~= "" and components.keywords
          :gsub("__", "")
          :gsub("_", " ") or nil,
        signature = components.signature ~= "" and components.signature
          :gsub("==", "")
          :gsub("=", " ") or nil,
        identifier = components.identifier,
      }

      local new_fm_content = frontmatter.generate_frontmatter(fm_fields, new_filetype)
      local original_lines = vim.fn.readfile(filename)
      local final_lines = {}

      if new_fm_content then
        local new_fm_lines = vim.split(new_fm_content, "\n")
        -- Remove empty line at end if present
        if new_fm_lines[#new_fm_lines] == "" then
          table.remove(new_fm_lines)
        end

        -- Add frontmatter lines
        for _, line in ipairs(new_fm_lines) do
          table.insert(final_lines, line)
        end
      end

      -- Add original content
      for _, line in ipairs(original_lines) do
        table.insert(final_lines, line)
      end

      -- Write to new filename
      vim.fn.writefile(final_lines, new_filename)
      if filename ~= new_filename then
        vim.fn.delete(filename)
      end
      return
    else
      -- Just copy the file
      local lines = vim.fn.readfile(filename)
      vim.fn.writefile(lines, new_filename)
      if filename ~= new_filename then
        vim.fn.delete(filename)
      end
      return
    end
  end

  M.replace_file(filename, new_filename)
end

--- PARSERS

---Parse Denote file name to get components
---@param filename string
---@return table components
function M.parse_filename(filename, split)
  local function __id2date(identifier)
    local pattern = "(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)"
    local matches = { string.match(identifier, pattern) }
    if #matches ~= 6 then
      return nil
    end

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
  local ok, date = pcall(__id2date, components.identifier)
  if ok then
    components.date = date
  end

  return components
end

return M
