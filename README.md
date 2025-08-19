# denote.nvim

A modern, modular Neovim plugin for creating and managing notes using the [Emacs Denote package's file-naming scheme](https://protesilaos.com/emacs/denote#h:4e9c7512-84dc-4dfb-9fa9-e15d51178e5d):

`DATE==SIGNATURE--TITLE__KEYWORDS.EXTENSION`

## Features

- **Consistent file naming**: Compatible with denote.el format
- **Frontmatter generation**: Automatic frontmatter for Org-mode, Markdown, and text files
- **Modular API**: Clean, extensible architecture for advanced usage
- **Well tested**: Comprehensive unit test coverage
- **Fast**: Minimal dependencies, optimized for performance
- **Integrations**: Oil.nvim and Telescope.nvim support

## Example Files

```
20240601T174946--how-to-tie-a-tie__lifeskills_clothes.md
20240601T180054--title-only.org
20240601T193022__only_keywords.norg
20240601T200121.txt
20240601T213392==1a1--i-have-a-signature__denote.csv
```

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "cvigilv/denote.nvim",
  opts = {
    extension = ".md",           -- Default file extension
    directory = "~/notes",       -- Notes directory
    frontmatter = true,          -- Generate frontmatter
    prompts = { "title", "keywords" }, -- Note creation prompts
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "cvigilv/denote.nvim",
  config = function()
    require("denote").setup({
      extension = ".md",
      directory = "~/notes",
      frontmatter = true,
    })
  end
}
```

### Manual Installation

```bash
git clone https://github.com/cvigilv/denote.nvim.git ~/.local/share/nvim/site/pack/plugins/start/denote.nvim
```

## Configuration

<details>
<summary>Full configuration example</summary>

```lua
require("denote").setup({
  -- Default file extension (with dot)
  extension = ".md",
  
  -- Notes directory (will be expanded)  
  directory = "~/notes/",
  
  -- Prompts shown when creating notes
  prompts = { "title", "keywords", "signature" },
  
  -- Generate frontmatter based on file extension
  frontmatter = true,
  
  -- Integration settings
  integrations = {
    oil = false,
    telescope = {
      enabled = true,
      opts = {
        theme = "dropdown"
      }
    }
  }
})
```

</details>

## Commands

The plugin provides these commands:

```vim
:Denote note       " Create new note
:Denote title      " Update note title  
:Denote keywords   " Update note keywords
:Denote signature  " Update note signature
:Denote extension  " Change file extension
:Denote rename     " Interactive rename
:Denote search     " Search notes (requires telescope)
:Denote link       " Insert link to note (requires telescope)
```

### Keymaps

```lua
local map = vim.keymap.set
map("n", "<leader>nn", ":Denote note<cr>", { desc = "New note" })
map("n", "<leader>nt", ":Denote title<cr>", { desc = "Change title" })
map("n", "<leader>nk", ":Denote keywords<cr>", { desc = "Change keywords" })
map("n", "<leader>ns", ":Denote signature<cr>", { desc = "Change signature" })
map("n", "<leader>ne", ":Denote extension<cr>", { desc = "Change extension" })
map("n", "<leader>nr", ":Denote rename<cr>", { desc = "Rename note" })
```

## API Usage

For advanced usage and integrations:

```lua
local denote = require("denote")

-- Create note programmatically
local file_path = denote.create_note({
  title = "My Note",
  keywords = "tag1 tag2",
  signature = "project"
})

-- Parse existing denote file
local components = denote.parse_file("/path/to/note.md")
print(components.title) -- "My Note"

-- Check if file follows denote format
if denote.is_denote_file("/path/to/file.md") then
  print("This is a denote file!")
end

-- Access core modules for advanced operations
local filename = denote.core.filename
local frontmatter = denote.core.frontmatter
local file_ops = denote.core.file
```

## Development & Debugging

The plugin includes comprehensive logging for debugging. Enable it in your configuration:

```lua
require("denote").setup({
  extension = ".md",
  directory = "~/notes",
  -- Logging is handled by the logging.lua module
  -- Check ~/.local/share/nvim/cache/denote.log for detailed logs
})
```

### Running Tests

```bash
make test           # Run all tests
make lint           # Lint code  
make check          # Lint + test
make test-file FILE=tests/filename_spec.lua  # Single test
```

# Road map

- [ ] Documentation
    - [ ] Rewrite `:h denote`
    - [ ] Add API usage examples
- [ ] House-keeping
    - [ ] Refactor and clean-up code
    - [ ] Change `setup` logic
    - [ ] Add types
    - [ ] Add docstrings
    - [ ] Add logging
    - [ ] Add tests
- [ ] [Points of entry](https://protesilaos.com/emacs/denote#h:17896c8c-d97a-4faa-abf6-31df99746ca6)
    - [ ] Implement [The `denote-prompts` option](https://protesilaos.com/emacs/denote#h:f9204f1f-fcee-49b1-8081-16a08a338099)
- [ ] [Front mattter](https://protesilaos.com/emacs/denote#h:13218826-56a5-482a-9b91-5b6de4f14261)
    - [ ] Front matter generator for `org`, `markdown` and `text`
    - [ ] Front matter format (`denote-{org,text,toml,yaml}-front-matter`)
    - [ ] Regenerate front matter (`denote-add-front-matter`)
- [ ] Extensions
    - [X] Custom highlighting in oil.nvim ([Fontification in Dired](https://protesilaos.com/emacs/denote#h:337f9cf0-9f66-45af-b73f-f6370472fb51))
    - [ ] Search capabilities with telescope.nvim

# Credits

* [historia/simple-denote.nivm](https://codeberg.org/historia/simple-denote.nvim) - This is a
  fork from this project, which includes integration to other common plugins I use to manage my
  PKM (oil.nvim, telescope.nvim, nvim-orgmode, etc.)
* [HumanEntity/denote.nvim](https://github.com/HumanEntity/denote.nvim)
* [denote.el](https://protesilaos.com/emacs/denote) - The original Emacs package

# License

MIT
