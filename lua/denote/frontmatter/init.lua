---@module "denote.helpers.frontmatter"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

-- Helper functions
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

  if fields.signature then
    table.insert(lines, "#+signature:  " .. fields.signature)
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

  table.insert(lines, "+++")
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

  table.insert(lines, "---------------------------")
  return table.concat(lines, "\n") .. "\n"
end

-- Generic interface for frontmatter handling

---Parse frontmatter
---@param filename string
---@param filetype string|nil
---@return table|nil frontmatter
M.parse_frontmatter = function(filename, filetype)
  filename = filename or vim.api.nvim_buf_get_name(0)
  filetype = filetype or vim.bo.filetype

  if filetype == "org" then
    return M.parse_org_frontmatter(filename)
  elseif filetype == "markdown" then
    local lines = vim.fn.readfile(filename, "", 3)
    if lines[1] == "---" then
      return M.parse_yaml_frontmatter(filename)
    elseif lines[1] == "+++" then
      return M.parse_toml_frontmatter(filename)
    end
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
  else
    return M.generate_text_frontmatter(fields)
  end
end

---Get file content after frontmatter
---@param filename string Path to the file
---@param max_lines number? Maximum lines to return (default: all lines)
---@return string[] lines Content lines after frontmatter
function M.get_content_after_frontmatter(filename, max_lines)
  max_lines = max_lines or math.huge
  local lines = vim.fn.readfile(filename)
  if #lines == 0 then
    return {}
  end

  local content_start = 1
  local first_line = lines[1]

  -- YAML frontmatter (---)
  if first_line == "---" then
    for i = 2, #lines do
      if lines[i] == "---" then
        content_start = i + 1
        break
      end
    end
  -- TOML frontmatter (+++)
  elseif first_line == "+++" then
    for i = 2, #lines do
      if lines[i] == "+++" then
        content_start = i + 1
        break
      end
    end
  -- Org frontmatter (#+)
  elseif first_line:match("^#%+") then
    for i = 1, #lines do
      if not lines[i]:match("^#%+") and lines[i] ~= "" then
        content_start = i
        break
      elseif lines[i] == "" then
        content_start = i + 1
        break
      end
    end
  -- Plain text frontmatter (ends with --- separator)
  elseif first_line:match("^%w+:%s*") then
    for i = 1, #lines do
      if lines[i]:match("^%-+$") or lines[i] == "" then
        content_start = i + 1
        break
      end
    end
  end

  -- Skip leading empty lines after frontmatter
  while content_start <= #lines and lines[content_start] == "" do
    content_start = content_start + 1
  end

  -- Return content up to max_lines
  local result = {}
  for i = content_start, math.min(#lines, content_start + max_lines - 1) do
    table.insert(result, lines[i])
  end

  return result
end

return M
