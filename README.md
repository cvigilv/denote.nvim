# denote.nvim

> [!NOTE]  
> I'm working on this project in my free time, so expect bursts of changes as I get said free time. This is already functional and
> provides an API you can use to make custom hooks and implement your own pipelines for using the denote naming convention. That
> said, I'm working on an in-process LSP that enables having other nice things. If you are interested in that, point Neovim
> to use that branch. Open to issues, ideas, PRs, etc. Help me make this plugin great!

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

# Installation and configuration

Denote requires Neovim 0.11 or newer.

Set `vim.g.denote` before the plugin loads. For example, with
[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "cvigilv/denote.nvim",
  init = function()
    vim.g.denote = {
      filetype = "markdown-toml",
      directory = "~/notes/",
      prompts = { "title", "keywords" },
      integrations = {
        highlights = false,
        telescope = false,
      },
    }
  end,
}
```

The plugin validates this table, fills in omitted defaults, and stores the normalized
configuration in `vim.g.denote`.

# :Denote Command

The bare `:Denote` command is available in every buffer. Its subcommands are listed and
accepted only when the current buffer has a Denote filetype, such as `markdown.denote`.

Currently, the `:Denote` command supports the following subcommands:

- `:Denote`, create a new note interactively
- `:Denote rename-file`, renames the current note interactively
- `:Denote rename-file-title`, change the title of the current note
- `:Denote rename-file-keywords`, change the keywords of the current note
- `:Denote rename-file-signature`, change the signature of the current note
- `:Denote backlinks`, populates and opens loclist with backlinks to current note

# Extensions

## Filename highlights

Set `integrations.highlights` to `true` to highlight the identifier, signature, title,
keywords, and extension in Denote filenames. Matching is not limited to the configured notes
directory, so this option is disabled by default.

```lua
vim.g.denote = {
  integrations = {
    highlights = true,
  },
}
```

<img width="1031" height="806" alt="Denote filename highlighting in oil.nvim" src="https://github.com/user-attachments/assets/377adb4a-8060-4c8d-a03f-c3e41b2effba" />

## nvim-telescope/telescope.nvim

Install [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
and set `integrations.telescope` to `true` to load the extension. If you use lazy.nvim, list
Telescope as a dependency so it is available when Denote loads.

The integration adds these subcommands in Denote buffers:

- `:Denote search`, search for notes
- `:Denote insert-link`, select a note and insert a link

To configure both pickers, use
`integrations.telescope = { enabled = true, opts = { ... } }`. Denote passes `opts` to each
picker.

<img width="1031" height="806" alt="Simple telescope.nvim search" src="https://github.com/user-attachments/assets/6a29e965-0268-40a6-9ae5-d93bd17859df" />

## nvim-orgmode/orgmode

If you use [nvim-orgmode/orgmode](https://github.com/nvim-orgmode/orgmode), you can enable the
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

The `files` option is required. Link completion scans this directory for valid Denote files
using the supported note extensions: `.md`, `.norg`, `.org`, and `.txt`.

# Tests

Run the headless Neovim test suite with:

```sh
make test
```

Set `NVIM` to test a specific executable, for example `make test NVIM=nvim-0.11`.
CI tests Neovim 0.11, stable, and nightly on Linux, plus stable on macOS and Windows.

# Credits

* [historia/simple-denote.nivm](https://codeberg.org/historia/simple-denote.nvim) - This is a
  fork from this project, which includes integration to other common plugins I use to manage my
  PKM (oil.nvim, telescope.nvim, nvim-orgmode, etc.)
* [HumanEntity/denote.nvim](https://github.com/HumanEntity/denote.nvim)
* [denote.el](https://protesilaos.com/emacs/denote) - The original Emacs package

# License

MIT
