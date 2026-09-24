local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

local function clear_modules(names)
  for _, name in ipairs(names) do
    package.loaded[name] = nil
    package.preload[name] = nil
  end
end

local function insert_links(source_path, source_filetype, target_paths)
  local module_names = {
    "telescope",
    "telescope._extensions.denote",
    "telescope.actions",
    "telescope.actions.state",
    "telescope.config",
    "telescope.finders",
    "telescope.pickers",
    "telescope.pickers.entry_display",
    "denote.ui.highlights",
  }
  clear_modules(module_names)

  local previous_config = vim.g.denote
  vim.g.denote = {
    directory = vim.fs.dirname(target_paths[1]),
    integrations = { telescope = { enabled = true, opts = {} } },
  }

  local source_bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(source_bufnr, source_path)
  vim.api.nvim_buf_set_lines(source_bufnr, 0, -1, false, { "" })
  vim.bo[source_bufnr].filetype = source_filetype
  vim.api.nvim_set_current_buf(source_bufnr)

  local entries = vim.tbl_map(function(path) return { path = path } end, target_paths)
  local callback
  local prompt_bufnr

  package.preload["telescope"] = function()
    return { register_extension = function(extension) return extension end }
  end
  package.preload["telescope.pickers.entry_display"] = function()
    return { create = function() return function() return {} end end }
  end
  package.preload["telescope.finders"] = function()
    return { new_table = function(options) return options end }
  end
  package.preload["telescope.pickers"] = function()
    return {
      new = function(_, config)
        return {
          find = function()
            prompt_bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_set_current_buf(prompt_bufnr)
            config.attach_mappings(prompt_bufnr, nil)
          end,
        }
      end,
    }
  end
  package.preload["telescope.config"] = function()
    return {
      values = {
        file_sorter = function() return nil end,
        file_previewer = function() return nil end,
      },
    }
  end
  package.preload["telescope.actions"] = function()
    return {
      select_default = {
        replace = function(_, replacement) callback = replacement end,
      },
      close = function() vim.api.nvim_set_current_buf(source_bufnr) end,
    }
  end
  package.preload["telescope.actions.state"] = function()
    return {
      get_current_picker = function()
        return {
          get_multi_selection = function() return #entries > 1 and entries or {} end,
        }
      end,
      get_selected_entry = function() return entries[1] end,
    }
  end
  package.preload["denote.ui.highlights"] = function()
    return { setup = function() end }
  end

  local extension = require("telescope._extensions.denote")
  extension.exports.insert_link()
  local ok, callback_error = pcall(callback)
  local lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)

  local cleanup_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(cleanup_bufnr)
  vim.api.nvim_buf_delete(source_bufnr, { force = true })
  if prompt_bufnr and vim.api.nvim_buf_is_valid(prompt_bufnr) then
    vim.api.nvim_buf_delete(prompt_bufnr, { force = true })
  end
  vim.g.denote = previous_config
  clear_modules(module_names)

  if not ok then
    error(callback_error)
  end
  return lines
end

return {
  H.test("Telescope integration loads and exposes Denote commands", function()
    local directory = H.tmpdir()
    local module_names = { "telescope", "denote.api" }
    clear_modules(module_names)
    pcall(vim.api.nvim_del_user_command, "Denote")
    vim.g.loaded_denote_plugin = nil
    vim.g.denote = {
      directory = directory,
      prompts = {},
      integrations = {
        highlights = false,
        telescope = { enabled = true, opts = {} },
      },
    }

    local loaded_extension
    local calls = {}
    package.preload["telescope"] = function()
      return {
        extensions = {
          denote = {
            search = function()
              calls[#calls + 1] = "search"
            end,
            insert_link = function()
              calls[#calls + 1] = "insert_link"
            end,
          },
        },
        load_extension = function(name)
          loaded_extension = name
        end,
      }
    end

    vim.cmd("runtime plugin/denote.lua")
    vim.bo.filetype = "markdown.denote"
    local completions = vim.fn.getcompletion("Denote ", "cmdline")
    vim.cmd("Denote search")
    vim.cmd("Denote insert-link")
    local accepted_link, link_error = pcall(vim.cmd, "Denote link")

    pcall(vim.api.nvim_del_user_command, "Denote")
    vim.g.loaded_denote_plugin = nil
    clear_modules(module_names)
    H.remove(directory)

    H.eq("denote", loaded_extension)
    H.eq({
      "backlinks",
      "insert-link",
      "rename-file",
      "rename-file-keywords",
      "rename-file-signature",
      "rename-file-title",
      "search",
    }, completions)
    H.eq({ "search", "insert_link" }, calls)
    H.eq(false, accepted_link)
    H.matches("Unsupported subcommand: link", link_error)
  end),

  H.test("Telescope pickers receive configured options", function()
    local directory = H.tmpdir()
    H.write_file(directory .. "/20250102T030405--one.md", { "# One" })
    vim.g.denote = {
      directory = directory .. "/",
      integrations = {
        telescope = {
          enabled = true,
          opts = {
            layout_strategy = "vertical",
            sorting_strategy = "ascending",
          },
        },
      },
    }

    local module_names = {
      "telescope",
      "telescope._extensions.denote",
      "telescope.config",
      "telescope.finders",
      "telescope.pickers",
      "telescope.pickers.entry_display",
      "denote.ui.highlights",
    }
    clear_modules(module_names)

    local picker_options
    local picker_config
    package.preload["telescope"] = function()
      return { register_extension = function(extension) return extension end }
    end
    package.preload["telescope.pickers.entry_display"] = function()
      return { create = function() return function() return {} end end }
    end
    package.preload["telescope.finders"] = function()
      return { new_table = function(options) return options end }
    end
    package.preload["telescope.pickers"] = function()
      return {
        new = function(options, config)
          picker_options = options
          picker_config = config
          return { find = function() end }
        end,
      }
    end
    package.preload["telescope.config"] = function()
      return {
        values = {
          file_sorter = function() return "sorter" end,
          file_previewer = function() return "previewer" end,
        },
      }
    end
    package.preload["denote.ui.highlights"] = function()
      return { setup = function() end }
    end

    local extension = require("telescope._extensions.denote")
    extension.exports.search({ sorting_strategy = "descending", prompt_prefix = "> " })

    H.eq({
      layout_strategy = "vertical",
      sorting_strategy = "descending",
      prompt_prefix = "> ",
    }, picker_options)
    H.eq(1, #picker_config.finder.results)

    clear_modules(module_names)
    H.remove(directory)
  end),

  H.test("Telescope inserts links relative to the saved source buffer", function()
    local root = H.tmpdir()
    local notes = root .. "/notes"
    local elsewhere = root .. "/elsewhere"
    local source = notes .. "/20250101T000000--source.md"
    local markdown_target = notes .. "/20250102T000000--markdown.md"
    local org_target = notes .. "/20250103T000000--org.org"
    H.write_file(source, { "# Source" })
    H.write_file(markdown_target, { "+++", 'title = "Markdown title"', "+++" })
    H.write_file(org_target, { "#+title: Org title" })
    vim.fn.mkdir(elsewhere, "p")

    local previous_directory = vim.fn.getcwd()
    vim.fn.chdir(elsewhere)
    local ok, lines = pcall(insert_links, source, "markdown.denote", {
      markdown_target,
      org_target,
    })
    vim.fn.chdir(previous_directory)
    H.remove(root)
    if not ok then
      error(lines)
    end

    H.eq({
      "",
      "- [Markdown title](20250102T000000--markdown.md)",
      "- [Org title](20250103T000000--org.org)",
    }, lines)
  end),

  H.test("Telescope uses filename metadata for a single link", function()
    local directory = H.tmpdir()
    local source = directory .. "/20250101T000000--source.md"
    local target = directory .. "/20250102T000000--filename-title.md"
    H.write_file(source, { "# Source" })
    H.write_file(target, { "No frontmatter" })

    local default_description
    local input = vim.fn.input
    vim.fn.input = function(options)
      default_description = options.default
      return "Custom title"
    end
    local ok, lines = pcall(insert_links, source, "markdown.denote", { target })
    vim.fn.input = input
    H.remove(directory)
    if not ok then
      error(lines)
    end

    H.eq("filename-title", default_description)
    H.eq({ "[Custom title](20250102T000000--filename-title.md)" }, lines)
  end),

  H.test("Telescope uses filename metadata for multiple links", function()
    local directory = H.tmpdir()
    local source = directory .. "/20250101T000000--source.md"
    local titled_target = directory .. "/20250102T000000--filename-title.md"
    local identifier_target = directory .. "/20250103T000000.md"
    H.write_file(source, { "# Source" })
    H.write_file(titled_target, { "No frontmatter" })
    H.write_file(identifier_target, { "No frontmatter" })

    local ok, lines = pcall(insert_links, source, "markdown.denote", {
      titled_target,
      identifier_target,
    })
    H.remove(directory)
    if not ok then
      error(lines)
    end

    H.eq({
      "",
      "- [filename-title](20250102T000000--filename-title.md)",
      "- [20250103T000000](20250103T000000.md)",
    }, lines)
  end),
}
