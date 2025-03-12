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

-- Make sure leader key is properly recognized
vim.keymap.set({ "n", "v" }, "\\", "<Nop>", { silent = true })

-- Add a splash screen to hide startup messages
vim.opt.shortmess:append("I") -- Disable intro message

-- Plugin setup
local lazy_ok, lazy = pcall(function() return require("lazy") end)
if not lazy_ok then
  vim.notify("lazy.nvim not found", vim.log.levels.ERROR)
  return
end

lazy.setup({
  -- Tree-sitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      local ts_ok, ts_configs = pcall(function() return require("nvim-treesitter.configs") end)
      if ts_ok then
        ts_configs.setup({
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
      end
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
          local mason_ok, mason = pcall(function() return require("mason") end)
          if mason_ok then
            mason.setup()
          end
        end,
      },
      {
        "williamboman/mason-lspconfig.nvim",
        config = function()
          local mason_lspconfig_ok, mason_lspconfig = pcall(function() return require("mason-lspconfig") end)
          if mason_lspconfig_ok then
            mason_lspconfig.setup({
              ensure_installed = { "lua_ls", "rust_analyzer", "luau_lsp" },
              automatic_installation = true,
            })
          end
        end,
      },
      -- Linter integration
      {
        "mfussenegger/nvim-lint",
        config = function()
          local lint_ok, lint = pcall(function() return require("lint") end)
          if lint_ok then
            lint.linters_by_ft = {
              lua = {"luacheck"},
            }
            -- Run linter on save
            vim.api.nvim_create_autocmd({ "BufWritePost" }, {
              callback = function()
                local lint_mod = vim.F.npcall(require, "lint")
                if lint_mod then
                  lint_mod.try_lint()
                end
              end,
            })
          end
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
      local tokyonight_ok, tokyonight = pcall(function() return require("tokyonight") end)
      if tokyonight_ok then
        tokyonight.setup({
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
      end
    end,
  },

  -- Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
  },
})

-- LSP Configuration
local lspconfig = vim.F.npcall(require, "lspconfig")
if not lspconfig then
  vim.notify("lspconfig not found", vim.log.levels.ERROR)
  return
end

local cmp_nvim_lsp = vim.F.npcall(require, "cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp and cmp_nvim_lsp.default_capabilities() or {}

-- Setup common LSP servers
local servers = { "lua_ls", "rust_analyzer", "luau_lsp" }
for _, lsp in pairs(servers) do
  local ok, _ = pcall(function() return require("lspconfig." .. lsp) end)
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
local cmp = vim.F.npcall(require, "cmp")
if not cmp then
  vim.notify("nvim-cmp not found", vim.log.levels.ERROR)
  return
end

local luasnip = vim.F.npcall(require, "luasnip")
if not luasnip then
  vim.notify("luasnip not found", vim.log.levels.ERROR)
  return
end

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
-- Define in global scope to make it accessible to v:lua
get_statusline = function()
  local mode = vim.api.nvim_get_mode().mode
  local filename = vim.fn.expand('%:t')
  local modified = vim.bo.modified and '[+]' or ''
  local readonly = vim.bo.readonly and '[RO]' or ''
  local filetype = vim.bo.filetype ~= '' and vim.bo.filetype or 'no ft'
  local pos = vim.fn.printf('%d:%d', vim.fn.line('.'), vim.fn.col('.'))
  
  return vim.fn.printf(
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
vim.opt.statusline = '%!v:lua.get_statusline()'

-- Statusline colors
vim.api.nvim_set_hl(0, "StatusLineMode", { bg = "#7aa2f7", fg = "#1a1b26", bold = true })
vim.api.nvim_set_hl(0, "StatusLineFile", { bg = "#292e42", fg = "#c0caf5", bold = true })
vim.api.nvim_set_hl(0, "StatusLineInfo", { bg = "#1a1b26", fg = "#7dcfff" })

-- Keymaps
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
-- Use a more explicit mapping for the linter
vim.keymap.set("n", "<leader>ll", function() 
  vim.notify("Running linter...", vim.log.levels.INFO)
  local lint = vim.F.npcall(require, "lint")
  if lint then
    lint.try_lint()
    vim.notify("Linter completed", vim.log.levels.INFO)
  else
    vim.notify("Linter not available", vim.log.levels.ERROR)
  end
end, { desc = "Run linter" })

-- Automatically run linter on certain events
vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
  callback = function()
    -- Only run linter if the buffer has a filetype
    if vim.bo.filetype and vim.bo.filetype ~= "" then
      local lint = vim.F.npcall(require, "lint")
      if lint then
        lint.try_lint()
      end
    end
  end,
})

-- Format Lua code on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.lua",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Create .luacheckrc file if it doesn't exist
local luacheckrc_path = vim.fn.getcwd() .. "/.luacheckrc"
if vim.fn.filereadable(luacheckrc_path) == 0 then
  -- Use vim.fn.writefile instead of io.open for better compatibility
  local content = {
    "-- Lua linter configuration",
    "std = {",
    "  globals = {\"vim\"},",
    "  read_globals = {\"vim\"}",
    "}",
    "-- Increase line length limit",
    "max_line_length = 120",
    "-- Ignore unused self parameter in methods",
    "self = false",
    "-- Ignore whitespace warnings",
    "ignore = {\"611\", \"612\", \"613\", \"614\"}",
    "-- Be more lenient with line length in comments",
    "max_comment_line_length = 160"
  }
  
  local result = vim.fn.writefile(content, luacheckrc_path)
  if result == 0 then
    vim.notify("Created .luacheckrc file", vim.log.levels.INFO)
  else
    vim.notify("Failed to create .luacheckrc file", vim.log.levels.ERROR)
  end
end

