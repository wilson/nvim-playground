# TODOs

## Treesitter Migration

### Context
The primary `nvim-treesitter/nvim-treesitter` repository has
undergone a massive architectural shift. The old plugin has been archived
(locked to the `master` branch), and the `main` branch is now a completely
incompatible rewrite.
This shift happened because Neovim 0.12+ now natively handles the core parsing,
highlighting, and folding functionalities that the plugin used to provide.

### Current Status
Explicitly locked `nvim-treesitter/nvim-treesitter` to the `master` branch in `custom/packages.lua` (`branch = "master"`).
This preserves the existing workflow, specifically:
- `install_dev_tools.sh` can still use `TSInstallSync!` headlessly.
- `nvim-treesitter-textobjects` (currently relied-on heavily for semantic navigation) continues to function.

### Future Plans
**Host Dependencies**:
The new `main` branch requires `tree-sitter-cli` to be installed on the host operating system. `install_dev_tools.sh` will need to be updated to detect and install this dependency across macOS, FreeBSD, and Linux.

**Headless Installation**:
The headless parser installation command (`TSInstallSync!`) no longer exists.
`install_dev_tools.sh` needs to be updated to use the new Lua async install API: (`require('nvim-treesitter').install({...}):wait(...)`).

**Textobjects**:
The `nvim-treesitter-textobjects` plugin will likely need an update or replacement, as the configuration structure has fundamentally changed.

**Alternatives**:
Look into lightweight community alternatives like `arborist.nvim` or `tree-sitter-manager.nvim` as replacements for the parser management aspect.
