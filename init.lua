-----------------------------------------------------------
-- Module: Core Initialization
-- Handles initial setup of Neovim including bootstrapping lazy.nvim
-----------------------------------------------------------

-- Helper function to safely load the language configuration
local function load_language_config()
  -- Always load directly from the absolute path
  local config_dir = vim.fn.stdpath("config")
  local languages_path = config_dir .. "/config/languages.lua"
  local ok, result = pcall(function()
    local chunk, err = loadfile(languages_path)
    if not chunk then
      error("Could not load " .. languages_path .. ": " .. (err or "unknown error"))
    end
    return chunk()
  end)
  if not ok then
    vim.notify("Failed to load language configuration: " .. (result or "unknown error"), vim.log.levels.WARN)
    return {}
  end
  return result
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

    " Set base colors with 256-color palette for startup
    " The full colorscheme will be applied later
    hi Normal ctermfg=252 ctermbg=233      " Light gray text on very dark gray
    hi LineNr ctermfg=240 ctermbg=234      " Medium gray line numbers on slightly lighter bg
    hi Comment ctermfg=245 cterm=italic    " Medium gray with italic
    " Set initial syntax colors
    hi Keyword    ctermfg=81  cterm=bold   " Light blue
    hi Directory  ctermfg=75               " Bright blue
    hi Function   ctermfg=148 cterm=bold   " Yellow-green
    hi Statement  ctermfg=168 cterm=bold   " Light coral red
    hi Constant   ctermfg=170 cterm=bold   " Light purple
    hi Number     ctermfg=141              " Lighter purple
    hi Boolean    ctermfg=176 cterm=bold   " Pinkish purple
    hi String     ctermfg=114              " Light green

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
      -- Force standard vim syntax
      vim.cmd("syntax on")
      vim.cmd("syntax enable")

      -- Get language configuration
      local lang_config = load_language_config()
      -- Check headless mode
      local is_headless = #vim.api.nvim_list_uis() == 0

      -- Avoid reinstalling parsers on every startup
      -- Use a state file to track when we've already installed parsers
      local cache_dir = vim.fn.stdpath("cache")
      local ts_installed_file = cache_dir .. "/ts_parsers_installed"
      local parsers_need_install = false
      -- Check if we've installed parsers before
      if not vim.loop.fs_stat(ts_installed_file) and not is_headless then
        parsers_need_install = true
        -- Create the state file to mark parsers as installed
        vim.fn.writefile({os.date("%Y-%m-%d")}, ts_installed_file)
        -- Get parser dir to monitor installation progress
        local runtime_dir = vim.api.nvim_get_runtime_file("parser", true)[1]
        local parser_dir = runtime_dir or (vim.fn.stdpath("data") .. "/site/parser")
        -- Immediately show a startup message
        print("\n ⬇️  Installing TreeSitter parsers in parallel (this will be faster)...")
        -- Create counters for tracking installation progress
        local total_parsers = #lang_config.treesitter_parsers
        _G._ts_install_start_time = vim.loop.now()
        -- Create a timer to periodically check parser installation progress
        local timer = vim.loop.new_timer()
        if timer then
          -- Function to count installed parsers by checking the file system
          local function count_installed_parsers()
            local count = 0
            -- Check if the parser directory exists
            if vim.fn.isdirectory(parser_dir) == 1 then
              -- Count parser files in the directory
              local parser_files = vim.fn.glob(parser_dir .. "/*.so", false, true)
              count = #parser_files
            end
            return count
          end
          -- Track progress every 2 seconds
          timer:start(1000, 2000, vim.schedule_wrap(function()
            local elapsed = math.floor((vim.loop.now() - _G._ts_install_start_time) / 1000)
            local installed = count_installed_parsers()
            local percent = installed > 0
              and math.floor((installed / total_parsers) * 100)
              or 0
            -- Show progress with percentage
            print(string.format(" ⌛ TreeSitter installation: %d%% complete (%d/%d parsers, %ds elapsed)",
                               percent, installed, total_parsers, elapsed))
            -- Check if installation is complete
            if installed >= total_parsers or elapsed > 50 then
              if not timer:is_closing() then
                timer:stop()
                timer:close()
                print(string.format(" ✅ TreeSitter installation completed! (%d/%d parsers in %ds)",
                                  installed, total_parsers, elapsed))
              end
            end
          end))
          -- Set a maximum timeout
          vim.defer_fn(function()
            if not timer:is_closing() then
              timer:stop()
              timer:close()
              local elapsed = math.floor((vim.loop.now() - _G._ts_install_start_time) / 1000)
              local installed = count_installed_parsers()
              print(string.format(" ✅ TreeSitter installation timed out, but completed with %d/%d parsers in %ds",
                                installed, total_parsers, elapsed))
            end
            -- Clean up global state
            _G._ts_install_start_time = nil
          end, 60000) -- Allow 60 seconds for parallel installation
        end
      end

      -- Configure treesitter
      -- First, set up a more aggressive approach to reduce TreeSitter installation verbosity
      if parsers_need_install then
        -- Suppress TreeSitter installation messages
        local old_handler = vim.notify
        local old_print = _G.print
        -- Simple function to filter TreeSitter messages
        local function is_treesitter_message(msg)
          if type(msg) ~= "string" then return false end
          return msg:match("[Tt]ree[%-]?[Ss]itter") or
                 msg:match("[Tt]emporary [Dd]irectory") or
                 msg:match("[Ee]xtracting") or
                 msg:match("[Cc]ompiling") or
                 msg:match("[Dd]ownloading") or
                 msg:match("Installing parser") or
                 msg:match("has been installed")
        end
        -- Override notify to hide TreeSitter messages
        vim.notify = function(msg, level, opts)
          -- Skip TreeSitter messages
          if is_treesitter_message(msg) then
            return
          end
          -- Pass through other messages
          old_handler(msg, level, opts)
        end
        -- Override print to hide TreeSitter messages but allow our progress updates
        _G.print = function(...)
          local args = {...}
          local msg = args[1]
          -- Allow our progress messages
          if type(msg) == "string" and (msg:match("%%") or msg:match("⬇️") or msg:match("⌛") or msg:match("✅")) then
            old_print(...)
            return
          end
          -- Skip TreeSitter messages
          if is_treesitter_message(msg) then
            return
          end
          -- Pass through other messages
          old_print(...)
        end
        -- Restore original functions after installation finishes
        vim.defer_fn(function()
          vim.notify = old_handler
          _G.print = old_print
        end, 50000)  -- Allow 50 seconds for installation
      end
      -- Configure TreeSitter with parallel installation
      require("nvim-treesitter.configs").setup({
        auto_install = false,
        sync_install = false, -- Use async installation for better performance
        ensure_installed = parsers_need_install and lang_config.treesitter_parsers or {},

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
          -- Disable treesitter highlighting in terminal mode
          disable = function(_)
            return vim.g.terminal_app_mode -- Only disable in terminal mode
          end,
        },

        -- Better indentation with treesitter
        indent = { enable = true },

        -- Enable incremental selection
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
            -- Filter out any servers that aren't available in mason-lspconfig
            local available_servers = {}
            -- Only try this if we can get the list
            pcall(function()
              local all_mason_servers = mason_lspconfig.get_available_servers()
              local all_servers_set = {}
              -- Convert to a set for faster lookup
              for _, server in ipairs(all_mason_servers) do
                all_servers_set[server] = true
              end
              -- Only include servers that are available
              for _, server in ipairs(lang_config.language_servers or {}) do
                if all_servers_set[server] then
                  table.insert(available_servers, server)
                end
              end
            end)
            mason_lspconfig.setup({
              ensure_installed = available_servers,
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
            -- Only set up linting in non-headless mode
            local is_headless = #vim.api.nvim_list_uis() == 0
            if not is_headless then
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

-- Helper function to set up a single LSP server
function lsp.setup_server(lspconfig, _, server_name, capabilities)
  local ok, _ = pcall(function() return require("lspconfig." .. server_name) end)
  if ok then
    lspconfig[server_name].setup({ capabilities = capabilities })
  end
  -- Silently continue if server is not available
  -- We don't want to clutter the startup with warnings
end

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

  -- Server name mapping (for lspconfig vs mason-lspconfig differences)
  local server_mapping = {
    -- Map our servers to lspconfig server names
    vtsls = "tsserver",      -- TypeScript server
    ruby_lsp = "ruby_ls"     -- Ruby language server
  }

  for _, server in pairs(servers) do
    -- Use the mapping if it exists, otherwise use the original server name
    local server_name = server_mapping[server] or server
    lsp.setup_server(lspconfig, server, server_name, capabilities)
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
  -- Skip in headless mode
  local is_headless = #vim.api.nvim_list_uis() == 0
  if is_headless then
    return
  end

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

  -- Use enhanced 256-color palette for terminal mode while letting lw-rubber handle the base
  vim.cmd([[
    " Enable syntax highlighting first to let lw-rubber define most colors
    syntax on
    syntax enable
    " Use 256 colors for better visibility and closer GUI appearance
    " Color codes reference: https://jonasjacek.github.io/colors/
    " Syntax elements
    hi Keyword    ctermfg=81  cterm=bold     " Light blue (closer to GUI blue)
    hi Directory  ctermfg=75                 " Bright blue - visible but not harsh
    hi Function   ctermfg=148 cterm=bold     " Yellow-green for functions
    hi Statement  ctermfg=168 cterm=bold     " Light coral red for statements
    hi Type       ctermfg=178 cterm=bold     " Gold/mustard for types
    " Constants and values
    hi Constant   ctermfg=170 cterm=bold     " Light purple for constants
    hi Number     ctermfg=141                " Lighter purple for numbers
    hi Boolean    ctermfg=176 cterm=bold     " Pinkish purple for booleans
    hi Float      ctermfg=135                " Medium purple for floats
    hi String     ctermfg=114                " Light green for strings
    " Other common elements
    hi Comment    ctermfg=245 cterm=italic   " Medium gray with italic
    hi Visual     ctermbg=238                " Dark gray for selections
    hi Search     ctermfg=232 ctermbg=214    " Black on amber for search
    hi MatchParen ctermfg=232 ctermbg=214    " Black on amber for matching parentheses
    hi Error      ctermfg=231 ctermbg=196    " White on red for errors
    hi Todo       ctermfg=232 ctermbg=226    " Black on yellow for todos
  ]])

  -- Let plugin-based highlighting take over
  -- Enhanced plugins will provide better highlighting

  -- Only notify if this was triggered by a user command, not during startup
  if vim.v.vim_did_enter == 1 and was_gui_mode and vim.g.explicit_mode_change then
    -- Only notify when explicitly switching from GUI mode
    vim.notify("Switched from GUI mode to basic color mode", vim.log.levels.INFO)
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
    "  tree-sitter availability: " .. (vim.fn.exists(":TSInstall") == 2 and "Installed" or "Not available"),
    "  parsers installed: " .. (vim.fn.exists(":TSInstallInfo") == 2 and "Use :TSInstallInfo to see" or "none"),
    "  highlight enabled: " .. tostring(not vim.g.terminal_app_mode),
    "",
    "Current Mode:",
    "  " .. (vim.g.terminal_app_mode
      and "Basic color mode (256 colors with lw-rubber, vim syntax)"
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
    "  :TSReinstall - Force reinstallation of TreeSitter parsers on next restart",
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
    "#3465A4", -- Blue (Note: We avoid using this directly in terminal mode)
    "#75507B", -- Magenta
    "#06989A", -- Cyan
    "#D3D7CF", -- White/Light gray
    -- Bright ANSI colors (8-15)
    "#555753", -- Bright black (gray)
    "#EF2929", -- Bright red
    "#8AE234", -- Bright green
    "#FCE94F", -- Bright yellow
    "#729FCF", -- Bright blue (Better visibility on black background)
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
      "  1. Use :BasicMode to apply enhanced 256-color mode that works in any modern terminal",
      "  2. Make sure termguicolors is OFF in basic mode for maximum compatibility",
      "  3. This config uses the full 256-color palette for vibrant syntax highlighting",
      "  4. Consider using iTerm2 or Alacritty for even better color support",
      "  5. If using Terminal.app, go to Preferences > Profiles > [Your Profile] > Advanced",
      "     and ensure 'Report Terminal Type' is set to xterm-256color"
    })
  end

  -- Make the buffer read-only
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.notify("System diagnostics created", vim.log.levels.INFO)
end, {})

-- No longer need RefreshSyntax command

-- Add a command to force reinstallation of TreeSitter parsers
vim.api.nvim_create_user_command("TSReinstall", function()
  local cache_dir = vim.fn.stdpath("cache")
  local ts_installed_file = cache_dir .. "/ts_parsers_installed"
  -- Remove the state file to force reinstallation next time
  if vim.loop.fs_stat(ts_installed_file) then
    vim.fn.delete(ts_installed_file)
    vim.notify("TreeSitter parsers will be reinstalled on next Neovim restart", vim.log.levels.INFO)
  end
  -- Ask user to restart Neovim
  print("Please restart Neovim for changes to take effect.")
end, {})

-- TSEnableHighlight functionality is now integrated into GUIMode command

-- Add explicit commands for Terminal.app mode and GUI mode
vim.api.nvim_create_user_command("TerminalMode", function()
  -- Mark that we're explicitly running the command
  vim.g.explicit_mode_change = true
  -- Force Terminal.app mode
  vim.g.terminal_app_mode = true
  force_reset_syntax()
  -- Clear the flag
  vim.g.explicit_mode_change = nil
end, {})

vim.api.nvim_create_user_command("GUIMode", function()
  -- Mark that we're explicitly running the command
  vim.g.explicit_mode_change = true
  -- Enable GUI mode with tree-sitter
  vim.g.terminal_app_mode = false
  vim.opt.termguicolors = true
  vim.cmd("colorscheme lw-rubber")

  -- Enable treesitter highlighting
  if vim.fn.exists(":TSBufEnable") == 2 then
    pcall(vim.cmd, "TSBufEnable highlight")
    -- Also enable highlighting for all installed parsers
    pcall(function()
      local parsers = require("nvim-treesitter.parsers")
      local installed = parsers.available_parsers()
      for _, parser in ipairs(installed) do
        pcall(vim.cmd, "TSEnable highlight " .. parser)
      end
    end)
  end

  -- Fire an event that other code can hook into
  vim.api.nvim_exec_autocmds("User", { pattern = "GUIModeApplied" })

  -- Only notify after Vim is fully started
  if vim.v.vim_did_enter == 1 then
    vim.notify("Switched to GUI mode with tree-sitter highlights", vim.log.levels.INFO)
  end
  -- Clear the flag
  vim.g.explicit_mode_change = nil
end, {})

-- Create augroups for color mode compatibility
vim.api.nvim_create_augroup("ColorModeSettings", { clear = true })

-- Add a command to switch to basic color mode
vim.api.nvim_create_user_command("BasicMode", function()
  -- Mark that we're explicitly running the command
  vim.g.explicit_mode_change = true
  -- Apply the syntax
  pcall(force_reset_syntax)
  -- Only notify after Vim is fully started
  if vim.v.vim_did_enter == 1 then
    vim.notify("Basic color mode applied", vim.log.levels.INFO)
  end
  -- Clear the flag
  vim.g.explicit_mode_change = nil
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
      -- Skip in headless mode
      local is_headless = #vim.api.nvim_list_uis() == 0
      if is_headless then
        return
      end
      -- Only apply basic color mode if we're in basic mode and only once on VimEnter
      if vim.g.terminal_app_mode then
        -- Set a flag to avoid multiple startup messages
        local is_vim_enter = vim.fn.exists('v:vim_did_enter') == 0
        -- Temporarily disable notifications during startup
        if not vim.g._init_colors_done and is_vim_enter then
          -- Store old notify function
          local old_notify = vim.notify
          -- Set empty notify function
          vim.notify = function() end
          -- Run the syntax setup
          pcall(force_reset_syntax)
          -- Restore notify
          vim.notify = old_notify
          -- Set flag
          vim.g._init_colors_done = true
        else
          -- Regular call for other events
          pcall(force_reset_syntax)
        end
      end
    end,
    desc = "Maintain basic color mode settings",
  })
end

-- Set up the autocmds
setup_autocmds()

-- No automatic .luacheckrc creation for projects
-- Users should create their own .luacheckrc files based on project requirements