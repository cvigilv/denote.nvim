local M = {}

---@param options? Denote.Configuration User configuration
function M.setup(options)
  -- Initialize global state
  _G.denote = {}

  -- Update configuration and store in global state
  options = require("denote.config").update_config(options)
  _G.denote.config = options

  -- Initialize extensions
  if options.integrations.oil then
    require("denote.integrations.oil").setup(options)
  end
  if options.integrations.telescope then
    require("denote.integrations.telescope").setup(options)
  end

  -- Initialize excommands
  require("denote.excmds").setup(options)
end

return M
