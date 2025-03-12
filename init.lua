-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- Create the parent directory if it doesn't exist
  local parent_dir = vim.fn.stdpath("data") .. "/lazy"
  vim.fn.mkdir(parent_dir, "p")
  
  -- Clone into the parent directory
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
    ">/dev/null 2>&1", -- Redirect both stdout and stderr
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key before lazy setup
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

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

-- Statusline customization
vim.opt.laststatus = 2  -- Always show statusline
vim.opt.showmode = false  -- Don't show mode in command line

-- Custom statusline function
function _G.statusline()
  local mode = vim.api.nvim_get_mode().mode
  local filename = vim.fn.expand('%:t')
  local modified = vim.bo.modified and '[+]' or ''
  local readonly = vim.bo.readonly and '[RO]' or ''
  local filetype = vim.bo.filetype ~= '' and vim.bo.filetype or 'no ft'
  local pos = string.format('%d:%d', vim.fn.line('.'), vim.fn.col('.'))
  
  return string.format(
    '%%#StatusLineMode#  %s %%#StatusLineFile# %s%s%s %%#StatusLineInfo# [%s] %%=%s ',
    mode:upper(),
    filename,
    modified,
    readonly,
    filetype,
    pos
  )
end

-- Set the statusline
vim.opt.statusline = '%!v:lua.statusline()'

-- Statusline colors
vim.api.nvim_set_hl(0, "StatusLineMode", { bg = "#7aa2f7", fg = "#1a1b26", bold = true })
vim.api.nvim_set_hl(0, "StatusLineFile", { bg = "#292e42", fg = "#c0caf5", bold = true })
vim.api.nvim_set_hl(0, "StatusLineInfo", { bg = "#1a1b26", fg = "#7dcfff" })

-- Keymaps
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Git repository health check
vim.keymap.set("n", "<leader>gh", function()
  local health_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(health_buffer, "buftype", "nofile")
  vim.api.nvim_buf_set_option(health_buffer, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(health_buffer, "swapfile", false)
  vim.api.nvim_buf_set_name(health_buffer, "GitHealth")
  
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }
  
  local win = vim.api.nvim_open_win(health_buffer, true, opts)
  vim.api.nvim_win_set_option(win, "winblend", 0)
  
  local function append_line(line)
    local lines = vim.split(line, "\n")
    vim.api.nvim_buf_set_lines(health_buffer, -1, -1, false, lines)
  end
  
  append_line("# Git Repository Health Check")
  append_line("")
  append_line("## Checking for corrupted objects...")
  
  vim.fn.jobstart("git fsck --full", {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            append_line("  " .. line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            append_line("  ERROR: " .. line)
          end
        end
      end
    end,
    on_exit = function()
      append_line("")
      append_line("## Suggested fixes:")
      append_line("")
      append_line("If corrupted objects were found, try these commands:")
      append_line("```")
      append_line("# Try to repair the repository")
      append_line("git gc --aggressive --prune=now")
      append_line("")
      append_line("# If that doesn't work, try cloning a fresh copy")
      append_line("cd ..")
      append_line("git clone <repository-url> fresh-repo")
      append_line("```")
    end
  })
end, { desc = "Git repository health check" })
