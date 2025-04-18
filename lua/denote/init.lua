local M = {}

local config = require("denote.config")
local api = require("denote.api")

function M.load_cmd(options)
  vim.api.nvim_create_user_command("Denote", function(opts)
    if opts.fargs[1] == "note" then
      api.note(options)
    elseif opts.fargs[1] == "title" then
      api.title(options)
    elseif opts.fargs[1] == "keywords" then
      api.keywords()
    elseif opts.fargs[1] == "signature" then
      api.signature()
    elseif opts.fargs[1] == "extension" then
      api.extension()
    else
      error("Unsupported operation " .. opts.fargs[1])
    end
  end, {
    nargs = 1,
    complete = function()
      return { "note", "title", "keywords", "signature", "extension" }
    end,
  })
end

---Add / to directory if necessary and set the heading_char based on the ext
function M.fix_options()
  if config.options.dir:sub(-1) ~= "/" then
    config.options.dir = config.options.dir .. "/"
  end
  if config.options.ext == "md" then
    config.options.heading_char = "#"
  elseif config.options.ext == "org" or config.options.ext == "norg" then
    config.options.heading_char = "*"
  end
end

---@param options? table user configuration
function M.setup(options)
  config.options = vim.tbl_deep_extend("force", config.defaults, options or {})
  M.fix_options()
  M.load_cmd(config.options)

  -- Extensions
  if config.options.extensions.oil then
    require("denote.extensions.oil").setup(options)
  end
end

return M
