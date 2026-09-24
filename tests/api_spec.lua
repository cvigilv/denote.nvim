local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

return {
  H.test("rename title builds the destination inside the note directory", function()
    local directory = H.tmpdir()
    local old_path = directory .. "/20250102T030405--old-title.md"
    H.write_file(old_path, { "old contents" })
    vim.g.denote = { directory = directory .. "/", prompts = {} }

    local Filesystem = require("denote.core.fs")
    local original_replace_file = Filesystem.replace_file
    local replaced = {}
    Filesystem.replace_file = function(old_filename, new_filename)
      replaced = { old_filename, new_filename }
      return true
    end

    local ok = require("denote.api").rename_file_title(old_path, "New title")
    Filesystem.replace_file = original_replace_file

    H.eq(true, ok)
    H.eq(old_path, replaced[1])
    H.eq(directory .. "/20250102T030405--new-title.md", replaced[2])
    H.remove(directory)
  end),

  H.test("renaming a note moves its cached source entry", function()
    local directory = H.tmpdir()
    local old_path = directory .. "/20250102T030405--old-title.md"
    local new_path = directory .. "/20250102T030405--new-title.md"
    H.write_file(old_path, { "[Target](target.md)" })
    vim.g.denote = { directory = directory .. "/", prompts = {} }
    _G.denote_cache_links = {}

    local Filesystem = require("denote.core.fs")
    local Links = require("denote.links")
    local old_cache_path = Filesystem.canonical_path(old_path)
    local cached_links = Links.get_links(old_path)
    local ok, err = pcall(require("denote.api").rename_file_title, old_path, "New title")

    if not ok then
      H.remove(directory)
      error(err)
    end

    H.eq(nil, _G.denote_cache_links[old_cache_path])
    H.eq(cached_links, _G.denote_cache_links[Filesystem.canonical_path(new_path)])
    H.truthy(vim.uv.fs_stat(new_path))
    H.remove(directory)
  end),

  H.test("note creation sequences asynchronous prompts", function()
    local directory = H.tmpdir()
    vim.g.denote = require("denote.config").update_config({
      directory = directory,
      filetype = "markdown-toml",
      prompts = { "signature", "title", "keywords" },
    })

    local Naming = require("denote.naming")
    local original_timestamp = Naming.generate_timestamp
    local original_input = vim.ui.input
    local requests = {}
    local initial_buffer = vim.api.nvim_get_current_buf()
    local created_buffer
    local created_path
    local created_lines

    Naming.generate_timestamp = function()
      return "20250102T030405"
    end
    vim.ui.input = function(options, callback)
      requests[#requests + 1] = { options = options, callback = callback }
    end

    local prompt_counts = {}
    local buffers = {}
    local ok, err = pcall(function()
      require("denote.api").denote()
      prompt_counts[1] = #requests
      buffers[1] = vim.api.nvim_get_current_buf()
      requests[1].callback("1a")
      prompt_counts[2] = #requests
      buffers[2] = vim.api.nvim_get_current_buf()
      requests[2].callback("Project plan")
      prompt_counts[3] = #requests
      buffers[3] = vim.api.nvim_get_current_buf()
      requests[3].callback("neovim lua")
      created_buffer = vim.api.nvim_get_current_buf()
      created_path = vim.api.nvim_buf_get_name(created_buffer)
      created_lines = vim.api.nvim_buf_get_lines(created_buffer, 0, -1, false)
    end)

    Naming.generate_timestamp = original_timestamp
    vim.ui.input = original_input
    if created_buffer and vim.api.nvim_buf_is_valid(created_buffer) then
      vim.api.nvim_buf_delete(created_buffer, { force = true })
    end
    H.remove(directory)
    if not ok then
      error(err)
    end

    H.eq({ 1, 2, 3 }, prompt_counts)
    H.eq({ initial_buffer, initial_buffer, initial_buffer }, buffers)
    H.eq("[denote] New signature: ", requests[1].options.prompt)
    H.eq("[denote] New title: ", requests[2].options.prompt)
    H.eq("[denote] New keywords: ", requests[3].options.prompt)
    H.eq(
      vim.g.denote.directory .. "20250102T030405==1a--project-plan__neovim_lua.md",
      created_path
    )
    H.eq("+++", created_lines[1])
    H.eq('title      = "Project plan"', created_lines[2])
    H.matches("^date%s+=%s+2025%-01%-02T03:04:05", created_lines[3])
    H.eq('tags       = ["neovim", "lua"]', created_lines[4])
    H.eq('identifier = "20250102T030405"', created_lines[5])
    H.eq("+++", created_lines[6])
    H.eq("", created_lines[7])
  end),

  H.test("note creation initializes every configured filetype", function()
    local directory = H.tmpdir()
    local cases = {
      { filetype = "markdown-toml", extension = ".md", first_line = "^%+%+%+$" },
      { filetype = "markdown-yaml", extension = ".md", first_line = "^%-%-%-$" },
      { filetype = "org", extension = ".org", first_line = "^#%+date:" },
      { filetype = "neorg", extension = ".norg", first_line = "^@document%.meta$" },
      { filetype = "text", extension = ".txt", first_line = "^date:" },
    }
    local Naming = require("denote.naming")
    local original_timestamp = Naming.generate_timestamp
    Naming.generate_timestamp = function()
      return "20250102T030405"
    end

    local ok, err = pcall(function()
      for _, case in ipairs(cases) do
        vim.g.denote = require("denote.config").update_config({
          directory = directory .. "/" .. case.filetype,
          filetype = case.filetype,
          prompts = {},
        })
        require("denote.api").denote()

        local buffer = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
        H.eq(
          vim.g.denote.directory .. "20250102T030405" .. case.extension,
          vim.api.nvim_buf_get_name(buffer)
        )
        H.matches(case.first_line, lines[1])
        H.eq("", lines[#lines])
        H.eq(#lines, vim.api.nvim_win_get_cursor(0)[1])
        vim.api.nvim_buf_delete(buffer, { force = true })
      end
    end)

    Naming.generate_timestamp = original_timestamp
    H.remove(directory)
    if not ok then
      error(err)
    end
  end),

  H.test("note creation preserves an existing file", function()
    local directory = H.tmpdir()
    local path = directory .. "/20250102T030405.md"
    H.write_file(path, { "existing content" })
    vim.g.denote = require("denote.config").update_config({
      directory = directory,
      filetype = "markdown-toml",
      prompts = {},
    })

    local Naming = require("denote.naming")
    local original_timestamp = Naming.generate_timestamp
    Naming.generate_timestamp = function()
      return "20250102T030405"
    end

    local ok, err = pcall(require("denote.api").denote)
    Naming.generate_timestamp = original_timestamp
    local buffer = vim.api.nvim_get_current_buf()
    if not ok then
      H.remove(directory)
      error(err)
    end

    H.eq({ "existing content" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
    H.eq(false, vim.api.nvim_get_option_value("modified", { buf = buffer }))
    vim.api.nvim_buf_delete(buffer, { force = true })
    H.remove(directory)
  end),

  H.test("cancelling an interactive rename leaves the file alone", function()
    vim.g.denote = { directory = "/notes/", prompts = {} }

    local Filesystem = require("denote.core.fs")
    local original_replace_file = Filesystem.replace_file
    local original_input = vim.ui.input
    local replace_calls = 0
    local respond

    Filesystem.replace_file = function()
      replace_calls = replace_calls + 1
      return true
    end
    vim.ui.input = function(_, callback)
      respond = callback
    end

    local ok, err = pcall(function()
      require("denote.api").rename_file_title("20250102T030405--old-title.md")
      H.eq(0, replace_calls)
      respond(nil)
    end)

    Filesystem.replace_file = original_replace_file
    vim.ui.input = original_input
    if not ok then
      error(err)
    end

    H.eq(0, replace_calls)
  end),
}
