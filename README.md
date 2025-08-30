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
{
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
_G.denote.config
```

# :Denote Command

Currently, the `:Denote` command supports the following subcommands:

- `:Denote`, create a new note interactively
- `:Denote rename-file`, renames the current note interactively
- `:Denote rename-file-title`, change the title of the current note
- `:Denote rename-file-keywords`, change the keyworks of the current note
- `:Denote rename-file-signature`,  change the signature of the current note

# Extensions

## stevearc/oil.nvim

If you use [stevearc/oil.nvim](https://github.com/stevearc/oil.nvim) to manage your files, you
can enable the `oil` extension in the configuration. This will add custom highlighting to files
that follow the Denote file-naming scheme.

> Note: the highighting is only applied when the `oil` extension is enabled in the config, but
> it will highlight any file that follows the scheme, regardless of the directory.

<img width="1031" height="806" alt="stevearc/oil.nvim highlighting" src="https://github.com/user-attachments/assets/377adb4a-8060-4c8d-a03f-c3e41b2effba" />

## nvim-telescope/telescope.nvim

If you use [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim),
you can enable the `telescope` extension in the configuration. This will add the `:Denote
search`, `:Denote insert-link`, and `:Denote link` commands, which will open a picker to search
and insert links to existing buffer.

<img width="1031" height="806" alt="Simple telescope.nvim search" src="https://github.com/user-attachments/assets/6a29e965-0268-40a6-9ae5-d93bd17859df" />

## nvim-orgmode/orgmode

if you use [nvim-orgmode/orgmode](https://github.com/nvim-orgmode/orgmode), you can enale the
`[[denote:...]]` link format. This is done by adding the following to your orgmode
configuration:

```lua
require("orgmode").setup({
  -- your config...
  hyperlinks = {
    sources = {
      require("denote.extensions.orgmode"):new({
        files = _G.denote.config.directory,
      }),
    },
  },
})
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
