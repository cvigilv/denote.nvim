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

local function format_link(description, path, filetype)
    local link
    if string.match(filetype, "markdown") then
        link = string.format("[%s](%s)", description, path)
    elseif string.match(filetype, "norg") then
        link = string.format("{%s:%s:}", description, path)
    elseif string.match(filetype, "org") then
        link = string.format(
            "[[denote:%s][%s]]",
            path:match(Naming.PATTERNS.identifier),
            description
        )
    else
        link = string.format("%s (%s)", description, path)
    end

    return link
end

local function get_all_files(opts)
    local exts = { "md", "org", "norg", "txt" }
    local files = {}
    for _, ext in ipairs(exts) do
        local found =
            vim.split(vim.fn.glob(opts.path .. "/*." .. ext), "\n", { trimempty = true })
        for _, f in ipairs(found) do
            table.insert(files, f)
        end
    end
    return files
end


local function resolve_link(link)
    if link:match("^denote:") then
        link = M.identifier_to_path(link:gsub("^denote:", ""))
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

function M.identifier_to_path(identifier)
    local path = vim.fn.glob(vim.g.denote.directory .. identifier .. "*", false, true, true)
    if #path == 0 then
        error("No file found with identifier " .. identifier)
    elseif #path > 1 then
        error("Found more that one file with identifier " .. identifier)
    end
    return path[1]
end

-- Get links for a given file
---@param filepath string The path of the file to find "to" links for
---@return table to_links Array of file paths that are linked from this file
M.get_links = function(filepath)
    filepath = filepath or vim.api.nvim_buf_get_name(0)
    local links = {}
    vim.cmd("silent! lgrep denote:............... " .. filepath)
    local loclist = vim.fn.getloclist(0)
    for _, item in ipairs(loclist) do
        local line = vim.api.nvim_buf_get_lines(0, item.lnum - 1, item.lnum, false)[1]
        for link in line:gmatch("denote:(...............)") do
            local fp = vim.fn.glob(vim.g.denote.directory .. link .. "*", false, true)[1]
            table.insert(links, {
                filename = fp,
                lnum = 1,
                col = 1,
                text = line,
            })
        end
    end
    return links
end

-- Get backlinks for a given file
---@param filepath string The path of the file to find "from" links for
---@return table from_links Array of file paths that link to the given file
M.get_backlinks = function(filepath)
    filepath = filepath or vim.api.nvim_buf_get_name(0)
    local components = require("denote.naming").parse_filename(filepath, false)
    vim.cmd("silent! lgrep denote." .. components.identifier .. " " .. vim.g.denote.directory)
    return vim.fn.getloclist(0)
end

---Get denote identifier at cursor position (supports full link syntax)
---@param bufnr number Buffer number
---@param line number 0-indexed line number
---@param col number 0-indexed column number
---@return string|nil identifier The denote identifier under cursor, or nil
function M.get_link_at_position(bufnr, line, col)
    local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
    if not line_content then
        return nil
    end

    local identifier_pattern = "(%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)"

    -- Patterns for full link syntax (ordered from most specific to least)
    local link_patterns = {
        -- Org: [[denote:ID][description]] or [[denote:ID]]
        "%[%[denote:" .. identifier_pattern .. "%]%[[^%]]*%]%]",
        "%[%[denote:" .. identifier_pattern .. "%]%]",
        -- Markdown: [description](denote:ID)
        "%[[^%]]*%]%(denote:" .. identifier_pattern .. "%)",
        -- Neorg: {denote:ID}[description] or {denote:ID}
        "{denote:" .. identifier_pattern .. "}%[[^%]]*%]",
        "{denote:" .. identifier_pattern .. "}",
        -- Bare denote:ID (fallback)
        "denote:" .. identifier_pattern,
    }

    for _, pattern in ipairs(link_patterns) do
        local search_start = 1
        while true do
            local match_start, match_end, identifier = line_content:find(pattern, search_start)
            if not match_start then
                break
            end
            -- col is 0-indexed, match positions are 1-indexed
            if col >= (match_start - 1) and col < match_end then
                return identifier
            end
            search_start = match_end + 1
        end
    end

    return nil
end

return M
