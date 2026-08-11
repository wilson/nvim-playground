# TODOs

## Treesitter Migration

### Context
The primary `nvim-treesitter/nvim-treesitter` repository has
undergone a massive shift.
The old plugin has been archived (locked to the `master` branch),
and the `main` branch is now a completely incompatible rewrite.
This happened because Neovim 0.12+ now natively embeds Treesitter,
and therefore the highlighting and folding features that the plugin provided.

### Current Status
Explicitly locked `nvim-treesitter/nvim-treesitter` to the `master` branch in `custom/packages.lua` (`branch = "master"`).
This preserves the existing workflow, specifically:
- `install_dev_tools.sh` can still use `TSInstallSync!` headlessly.
- `nvim-treesitter-textobjects` (currently relied-on heavily for semantic navigation) continues to function.

### Future Plans
**Host Dependencies**:
The new `main` branch requires `tree-sitter-cli` to be installed on the host operating system.
This is a plausible thing to take on, but seems unnecessary after further review.
See below for the intended approach.

**Headless Installation**:
The headless parser installation command (`TSInstallSync!`) no longer exists.
`install_dev_tools.sh` needs to be updated to use the new Lua async install API: (`require('nvim-treesitter').install({...}):wait(...)`).

**Textobjects**:
The `nvim-treesitter-textobjects` plugin needs replacement, as the configuration structure has fundamentally changed.
The plan is to use the `.scm` files collected in `nvim-treesitter-textobjects`, but not the plugin itself.
Instead, `mini.ai` will implement the semantic replacements for existing NeoVim motions.
The individual treesitter language support repos often have `.scm` files included, but there is no standard naming convention.
At the moment, `nvim-treesitter-textobjects` seems like the best aggregation of them.

**Alternatives**:
In place of `nvim-treesitter`, the plan is to use `tree-sitter-manager.nvim` along with `mini.ai`, as described above.
