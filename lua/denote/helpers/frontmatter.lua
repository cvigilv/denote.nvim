---@module "denote.helpers.frontmatter"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

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
    if line == "" then
      break
    end

    local field, value = line:match("^#%+(%w+):%s*(.*)")
    if field then
      field = field:lower()
      if field == "filetags" then
        frontmatter.keywords =
          value:gsub(":", " "):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
      elseif field == "date" then
        frontmatter.date = value:gsub("^%[", ""):gsub("%]$", "")
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
    local date_str = type(fields.date) == "number" and M.format_date_org(fields.date)
      or fields.date
    table.insert(lines, "#+date:       " .. date_str)
  end

  if fields.keywords then
    local tags = type(fields.keywords) == "table" and table.concat(fields.keywords, ":")
      or fields.keywords:gsub("%s+", ":")
    table.insert(lines, "#+filetags:   :" .. tags .. ":")
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
    local date_str = type(fields.date) == "number" and M.format_date_markdown(fields.date)
      or fields.date
    table.insert(lines, "date:       " .. date_str)
  end

  if fields.keywords then
    local tags = type(fields.keywords) == "table" and fields.keywords
      or vim.split(fields.keywords, "%s+")
    table.insert(lines, 'tags:       ["' .. table.concat(tags, '", "') .. '"]')
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
    local date_str = type(fields.date) == "number" and M.format_date_markdown(fields.date)
      or fields.date
    table.insert(lines, "date       = " .. date_str)
  end

  if fields.keywords then
    local tags = type(fields.keywords) == "table" and fields.keywords
      or vim.split(fields.keywords, "%s+")
    table.insert(lines, 'tags       = ["' .. table.concat(tags, '", "') .. '"]')
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
    local date_str = type(fields.date) == "number" and M.format_date_text(fields.date)
      or fields.date
    table.insert(lines, "date:       " .. date_str)
  end

  if fields.keywords then
    local tags = type(fields.keywords) == "table" and table.concat(fields.keywords, "  ")
      or fields.keywords
    table.insert(lines, "tags:       " .. tags)
  end

  if fields.identifier then
    table.insert(lines, "identifier: " .. fields.identifier)
  end

  table.insert(lines, "---------------------------")
  return table.concat(lines, "\n") .. "\n"
end

-- Generic frontmatter functions based on filetype
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

return M
