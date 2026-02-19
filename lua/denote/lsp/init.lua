local lsp = {}

---@param buf integer
---@return integer?
lsp.start = function(buf)
    local log = require("denote.core.logger")
    local handlers = require("denote.lsp.handlers")
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    local lsp_config = {
        name = "denote-ls",
        capabilities = capabilities,
        offset_encoding = "utf-8",
        cmd = function()
            return {
                request = function(method, ...)
                    local ok = pcall(handlers[method], ...)
                    return ok
                end,
                notify = function(method, ...)
                    local ok = pcall(handlers[method], ...)
                    return ok
                end,
                is_closing = function() end,
                terminate = function() end,
            }
        end,
        init_options = {},
        root_dir = tostring(vim.g.denote.directory),
    }

    local ok, client_id = pcall(vim.lsp.start, lsp_config, { bufnr = buf, silent = false })

    if not ok then
        log.error("Failed to start LSP client: " .. tostring(client_id))
        return nil
    end

    return client_id
end

return lsp
