---@module "denote.frontmatter"
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

---Update a specific field in the frontmatter
---@param filename string
---@param field string
---@param value string
function M.update_frontmatter_field(filename, field, value)
  local frontmatter = require("denote.helpers.frontmatter")
  local filetype = vim.fn.fnamemodify(filename, ":e")

  -- Map extensions to filetypes
  local ext_to_filetype = {
    org = "org",
    md = "markdown", -- Use generic markdown for detection
    txt = "text",
    norg = "text", -- Treat neorg as text for now
  }

  filetype = ext_to_filetype[filetype] or "text"

  -- Read current frontmatter
  local current_fm = frontmatter.parse_frontmatter(filename, filetype)
  if current_fm then
    -- Update the specific field
    current_fm[field] = value

    -- Detect YAML vs TOML for markdown files
    local actual_filetype = filetype
    if filetype == "markdown" then
      local lines = vim.fn.readfile(filename, "", 3)
      if lines[1] == "---" then
        actual_filetype = "markdown-yaml"
      elseif lines[1] == "+++" then
        actual_filetype = "markdown-toml"
      else
        actual_filetype = "markdown-yaml" -- Default
      end
    end

    -- Regenerate frontmatter
    local new_fm_content = frontmatter.generate_frontmatter(current_fm, actual_filetype)

    -- Replace frontmatter in file
    M.replace_frontmatter_in_file(filename, new_fm_content, actual_filetype)
  end
end

---Replace frontmatter in file
---@param filename string
---@param new_frontmatter string
---@param filetype string
function M.replace_frontmatter_in_file(filename, new_frontmatter, filetype)
  local lines = vim.fn.readfile(filename)
  local fm_end = 0

  -- Find where frontmatter ends based on filetype
  if filetype == "org" then
    for i, line in ipairs(lines) do
      if not line:match("^#+") and line ~= "" then
        fm_end = i - 1
        break
      elseif line == "" then
        fm_end = i - 1
        break
      end
    end
  elseif filetype == "markdown-yaml" then
    local yaml_count = 0
    for i, line in ipairs(lines) do
      if line == "---" then
        yaml_count = yaml_count + 1
        if yaml_count == 2 then
          fm_end = i
          break
        end
      end
    end
  elseif filetype == "markdown-toml" then
    local toml_count = 0
    for i, line in ipairs(lines) do
      if line == "+++" then
        toml_count = toml_count + 1
        if toml_count == 2 then
          fm_end = i
          break
        end
      end
    end
  else -- text
    for i, line in ipairs(lines) do
      if line:match("^%-+$") then
        fm_end = i
        break
      elseif line == "" then
        fm_end = i - 1
        break
      end
    end
  end

  -- Replace frontmatter
  if fm_end > 0 then
    local new_fm_lines = vim.split(new_frontmatter, "\n")
    -- Remove empty line at end if present
    if new_fm_lines[#new_fm_lines] == "" then
      table.remove(new_fm_lines)
    end

    -- Replace old frontmatter with new
    for _ = 1, fm_end do
      table.remove(lines, 1)
    end

    for i = #new_fm_lines, 1, -1 do
      table.insert(lines, 1, new_fm_lines[i])
    end

    vim.fn.writefile(lines, filename)
  end
end

---Remove frontmatter from file
---@param filename string
---@param filetype string
function M.remove_frontmatter(filename, filetype)
  local lines = vim.fn.readfile(filename)
  local content_start = 1

  -- Find where content starts (after frontmatter)
  if filetype == "org" then
    for i, line in ipairs(lines) do
      if not line:match("^#+") and line ~= "" then
        content_start = i
        break
      elseif line == "" and i > 1 then
        content_start = i + 1
        break
      end
    end
  elseif filetype == "markdown" then
    local first_line = lines[1] or ""
    if first_line == "---" then
      local yaml_count = 0
      for i, line in ipairs(lines) do
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
      for i, line in ipairs(lines) do
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
    for i, line in ipairs(lines) do
      if line:match("^%-+$") then
        content_start = i + 1
        break
      elseif line == "" and i > 1 then
        content_start = i
        break
      end
    end
  end

  -- Remove frontmatter, keep only content
  local content_lines = {}
  for i = content_start, #lines do
    table.insert(content_lines, lines[i])
  end

  vim.fn.writefile(content_lines, filename)
end

---Regenerate frontmatter for an existing file
---@param filename string
function M.regenerate_frontmatter(filename)
  filename = filename or vim.api.nvim_buf_get_name(0)
  local components = M.parse_filename(filename)

  if not components.identifier then
    error("This doesn't look like a Denote file")
    return
  end

  local filetype = vim.fn.fnamemodify(filename, ":e")
  local ext_to_filetype = {
    org = "org",
    md = "markdown-yaml",
    txt = "text",
    norg = "text",
  }
  filetype = ext_to_filetype[filetype] or "text"

  local frontmatter = require("denote.helpers.frontmatter")
  local fm_fields = {
    title = components.title ~= "" and components.title:gsub("%-%-", ""):gsub("%-", " ") or nil,
    date = components.identifier,
    keywords = components.keywords ~= "" and components.keywords:gsub("__", ""):gsub("_", " ")
      or nil,
    signature = components.signature ~= "" and components.signature
      :gsub("==", "")
      :gsub("=", " ") or nil,
    identifier = components.identifier,
  }

  local new_fm_content = frontmatter.generate_frontmatter(fm_fields, filetype)
  M.replace_frontmatter_in_file(filename, new_fm_content, filetype)
end

-- ---Synchronize frontmatter with filename
-- ---@param filename string
-- function M.sync_frontmatter(filename)
--   filename = filename or vim.api.nvim_buf_get_name(0)
--   local filetype = vim.filetype.match({ filename = filename })
--   local components = vim.tbl_deep_extend(
--     "force",
--     {},
--     M.parse_filename(filename),
--     require("denote.helpers.frontmatter").parse_frontmatter(filename, filetype)
--   )
--
-- end

return M
