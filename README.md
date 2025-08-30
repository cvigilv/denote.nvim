# denote.nvim

This Neovim plugin provides a command `:Denote note` that prompts for a title and keywords
(tags), then creates a new file in a flat notes directory using the [Emacs Denote package's
file-naming scheme](https://protesilaos.com/emacs/denote#h:4e9c7512-84dc-4dfb-9fa9-e15d51178e5d):

`DATE==SIGNATURE--TITLE__KEYWORDS.EXTENSION`

For example:

```
20240601T174946--how-to-tie-a-tie__lifeskills_clothes.md
20240601T180054--title-only.org
20240601T193022__only_keywords.norg
20240601T200121.txt
20240601T213392==1a1--i-have-a-signature__denote.csv
```

That's all this does: create and consistently rename text files using the above scheme. No
frontmatter, links, etc. I have overcomplicated my notes too many times with fancy Org Mode and
Zettelkasten systems and this is my minimalist endgame.

The file-naming should be 1:1 with denote.el, down to minor things like triming/combining excess
whitespace, removing special characters, disallowing multi-word keywords, and separating
signature terms with = (e.g. `==three=word=sig`).

# Installation / Config

Example config via [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "cvigilv/denote.nvim",
  opts = {
    ext = "md",             -- Note file extension (e.g. md, org, norg, txt)
    dir = "~/notes",        -- Notes directory (should already exist)
  },
},
```

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
mkdir -p ~/.local/share/nvim/site/pack/denote.nvim/start
cd ~/.local/share/nvim/site/pack/denote.nvim/start
git clone https://github.com/cvigilv/denote.nvim.git
```

Add the following to `~/.config/nvim/init.lua`

```lua
require("denote").setup({
  ext = "md",
  dir = "~/notes",
})
```

# :Denote Command

```vim
" Creates a new note in the `dir` directory with `ext` extension
" Keywords are space delimited. The title or keywords can be blank.
:Denote note

" Renames the current note with the new title
:Denote title

" Renames the current note with the new list of keywords (space delimited)
:Denote keywords

" Rename the current note with a signature
" This has a user-defined meaning and no particular purpose
:Denote signature

" Rename the current file to a new extension
:Denote extension
```

# Road map

- [ ] Documentation
    - [ ] Rewrite `:h denote`
    - [ ] Add API usage examples
- [ ] House-keeping
    - [x] Refactor and clean-up code
    - [x] Complete modular rewrite
    - [x] Change `setup` logic
    - [ ] Add types
    - [ ] Add docstrings
    - [ ] Add logging
    - [ ] Add tests
- [x] [Points of entry](https://protesilaos.com/emacs/denote#h:17896c8c-d97a-4faa-abf6-31df99746ca6)
    - [x] Implement [The `denote-prompts` option](https://protesilaos.com/emacs/denote#h:f9204f1f-fcee-49b1-8081-16a08a338099)
- [ ] [Front mattter](https://protesilaos.com/emacs/denote#h:13218826-56a5-482a-9b91-5b6de4f14261)
    - [ ] Front matter generator for `org`, `markdown` and `text`
    - [ ] Front matter format (`denote-{org,text,toml,yaml}-front-matter`)
    - [ ] Regenerate front matter (`denote-add-front-matter`)
- [x] Extensions
    - [x] Custom highlighting in oil.nvim ([Fontification in Dired](https://protesilaos.com/emacs/denote#h:337f9cf0-9f66-45af-b73f-f6370472fb51))
    - [x] Search capabilities with telescope.nvim

# Credits

* [historia/simple-denote.nivm](https://codeberg.org/historia/simple-denote.nvim) - This is a
  fork from this project, which includes integration to other common plugins I use to manage my
  PKM (oil.nvim, telescope.nvim, nvim-orgmode, etc.)
* [HumanEntity/denote.nvim](https://github.com/HumanEntity/denote.nvim)
* [denote.el](https://protesilaos.com/emacs/denote) - The original Emacs package

# License

MIT
