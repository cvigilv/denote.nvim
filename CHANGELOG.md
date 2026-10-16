# Changelog

## [Unreleased]

### Added

- Add a changelog covering the plugin's release history.
- Rename notes of every filetype on save so the filename matches the frontmatter, controlled by the `sync_filename` option (enabled by default). Missing frontmatter fields raise an error instead of dropping filename components, and identifier changes ask for confirmation.

### Fix

- Keep buffers writable after a rename. Previously the next `:write` failed with `E13: File exists`.
- Create the cache directory before opening the log file, preventing startup failures in fresh profiles and sandboxed builds.
- Write the signature to new notes' frontmatter for every filetype, not only Org. The value matches the filename's signature component, and an empty signature is omitted.

## [v0.2]

### Added

- New notes now start with metadata for their configured filetype. This includes TOML and YAML
  frontmatter, Org keywords, Neorg document metadata, and plain-text headers. Existing files are
  left unchanged.
- `:Denote search` and `:Denote insert-link` commands are available when the Telescope integration
  is enabled.
- Configuration checks for supported filetypes, prompt names, and integration settings.
- A headless test suite and CI coverage for Neovim 0.11, stable, and nightly on Linux, plus stable
  Neovim on macOS and Windows.

### Changed

- Neovim 0.11 or newer is now required.
- `:Denote` is registered when the plugin loads. The base command works in every buffer, while
  subcommands and their completion are limited to Denote buffers.
- Interactive creation and renaming now sequence prompts through callbacks, which supports
  asynchronous `vim.ui.input` implementations. These functions return before the operation
  finishes, and cancelling any prompt cancels the operation.
- Filename validation now checks the complete basename against the Denote naming scheme instead of
  accepting any name that starts with a timestamp.
- Note directories, link targets, and cache keys now use canonical paths, including resolved
  symlinks.
- The former `integrations.oil` setting has been replaced by `integrations.highlights`. Its matching
  is not restricted to Oil buffers or the configured notes directory.
- Telescope picker options from `integrations.telescope.opts` now apply to every Denote picker.
  Options passed to an individual picker take precedence.

### Fixed

- File renaming now uses libuv instead of shell commands. Renames preserve shell metacharacters,
  refuse to overwrite existing files, detect buffer-name conflicts, and keep the source buffer
  attached to its new path.
- The link cache stays current after note writes, renames, and deletions. Plain-text notes are now
  included in write tracking.
- Relative links are resolved from the directory of the note containing them, which fixes backlink
  lookup from notes outside the working directory.
- The initial link-cache scan uses normalized paths and can retry after a filesystem error.
- Denote filetype detection no longer clears unrelated autocommands or appends `.denote` more than
  once. Detection works independently of plugin setup and the configured notes directory.
- Inserted Telescope links are built relative to the source note. Each target's title comes from
  its own frontmatter or filename.
- Orgmode link lookup and completion use the integration's required `files` directory and now
  include Neorg files.
- Non-note Orgmode link targets use Neovim's platform-aware launcher. Launcher failures are
  reported to the user.

## [v0.1] - 2026-05-01

### Added

- Filetype detection for Denote filenames. Matching files receive a `.denote` filetype suffix even
  when they are outside the configured notes directory.
- Orgmode links to non-text Denote files open with the operating system's default application.
- Help pages for configuration, commands, integrations, and Orgmode support.

### Fixed

- The plugin now sets `vim.g.loaded_denote_plugin` after setup, preventing duplicate initialization.

## [v0.0.1] - 2026-03-22

### Added

- Configurable prompt order for note creation and renaming.
- Commands and Lua functions to rename a complete filename or only its title, keywords, or
  signature.
- Link indexing and a `:Denote backlinks` command backed by the location list.
- Oil filename highlighting.
- Telescope pickers for searching notes, inserting links, and finding backlinks. Picker entries use
  frontmatter when available.
- Orgmode support for `denote:` links and link completion.
- Frontmatter parsers and generators for Org, TOML Markdown, YAML Markdown, and plain text.
- Diacritic normalization when converting input to Denote filename components.
- Vim help documentation.

### Changed

- Configuration moved from `require("denote").setup()` to `vim.g.denote`. The old `ext`, `dir`,
  `add_heading`, and `retitle_heading` options were replaced by `filetype`, `directory`, `prompts`,
  and `integrations`.
- The old `:Denote note`, `title`, `keywords`, `signature`, and `extension` subcommands were replaced
  by a bare `:Denote` command and the `rename-file*` subcommands.
- Automatic first-line heading creation and retitling were removed.
- Core helpers, naming logic, prompts, links, frontmatter, and integrations were split into separate
  Lua modules. Code importing the old internal modules must use the new module paths.
- Link metadata is cached when the notes directory is first opened and refreshed when supported
  note files are written.

### Fixed

- Full-file renames retain the source file's directory instead of moving files into the configured
  notes directory.
- Telescope handles boolean and table configuration forms, respects picker options, and falls back
  to an absolute path when a relative link cannot be calculated.
- Frontmatter generation preserves signatures and aligns signature fields correctly.

## [v0.0] - 2025-04-17

### Added

- Initial release.
- Note creation using the Denote filename scheme.
- Commands to change a note's title, keywords, signature, or extension.
- Lua configuration through `require("denote").setup()` with note directory and extension options.
- Optional first-line heading creation and retitling for Markdown, Org, and Neorg notes.
- Input cleanup for whitespace, special characters, keywords, and signatures.

[Unreleased]: https://github.com/cvigilv/denote.nvim/compare/0.2...HEAD
[v0.2]: https://github.com/cvigilv/denote.nvim/compare/0.1...0.2
[v0.1]: https://github.com/cvigilv/denote.nvim/compare/0.0.1...0.1
[v0.0.1]: https://github.com/cvigilv/denote.nvim/compare/v0.0..0.0.1
[v0.0]: https://github.com/cvigilv/denote.nvim/commits/v0.0
