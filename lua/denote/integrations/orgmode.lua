local utils = require("orgmode.utils")
local internal = require("denote.internal")
local DEFAULT_CONFIG = _G.denote.config

---@class OrgLinkDenote:OrgLinkType
---@field private files OrgFiles
---@field private config table Configuration for denote integration
local OrgLinkDenote = {}
OrgLinkDenote.__index = OrgLinkDenote

---@param opts { files: OrgFiles, config?: table }
function OrgLinkDenote:new(opts)
  local config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts.config or {})
  return setmetatable({
    files = opts.files,
    config = config,
  }, OrgLinkDenote)
end

---@return string
function OrgLinkDenote:get_name()
  return "denote"
end

---@param link string
---@return boolean
function OrgLinkDenote:follow(link)
  local denote_id = tostring(self:_parse(link))
  if denote_id:match(internal.PATTERNS.identifier) then
    local identifier = tostring(self:_parse(link))
    local denote_file = self:_find_denote_file(identifier)
    if denote_file ~= nil then
      vim.cmd("edit " .. vim.fn.fnameescape(denote_file))
      return true
    end
  end
  return false
end

---@param context OrgCompletionContext
---@return string[]
function OrgLinkDenote:autocomplete(context)
  local items = {}

  -- Get available denote files for completion
  local denote_files = self:_get_denote_files()
  for _, file_info in ipairs(denote_files) do
    local completion = string.format("%s:%s", self:get_name(), file_info.id)
    if context.matcher(completion, context.base) then
      table.insert(items, completion)
    end
  end

  return items
end

---@private
---@param link string
---@return string|nil
function OrgLinkDenote:_parse(link)
  local pattern = "^" .. self:get_name() .. ":(.+)$"
  return link:match(pattern)
end

---@private
---@param denote_id string
---@return string|nil
function OrgLinkDenote:_find_denote_file(denote_id)
  local denote_dir = vim.fn.expand(self.config.directory)
  local pattern = string.format("%s%s*", denote_dir, denote_id)
  local matches = vim.fn.glob(pattern, false, true)
  if #matches > 0 then
    if #matches > 1 then
      vim.notify("More than one entry with ID: " .. denote_id, vim.log.levels.INFO)
    end
    return matches[1] -- Return first match
  end

  return nil
end

---@private
---@return table[]
function OrgLinkDenote:_get_denote_files()
  local denote_dir = vim.fn.expand(self.config.denote_directory)
  local files = {}

  -- Build glob pattern for all denote files
  local extensions = table.concat({".md", ".org", ".txt"}, ",")
  local pattern = string.format("%s/*.{%s}", denote_dir, extensions)
  local matches = vim.fn.glob(pattern, false, true)

  for _, filepath in ipairs(matches) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    local id = filename:match(self.config.id_pattern)
    if id then
      local title = filename:match(self.config.title_pattern) or ""
      table.insert(files, {
        id = id,
        title = title,
        filepath = filepath,
      })
    end
  end

  return files
end

return OrgLinkDenote
