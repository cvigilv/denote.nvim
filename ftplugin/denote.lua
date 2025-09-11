---@author Carlos Vigil-Vásquez
---@license MIT 2025

local options = vim.g.denote

vim.api.nvim_create_user_command("Denote", function(opts)
  -- Core
  local cmd = opts.fargs
  if #cmd == 0 then
    require("denote.api").denote()
  elseif cmd[1] == "rename-file" then
    require("denote.api").rename_file()
  elseif cmd[1] == "rename-file-title" then
    require("denote.api").rename_file_title()
  elseif cmd[1] == "rename-file-keywords" then
    require("denote.api").rename_file_keywords()
  elseif cmd[1] == "rename-file-signature" then
    require("denote.api").rename_file_signature()
  elseif cmd[1] == "backlinks" then
    require("denote.api").backlinks()
  else
    error("[denote] Unsupported operation " .. opts.fargs[1])
  end
end, {
  desc = "Denote user commands",
  nargs = "*",
  complete = function()
    -- Builtin
    local subcommands = {
      "rename-file",
      "rename-file",
      "rename-file-title",
      "rename-file-keywords",
      "rename-file-signature",
      "backlinks",
    }

    -- Integrations
    if options.integrations.telescope.enabled then
      table.insert(subcommands, "search")
      table.insert(subcommands, "insert-link")
      table.insert(subcommands, "link")
    end

    return subcommands
  end,
})
