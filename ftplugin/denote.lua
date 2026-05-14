---@author Carlos Vigil-Vásquez
---@license MIT 2025

vim.api.nvim_create_user_command("Denote", function(opts)
  vim.deprecate(":Denote", "Refer to :h denote-user-cmds for more information", "1.0", "denote.nvim", true)

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
  elseif cmd[1] == "links" then
    require("denote.api").links()
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
      "rename-file-title",
      "rename-file-keywords",
      "rename-file-signature",
      "links",
      "backlinks",
    }
    return subcommands
  end,
})

require("denote.lsp").start()

vim.api.nvim_create_user_command("DenoteNew", function(opts)
  -- Normal mode (no range): interactive note creation
  if opts.range == 0 then
    require("denote.api").denote()
    return
  end

  -- Visual mode (range provided): create note from selection
  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")

  -- Reject multi-line selections
  if start_pos[1] ~= end_pos[1] then
    vim.notify("[denote] Multi-line selections are not supported, use a single-line selection", vim.log.levels.WARN)
    return
  end

  -- Extract selected text (single line, clamp end column for V / v$ selections)
  local line = vim.api.nvim_buf_get_lines(0, start_pos[1] - 1, start_pos[1], false)[1]
  local end_col = math.min(end_pos[2] + 1, #line)
  local selected_text = line:sub(start_pos[2] + 1, end_col)

  -- Empty selection: fallback to interactive
  if selected_text == "" then
    require("denote.api").denote()
    return
  end

  -- Save source buffer context
  local src_bufnr = vim.api.nvim_get_current_buf()
  local src_filetype = vim.bo[src_bufnr].filetype

  -- Build fields from selection (pass raw text as title so frontmatter is human-readable)
  local identifier = require("denote.naming").generate_timestamp()

  -- Create note on disk without opening it
  local filepath = require("denote.api").denote({
    identifier = identifier,
    title = selected_text,
  }, false)

  -- Replace selected text with a link in the source buffer
  local link = require("denote.core.links").format_link(selected_text, filepath, src_filetype)
  vim.api.nvim_buf_set_text(src_bufnr, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_col, { link })

  -- Save source buffer and open the newly created note
  vim.api.nvim_buf_call(src_bufnr, function() vim.cmd("write") end)
  vim.cmd("edit " .. filepath)
end, {
  desc = "Create a new Denote note, or create from visual selection and insert link",
  range = true,
})
