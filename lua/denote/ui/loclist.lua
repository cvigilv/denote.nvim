---@module "denote.ui.loclist"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

-- filepath: lua/custom_loclist.lua
local api = vim.api

local loclist = {
  {
    identifier = "main-10",
    title = "Main Function",
    signature = "function main(args)",
    file_tags = { "entry", "core" },
    extension = ".lua",
    text = "main.lua:10",
    lnum = 10,
    col = 5,
    file = "main.lua",
    link_type = "tolink",
    hl = "Added",
    expanded = false,
    children = {
      {
        identifier = "utils-3",
        title = "Utility Helper",
        signature = "function helper(x)",
        file_tags = { "helper" },
        extension = ".lua",
        text = "utils.lua:3",
        lnum = 3,
        col = 1,
        file = "utils.lua",
        link_type = "backlink",
        hl = "Removed",
        expanded = false,
        children = {
          {
            identifier = "core-8",
            title = "Core Logic",
            signature = "function core(y)",
            file_tags = { "core", "logic" },
            extension = ".lua",
            text = "core.lua:8",
            lnum = 8,
            col = 2,
            file = "core.lua",
            link_type = "bidirectional",
            hl = "Changed",
          },
        },
      },
    },
  },
  {
    identifier = "config-20",
    title = "Config Loader",
    signature = "function load_config()",
    file_tags = { "config" },
    extension = ".lua",
    text = "config.lua:20",
    lnum = 20,
    col = 1,
    file = "config.lua",
    link_type = "bidirectional",
    hl = "Changed",
    expanded = false,
    children = {
      {
        identifier = "main-25",
        title = "Main Entry",
        signature = "function main_entry()",
        file_tags = { "entry" },
        extension = ".lua",
        text = "main.lua:25",
        lnum = 25,
        col = 4,
        file = "main.lua",
        link_type = "tolink",
        hl = "Added",
      },
    },
  },
}

local flat_entries = {}

local function pad(str, len)
  str = tostring(str)
  if #str >= len then
    return str:sub(1, len)
  end
  return str .. string.rep(" ", len - #str)
end

local function format_entry(entry, level)
  local type_icon = ({
    backlink = "←", -- U+2190
    tolink = "→", -- U+2192
    bidirectional = "↔", -- U+2194
  })[entry.link_type] or " "
  local triangle_str = entry.children and (entry.expanded and "▼" or "▶") or " "
  local tags = entry.file_tags and table.concat(entry.file_tags, ", ") or ""

  -- Column widths
  local file_col = 20
  local id_sig_col = 30
  local title_col = 28

  local file_str = pad(entry.file, file_col)
  local id_sig_str = pad(entry.identifier .. "==" .. entry.signature, id_sig_col)
  local title_str = pad(entry.title .. " (" .. tags .. ")", title_col)

  -- Level prefix
  local level_str = "#" .. tostring(level)

  -- Compose line
  local line = level_str .. " " .. file_str .. " | " .. id_sig_str .. " | " .. title_str

  -- Add icon and triangle at the end, with padding for alignment
  line = line .. " " .. type_icon .. " " .. triangle_str

  return line
end

local function flatten_loclist(loclist, level)
  level = level or 0
  local lines = {}
  local highlights = {}
  flat_entries = {}
  local function recurse(entries, level)
    for _, entry in ipairs(entries) do
      local line = format_entry(entry, level)
      table.insert(lines, line)
      table.insert(highlights, { hl = entry.hl, line = #lines, col_start = 0, col_end = #line })
      table.insert(flat_entries, entry)
      if entry.children and entry.expanded then
        recurse(entry.children, level + 1)
      end
    end
  end
  recurse(loclist, level)
  return lines, highlights
end

local function jump_to_entry(entry)
  if entry.file and entry.lnum then
    vim.cmd("edit " .. entry.file)
    api.nvim_win_set_cursor(0, { entry.lnum, (entry.col or 1) - 1 })
  end
end

local function toggle_expand(entry)
  if entry.children then
    entry.expanded = not entry.expanded
  end
end

local function open_loclist()
  vim.cmd("botright 16split")
  local win = api.nvim_get_current_win()
  local buf = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(win, buf)

  local function render()
    local lines, highlights = flatten_loclist(loclist)
    api.nvim_buf_set_option(buf, "modifiable", true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    api.nvim_buf_clear_namespace(buf, 0, 0, -1)
    for _, hl in ipairs(highlights) do
      api.nvim_buf_add_highlight(buf, 0, hl.hl, hl.line - 1, hl.col_start, hl.col_end)
    end
    api.nvim_buf_set_option(buf, "modifiable", false)
  end

  render()

  api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
    noremap = true,
    callback = function()
      local line = api.nvim_win_get_cursor(win)[1]
      local entry = flat_entries[line]
      if entry then
        jump_to_entry(entry)
      end
    end,
  })
  api.nvim_buf_set_keymap(buf, "n", "<Tab>", "", {
    noremap = true,
    callback = function()
      local line = api.nvim_win_get_cursor(win)[1]
      local entry = flat_entries[line]
      if entry and entry.children then
        toggle_expand(entry)
        render()
        api.nvim_win_set_cursor(win, { line, 0 })
      end
    end,
  })
  api.nvim_buf_set_keymap(buf, "n", "q", "", {
    noremap = true,
    callback = function()
      api.nvim_win_close(win, true)
    end,
  })
  api.nvim_buf_set_keymap(buf, "n", "j", "j", { noremap = true })
  api.nvim_buf_set_keymap(buf, "n", "k", "k", { noremap = true })

  api.nvim_buf_set_option(buf, "buftype", "nofile")
end

open_loclist()

return M
