---@module "denote.lsp.handlers"
---@author Carlos Vigil-Vásquez
---@license MIT 2026

local ms = vim.lsp.protocol.Methods
local handlers = {}

---@param params lsp.HoverParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.Hover)
handlers[ms.textDocument_hover] = function(params, callback)
    local Links = require("denote.links")
    local Frontmatter = require("denote.frontmatter")
    local Naming = require("denote.naming")

    -- Helper to strip link syntax, keeping descriptions
    local function strip_links(text)
        -- Org: [[target][description]] -> description
        text = text:gsub("%[%[([^%]]+)%]%[([^%]]+)%]%]", "%2")
        -- Markdown: [description](target) -> description
        text = text:gsub("%[([^%]]+)%]%([^)]+%)", "%1")
        -- Neorg: {target}[description] -> description
        text = text:gsub("{[^}]+}%[([^%]]+)%]", "%1")
        return text
    end

    -- Get buffer and cursor position
    local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local line = params.position.line
    local col = params.position.character

    -- Check if cursor is on a denote link
    local identifier = Links.get_link_at_position(bufnr, line, col)
    if not identifier then
        ---@diagnostic disable-next-line: param-type-mismatch
        return callback(nil, nil)
    end

    -- Resolve identifier to filepath
    local ok, filepath = pcall(Links.identifier_to_path, identifier)
    if not ok or not filepath then
        ---@diagnostic disable-next-line: param-type-mismatch
        return callback(nil, nil)
    end

    -- Get frontmatter (title, keywords)
    local ft = vim.filetype.match({ filename = filepath })
    local components = Frontmatter.parse_frontmatter(filepath, ft)
        or Naming.parse_filename(filepath, false)

    -- Get content (all lines by default)
    local content_lines = Frontmatter.get_content_after_frontmatter(filepath)

    -- Format hover content as markdown
    -- TODO: add all relevant information (title, signature, keywords, etc.) and format nicely
    local hover_lines = {}
    table.insert(hover_lines, " # " .. (components.title or "Untitled"))
    if components.keywords and components.keywords ~= "" then
        local kw_str = type(components.keywords) == "table"
                and table.concat(components.keywords, ", ")
            or components.keywords
        table.insert(hover_lines, " **- Keywords:** " .. kw_str)
    end
    table.insert(hover_lines, "---")
    table.insert(hover_lines, "```" .. ft)

    -- Strip links from content lines
    for _, content_line in ipairs(content_lines) do
        table.insert(hover_lines, "    " .. strip_links(content_line) .. "    ")
    end

    table.insert(hover_lines, "```")

    -- Return hover result as markdown
    callback(nil, {
        contents = {
            kind = "markdown",
            value = table.concat(hover_lines, "\n"),
        },
    })
end

-- Get current buffer links
handlers[ms.textDocument_definition] = function(params, _)
    local filepath = vim.uri_to_fname(params.textDocument.uri)
    require("denote.api").links(filepath)
end

-- Get current buffer backlinks
handlers[ms.textDocument_references] = function(params, _)
    local filepath = vim.uri_to_fname(params.textDocument.uri)
    require("denote.api").backlinks(filepath)
end

-- Code actions
local commands = {
    rename_file = { desc = "Rename file", fn = require("denote.api").rename_file },
    links = { desc = "Get links", fn = require("denote.api").links },
    backlinks = { desc = "Get backlinks", fn = require("denote.api").backlinks },
}

---@param params lsp.ExecuteCommandParams
---@param callback fun(err?: lsp.ResponseError, result: any)
handlers[ms.workspace_executeCommand] = function(params, callback)
    local word = unpack(params.arguments)

    local ok, err = pcall(commands[params.command].fn, word)
    if not ok then
        ---@diagnostic disable-next-line: assign-type-mismatch
        return callback({ code = 1, message = err }, {})
    end
end

---@param _ lsp.CodeActionParams
---@param callback function
handlers[ms.textDocument_codeAction] = function(_, callback)
    local function new_action(cfg, command)
        local title = cfg.desc
        return {
            title = title,
            command = { title = title, command = command, arguments = {} },
        }
    end

    local res = {}
    for _, cmd_name in ipairs(vim.tbl_keys(commands)) do
        local config = commands[cmd_name]
        res[#res + 1] = new_action(config, cmd_name)
    end
    callback(nil, res)
end

---Adapted from none-ls
---gets word to complete for use in completion sources
---@param params lsp.CompletionParams
---@return string word_to_complete
local get_word_to_complete = function(params)
    local col = params.position.character + 1
    local line = vim.api.nvim_get_current_line()
    local line_to_cursor = line:sub(1, col)
    local regex = vim.regex("\\k*$")

    return line:sub(regex:match_str(line_to_cursor) + 1, col)
end

--TODO: Check https://github.com/obsidian-nvim/obsidian.nvim/blob/8af34a0532ae56e74ad7845a58eed5929d1813fa/lua/obsidian/lsp/handlers/completion.lua
---@param params lsp.CompletionParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.CompletionItem[])
handlers[ms.textDocument_completion] = function(params, callback)
    local word = get_word_to_complete(params)
    vim.print(word)
    local get_candidates = function(entries)
        entries = vim.fn.matchfuzzy(entries, word, { limit = 8 })
        local items = {}
        for k, v in ipairs(entries) do
            local c = require("denote.frontmatter").parse_frontmatter(v, vim.filetype.match({ filename = v }))
                or require("denote.naming").parse_filename(v, false)
            items[k] = {
                label = c.identifier,
                insertText = v,
                insertTextFormat=2,
                kind = vim.lsp.protocol.CompletionItemKind.File,
                documentation = {
                  kind = "markdown",
                  value = (
                    "*" .. c.identifier .. string.rep(" ", 32) .. string.sub(c.date, 2, -2) .. "*" .. "\n" ..
                    "# " .. c.title .. "\n" ..
                    "*" .. (c.signature or "") .. string.rep(" ", 32) .. (c.keywords and (type(c.keywords) == "table"
                        and table.concat(c.keywords, ", ")
                        or c.keywords) or "") .."*"
                  ),
                },
            }
        end

        return items
    end

    local candidates = get_candidates(vim.fn.glob(vim.g.denote.directory .. "*", true, true))

    callback(nil, {
        items = candidates,
        isIncomplete = #candidates > 0,
        max_width=80,
        max_height=24,
    })
end

---@param params lsp.InitializeParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.InitializeResult)
handlers[ms.initialize] = function(params, callback)
    local config = vim.g.denote

    callback(nil, {
        capabilities = {
            referencesProvider = true,
            definitionProvider = true,
            hoverProvider = true,
            codeActionProvider = true,
            executeCommandProvider = { commands = vim.tbl_keys(commands) },
            textDocumentSync = 1,
            completionProvider = { triggerCharacters = { "[[", "][" } },
        },
        serverInfo = {
            name = "denote-ls",
            version = "0.1.0",
        },
    })
end

return setmetatable(handlers, {
    __index = function(_, _)
        return function() end
    end,
})
