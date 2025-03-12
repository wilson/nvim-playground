-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- Redirect output to /dev/null to hide commit hash
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
    ">/dev/null", -- Redirect stdout
    "2>/dev/null", -- Redirect stderr
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key before lazy setup
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Add a splash screen to hide startup messages
vim.opt.shortmess:append("I") -- Disable intro message

-- Plugin setup
require("lazy").setup({
  -- Tree-sitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "rust" },
        highlight = { 
          enable = true,
          additional_vim_regex_highlighting = true, -- Enable both for better highlighting
        },
        indent = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      -- Mason for managing LSP servers
      {
        "williamboman/mason.nvim",
        config = function()
          require("mason").setup()
        end,
      },
      {
        "williamboman/mason-lspconfig.nvim",
        config = function()
          require("mason-lspconfig").setup({
            ensure_installed = { "lua_ls", "rust_analyzer" },
            automatic_installation = true,
          })
        end,
      },
    },
    config = function()
      -- LSP setup will be defined later
    end,
  },

  -- Rust
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },

  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,  -- Use terminal background
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
        },
        on_colors = function(colors)
          colors.bg = "#1a1b26"
          colors.bg_dark = "#16161e"
        end,
        on_highlights = function(highlights, colors)
          highlights.String = { fg = "#ff9e64" }
          highlights.Function = { fg = "#7aa2f7" }
          -- Ensure proper highlighting
          highlights.Normal = { bg = colors.bg, fg = colors.fg }
          highlights.NormalFloat = { bg = colors.bg_dark, fg = colors.fg }
        end,
      })
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  -- Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
  },
})

-- LSP Configuration
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Setup common LSP servers
local servers = { "lua_ls", "rust_analyzer" }
for _, lsp in ipairs(servers) do
  local ok, _ = pcall(require, "lspconfig." .. lsp)
  if ok then
    lspconfig[lsp].setup({ capabilities = capabilities })
  end
end

-- LSP keymaps
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format" })

-- Completion setup
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  }),
})

-- Copilot
vim.keymap.set("n", "<leader>p", function()
  vim.cmd("Copilot panel")
end, { desc = "Open Copilot panel" })

-- Whitespace highlighting
-- Trailing whitespace
vim.fn.matchadd("WhitespaceTrailing", [[\s\+$]])
-- Mixed tabs and spaces
vim.fn.matchadd("WhitespaceMixed", [[\(\t \|\s\+\t\)]])
-- Blank lines with whitespace
vim.fn.matchadd("WhitespaceBlankline", [[^\s\+$]])

-- Set highlighting colors
vim.api.nvim_set_hl(0, "WhitespaceTrailing", { bg = "#3f2d3d", fg = "#ff5370" })
vim.api.nvim_set_hl(0, "WhitespaceMixed", { bg = "#2d3f3d", fg = "#89ddff" })
vim.api.nvim_set_hl(0, "WhitespaceBlankline", { bg = "#3d3d2d", fg = "#ffcb6b" })

-- Editor settings
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.background = "dark"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Terminal color settings
vim.opt.termguicolors = true  -- Enable true colors support
-- Only disable if terminal doesn't support it
if vim.fn.has('termguicolors') == 0 then
  vim.opt.termguicolors = false
end

-- Keymaps
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
