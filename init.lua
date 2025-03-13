-----------------------------------------------------------
-- Module: Core Initialization
-- Handles initial setup of Neovim including bootstrapping lazy.nvim
-----------------------------------------------------------

-- Helper function to safely load the language configuration
local function load_language_config()
  local ok, config = pcall(require, "config.languages")
  if not ok then
    vim.notify("Failed to load language configuration: " .. (config or "unknown error"), vim.log.levels.WARN)
    return {}
  end
  return config
end

-- Define init module with functions for code organization
local init = {}

-- Bootstrap helper function to install lazy.nvim if not present
function init.bootstrap_lazy()
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
end

-- Initialize editor basics
function init.setup_editor_basics()
  -- Set leader key before lazy setup
  vim.g.mapleader = "\\"
  vim.g.maplocalleader = "\\"

  -- Make sure leader key is properly recognized
  vim.keymap.set({ "n", "v" }, "\\", "<Nop>", { silent = true })

  -- Add a splash screen to hide startup messages
  vim.opt.shortmess:append("I") -- Disable intro message
end

-- Setup basic color mode
function init.setup_terminal_app_mode()
  -- Apply basic color mode settings
  -- Default to basic color mode (users can switch to GUI mode with <leader>tt)
  vim.opt.termguicolors = false  -- Disable true colors for basic compatibility
  vim.opt.background = "dark"    -- Use dark mode for better contrast

  -- Create a global variable to track which mode we're in
  vim.g.terminal_app_mode = true

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
end

-- Function to set up lazy.nvim for plugin management
function init.setup_lazy_plugin_manager()
  local lazy_ok, lazy = pcall(function() return require("lazy") end)
  if not lazy_ok then
    vim.notify("lazy.nvim not found", vim.log.levels.ERROR)
    return nil
  end
  return lazy
end

-- Run bootstrap and initialization
init.bootstrap_lazy()
init.setup_editor_basics()
init.setup_terminal_app_mode()

-- Plugin setup
local lazy = init.setup_lazy_plugin_manager()
if not lazy then
  return
end

lazy.setup({
  -- Treesitter with fallback to standard syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      -- No termguicolors setting here - handled globally

      -- Force standard vim syntax on firs
      vim.cmd("syntax on")
      vim.cmd("syntax enable")

      -- Configure treesitter with optimized settings
      local lang_config = load_language_config()
      require("nvim-treesitter.configs").setup({
        auto_install = false,
        sync_install = true, -- Install parsers synchronously
        ensure_installed = lang_config.treesitter_parsers or {
          -- Fallback parsers if config not available
          "lua", "rust", "python", "javascript", "html", "css",
          "json", "toml", "yaml", "vim", "bash"
        },

        highlight = {
          enable = true,
          -- This allows either treesitter or vim regex highlighting to work based on environment
          additional_vim_regex_highlighting = true,

          -- Terminal.app compatibility - use treesitter only in GUI/capable terminals
          -- Disable treesitter highlighting when in Terminal.app mode
          disable = function(_, _)
            return vim.g.terminal_app_mode
          end,
        },

        -- Better indentation with treesitter
        indent = {
          enable = true
        },

        -- Enable incremental selection based on the named nodes from the grammar
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
      })

      -- No need for TSPlayground command anymore
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
            local lang_config = load_language_config()
            mason_lspconfig.setup({
              ensure_installed = lang_config.language_servers or {},
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
            local lang_config = load_language_config()
            -- Use the linters mapping from our shared config
            lint.linters_by_ft = lang_config.linters_by_ft or {}
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

  -- Enhanced Rust support
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },

  -- Rust tools with improved highlighting, LSP integration, and more
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("rust-tools").setup({
        tools = {
          autoSetHints = true,
          inlay_hints = {
            show_parameter_hints = true,
            parameter_hints_prefix = "<- ",
            other_hints_prefix = "=> ",
          },
        },
        -- Let our LSP configuration handle the server setup
        server = {
          standalone = false,
        },
      })
    end,
  },

  -- Better Lua syntax and indentation
  {
    "euclidianAce/BetterLua.vim",
    ft = "lua",
  },

  -- Little Wonder colorschemes collection
  {
    "VonHeikemen/little-wonder",
    lazy = false,
    priority = 1000, -- Load with highest priority
    config = function()
      -- lw-rubber colorscheme works well in both GUI and basic color modes
      -- No need for additional setup

      -- Apply lw-rubber theme if we're in a GUI environment
      if vim.fn.has('gui_running') == 1 or
         vim.fn.exists('g:GuiLoaded') == 1 or
         vim.fn.exists('g:neovide') == 1 or
         vim.env.NVIM_QT_PRODUCT_NAME ~= nil then

        -- GUI detected, use GUI colors with lw-rubber
        vim.opt.termguicolors = true
        vim.g.terminal_app_mode = false
        vim.cmd("colorscheme lw-rubber")
        -- Force apply GUI mode settings
        vim.api.nvim_exec_autocmds("User", { pattern = "GUIModeApplied" })
      end
    end,
  },

  -- GitHub Copilot
  {
    "github/copilot.vim",
    lazy = false, -- Load immediately to ensure it's properly recognized
  },

  -- Syntax highlighting plugins for basic mode
  -- These will work well in both Terminal.app and GUI modes
  {
    "vim-python/python-syntax",
    ft = "python",
    init = function()
      vim.g.python_highlight_all = 1
    end,
  },
  {
    "pangloss/vim-javascript",
    ft = "javascript",
  },
  {
    "HerringtonDarkholme/yats.vim",
    ft = "typescript",
  },
  {
    "vim-ruby/vim-ruby",
    ft = "ruby",
  },
  {
    "cespare/vim-toml",
    ft = "toml",
  },
  {
    "elzr/vim-json",
    ft = "json",
    init = function()
      vim.g.vim_json_syntax_conceal = 0
    end,
  },
  {
    "othree/html5.vim",
    ft = {"html", "xml"},
  },

})

-- Turn off cursorline highlight - works better in Terminal.app
vim.opt.cursorline = false

-----------------------------------------------------------
-- Module: LSP Configuration
-- Handles LSP server setup and completion configuration
-----------------------------------------------------------

local lsp = {}

-- Initialize LSP services
function lsp.setup()
  local lspconfig = vim.F.npcall(require, "lspconfig")
  if not lspconfig then
    vim.notify("lspconfig not found", vim.log.levels.ERROR)
    return false
  end

  local cmp_nvim_lsp = vim.F.npcall(require, "cmp_nvim_lsp")
  local capabilities = cmp_nvim_lsp and cmp_nvim_lsp.default_capabilities() or {}

  -- Setup common LSP servers
  local lang_config = load_language_config()
  local servers = lang_config.language_servers or {}

  for _, server in pairs(servers) do
    local ok, _ = pcall(function() return require("lspconfig." .. server) end)
    if ok then
      lspconfig[server].setup({ capabilities = capabilities })
    end
  end

  -- Set up key mappings
  lsp.setup_keymaps()
  return true
end

-- Configure LSP keymaps
function lsp.setup_keymaps()
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
  vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format" })
end

-- Initialize completion
function lsp.setup_completion()
  local cmp = vim.F.npcall(require, "cmp")
  if not cmp then
    vim.notify("nvim-cmp not found", vim.log.levels.ERROR)
    return false
  end

  local luasnip = vim.F.npcall(require, "luasnip")
  if not luasnip then
    vim.notify("luasnip not found", vim.log.levels.ERROR)
    return false
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
  return true
end

-- Initialize LSP services and completion
if not lsp.setup() then
  return
end

if not lsp.setup_completion() then
  return
end

-- Copilot panel shortcut
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

-- Terminal color settings for basic mode
vim.opt.termguicolors = false  -- Disable true colors for better compatibility
-- Use a safer way to set t_Co that works in both Vim and Neovim
pcall(function()
  if vim.fn.has("vim") == 1 then
    vim.cmd("set t_Co=256")  -- Only for Vim, not Neovim
  end
end)
vim.opt.background = "dark"   -- Use dark mode for better contras

-- Basic mode function for terminals with limited color support
local function force_reset_syntax()
  -- Using plugin-based highlighting with no buffer/filetype dependencies

  -- Store current state
  local was_gui_mode = not vim.g.terminal_app_mode

  -- Disable treesitter highlighting when in basic mode
  if vim.fn.exists(":TSBufDisable") == 2 then
    pcall(vim.cmd, "TSBufDisable highlight")
  end

  -- Set up for basic color mode
  vim.opt.termguicolors = false
  vim.g.terminal_app_mode = true
  vim.opt.background = "dark"

  -- Apply basic color mode highlighting
  vim.cmd("syntax clear")
  vim.cmd("syntax reset")
  vim.cmd("hi clear")

  -- Use lw-rubber for basic color mode too (with cterm colors)
  vim.cmd("colorscheme lw-rubber")

  -- Apply optimized ANSI colors for basic terminals
  vim.cmd([[
    " Basic ANSI color definitions
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
    hi Visual     ctermbg=8
    hi Keyword    ctermfg=4  cterm=bold
    hi Directory  ctermfg=4

    " Enable syntax highlighting
    syntax on
    syntax enable
  ]])

  -- Let plugin-based highlighting take over
  -- Enhanced plugins will provide better highlighting

  -- Notify user about mode state
  if was_gui_mode then
    vim.notify("Switched from GUI mode to basic color mode", vim.log.levels.INFO)
  else
    vim.notify("Refreshed basic color mode", vim.log.levels.INFO)
  end
end

-- Add keybinding to switch to basic color mode
-- No keybinding needed - use the :BasicMode command instead

-- No alternative shortcut needed - use :BasicMode command instead

-- No toggle key needed - use :BasicMode or :GUIMode commands instead

-- ColorTest functionality integrated into Diagnostics command

-- Helper function to get environment information for diagnostics
local function get_env_info()
  return {
    "Terminal Diagnostics",
    "===================",
    "",
    "Environment variables:",
    "  TERM: " .. (vim.env.TERM or "not set"),
    "  COLORTERM: " .. (vim.env.COLORTERM or "not set"),
    "  TERM_PROGRAM: " .. (vim.env.TERM_PROGRAM or "not set"),
  }
end

-- Helper function to get Neovim settings for diagnostics
local function get_nvim_settings()
  -- Determine if we're in a GUI environment
  local in_gui = vim.fn.has('gui_running') == 1 or
                 vim.fn.exists('g:GuiLoaded') == 1 or
                 vim.fn.exists('g:neovide') == 1 or
                 vim.env.NVIM_QT_PRODUCT_NAME ~= nil
  -- Force terminal_app_mode to false if in a GUI
  if in_gui and vim.g.terminal_app_mode then
    vim.g.terminal_app_mode = false
  end
  -- Force termguicolors to true if in GUI mode
  if in_gui and not vim.opt.termguicolors:get() then
    vim.opt.termguicolors = true
  end

  return {
    "",
    "Neovim settings:",
    "  termguicolors: " .. tostring(vim.opt.termguicolors:get()),
    "  terminal_app_mode: " .. tostring(vim.g.terminal_app_mode),
    "  background: " .. vim.opt.background:get(),
    "  has('termguicolors'): " .. tostring(vim.fn.has('termguicolors') == 1),
    "  has('gui_running'): " .. tostring(vim.fn.has('gui_running') == 1),
    "  is_gui: " .. tostring(in_gui),
    "  colorscheme: " .. (vim.g.colors_name or "default"),
  }
end

-- Helper function to get tree-sitter information
local function get_treesitter_info()
  return {
    "",
    "Tree-sitter settings:",
    "  tree-sitter version: " .. (vim.fn.has('nvim-0.9.0') and "0.25.3 (latest)" or "unknown"),
    "  parsers installed: " .. (vim.fn.exists(":TSInstallInfo") == 2 and "Use :TSInstallInfo to see" or "none"),
    "  highlight enabled: " .. tostring(not vim.g.terminal_app_mode),
    "",
    "Current Mode:",
    "  " .. (vim.g.terminal_app_mode
      and "Basic color mode (ANSI colors with lw-rubber, vim syntax)"
      or "GUI mode (true colors with lw-rubber, tree-sitter)"),
  }
end

-- Helper function to get command information
local function get_command_info()
  return {
    "",
    "Available Commands:",
    "  :BasicMode - Switch to basic color mode",
    "  :GUIMode - Switch to GUI mode with lw-rubber and tree-sitter",
    "  :Diagnostics - Display system and terminal diagnostics with color test",
    "  <leader>p - Open GitHub Copilot panel",
    "",
    "Color Test (shows colored blocks):",
  }
end

-- Helper function to generate terminal diagnostics information
local function get_terminal_diagnostics_info()
  local info = {}

  -- Combine all sections
  vim.list_extend(info, get_env_info())
  vim.list_extend(info, get_nvim_settings())
  vim.list_extend(info, get_treesitter_info())
  vim.list_extend(info, get_command_info())

  return info
end

-- Helper function to add color test blocks to the diagnostics buffer
local function add_color_test_blocks(buf)
  -- Check if we're in GUI mode for proper color display
  local in_gui = vim.g.terminal_app_mode == false and vim.opt.termguicolors:get()

  -- Define standard GUI colors that match ANSI terminal colors
  local gui_colors = {
    -- Basic ANSI colors (0-7)
    "#000000", -- Black
    "#CC0000", -- Red
    "#4E9A06", -- Green
    "#C4A000", -- Yellow/Brown
    "#3465A4", -- Blue
    "#75507B", -- Magenta
    "#06989A", -- Cyan
    "#D3D7CF", -- White/Light gray
    -- Bright ANSI colors (8-15)
    "#555753", -- Bright black (gray)
    "#EF2929", -- Bright red
    "#8AE234", -- Bright green
    "#FCE94F", -- Bright yellow
    "#729FCF", -- Bright blue
    "#AD7FA8", -- Bright magenta
    "#34E2E2", -- Bright cyan
    "#EEEEEC"  -- Bright white
  }

  -- Add basic ANSI colors
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "Basic ANSI colors (0-7):"})
  for i = 0, 7 do
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Color " .. i .. "  "})
    if in_gui then
      -- Use standard GUI colors in GUI mode
      vim.api.nvim_set_hl(0, "TestBgColor" .. i, {ctermbg = i, bg = gui_colors[i+1]})
    else
      -- Use only CTERM colors in terminal mode
      vim.api.nvim_set_hl(0, "TestBgColor" .. i, {ctermbg = i})
    end
    vim.fn.matchadd("TestBgColor" .. i, "Color " .. i .. "  $")
  end

  -- Add bright ANSI colors
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "Bright ANSI colors (8-15):"})
  for i = 8, 15 do
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Color " .. i .. "  "})
    if in_gui then
      -- Use standard GUI colors in GUI mode
      vim.api.nvim_set_hl(0, "TestBgColor" .. i, {ctermbg = i, bg = gui_colors[i+1-8]})
    else
      -- Use only CTERM colors in terminal mode
      vim.api.nvim_set_hl(0, "TestBgColor" .. i, {ctermbg = i})
    end
    vim.fn.matchadd("TestBgColor" .. i, "Color " .. i .. "  $")
  end

  -- Add text style tests
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "Text attributes:"})

  -- Bold test
  vim.api.nvim_set_hl(0, "TestBold", {bold = true})
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Bold text"})
  vim.fn.matchadd("TestBold", "Bold text$")

  -- Italic test
  vim.api.nvim_set_hl(0, "TestItalic", {italic = true})
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Italic text"})
  vim.fn.matchadd("TestItalic", "Italic text$")

  -- Underline test
  vim.api.nvim_set_hl(0, "TestUnderline", {underline = true})
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"  Underlined text"})
  vim.fn.matchadd("TestUnderline", "Underlined text$")
end

-- Create diagnostic function for terminal settings
vim.api.nvim_create_user_command("Diagnostics", function()
  -- Create a new buffer to display terminal diagnostic information
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].buftype = "nofile"

  -- Get and set terminal information
  local lines = get_terminal_diagnostics_info()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Add color test blocks
  add_color_test_blocks(buf)

  -- Check if we're in a GUI
  local in_gui = vim.fn.has('gui_running') == 1 or
                 vim.fn.exists('g:GuiLoaded') == 1 or
                 vim.fn.exists('g:neovide') == 1 or
                 vim.env.NVIM_QT_PRODUCT_NAME ~= nil
  -- Add appropriate recommendations based on environment
  if in_gui then
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "",
      "GUI Environment Detected:",
      "  - You are running in a GUI environment (nvim-qt, neovide, etc.)",
      "  - Make sure termguicolors is ON (use :GUIMode if needed)",
      "  - GUI mode offers better color support and visual features",
      "  - Use :GUIMode to ensure proper GUI settings"
    })
  else
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "",
      "Recommendations for Terminal.app:",
      "  1. Use :BasicMode to apply basic terminal colors that work in any terminal",
      "  2. Make sure termguicolors is OFF in basic mode",
      "  3. Consider using iTerm2 instead for better color support",
      "  4. If using Terminal.app, go to Preferences > Profiles > [Your Profile] > Advanced",
      "     and ensure 'Report Terminal Type' is set to xterm-256color"
    })
  end

  -- Make the buffer read-only
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.notify("System diagnostics created", vim.log.levels.INFO)
end, {})

-- No longer need RefreshSyntax command

-- No need for TSUpdate command anymore

-- Add explicit commands for Terminal.app mode and GUI mode
vim.api.nvim_create_user_command("TerminalMode", function()
  -- Force Terminal.app mode
  vim.g.terminal_app_mode = true
  force_reset_syntax()
end, {})

vim.api.nvim_create_user_command("GUIMode", function()
  -- Enable GUI mode with tree-sitter
  vim.g.terminal_app_mode = false
  vim.opt.termguicolors = true
  vim.cmd("colorscheme lw-rubber")

  -- Enable treesitter highlighting if available
  if vim.fn.exists(":TSBufEnable") == 2 then
    pcall(vim.cmd, "TSBufEnable highlight")
  end

  -- Fire an event that other code can hook into
  vim.api.nvim_exec_autocmds("User", { pattern = "GUIModeApplied" })

  vim.notify("Switched to GUI mode with tree-sitter highlights", vim.log.levels.INFO)
end, {})

-- Create augroups for color mode compatibility
vim.api.nvim_create_augroup("ColorModeSettings", { clear = true })

-- Add a command to switch to basic color mode
vim.api.nvim_create_user_command("BasicMode", function()
  pcall(force_reset_syntax)
  vim.notify("Basic color mode applied", vim.log.levels.INFO)
end, {})

-- Function to set up autocmds
local function setup_autocmds()
  -- Format Lua code on save
  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.lua",
    callback = function()
      vim.lsp.buf.format({ async = false })
    end,
  })

  -- Apply color mode settings on key events
  vim.api.nvim_create_autocmd({"VimEnter", "BufEnter", "ColorScheme"}, {
    group = "ColorModeSettings",
    callback = function()
      -- Only apply basic color mode if we're in basic mode
      if vim.g.terminal_app_mode then
        pcall(force_reset_syntax)
      end
    end,
    desc = "Maintain basic color mode settings",
  })
end

-- Set up the autocmds
setup_autocmds()

-- No automatic .luacheckrc creation for projects
-- Users should create their own .luacheckrc files based on project requirements