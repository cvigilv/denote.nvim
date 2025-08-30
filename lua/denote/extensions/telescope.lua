---@module "denote.extensions.telescope"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Naming = require("denote.naming")
local frontmatter = require("denote.frontmatter")

local function format_entry(filepath)
  -- Initialize results table
  local results = {}

  -- Find all matches for each pattern
  for name, pattern in pairs(Naming.PATTERNS) do
    for match in string.gmatch(filepath, pattern) do
      results[name] = match
    end
  end

  -- Check if format complies with denote file format
  results["filename"] = filepath
  if results.identifier then
    -- Remove data so it doesn't show in picker
    results["filename"] = ""

    -- Try to enhance with frontmatter data if this is a Denote file
    local filetype = vim.filetype.match({ filename = filepath })
    local fm_data = frontmatter.parse_frontmatter(filepath, filetype)
    if fm_data then
      -- Override with frontmatter data if available
      if fm_data.title then
        results.title = fm_data.title
      end
      if fm_data.keywords then
        results.keywords = type(fm_data.keywords) == "table"
            and table.concat(fm_data.keywords, " ")
          or fm_data.keywords
      end
    end
  end

  return results
end

local M = {}

--- Setup Telescope integration
---@param opts? Denote.Configuration User configuration
---@diagnostic disable-next-line: unused-local
M.setup = function(opts)
  -- Check if telescope exists
  local telescope_installed, _ = pcall(require, "telescope")

  if not telescope_installed then
    error("[denote] This plugin requires nvim-telescope/telescope.nvim")
  end

  -- Initialize
  local entry_display = require("telescope.pickers.entry_display")
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  require("denote.ui.highlights").setup()

  ---Search note
  ---@param options Denote.Configuration User configuration
  M.search = function(options)
    ---@type Denote.Configuration
    local tele_opts = options.integrations.telescope.opts

    -- Define how to build entry for Telescope
    local make_display = function(entry)
      local components = format_entry(entry.value)

      local displayer = entry_display.create({
        separator = " ",
        items = { {}, {}, {}, {}, {}, {} },
      })

      return displayer({
        { components.identifier or "", "DenoteDate" },
        { components.signature or "", "DenoteSignature" },
        { components.title or "", "DenoteTitle" },
        { components.keywords or "", "DenoteKeyword" },
        { components.extension or "", "DenoteExtension" },
        { components.filename or "", "Comment" },
      })
    end

    local files = vim.fn.glob(options.directory .. "*", false, true)

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
        sorter = conf.file_sorter({}),
        previewer = conf.file_previewer({}),
      })
      :find()
  end

  ---Insert link prompt
  ---@param options Denote.Configuration User configuration
  ---@param interactive boolean Whether to prompt for description when inserting link
  M.insert_link = function(options, interactive)
    ---@type Denote.Configuration
    local tele_opts = options.integrations.telescope.opts

    -- Define how to build entry for Telescope
    local make_display = function(entry)
      local components = format_entry(entry.value)

      local displayer = entry_display.create({
        separator = "  ",
        items = { {}, {}, {}, {}, {}, {} },
      })

      return displayer({
        { components.identifier or "", "DenoteDate" },
        { components.signature or "", "DenoteSignature" },
        { components.title or "", "DenoteTitle" },
        { components.keywords or "", "DenoteKeyword" },
        { components.extension or "", "DenoteExtension" },
        { components.filename or "", "Comment" },
      })
    end

    local files = vim.fn.glob(options.directory .. "*", false, true)
    local bufnr = vim.api.nvim_get_current_buf()

    pickers
      .new(tele_opts, {
        prompt_title = "Insert link to Denote file",
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
        sorter = conf.file_sorter({}),
        previewer = conf.file_previewer({}),
        attach_mappings = function(prompt_bufnr, _)
          -- Register the action without binding it to a key
          actions.select_default:replace(function()
            -- Helper function to calculate relative path
            local function get_relative_path(entry_path)
              return vim.fs.relpath(
                vim.fs.normalize(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")),
                vim.fs.normalize(entry_path)
              )
            end

            -- Helper function to format link based on filetype
            local function format_link(description, path, filetype, is_list_item)
              local prefix = is_list_item and "- " or ""
              local link
              if string.match(filetype, "markdown") then
                link = string.format("[%s](%s)", description, path)
              elseif string.match(filetype, "neorg") then
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

              return prefix .. link
            end

            -- Get selected entries
            local picker = action_state.get_current_picker(prompt_bufnr)
            local multi_selection = picker:get_multi_selection()
            local entries = {}
            if #multi_selection > 0 then
              entries = multi_selection
            else
              local current_entry = action_state.get_selected_entry()
              if current_entry then
                table.insert(entries, current_entry)
              end
            end

            -- Close picker if no entries are selected
            actions.close(prompt_bufnr)
            if #entries == 0 then
              return
            end

            -- Process all entries in a single loop
            local filetype = vim.bo[bufnr].filetype
            local is_multiple = #entries > 1
            local links = {}

            for _, entry in ipairs(entries) do
              local path = get_relative_path(entry.path)
              local description

              if not is_multiple and interactive then
                description = vim.fn.input({
                  prompt = "[denote] Link description: ",
                  default = frontmatter.parse_frontmatter(entry.path, filetype)["title"]
                    or Naming.parse_filename(entry.path, false)["title"]:gsub("-", " ")
                    or "",
                })
              else
                description = frontmatter.parse_frontmatter(entry.path, filetype)["identifier"]
                  or Naming.parse_filename(entry.path)["identifier"]
              end

              table.insert(links, format_link(description, path, filetype, is_multiple))
            end

            -- Insert links
            local put_type = is_multiple and "l" or ""
            vim.api.nvim_put(links, put_type, true, true)
          end)

          -- Return true to keep other default mappings
          return true
        end,
      })
      :find()
  end
end

return M
