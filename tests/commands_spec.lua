local H = dofile(vim.g.denote_test_root .. "/tests/helpers.lua")

local function load_command()
  pcall(vim.api.nvim_del_user_command, "Denote")
  vim.g.loaded_denote_plugin = nil
  local directory = H.tmpdir()
  vim.g.denote = {
    directory = directory .. "/",
    prompts = {},
    integrations = { oil = false, telescope = false },
  }
  vim.cmd("runtime plugin/denote.lua")
  return directory
end

return {
  H.test("the Denote command and completion are available at plugin load", function()
    local directory = load_command()

    H.truthy(vim.api.nvim_get_commands({ builtin = false }).Denote)
    H.eq({
      "rename-file",
      "rename-file-keywords",
      "rename-file-signature",
      "rename-file-title",
    }, vim.fn.getcompletion("Denote rename-file", "cmdline"))
    H.remove(directory)
  end),

  H.test("the Denote command dispatches every core subcommand", function()
    local directory = load_command()
    local api = require("denote.api")
    local names = {
      "denote",
      "backlinks",
      "rename_file",
      "rename_file_keywords",
      "rename_file_signature",
      "rename_file_title",
    }
    local calls = {}
    local originals = {}

    for _, name in ipairs(names) do
      originals[name] = api[name]
      api[name] = function()
        calls[#calls + 1] = name
      end
    end

    local ok, err = pcall(function()
      vim.cmd("Denote")
      vim.cmd("Denote backlinks")
      vim.cmd("Denote rename-file")
      vim.cmd("Denote rename-file-keywords")
      vim.cmd("Denote rename-file-signature")
      vim.cmd("Denote rename-file-title")
    end)

    for name, original in pairs(originals) do
      api[name] = original
    end
    H.remove(directory)
    if not ok then
      error(err)
    end

    H.eq(names, calls)
  end),

  H.test("the Denote command rejects invalid arguments", function()
    local directory = load_command()

    local unsupported, unsupported_error = pcall(vim.cmd, "Denote unknown")
    local excess, excess_error = pcall(vim.cmd, "Denote backlinks extra")

    H.eq(false, unsupported)
    H.matches("Unsupported subcommand: unknown", unsupported_error)
    H.eq(false, excess)
    H.matches("Expected one subcommand, got 2 arguments", excess_error)
    H.remove(directory)
  end),
}
