---@module "denote.excmds"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local api = require("denote.api")

local M = {}

---Setup Denote excommands
---@param options Denote.Configuration User provided configuration table
M.setup = function(options)
  vim.api.nvim_create_user_command("Denote", function(opts)
    if opts.fargs[1] == "note" then
      api.note(options)
    elseif opts.fargs[1] == "title" then
      api.title()
    elseif opts.fargs[1] == "keywords" then
      api.keywords()
    elseif opts.fargs[1] == "signature" then
      api.signature()
    elseif opts.fargs[1] == "extension" then
      api.extension()
    elseif opts.fargs[1] == "rename-file" then
      api.rename_file(options)
    elseif opts.fargs[1] == "frontmatter" then
      api.regenerate_frontmatter()
    ---@diagnostic disable-next-line: need-check-nil
    elseif opts.fargs[1] == "search" and options.integrations.telescope.enabled then
      require("denote.integrations.telescope").search(options)
    elseif opts.fargs[1] == "insert-link" and options.integrations.telescope.enabled then
      require("denote.integrations.telescope").insert_link(options, true)
    elseif opts.fargs[1] == "link" and options.integrations.telescope.enabled then
      require("denote.integrations.telescope").insert_link(options, false)
    else
      error("Unsupported operation " .. opts.fargs[1])
    end
  end, {
    nargs = 1,
    complete = function()
      -- Builtin
      local subcommands = {
        "note",
        "title",
        "keywords",
        "signature",
        "extension",
        "rename-file",
        "frontmatter",
        "insert-link",
      }

      -- Integrationg
      if options.integrations.telescope.enabled then
        table.insert(subcommands, "search")
      end

      return subcommands
    end,
  })
end

return M
