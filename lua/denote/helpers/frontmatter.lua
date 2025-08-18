---@module "denote.helpers.frontmatter"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Utils = require("denote.internal")
local function __reverse_table(t)
  local reversed = {}
  for k, v in pairs(t) do
    reversed[v] = k
  end
  return reversed
end

local denote2org = {
  ["title"] = "title",
  ["date"] = "date",
  ["keywords"] = "filetags",
  ["signature"] = "signature",
  ["identifier"] = "identifier",
}
local org2denote = __reverse_table(denote2org)

local M = {}

--- Parse org file front matter and normalize to denote format
---@param filename string
---@return table|nil frontmatter
M.parse_org_frontmatter = function(filename)
  filename = filename or vim.api.nvim_buf_get_name(0)

  if
    vim.tbl_contains(
      vim.tbl_values(Utils.FILETYPE_TO_EXTENSION),
      "." .. vim.fn.fnamemodify(filename, ":e")
    )
  then
    local frontmatter = {}
    for _, l in ipairs(vim.fn.readfile(filename, "\n", 5)) do -- HACK: Parse only the first 5 lines
      print(l)
      if l == "" then
        break
      else
        local fm_pattern = "#%+(%w+):%s*(.*)"
        if string.match(l, fm_pattern) then
          local field, value = l:match(fm_pattern)
          field = org2denote[field:lower()] or field:lower()
          frontmatter[field] = value
        end
      end
    end
    return frontmatter
  end
end

-- M.generate_org_frontmatter(filename, date, identifier, title, signature, keywords)
--
-- end
--

return M
