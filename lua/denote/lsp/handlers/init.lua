---@module "denote.lsp.handlers"
---@author Carlos Vigil-Vásquez
---@license MIT 2026

local ms = vim.lsp.protocol.Methods
local handlers = {}

---@param _ lsp.HoverParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.Hover)
handlers[ms.textDocument_hover] = function(params, callback)
    local line = params.position.line
    local linecontent =
        vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), line, line + 1, false)[1]
end

-- Foward links
handlers[ms.textDocument_definition] = function(params, _)
    -- Get links
    local filepath = vim.uri_to_fname(params.textDocument.uri)
    local links = require("denote.links").get_links(filepath)

    -- Format loclist title
    local ft = vim.filetype.match({ filename = filepath })
    local components = require("denote.frontmatter").parse_frontmatter(filepath, ft)
        or require("denote.naming").parse_filename(filepath, false)
    local shorttitle = #components.title > 54 and components.title:sub(1, 51) .. "..."
        or components.title

    -- Set loclist and open
    vim.fn.setloclist(0, links, "r")
    vim.fn.setloclist(
        0,
        {},
        "r",
        { title = "Links in " .. components.identifier .. " '" .. shorttitle .. "'" }
    )
    vim.cmd("lopen")
end

-- backlinks
handlers[ms.textDocument_references] = function(params, _)
    -- Get backlinks
    local filepath = vim.uri_to_fname(params.textDocument.uri)
    local backlinks = require("denote.links").get_backlinks(filepath)

    -- Format loclist title
    local ft = vim.filetype.match({ filename = filepath })
    local components = require("denote.frontmatter").parse_frontmatter(filepath, ft)
        or require("denote.naming").parse_filename(filepath, false)
    local shorttitle = #components.title > 54 and components.title:sub(1, 51) .. "..."
        or components.title

    -- Set loclist and open
    vim.fn.setloclist(0, backlinks, "r")
    vim.fn.setloclist(
        0,
        {},
        "r",
        { title = "Backlinks for " .. components.identifier .. " '" .. shorttitle .. "'" }
    )
    vim.cmd("lopen")
end

-- Code actions
local commands = {
    rename_file = { desc = "Rename file", fn = require("denote.api").rename_file },
    rename_title = { desc = "Rename title", fn = require("denote.api").rename_file_title },
    rename_keywords = {
        desc = "Rename keywords",
        fn = require("denote.api").rename_file_keywords,
    },
    rename_signature = {
        desc = "Rename signature",
        fn = require("denote.api").rename_file_signature,
    },
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

---@param params lsp.InitializeParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.InitializeResult)
handlers[ms.initialize] = function(params, callback)
    local config = vim.g.denote

    -- Populate links cache (run once per neovim instance)
    if _G.denote_cache_links == nil then
        require("denote.links").populate_cache()
    end

    callback(nil, {
        capabilities = {
            referencesProvider = true,
            definitionProvider = true,
            hoverProvider = true,
            codeActionProvider = true,
            executeCommandProvider = { commands = vim.tbl_keys(commands) },
            textDocumentSync = 1,
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
