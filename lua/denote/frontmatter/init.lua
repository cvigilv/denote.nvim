---@module "denote.helpers.frontmatter"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Filesystem = require("denote.core.fs")
local Naming = require("denote.naming")

local M = {}

-- Helper functions
---Signature as it appears in the filename, without the leading separator.
---@param fields table
---@return string|nil
local function signature_value(fields)
  local signature = fields.signature
  if signature == nil or signature == "" then
    return nil
  end
  return (Naming.as_component_string(signature, "signature"):gsub("^==", ""))
end

---@param date_field string|number
---@param format_func function
---@return string
M.format_date_field = function(date_field, format_func)
  if type(date_field) == "number" then
    return format_func(date_field)
  elseif date_field:match("^%d%d%d%d%d%d%d%dT%d%d%d%d%d%d$") then
    -- Convert Denote timestamp to proper format
    local year, month, day, hour, min, sec =
      date_field:match("^(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)$")
    if year then
      local timestamp = os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
      })
      return format_func(timestamp)
    end
  end
  return date_field
end

---@param keywords_field string|table
---@return table
M.clean_keywords = function(keywords_field)
  local clean_keywords = {}

  if type(keywords_field) == "table" then
    for _, kw in ipairs(keywords_field) do
      local clean_kw = kw:gsub("[^%w%s]", ""):lower():gsub("%s+", "")
      if clean_kw ~= "" then
        table.insert(clean_keywords, clean_kw)
      end
    end
  else
    for word in keywords_field:gmatch("%S+") do
      local clean_word = word:gsub("[^%w]", ""):lower()
      if clean_word ~= "" then
        table.insert(clean_keywords, clean_word)
      end
    end
  end

  return clean_keywords
end

-- Date formatting functions
M.format_date_org = function(timestamp)
  timestamp = timestamp or os.time()
  return "[" .. os.date("%Y-%m-%d %a %H:%M", timestamp) .. "]"
end

M.format_date_markdown = function(timestamp)
  timestamp = timestamp or os.time()
  return os.date("%Y-%m-%dT%H:%M:%S%z", timestamp)
end

M.format_date_text = function(timestamp)
  timestamp = timestamp or os.time()
  return os.date("%Y-%m-%d", timestamp)
end

-- Org mode frontmatter
---@param filename string
---@return table|nil frontmatter
M.parse_org_frontmatter = function(filename)
  filename = filename or vim.api.nvim_buf_get_name(0)
  local frontmatter = {}

  local lines = vim.fn.readfile(filename, "", 10)
  for _, line in ipairs(lines) do
    if line == "" and next(frontmatter) then
      break
    end

    local field, value = line:match("^#%+(%w+):%s*(.*)")
    if field then
      field = field:lower()
      if field == "filetags" then
        frontmatter.keywords = vim.split(
          value:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "),
          ":",
          { trimempty = true }
        )
      elseif field == "date" then
        frontmatter.date = value
      else
        frontmatter[field] = value
      end
    end
  end

  return next(frontmatter) and frontmatter or nil
end

---@param fields table
---@return string
M.generate_org_frontmatter = function(fields)
  local lines = {}

  if fields.title then
    table.insert(lines, "#+title:      " .. fields.title)
  end

  if fields.date then
    local date_str = M.format_date_field(fields.date, M.format_date_org)
    table.insert(lines, "#+date:       " .. date_str)
  end

  if fields.keywords then
    local clean_keywords = M.clean_keywords(fields.keywords)
    if #clean_keywords > 0 then
      local tags = table.concat(clean_keywords, ":")
      table.insert(lines, "#+filetags:   :" .. tags .. ":")
    end
  end

  if fields.identifier then
    table.insert(lines, "#+identifier: " .. fields.identifier)
  end

  local signature = signature_value(fields)
  if signature then
    table.insert(lines, "#+signature:  " .. signature)
  end

  return table.concat(lines, "\n") .. "\n"
end

-- Markdown YAML frontmatter
---@param filename string
---@return table|nil frontmatter
M.parse_yaml_frontmatter = function(filename)
  filename = filename or vim.api.nvim_buf_get_name(0)
  local frontmatter = {}
  local in_yaml = false

  local lines = vim.fn.readfile(filename, "", 20)
  for _, line in ipairs(lines) do
    if line == "---" then
      if in_yaml then
        break
      end
      in_yaml = true
    elseif in_yaml then
      local field, value = line:match("^(%w+):%s*(.*)")
      if field then
        field = field:lower()
        if field == "tags" then
          value = value:gsub('^%["', ""):gsub('"%]$', ""):gsub('", "', " ")
          frontmatter.keywords = value
        else
          frontmatter[field] = value:gsub('^"', ""):gsub('"$', "")
        end
      end
    end
  end

  return next(frontmatter) and frontmatter or nil
end

---@param fields table
---@return string
M.generate_yaml_frontmatter = function(fields)
  local lines = { "---" }

  if fields.title then
    table.insert(lines, 'title:      "' .. fields.title .. '"')
  end

  if fields.date then
    local date_str = M.format_date_field(fields.date, M.format_date_markdown)
    table.insert(lines, "date:       " .. date_str)
  end

  if fields.keywords then
    local clean_keywords = M.clean_keywords(fields.keywords)
    if #clean_keywords > 0 then
      table.insert(lines, 'tags:       ["' .. table.concat(clean_keywords, '", "') .. '"]')
    end
  end

  if fields.identifier then
    table.insert(lines, 'identifier: "' .. fields.identifier .. '"')
  end

  local signature = signature_value(fields)
  if signature then
    table.insert(lines, 'signature:  "' .. signature .. '"')
  end

  table.insert(lines, "---")
  return table.concat(lines, "\n") .. "\n"
end

-- Markdown TOML frontmatter
---@param filename string
---@return table|nil frontmatter
M.parse_toml_frontmatter = function(filename)
  filename = filename or vim.api.nvim_buf_get_name(0)
  local frontmatter = {}
  local in_toml = false

  local lines = vim.fn.readfile(filename, "", 20)
  for _, line in ipairs(lines) do
    if line == "+++" then
      if in_toml then
        break
      end
      in_toml = true
    elseif in_toml then
      local field, value = line:match("^(%w+)%s*=%s*(.*)")
      if field then
        field = field:lower()
        if field == "tags" then
          value = value:gsub('^%["', ""):gsub('"%]$', ""):gsub('", "', " ")
          frontmatter.keywords = value
        else
          frontmatter[field] = value:gsub('^"', ""):gsub('"$', "")
        end
      end
    end
  end

  return next(frontmatter) and frontmatter or nil
end

---@param fields table
---@return string
M.generate_toml_frontmatter = function(fields)
  local lines = { "+++" }

  if fields.title then
    table.insert(lines, 'title      = "' .. fields.title .. '"')
  end

  if fields.date then
    local date_str = M.format_date_field(fields.date, M.format_date_markdown)
    table.insert(lines, "date       = " .. date_str)
  end

  if fields.keywords then
    local clean_keywords = M.clean_keywords(fields.keywords)
    if #clean_keywords > 0 then
      table.insert(lines, 'tags       = ["' .. table.concat(clean_keywords, '", "') .. '"]')
    end
  end

  if fields.identifier then
    table.insert(lines, 'identifier = "' .. fields.identifier .. '"')
  end

  local signature = signature_value(fields)
  if signature then
    table.insert(lines, 'signature  = "' .. signature .. '"')
  end

  table.insert(lines, "+++")
  return table.concat(lines, "\n") .. "\n"
end

-- Neorg metadata
---@param filename string
---@return table|nil frontmatter
M.parse_neorg_frontmatter = function(filename)
  filename = filename or vim.api.nvim_buf_get_name(0)
  local frontmatter = {}
  local in_meta = false
  local list_field

  local lines = vim.fn.readfile(filename, "", 50)
  for _, line in ipairs(lines) do
    if line == "@document.meta" then
      in_meta = true
    elseif line == "@end" then
      break
    elseif in_meta and list_field then
      -- Multi-line list: one item per line until the closing bracket
      if line:match("^%s*%]") then
        list_field = nil
      else
        frontmatter[list_field] = vim.trim(frontmatter[list_field] .. " " .. vim.trim(line))
      end
    elseif in_meta then
      local field, value = line:match("^%s*([%w_]+):%s*(.*)")
      if field then
        field = field:lower()
        if field == "categories" then
          field = "keywords"
        elseif field == "created" then
          field = "date"
        end

        if value:match("^%[%s*$") then
          list_field = field
          frontmatter[field] = ""
        else
          frontmatter[field] = vim.trim((value:gsub("^%[", ""):gsub("%]$", "")))
        end
      end
    end
  end

  return next(frontmatter) and frontmatter or nil
end

---@param fields table
---@return string
M.generate_neorg_frontmatter = function(fields)
  local lines = { "@document.meta" }

  if fields.title then
    table.insert(lines, "title: " .. fields.title)
  end

  if fields.date then
    local date_str = M.format_date_field(fields.date, M.format_date_markdown)
    table.insert(lines, "created: " .. date_str)
  end

  if fields.keywords then
    local clean_keywords = M.clean_keywords(fields.keywords)
    if #clean_keywords > 0 then
      table.insert(lines, "categories: " .. table.concat(clean_keywords, " "))
    end
  end

  if fields.identifier then
    table.insert(lines, "identifier: " .. fields.identifier)
  end

  local signature = signature_value(fields)
  if signature then
    table.insert(lines, "signature: " .. signature)
  end

  table.insert(lines, "@end")
  return table.concat(lines, "\n") .. "\n"
end

-- Plain text frontmatter
---@param filename string
---@return table|nil frontmatter
M.parse_text_frontmatter = function(filename)
  filename = filename or vim.api.nvim_buf_get_name(0)
  local frontmatter = {}

  local lines = vim.fn.readfile(filename, "", 10)
  for _, line in ipairs(lines) do
    if line == "" or line:match("^%-+$") then
      break
    end

    local field, value = line:match("^(%w+):%s*(.*)")
    if field then
      field = field:lower()
      if field == "tags" then
        frontmatter.keywords = value
      else
        frontmatter[field] = value
      end
    end
  end

  return next(frontmatter) and frontmatter or nil
end

---@param fields table
---@return string
M.generate_text_frontmatter = function(fields)
  local lines = {}

  if fields.title then
    table.insert(lines, "title:      " .. fields.title)
  end

  if fields.date then
    local date_str = M.format_date_field(fields.date, M.format_date_text)
    table.insert(lines, "date:       " .. date_str)
  end

  if fields.keywords then
    local clean_keywords = M.clean_keywords(fields.keywords)
    if #clean_keywords > 0 then
      table.insert(lines, "tags:       " .. table.concat(clean_keywords, "  "))
    end
  end

  if fields.identifier then
    table.insert(lines, "identifier: " .. fields.identifier)
  end

  local signature = signature_value(fields)
  if signature then
    table.insert(lines, "signature:  " .. signature)
  end

  table.insert(lines, "---------------------------")
  return table.concat(lines, "\n") .. "\n"
end

-- Frontmatter updates

local FORMATS = {
  org = { generate = M.generate_org_frontmatter, field = "^#%+(%w+):", keywords = "filetags" },
  yaml = { generate = M.generate_yaml_frontmatter, field = "^(%w+):", keywords = "tags" },
  toml = { generate = M.generate_toml_frontmatter, field = "^(%w+)%s*=", keywords = "tags" },
  neorg = { generate = M.generate_neorg_frontmatter, field = "^%s*([%w_]+):", keywords = "categories" },
  text = { generate = M.generate_text_frontmatter, field = "^(%w+):", keywords = "tags" },
}

local UPDATABLE_FIELDS = { "title", "keywords", "identifier", "signature" }

---Find the frontmatter block of a note.
---@param lines string[]
---@param filetype string
---@return string|nil format Key of `FORMATS`, or nil when the note has no frontmatter
---@return integer first First line of the block's fields
---@return integer last Last line of the block's fields, `first - 1` when it has none
local function locate_frontmatter(lines, filetype)
  local function find_line(target, start)
    for i = start, #lines do
      if lines[i] == target then
        return i
      end
    end
  end

  if filetype == "markdown" then
    local format = ({ ["---"] = "yaml", ["+++"] = "toml" })[lines[1]]
    local close = format and find_line(lines[1], 2)
    if close then
      return format, 2, close - 1
    end
  elseif filetype == "norg" then
    local open = find_line("@document.meta", 1)
    local close = open and find_line("@end", open + 1)
    if close then
      return "neorg", open + 1, close - 1
    end
  elseif filetype == "org" then
    local last = 0
    while lines[last + 1] and lines[last + 1]:match("^#%+") do
      last = last + 1
    end
    if last > 0 then
      return "org", 1, last
    end
  else
    local last = 0
    while lines[last + 1] and lines[last + 1] ~= "" and not lines[last + 1]:match("^%-+$") do
      last = last + 1
    end
    for i = 1, last do
      if lines[i]:match(FORMATS.text.field) then
        return "text", 1, last
      end
    end
  end

  return nil, 0, 0
end

---Replace, remove, or append fields in the lines of a frontmatter block.
---@param block string[]
---@param format string
---@param fields table<string,string>
---@return string[] block
local function update_block(block, format, fields)
  local spec = FORMATS[format]
  for _, field in ipairs(UPDATABLE_FIELDS) do
    local value = fields[field]
    if value ~= nil then
      local key = field == "keywords" and spec.keywords or field
      local function key_of(line)
        local name = line:match(spec.field)
        return name and name:lower()
      end

      -- Render the field with the same generator used for new notes
      local replacement = {}
      if value ~= "" then
        for _, line in ipairs(vim.split(spec.generate({ [field] = value }), "\n")) do
          if key_of(line) == key then
            replacement = { line }
            break
          end
        end
      end

      local first, last
      for i, line in ipairs(block) do
        if key_of(line) == key then
          first, last = i, i
          -- Neorg lists can span lines up to a closing bracket
          if format == "neorg" and line:match(":%s*%[%s*$") then
            for j = i + 1, #block do
              if block[j]:match("^%s*%]") then
                last = j
                break
              end
            end
          end
          break
        end
      end

      if first then
        local updated = vim.list_extend(vim.list_slice(block, 1, first - 1), replacement)
        block = vim.list_extend(updated, block, last + 1)
      else
        block = vim.list_extend(block, replacement)
      end
    end
  end
  return block
end

---Rewrite fields of a note's frontmatter. A loaded buffer of the note is edited and written
---(including any unsaved changes); otherwise the file is edited on disk. Notes without
---frontmatter are left untouched.
---@param filename string
---@param fields table<string,string> New values for `title`, `keywords` (written as `tags`, `filetags`, or `categories`), `signature`, or `identifier`; `""` removes the field
---@return boolean updated Whether the note has frontmatter
M.update_frontmatter = function(filename, fields)
  for field in pairs(fields) do
    if not vim.tbl_contains(UPDATABLE_FIELDS, field) then
      error(string.format(
        "[denote] Cannot update frontmatter field %q; expected one of: %s",
        field,
        table.concat(UPDATABLE_FIELDS, ", ")
      ))
    end
  end

  local filetype = vim.filetype.match({ filename = filename }) or ""
  local buffer = Filesystem.buffer_for_path(filename)
  local loaded = buffer >= 0 and vim.api.nvim_buf_is_loaded(buffer)
  local lines = loaded and vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    or vim.fn.readfile(filename)

  local format, first, last = locate_frontmatter(lines, filetype)
  if not format then
    return false
  end
  local block = update_block(vim.list_slice(lines, first, last), format, fields)

  if loaded then
    vim.api.nvim_buf_set_lines(buffer, first - 1, last, false, block)
    vim.api.nvim_buf_call(buffer, function()
      vim.cmd("silent noautocmd write!")
    end)
  else
    local updated = vim.list_extend(vim.list_slice(lines, 1, first - 1), block)
    vim.fn.writefile(vim.list_extend(updated, lines, last + 1), filename)
  end
  return true
end

-- Generic interface for frontmatter handling

---Parse frontmatter
---@param filename string
---@param filetype string|nil
---@return table|nil frontmatter
M.parse_frontmatter = function(filename, filetype)
  filename = filename or vim.api.nvim_buf_get_name(0)
  filetype = filetype or vim.filetype.match({ filename = filename }) or vim.bo.filetype

  if filetype == "org" then
    return M.parse_org_frontmatter(filename)
  elseif filetype == "markdown" then
    local lines = vim.fn.readfile(filename, "", 3)
    if lines[1] == "---" then
      return M.parse_yaml_frontmatter(filename)
    elseif lines[1] == "+++" then
      return M.parse_toml_frontmatter(filename)
    end
  elseif filetype == "norg" then
    return M.parse_neorg_frontmatter(filename)
  else
    return M.parse_text_frontmatter(filename)
  end

  return nil
end

---Generate frontmatter
---@param fields table
---@param filetype string
---@return string
M.generate_frontmatter = function(fields, filetype)
  if filetype == "org" then
    return M.generate_org_frontmatter(fields)
  elseif filetype == "markdown-yaml" then
    return M.generate_yaml_frontmatter(fields)
  elseif filetype == "markdown-toml" then
    return M.generate_toml_frontmatter(fields)
  elseif filetype == "neorg" then
    return M.generate_neorg_frontmatter(fields)
  elseif filetype == "text" then
    return M.generate_text_frontmatter(fields)
  end

  error("[denote] Unsupported frontmatter filetype: " .. filetype)
end

return M
