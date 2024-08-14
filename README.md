# simple-denote.nvim

This Neovim plugin provides a command `:Denote note` that prompts for a title and keywords (tags), then creates a new file in a flat notes directory using the [Emacs Denote package's file-naming scheme](https://protesilaos.com/emacs/denote#h:4e9c7512-84dc-4dfb-9fa9-e15d51178e5d):

`DATE==SIGNATURE--TITLE__KEYWORDS.EXTENSION`

For example:

```
20240601T174946--how-to-tie-a-tie__lifeskills_clothes.md
20240601T180054--title-only.org
20240601T193022__only_keywords.norg
20240601T200121.txt
20240601T213392==1a1--i-have-a-signature__denote.csv
```

That's all this does: create and consistently rename text files using the above scheme. No frontmatter, links, etc. I have overcomplicated my notes too many times with fancy Org Mode and Zettelkasten systems and this is my minimalist endgame.

The file-naming should be 1:1 with denote.el, down to minor things like triming/combining excess whitespace, removing special characters, disallowing multi-word keywords, and separating signature terms with = (e.g. `==three=word=sig`).

# Installation / Config

Example config via [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "https://codeberg.org/historia/simple-denote.nvim",
  opts = {
    ext = "md",             -- Note file extension (e.g. md, org, norg, txt)
    dir = "~/notes",        -- Notes directory (should already exist)
    add_heading = true,     -- Add a md/org heading to new notes
    retitle_heading = true, -- Replace the first line heading when retitling
  },
},
```

The heading options automatically support Markdown (#) and Org/Norg (*) headings.

## Keymaps

Maybe you want to set keymaps for the commands as well

```lua
vim.keymap.set({'n','v'}, '<leader>nn', ":Denote note<cr>",      { desc = "New note"         })
vim.keymap.set({'n','v'}, '<leader>nt', ":Denote title<cr>",     { desc = "Change title"     })
vim.keymap.set({'n','v'}, '<leader>nk', ":Denote keywords<cr>",  { desc = "Change keywords"  })
vim.keymap.set({'n','v'}, '<leader>nz', ":Denote signature<cr>", { desc = "Change signature" })
vim.keymap.set({'n','v'}, '<leader>ne', ":Denote extension<cr>", { desc = "Change extension" })
```

## Manual Install

To install without a plugin manager:

```bash
mkdir -p ~/.local/share/nvim/site/pack/simple-denote.nvim/start
cd ~/.local/share/nvim/site/pack/simple-denote.nvim/start
git clone https://codeberg.org/historia/simple-denote.nvim
```

Add the following to `~/.config/nvim/init.lua`

```lua
require('simple-denote').setup({
  ext = "md",
  dir = "~/notes",
  add_heading = true,
  retitle_heading = true,
})
```

# :Denote Command

```vim
" Creates a new note in the `dir` directory with `ext` extension
" Keywords are space delimited. The title or keywords can be blank.
:Denote note

" Renames the current note with the new title
" If `retitle_heading` is true, overwrites the first line heading as well
:Denote title

" Renames the current note with the new list of keywords (space delimited)
:Denote keywords

" Rename the current note with a signature
" This has a user-defined meaning and no particular purpose
:Denote signature

" Rename the current file to a new extension
:Denote extension
```

# Credits

* [HumanEntity/denote.nvim](https://github.com/HumanEntity/denote.nvim) - This project was based on denote.nvim and modified to suit my personal preference or closer adhere to the original Denote spec.
* [denote.el](https://protesilaos.com/emacs/denote) - The original Emacs package

# License

MIT
