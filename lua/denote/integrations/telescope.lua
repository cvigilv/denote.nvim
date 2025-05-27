---@module "denote.extensions.telescope"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Internal = require("denote.internal")

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
        { components.date or "", "DenoteDate" },
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
  M.insert_link = function(options)
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
        { components.date or "", "DenoteDate" },
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
            local selection = action_state.get_selected_entry()

            -- Close telescope
            actions.close(prompt_bufnr)
            if not selection then
              return
            end


            -- TODO: Extract this function, add it to the API and accept a list of denote
            -- files / IDs to insert. In the case its a list, dont make it interactive and extract
            -- title from header or file path (in that order). If just 1 file, run interactively.
            -- TODO: Make 2 versions of insert link function: insert-link (which if this one) and
            -- link (which doesn't add the decription to the link)
            -- Extract link details based on your data structure
            local link_description = vim.fn.input({
              prompt = "[denote] Link description: ",
              default = Internal.parse_filename(selection.path, false)["title"]:gsub("-", " "),
            })
            local link_path = selection.path

            -- Create the markdown link
            local filetype = vim.bo[bufnr].filetype
            local link
            if string.match(filetype, "markdown") then
              link = string.format("[%s](%s)", link_description, link_path)
            elseif string.match(filetype, "neorg") then
              link = string.format("{%s:%s:}", link_description, link_path)
            else
              link = string.format("[[%s][%s]]", link_path, link_description)
            end

            -- Insert the markdown link at cursor position
            vim.api.nvim_put({ link }, "", true, true)
          end)

          -- Return true to keep other default mappings
          return true
        end,
      })
      :find()
  end
end

return M
