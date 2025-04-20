---@module "denote.extensions.telescope"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local function format_entry(text)
  -- Define patterns
  local patterns = {
    date = "(%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)",
    signature = "==([a-zA-Z0-9=]+)",
    title = "%-%-([a-z0-9%-]+)",
    keywords = "__([a-z0-9_]+)",
    extension = "(%.[^%s%.]+)",
  }

  -- Initialize results table
  local results = {}

  -- Find all matches for each pattern
  for name, pattern in pairs(patterns) do
    for match in string.gmatch(text, pattern) do
      results[name] = match
    end
  end

  -- Check if format complies with denote file format
  results["filename"] = text
  if results.date then
    results["filename"] = ""
  end

  return results
end

local M = {}

M.setup = function(opts)
  -- Check if telescope exists
  local telescope_installed, _ = pcall(require, "telescope")

  if not telescope_installed then
    error("This plugin requires nvim-telescope/telescope.nvim")
  end

  -- Initialize
  require("denote.helpers.highlights").setup()

  -- Generate searchers
  M.search = function(tele_opts)
    tele_opts = tele_opts or {}

    -- Define how to build entry for Telescope
    local make_display = function(entry)
      local components = format_entry(vim.fs.basename(entry.value))

      local displayer = entry_display.create({
        separator = "  ",
        items = {
          { remaining = true },
          { remaining = true },
          { remaining = true },
          { remaining = true },
          { remaining = true },
          { remaining = true },
        },
      })

      return displayer({
        { components.date or "", "DenoteDate" },
        { components.signature or "", "DenoteSignature" },
        { components.title or "", "DenoteTitle" },
        { components.keywords or "", "DenoteExtension" },
        { components.extension or "", "DenoteExtension" },
        { components.filename or "", "Comment" },
      })
    end

    local files = vim.fn.glob(opts.directory .. "*", false, true)

    pickers
      .new(tele_opts, {
        prompt_title = "Find Denote Files",
        finder = finders.new_table({
          results = files,
          entry_maker = function(entry)
            return {
              value = entry,
              display = make_display,
              ordinal = entry,
              path = entry,
            }
          end,
        }),
        sorter = conf.file_sorter(tele_opts),
        previewer = conf.file_previewer(tele_opts),
      })
      :find()
  end
end

return M
