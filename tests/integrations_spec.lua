local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

local function clear_modules(names)
  for _, name in ipairs(names) do
    package.loaded[name] = nil
    package.preload[name] = nil
  end
end

return {
  H.test("Telescope search sends note files to a picker", function()
    local directory = H.tmpdir()
    H.write_file(directory .. "/20250102T030405--one.md", { "# One" })
    H.write_file(directory .. "/20250102T040506--two.org", { "#+title: Two" })
    vim.g.denote = { directory = directory .. "/" }

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

    local registered
    local finder_options
    local picker_options
    local picker_started = false

    package.preload["telescope"] = function()
      return {
        register_extension = function(extension)
          registered = extension
          return extension
        end,
      }
    end
    package.preload["telescope.pickers.entry_display"] = function()
      return { create = function() return function() return {} end end }
    end
    package.preload["telescope.finders"] = function()
      return {
        new_table = function(options)
          finder_options = options
          return options
        end,
      }
    end
    package.preload["telescope.pickers"] = function()
      return {
        new = function(_, options)
          picker_options = options
          return {
            find = function()
              picker_started = true
            end,
          }
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
    extension.exports.search({})

    H.eq(extension, registered)
    H.eq(2, #finder_options.results)
    H.eq("Find Denote Files", picker_options.prompt_title)
    H.eq(true, picker_started)

    clear_modules(module_names)
    H.remove(directory)
  end),

  H.test("Orgmode follows Denote links to text notes", function()
    local directory = H.tmpdir()
    local identifier = "20250102T030405"
    local path = directory .. "/" .. identifier .. "--org-link.md"
    H.write_file(path, { "# Linked note" })
    vim.g.denote = { directory = directory .. "/" }
    package.loaded["denote.extensions.orgmode"] = nil

    local command
    local original_cmd = vim.cmd
    vim.cmd = function(value)
      command = value
    end

    local source = require("denote.extensions.orgmode"):new({ files = {} })
    local followed = source:follow("denote:" .. identifier)
    vim.cmd = original_cmd

    local matched_path = vim.fn.glob(directory .. "/" .. identifier .. "*", false, true)[1]
    H.eq(true, followed)
    H.eq("edit " .. vim.fn.fnameescape(matched_path), command)
    package.loaded["denote.extensions.orgmode"] = nil
    H.remove(directory)
  end),
}
