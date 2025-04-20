---@module "denote.excmds"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local api = require("denote.api")

local M = {}

---Setup Denote excommands
---@param options Denote.Configuration|nil User provided configuration table
M.setup = function(options)
  vim.api.nvim_create_user_command("Denote", function(opts)
    if opts.fargs[1] == "note" then
      api.note(options --[[@as table]])
    elseif opts.fargs[1] == "title" then
      api.title(options --[[@as table]])
    elseif opts.fargs[1] == "keywords" then
      api.keywords()
    elseif opts.fargs[1] == "signature" then
      api.signature()
    elseif opts.fargs[1] == "extension" then
      api.extension()
    ---@diagnostic disable-next-line: need-check-nil
    elseif options.integrations.telescope and opts.fargs[1] == "search" then
      require("denote.integrations.telescope").search(options)
    else
      error("Unsupported operation " .. opts.fargs[1])
    end
  end, {
    nargs = 1,
    complete = function()
      local subcommands = { "note", "title", "keywords", "signature", "extension" }

      ---@diagnostic disable-next-line: need-check-nil
      if options.integrations.telescope then
        table.insert(subcommands, "search")
      end

      return subcommands
    end,
  })
end

return M
