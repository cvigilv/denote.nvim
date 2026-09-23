local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(source, ":p:h:h")

vim.g.denote_test_root = root
vim.opt.runtimepath = { root, vim.env.VIMRUNTIME }
vim.opt.packpath = vim.opt.runtimepath:get()
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.shadafile = "NONE"
vim.cmd("filetype off")
vim.cmd("filetype plugin off")
