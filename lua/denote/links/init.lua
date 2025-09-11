---@module "denote.links"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

-- Forward Link Functions:
--
-- • denote-link - Create a link to another note with description
-- • denote-find-link - Use completion to visit a file linked from current file
-- • denote-link-after-creating - Create new note and immediately link to it
-- • denote-link-or-create - Link to existing note or create and link to new one
-- • denote-add-links - Insert multiple links matching a regexp pattern
-- • denote-link-to-file-with-contents - Link to files containing specific content
-- • denote-link-open-at-point - Open link under cursor
--
-- Backlink Functions:
--
-- • denote-backlinks - Show buffer with all backlinks to current note
-- • denote-find-backlink - Use completion to visit a file linking to current file
-- • denote-find-backlink-with-location - Visit backlink and jump to exact link location
--
-- ## Programmatic API (Non-interactive functions):
--
-- Data Retrieval:
--
-- • denote-get-links - Return list of files that current file links to
-- • denote-get-backlinks - Return list of files that link to current file
-- • denote-format-link - Format a link with proper syntax for file type
-- • denote-get-link-description - Get description text for a link
--
-- Internal/Helper Functions:
--
-- • denote-link--collect-identifiers - Extract identifiers from link text in buffer
-- • denote--get-all-backlinks - Internal function to collect all backlinks by identifier
-- • denote-retrieve-xref-alist-for-backlinks - Get xref data for backlink locations
-- • denote-fontify-links - Add syntax highlighting to links in buffer

local logger = require("denote.core.logger")

local function format_link(description, path, filetype)
  local link
  if string.match(filetype, "markdown") then
    link = string.format("[%s](%s)", description, path)
  elseif string.match(filetype, "norg") then
    link = string.format("{%s:%s:}", description, path)
  elseif string.match(filetype, "org") then
    link =
      string.format("[[denote:%s][%s]]", path:match(Naming.PATTERNS.identifier), description)
  else
    link = string.format("%s (%s)", description, path)
  end

  return link
end

local function get_all_files(opts)
  local exts = { "md", "org", "norg", "txt" }
  local files = {}
  for _, ext in ipairs(exts) do
    local found = vim.split(vim.fn.glob(opts.path .. "/*." .. ext), "\n", { trimempty = true })
    for _, f in ipairs(found) do
      table.insert(files, f)
    end
  end
  return files
end

local function identifier_to_path(identifier)
  local path = vim.fn.glob(vim.g.denote.directory .. identifier .. "*", false, true, true)
  if #path == 0 then
    error("No file found with identifier " .. identifier)
  elseif #path > 1 then
    error("Found more that one file with identifier " .. identifier)
  end
  return path[1]
end

local function resolve_link(link)
  if link:match("^denote:") then
    link = identifier_to_path(link:gsub("^denote:", ""))
  elseif link:match("^file:") then
    link = link:gsub("^file:", "")
  end
  return vim.fn.resolve(link)
end

local function extract_links(line, ext)
  local links = {}
  if ext == "markdown" then
    for link in line:gmatch("%[.-%]%((.-)%)") do
      table.insert(links, link)
    end
  elseif ext == "org" then
    for link in line:gmatch("%[%[([^%]]+)%]%[?[^%]]*%]?%]") do
      if
        link:match("^file:")
        or link:match("^denote:")
        or link:match("^%.%./")
        or link:match("^[^:]+/")
      then
        table.insert(links, resolve_link(link))
      end
    end
  elseif ext == "norg" then
    for link in line:gmatch("{(.-)}") do
      table.insert(links, link)
    end
    for link in line:gmatch("link::%s*(%S+)") do
      table.insert(links, link)
    end
  end
  return links
end

local M = {}

-- Get links for a given file
---@param filepath string The path of the file to find "to" links for
---@return table to_links Array of file paths that are linked from this file
M.get_links = function(filepath)
  local content = vim.fn.readfile(filepath)
  local filetype = vim.filetype.match({ filename = filepath })
  local links = {}
  if content ~= nil then
    local linenr = 0
    for _, line in ipairs(content) do
      linenr = linenr + 1
      for _, path in ipairs(extract_links(line, filetype)) do
        local link_data = { path = path, linenr = linenr }
        table.insert(links, link_data)
      end
    end
  end
  _G.denote_cache_links[filepath] = links
  return links
end

-- Get backlinks for a given file
---@param filepath string The path of the file to find "from" links for
---@return table from_links Array of file paths that link to the given file
M.get_backlinks = function(filepath)
  local backlinks = {}
  for fp, links in pairs(_G.denote_cache_links) do
    for _, link in ipairs(links) do
      if link.path == filepath then
        local ft = vim.filetype.match({ filename = fp })
        local components = require("denote.frontmatter").parse_frontmatter(fp, ft)
          or require("denote.naming").parse_filename(fp)
        table.insert(backlinks, {
          filename = fp,
          lnum = link.linenr,
          col = 0,
          text = components.title or vim.fs.basename(fp),
        })
      end
    end
  end
  return backlinks
end

return M
