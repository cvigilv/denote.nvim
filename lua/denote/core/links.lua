---@module "denote.core.links"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local Naming = require("denote.naming")

local M = {}

--- Format a link according to the given filetype.
---@param description string The link description text.
---@param filepath string The target filepath (or identifier for org).
---@param filetype string The source buffer filetype (e.g. "markdown", "org", "norg").
---@return string link The formatted link string.
function M.format_link(description, filepath, filetype)
    if string.match(filetype, "markdown") then
        return string.format("[%s](%s)", description, filepath)
    elseif string.match(filetype, "norg") then
        return string.format("{%s:%s:}", description, filepath)
    elseif string.match(filetype, "org") then
        return string.format(
            "[[denote:%s][%s]]",
            filepath:match(Naming.PATTERNS.identifier),
            description
        )
    else
        return string.format("%s (%s)", description, filepath)
    end
end

return M
