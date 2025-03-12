local PKGS = {
    { 'savq/paq-nvim' },

    -- Tree-sitter
    { 'nvim-treesitter/nvim-treesitter', build = function() cmd 'TSUpdate' end },
    'nvim-treesitter/nvim-treesitter-textobjects',

    -- LSP & Language plugins
    'neovim/nvim-lspconfig',
    'rust-lang/rust.vim',

    -- Copilot
    'github/copilot.vim'
  }


local function clone_paq()
  local path = vim.fn.stdpath 'data' .. '/site/pack/paqs/start/paq-nvim'
  if vim.fn.empty(vim.fn.glob(path)) > 0 then
    vim.fn.system {
      'git',
      'clone',
      '--depth=1',
      'https://github.com/savq/paq-nvim.git',
      path,
    }
  end
end

clone_paq()
vim.cmd 'packadd paq-nvim'
package.loaded.plugins = nil
require 'paq'(PKGS)

do -- Copilot
  vim.keymap.set('n', '<leader>p', function()
    vim.cmd 'Copilot panel'
  end)
end

do -- Trailing whitespace
  vim.fn.matchadd('WhitespaceTrailing', [[\s\{1,}$]])
  vim.api.nvim_set_hl(0, 'WhitespaceTrailing', { link = 'diffText' })
end

do -- Tab config
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.expandtab = true
end
