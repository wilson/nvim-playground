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

-- Early Terminal.app setup (apply consistent settings right away)
vim.opt.termguicolors = false  -- Disable true colors for Terminal.app compatibility
vim.opt.background = "dark"    -- Use dark mode for better contrast
vim.cmd([[
  " Clear any existing highlighting
  syntax clear
  hi clear

  " Set basic readable colors for startup
  hi Normal ctermfg=7 ctermbg=0
  hi Statement ctermfg=1 cterm=bold
  hi Comment ctermfg=8

  " Redraw to prevent flash of unstyled content
  redraw
]])

-- Plugin setup
local lazy_ok, lazy = pcall(function() return require("lazy") end)
if not lazy_ok then
  vim.notify("lazy.nvim not found", vim.log.levels.ERROR)
  return
end

lazy.setup({
  -- Treesitter with fallback to standard syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/playground", -- Add treesitter playground for debugging
    },
    config = function()
      -- No termguicolors setting here - handled globally

      -- Force standard vim syntax on first
      vim.cmd("syntax on")
      vim.cmd("syntax enable")

      -- Configure treesitter to work alongside Vim's highlighting
      -- Don't set termguicolors here - will be handled globally
      require("nvim-treesitter.configs").setup({
        auto_install = false,
        sync_install = false,
        ensure_installed = {},

        highlight = {
          enable = true,
          -- Use both treesitter AND Vim's regex highlighting for best results
          additional_vim_regex_highlighting = true,
        },

        indent = {
          enable = true
        },
      })

      -- Set up key mappings for toggling treesitter playground
      vim.keymap.set("n", "<leader>tp", function()
        vim.cmd("TSPlaygroundToggle")
      end, { desc = "Toggle treesitter playground" })
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

  -- Gruvbox Colorscheme with Terminal.app optimizations
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000, -- Load before treesitter
    config = function()
      -- We don't set termguicolors here - it's already set globally
      -- The setting is maintained to false for Terminal.app compatibility

      -- Turn off cursorline highlight
      vim.opt.cursorline = false

      -- Configure Gruvbox with terminal-friendly settings
      require("gruvbox").setup({
        contrast = "hard",
        bold = true,
        italic = {
          strings = false,  -- Disable italic in strings for terminal compatibility
          comments = true,
          operators = false,
          folds = false,
        },

        -- Simple palette that works well in 256-color mode
        palette_overrides = {
          dark0_hard = "#1d2021",
          dark0 = "#282828",
          dark1 = "#3c3836",
          dark2 = "#504945",
          dark3 = "#665c54",
          dark4 = "#7c6f64",
          light0_hard = "#f9f5d7",
          light0 = "#fbf1c7",
          light1 = "#ebdbb2",
          light2 = "#d5c4a1",
          light3 = "#bdae93",
          light4 = "#a89984",
          bright_red = "#fb4934",
          bright_green = "#b8bb26",
          bright_yellow = "#fabd2f",
          bright_blue = "#83a598",
          bright_purple = "#d3869b",
          bright_aqua = "#8ec07c",
          bright_orange = "#fe8019",
          neutral_red = "#cc241d",
          neutral_green = "#98971a",
          neutral_yellow = "#d79921",
          neutral_blue = "#458588",
          neutral_purple = "#b16286",
          neutral_aqua = "#689d6a",
          neutral_orange = "#d65d0e",
        },

        -- Basic overrides with terminal color numbers for better compatibility
        overrides = {
          Normal =     { fg = "#ebdbb2", bg = "#282828" },
          Comment =    { fg = "#928374", italic = true },
          String =     { fg = "#b8bb26" },
          Identifier = { fg = "#83a598" },
          Function =   { fg = "#b8bb26", bold = true },
          Statement =  { fg = "#fb4934", bold = true },
          PreProc =    { fg = "#8ec07c" },
          Type =       { fg = "#fabd2f", bold = true },
          Special =    { fg = "#fe8019" },
          Constant =   { fg = "#d3869b" },
        }
      })

      -- Add a terminal-specific colorscheme command
      vim.cmd("colorscheme gruvbox")

      -- Add a simple color tester
      vim.keymap.set("n", "<leader>tc2", function()
        vim.cmd([[
          " Create a simple color test buffer
          new
          file ColorTest
          setlocal buftype=nofile

          " Add test content
          call append(0, "Terminal Color Test:")
          call append(1, "")
          call append(2, "Basic Syntax Elements:")
          call append(3, "Statement: if, else, return (should be bold red)")
          call append(4, "Comment: -- This is a comment (should be gray)")
          call append(5, "String: 'Hello world' (should be green)")
          call append(6, "Function: function() (should be bold green)")
          call append(7, "Type: string, number (should be bold yellow)")
          call append(8, "")

          " Set highlighting
          syntax match Statement /if\|else\|return/
          syntax match Comment /--.*$/
          syntax match String /'.*'/
          syntax match Function /function/
          syntax match Type /string\|number/

          " Set readonly
          setlocal readonly
          setlocal nomodifiable
        ]])
      end, { desc = "Test syntax highlighting (VimScript version)" })
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

-- Terminal color settings - Terminal.app compatibility
vim.opt.termguicolors = false  -- Disable true colors for better Terminal.app compatibility
-- Use a safer way to set t_Co that works in both Vim and Neovim
pcall(function()
  if vim.fn.has("vim") == 1 then
    vim.cmd("set t_Co=256")  -- Only for Vim, not Neovim
  end
end)
vim.opt.background = "dark"   -- Use dark mode for better contrast

-- Core syntax reset function for Terminal.app compatibility
local function force_reset_syntax()
  -- Get current buffer and filetype
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  -- Disable treesitter highlighting for this buffer
  if vim.fn.exists(":TSBufDisable") == 2 then
    pcall(vim.cmd, "TSBufDisable highlight")
  end

  -- Ensure termguicolors is off for Terminal.app compatibility
  vim.opt.termguicolors = false
  vim.opt.background = "dark"

  -- Apply Terminal.app-friendly syntax highlighting
  vim.cmd([[
    " Reset syntax and highlighting
    syntax clear
    syntax reset
    hi clear

    " Terminal.app optimized colors using ANSI colors (0-15)
    hi Normal     ctermfg=7  ctermbg=0
    hi Comment    ctermfg=8  cterm=italic
    hi Statement  ctermfg=1  cterm=bold
    hi Function   ctermfg=2  cterm=bold
    hi String     ctermfg=2
    hi Constant   ctermfg=5
    hi Special    ctermfg=3
    hi Identifier ctermfg=6
    hi Type       ctermfg=3  cterm=bold
    hi PreProc    ctermfg=5
    hi Number     ctermfg=5
    hi Boolean    ctermfg=5
    hi Error      ctermfg=15 ctermbg=1
    hi Todo       ctermfg=0  ctermbg=3
    hi MatchParen ctermfg=0  ctermbg=3
    hi Search     ctermfg=0  ctermbg=11

    " Enable syntax highlighting
    syntax on
    syntax enable
  ]])

  -- Apply custom syntax file if applicable
  if ft == "lua" or ft == "rust" then
    pcall(vim.cmd, "source ~/.config/nvim/after/syntax/" .. ft .. ".vim")
  end
end

-- Add keybinding to force Terminal.app compatible syntax highlighting
vim.keymap.set("n", "<leader>sh", function()
  -- Force reset the syntax system
  force_reset_syntax()

  -- For a more complete reset, reload the current file if applicable
  local current_file = vim.fn.expand("%:p")
  if current_file and current_file ~= "" then
    local view = vim.fn.winsaveview()   -- Save cursor position
    vim.cmd("edit! " .. vim.fn.fnameescape(current_file))  -- Force reload
    vim.fn.winrestview(view)            -- Restore cursor position

    -- Apply syntax after reload in case reloading cleared it
    force_reset_syntax()
  end

  vim.notify("Terminal.app compatible syntax highlighting applied", vim.log.levels.INFO)
end, { desc = "Force Terminal.app syntax highlighting" })

-- Add alternative shortcut to use just Vim's 'default' colorscheme
vim.keymap.set("n", "<leader>sd", function()
  vim.opt.termguicolors = false
  vim.cmd("colorscheme default")
  vim.notify("Default Vim colorscheme applied", vim.log.levels.INFO)
end, { desc = "Use default Vim colorscheme" })

-- Add a key to toggle between termguicolors and basic terminal colors
vim.keymap.set("n", "<leader>tt", function()
  if vim.opt.termguicolors:get() then
    -- Switch to basic terminal colors
    vim.opt.termguicolors = false

    -- Use a very basic approach for highlighting
    vim.cmd([[
      hi clear
      set background=dark

      " Basic terminal-friendly highlight groups (should work on ANY terminal)
      hi Normal term=NONE cterm=NONE ctermfg=7 ctermbg=0
      hi Statement term=bold cterm=bold ctermfg=1
      hi Constant term=NONE cterm=NONE ctermfg=5
      hi Identifier term=NONE cterm=NONE ctermfg=6
      hi Comment term=NONE cterm=NONE ctermfg=8
      hi Special term=NONE cterm=NONE ctermfg=3
      hi PreProc term=NONE cterm=NONE ctermfg=5
      hi Type term=bold cterm=bold ctermfg=3
      hi Function term=bold cterm=bold ctermfg=2
      hi Repeat term=bold cterm=bold ctermfg=1
      hi String term=NONE cterm=NONE ctermfg=2
      hi Number term=NONE cterm=NONE ctermfg=5
    ]])

    vim.notify("Basic terminal colors mode (should work everywhere)", vim.log.levels.INFO)
  else
    -- Switch to true color mode
    vim.opt.termguicolors = true

    -- Reapply colorscheme
    vim.cmd("colorscheme gruvbox")
    vim.notify("True color mode (24-bit colors - may not work in Terminal.app)", vim.log.levels.INFO)
  end
end, { desc = "Toggle between color modes" })

-- Add a simple highlight-based color test command
vim.keymap.set("n", "<leader>tc", function()
  -- Create an empty buffer for the test
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer content
  local lines = {
    "Terminal Color Test",
    "==================",
    "",
    "Basic color test (background colors):",
    "-----------------------------------",
  }

  -- Add color test lines
  for i = 0, 15 do
    table.insert(lines, string.format("  Color %d  ", i))
  end

  -- Add text style test
  table.insert(lines, "")
  table.insert(lines, "Text style test:")
  table.insert(lines, "--------------")
  table.insert(lines, "  Bold text")
  table.insert(lines, "  Italic text")
  table.insert(lines, "  Underlined text")

  -- Add note
  table.insert(lines, "")
  table.insert(lines, "Note: If colors aren't displaying correctly:")
  table.insert(lines, "1. Run :TerminalFix command")
  table.insert(lines, "2. Press <leader>sh to force Terminal.app compatible syntax")
  table.insert(lines, "3. Use <leader>td to diagnose terminal capabilities")

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Display the buffer
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].modifiable = true
  vim.bo[buf].buftype = "nofile"

  -- Apply highlight groups after setting content
  vim.cmd([[
    syntax clear

    " Color test highlights - using direct terminal colors
    syntax match Color0 /Color 0/
    syntax match Color1 /Color 1/
    syntax match Color2 /Color 2/
    syntax match Color3 /Color 3/
    syntax match Color4 /Color 4/
    syntax match Color5 /Color 5/
    syntax match Color6 /Color 6/
    syntax match Color7 /Color 7/
    syntax match Color8 /Color 8/
    syntax match Color9 /Color 9/
    syntax match Color10 /Color 10/
    syntax match Color11 /Color 11/
    syntax match Color12 /Color 12/
    syntax match Color13 /Color 13/
    syntax match Color14 /Color 14/
    syntax match Color15 /Color 15/

    " Text style test
    syntax match BoldTest /Bold text/
    syntax match ItalicTest /Italic text/
    syntax match UnderlineTest /Underlined text/

    " Define colors - terminal friendly
    hi Color0 ctermfg=15 ctermbg=0
    hi Color1 ctermfg=15 ctermbg=1
    hi Color2 ctermfg=0 ctermbg=2
    hi Color3 ctermfg=0 ctermbg=3
    hi Color4 ctermfg=15 ctermbg=4
    hi Color5 ctermfg=15 ctermbg=5
    hi Color6 ctermfg=0 ctermbg=6
    hi Color7 ctermfg=0 ctermbg=7
    hi Color8 ctermfg=15 ctermbg=8
    hi Color9 ctermfg=15 ctermbg=9
    hi Color10 ctermfg=0 ctermbg=10
    hi Color11 ctermfg=0 ctermbg=11
    hi Color12 ctermfg=15 ctermbg=12
    hi Color13 ctermfg=15 ctermbg=13
    hi Color14 ctermfg=0 ctermbg=14
    hi Color15 ctermfg=0 ctermbg=15

    " Text styles
    hi BoldTest cterm=bold
    hi ItalicTest cterm=italic
    hi UnderlineTest cterm=underline
  ]])

  -- Make buffer readonly after highlighting applied
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.notify("Terminal color test created", vim.log.levels.INFO)
end, { desc = "Test terminal colors" })

-- Create diagnostic function for terminal settings
vim.keymap.set("n", "<leader>td", function()
  -- Create a new buffer to display terminal diagnostic information
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].buftype = "nofile"

  -- Get terminal information
  local lines = {
    "Terminal Diagnostics",
    "===================",
    "",
    "Environment variables:",
    "  TERM: " .. (vim.env.TERM or "not set"),
    "  COLORTERM: " .. (vim.env.COLORTERM or "not set"),
    "  TERM_PROGRAM: " .. (vim.env.TERM_PROGRAM or "not set"),
    "",
    "Neovim settings:",
    "  termguicolors: " .. tostring(vim.opt.termguicolors:get()),
    "  background: " .. vim.opt.background:get(),
    "  has('termguicolors'): " .. tostring(vim.fn.has('termguicolors') == 1),
    "  has('gui_running'): " .. tostring(vim.fn.has('gui_running') == 1),
    "  colorscheme: " .. (vim.g.colors_name or "default"),
    "",
    "Terminal color test (should show colored blocks):",
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Add basic ANSI colors
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "Basic ANSI colors (0-7):"})
  for i = 0, 7 do
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Color " .. i .. "  "})
    vim.api.nvim_set_hl(0, "TestBgColor" .. i, {ctermbg = i})
    vim.fn.matchadd("TestBgColor" .. i, "Color " .. i .. "  $")
  end

  -- Add bright ANSI colors
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "Bright ANSI colors (8-15):"})
  for i = 8, 15 do
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Color " .. i .. "  "})
    vim.api.nvim_set_hl(0, "TestBgColor" .. i, {ctermbg = i})
    vim.fn.matchadd("TestBgColor" .. i, "Color " .. i .. "  $")
  end

  -- Add text attributes
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "Text attributes (may not work in Terminal.app):"})
  vim.api.nvim_set_hl(0, "TestBold", {bold = true})
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Bold text"})
  vim.fn.matchadd("TestBold", "Bold text$")

  vim.api.nvim_set_hl(0, "TestItalic", {italic = true})
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Italic text"})
  vim.fn.matchadd("TestItalic", "Italic text$")

  vim.api.nvim_set_hl(0, "TestUnderline", {underline = true})
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Underlined text"})
  vim.fn.matchadd("TestUnderline", "Underlined text$")

  -- Recommendations
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
    "",
    "Recommendations for Terminal.app:",
    "  1. Try <leader>sh to use basic terminal colors that work in any terminal",
    "  2. Make sure termguicolors is OFF (use <leader>tt to toggle)",
    "  3. Consider using iTerm2 instead for better color support",
    "  4. If using Terminal.app, go to Preferences > Profiles > [Your Profile] > Advanced",
    "     and ensure 'Report Terminal Type' is set to xterm-256color"
  })

  -- Make the buffer read-only
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.notify("Terminal diagnostics created", vim.log.levels.INFO)
end, { desc = "Show terminal diagnostics" })

-- Add a simple refresh command for syntax highlighting
vim.keymap.set("n", "<leader>sr", function()
  force_reset_syntax()
  local ft = vim.bo.filetype or "unknown"
  vim.notify("Terminal.app syntax highlighting refreshed for " .. ft, vim.log.levels.INFO)
end, { desc = "Refresh Terminal.app syntax" })

-- Create augroups for Terminal.app compatibility
vim.api.nvim_create_augroup("TerminalAppFixes", { clear = true })

-- Add a command to manually fix Terminal.app syntax issues
vim.api.nvim_create_user_command("TerminalFix", function()
  pcall(force_reset_syntax)
  vim.notify("Terminal.app compatibility fix applied", vim.log.levels.INFO)
end, {})

-- Format Lua code on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.lua",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Apply Terminal.app compatibility settings on key events
vim.api.nvim_create_autocmd({"VimEnter", "BufEnter", "ColorScheme"}, {
  group = "TerminalAppFixes",
  callback = function()
    pcall(force_reset_syntax)
  end,
  desc = "Maintain Terminal.app compatibility",
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