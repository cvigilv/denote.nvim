local Config = require("denote.config")
local Filesystem = require("denote.core.fs")
local Naming = require("denote.naming")

local function open(filepath)
  local open_cmd
  if vim.fn.has 'win32' == 1 then
    open_cmd = 'start'
  elseif vim.fn.has 'macunix' == 1 then
    open_cmd = 'open'
  else -- Assume Unix
    open_cmd = 'xdg-open'
  end
  vim.notify('[dneote] Opening URL with: ' .. open_cmd .. ' ' .. vim.fn.shellescape(filepath), vim.log.levels.INFO)
  vim.fn.jobstart({ open_cmd, filepath }, { detach = true })
end

---@class OrgLinkDenote:OrgLinkType
---@field private files string
local OrgLinkDenote = {}
OrgLinkDenote.__index = OrgLinkDenote

---@param opts { files: string }
function OrgLinkDenote:new(opts)
  vim.validate("denote.orgmode", opts, "table")
  vim.validate("denote.orgmode.files", opts.files, function(value)
    return type(value) == "string" and value ~= ""
  end, "non-empty string")

  return setmetatable({
    files = Filesystem.canonical_path(opts.files),
  }, OrgLinkDenote)
end

---@return string
function OrgLinkDenote:get_name()
  return "denote"
end

---@param link string
---@return boolean
function OrgLinkDenote:follow(link)
  local identifier = self:_parse(link)
  if not identifier or not identifier:match("^" .. Naming.PATTERNS.identifier .. "$") then
    return false
  end

  local denote_file = self:_find_denote_file(identifier)
  if denote_file ~= nil then
    if vim.tbl_contains({ "md", "org", "txt", "norg" }, vim.fn.fnamemodify(denote_file, ":e")) then
      vim.cmd("edit " .. vim.fn.fnameescape(denote_file))
      return true
    else
      open(denote_file)
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
---@diagnostic disable-next-line: undefined-field
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
  local matches = vim.fn.globpath(self.files, denote_id .. "*", false, true)
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
  local files = {}
  local matches = {}

  for _, extension in ipairs(Config.note_extensions()) do
    vim.list_extend(matches, vim.fn.globpath(self.files, "*" .. extension, false, true))
  end
  table.sort(matches)

  for _, filepath in ipairs(matches) do
    local components = Naming.parse_filename(filepath)
    if components.identifier ~= "" then
      table.insert(files, {
        id = components.identifier,
        title = components.title,
        filepath = filepath,
      })
    end
  end

  return files
end

return OrgLinkDenote
