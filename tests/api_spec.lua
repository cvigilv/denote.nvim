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
    vim.g.denote = {
      directory = directory .. "/",
      filetype = "markdown-toml",
      prompts = { "title", "keywords" },
    }

    local Naming = require("denote.naming")
    local original_timestamp = Naming.generate_timestamp
    local original_input = vim.ui.input
    local original_cmd = vim.cmd
    local requests = {}
    local commands = {}

    Naming.generate_timestamp = function()
      return "20250102T030405"
    end
    vim.ui.input = function(options, callback)
      requests[#requests + 1] = { options = options, callback = callback }
    end
    vim.cmd = function(command)
      commands[#commands + 1] = command
    end

    local prompt_counts = {}
    local command_counts = {}
    local ok, err = pcall(function()
      require("denote.api").denote()
      prompt_counts[1] = #requests
      command_counts[1] = #commands
      requests[1].callback("Project plan")
      prompt_counts[2] = #requests
      command_counts[2] = #commands
      requests[2].callback("neovim lua")
      command_counts[3] = #commands
    end)

    Naming.generate_timestamp = original_timestamp
    vim.ui.input = original_input
    vim.cmd = original_cmd
    H.remove(directory)
    if not ok then
      error(err)
    end

    H.eq({ 1, 2 }, prompt_counts)
    H.eq({ 0, 0, 2 }, command_counts)
    H.eq("[denote] New title: ", requests[1].options.prompt)
    H.eq("[denote] New keywords: ", requests[2].options.prompt)
    H.eq("edit " .. directory .. "/20250102T030405--project-plan__neovim_lua.md", commands[1])
    H.eq("startinsert", commands[2])
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
