---@module "denote.extensions.telescope"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Internal = require("denote.internal")

local function format_entry(filename)
  -- Define patterns
  local patterns = {
    identifier = "(%d%d%d%d%d%d%d%dT%d%d%d%d%d%d)",
    signature = "==([a-zA-Z0-9=]+)",
    title = "%-%-([a-z0-9%-]+)",
    keywords = "__([a-z0-9_]+)",
    extension = "(%.[^%s%.]+)",
  }

  -- Initialize results table
  local results = {}

  -- Find all matches for each pattern
  for name, pattern in pairs(patterns) do
    for match in string.gmatch(filename, pattern) do
      results[name] = match
    end
  end

  -- Check if format complies with denote file format
  results["filename"] = filename
  if results.identifier then
    results["filename"] = ""

    -- Try to enhance with frontmatter data if this is a Denote file
    local filepath = filename
    local ext = vim.fn.fnamemodify(filepath, ":e"):lower()
    local filetype = "text" -- default
    if ext == "org" then
      filetype = "org"
    elseif ext == "md" then
      filetype = "markdown"
    end

    local frontmatter = require("denote.helpers.frontmatter")
    local fm_data = frontmatter.parse_frontmatter(filepath, filetype)
    if fm_data then
      -- Override with frontmatter data if available (use literally)
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
---@param opts Denote.Configuration User configuration
M.setup = function(opts)
  local entry_display = require("telescope.pickers.entry_display")
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- Check if telescope exists
  local telescope_installed, _ = pcall(require, "telescope")

  if not telescope_installed then
    error("This plugin requires nvim-telescope/telescope.nvim")
  end

  -- Initialize
  require("denote.helpers.highlights").setup()

  -- Generate searchers
  M.search = function(options)
    ---@type Denote.Configuration
    local tele_opts = options.integrations.telescope.opts

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
  M.insert_link = function(options, interactive)
    ---@type Denote.Configuration
    local tele_opts = options.integrations.telescope.opts

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
              else
                link = string.format("[[file:%s][%s]]", path, description)
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
                  default = Internal.parse_filename(entry.path, false)["title"]:gsub("-", " "),
                })
              else
                description = Internal.parse_filename(entry.path)["identifier"]
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
