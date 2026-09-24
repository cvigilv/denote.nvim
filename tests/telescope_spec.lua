local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

local function clear_modules(names)
  for _, name in ipairs(names) do
    package.loaded[name] = nil
    package.preload[name] = nil
  end
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
        oil = false,
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
}
