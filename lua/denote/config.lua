local M = {}

M.defaults = {
  ext = "md",
  dir = "~/notes/",
  add_heading = true,
  retitle_heading = true,
  heading_char = "", -- This gets set automatically
  extensions = {
    oil = false
  }
}

M.options = M.defaults

return M
