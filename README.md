# denote.nvim

This Neovim plugin provides a command `:Denote` that contains subcommands to create and rename
text files in a flat notes directory using the [Emacs Denote package's file-naming
scheme](https://protesilaos.com/emacs/denote#h:4e9c7512-84dc-4dfb-9fa9-e15d51178e5).

The file-naming scheme is as follows:

`DATE==SIGNATURE--TITLE__KEYWORDS.EXTENSION`

For example:

```
20240601T174946--how-to-tie-a-tie__lifeskills_clothes.md
20240601T180054--title-only.org
20240601T193022__only_keywords.norg
20240601T200121.txt
20240601T213392==1a1--i-have-a-signature__denote.csv
```

# Features

- Single access point for all functionality via the `:Denote` command
- Create new notes interactively
- Extensions for integrating with other plugins (e.g. telescope.nvim)

# Installation / Config

Example config via [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
---@class Denote.Integrations.Telescope.Configuration
---@field enabled boolean
---@field opts table?

---@class Denote.Integrations.Configuration
---@field oil boolean Activate `stevearc/oil.nvim` extension
---@field telescope boolean|Denote.Integrations.Telescope.Configuration

---@class Denote.Configuration
---@field filetype string? Default note file type
---@field directory string? Denote files directory
---@field prompts string[]? File creation/renaming prompt order
---@field integrations Denote.Integrations.Configuration? Extensions configuration

--@type Denote.Configuration
vim.g.denote = {
  filetype = "md",
  directory = "~/notes/",
  prompts = { "title", "keywords" },
  integrations = {
    oil = false,
    telescope = false,
  },
}
```

On setup, the plugin will create a global variable `denote` that contains the configuration
table, which can be employed for extensions or other custom functionality:

```lua
vim.g.denote
```

# :Denote Command

Currently, the `:Denote` command supports the following subcommands:

- `:Denote`, create a new note interactively
- `:Denote rename-file`, renames the current note interactively
- `:Denote rename-file-title`, change the title of the current note
- `:Denote rename-file-keywords`, change the keywords of the current note
- `:Denote rename-file-signature`, change the signature of the current note
- `:Denote backlinks`, populates and opens loclist with backlinks to current note

# Extensions

## stevearc/oil.nvim

If you use [stevearc/oil.nvim](https://github.com/stevearc/oil.nvim) to manage your files, this
extension will automatically setup custom highlighting to files that follow the Denote file-naming scheme
whenever you open an `oil` buffer on the directory set in `vim.g.denote`.

> Note: the highlighting is only applied when the `oil` extension is enabled in the config, but
> it will highlight any file that follows the scheme, regardless of the directory.

<img width="1031" height="806" alt="stevearc/oil.nvim highlighting" src="https://github.com/user-attachments/assets/377adb4a-8060-4c8d-a03f-c3e41b2effba" />

## nvim-telescope/telescope.nvim

If you use [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim),
you can register the `telescope` extension to access to some functionality directly from
telescope. Currently, the following pickers are implemented:

- `:Telescope denote search`, for searching notes in you Denote silo
- `:Telescope denote insert-link`, for inserting links interactively
- `:Telescope denote link`, for inserting links
- `:Telescope denote backlinks`, for searching backlinks of current buffer

<img width="1031" height="806" alt="Simple telescope.nvim search" src="https://github.com/user-attachments/assets/6a29e965-0268-40a6-9ae5-d93bd17859df" />

## nvim-orgmode/orgmode

if you use [nvim-orgmode/orgmode](https://github.com/nvim-orgmode/orgmode), you can enable the
`[[denote:...]]` link format. This is done by adding the following to your orgmode
configuration:

```lua
require("orgmode").setup({
  -- your config...
  hyperlinks = {
    sources = {
      require("denote.extensions.orgmode"):new({
        files = vim.g.denote.directory
      }),
    },
  },
})
```
# Credits

* [historia/simple-denote.nivm](https://codeberg.org/historia/simple-denote.nvim) - This is a
  fork from this project, which includes integration to other common plugins I use to manage my
  PKM (oil.nvim, telescope.nvim, nvim-orgmode, etc.)
* [HumanEntity/denote.nvim](https://github.com/HumanEntity/denote.nvim)
* [denote.el](https://protesilaos.com/emacs/denote) - The original Emacs package

# License

MIT
