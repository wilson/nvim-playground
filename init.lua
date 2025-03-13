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

-- Removed unused load_plugin function

-- Module initialization
local init = {}

function init.basic_setup()
  -- Basic settings
  vim.opt.number = true               -- Show line numbers
  vim.opt.relativenumber = true       -- Show relative line numbers
  vim.opt.cursorline = true           -- Highlight current line
  vim.opt.tabstop = 2                 -- Number of spaces per tab
  vim.opt.shiftwidth = 2              -- Number of spaces for indent
  vim.opt.expandtab = true            -- Use spaces instead of tabs
  vim.opt.ignorecase = true           -- Ignore case in search
  vim.opt.smartcase = true            -- Except when uppercase is used
  vim.opt.wrap = false                -- Don't wrap lines
  vim.opt.backup = false              -- Don't create backup files
  vim.opt.writebackup = false         -- Don't create writebackup files
  vim.opt.swapfile = false            -- Don't create swap files
  vim.opt.hlsearch = true             -- Highlight search results
  vim.opt.incsearch = true            -- Incrementally highlight search
  vim.opt.showmatch = true            -- Show matching brackets
  vim.opt.laststatus = 2              -- Always show status line
  vim.opt.list = true                 -- Show hidden characters
  vim.opt.listchars = {tab = "▸ ", trail = "·"} -- Character representations
  vim.opt.hidden = true               -- Allow hidden buffers
  vim.opt.splitbelow = true           -- Split below current window
  vim.opt.splitright = true           -- Split right of current window
  vim.opt.mouse = "a"                 -- Enable mouse in all modes
  vim.opt.shortmess:append("I") -- Disable intro message
end

-- Setup basic color mode
function init.setup_basic_mode()
  -- Load the color modes module and initialize it
  local ok, color_modes = pcall(require, "config.color_modes")
  if ok then
    color_modes.init()
  else
    -- Fallback to basic settings if module fails to load
    vim.notify("Failed to load color_modes module. Using fallback settings.", vim.log.levels.WARN)
    vim.opt.termguicolors = false
    vim.opt.background = "dark"
    vim.g.basic_mode = true
  end
end

-- Main setup function
function init.setup()
  -- Basic settings first
  init.basic_setup()

  -- Initialize basic color mode
  init.setup_basic_mode()

  -- Default leader key
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  -- Load languages configuration
  local languages_config = load_language_config()

  -- Configure lazy.nvim plugin manager if it exists
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

  -- Ensure lazy.nvim is installed
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Initialize plugins with lazy.nvim
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    vim.notify("Failed to load lazy.nvim plugin manager. Plugins will not be available.", vim.log.levels.WARN)
    return
  end

  -- Configure plugins with lazy.nvim
  lazy.setup({
    -- Color scheme
    {
      "VonHeikemen/little-wonder",
      lazy = false,
      priority = 1000, -- Load before other plugins
      config = function()
        -- Only set colorscheme in GUI mode (not Basic mode)
        if not vim.g.basic_mode then
          vim.opt.termguicolors = true
          -- Make sure the colorscheme is available by checking if the plugin path exists
          local plugin_path = vim.fn.expand("~/.local/share/nvim/lazy/little-wonder")
          if vim.fn.isdirectory(plugin_path) == 1 then
            pcall(vim.cmd, "colorscheme lw-rubber")
          else
            vim.notify("little-wonder plugin not found. Colorscheme not applied.", vim.log.levels.WARN)
          end
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

    -- LSP Configuration
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        -- Optional LSP progress UI
        -- { "j-hui/fidget.nvim", tag = "legacy" },
      },
      config = function()
        -- Set up LSP keymaps and configurations
        local lspconfig = require("lspconfig")

        -- Configure Mason integration if available
        local mason_ok, _ = pcall(require, "mason")
        local mason_lspconfig_ok, _ = pcall(require, "mason-lspconfig")

        if mason_ok and mason_lspconfig_ok then
          require("mason").setup({})
          require("mason-lspconfig").setup({
            ensure_installed = languages_config.lsp_servers or {},
            automatic_installation = true,
          })
        end

        -- Use a loop to conveniently call 'setup' on multiple servers
        local servers = languages_config.lsp_servers or {}
        for _, lsp in ipairs(servers) do
          lspconfig[lsp].setup({
            on_attach = function(client, bufnr)
              -- Enable formatting capability for each server
              -- if client.server_capabilities.documentFormattingProvider then
              --   vim.api.nvim_buf_set_option(bufnr, "formatexpr", "v:lua.vim.lsp.formatexpr()")
              --   -- Optional: Format on save
              --   -- local format_cmd = function() vim.lsp.buf.format() end
              --   -- vim.api.nvim_create_autocmd("BufWritePre", { buffer = bufnr, callback = format_cmd })
              -- end
            end,
            capabilities = require("cmp_nvim_lsp").default_capabilities(),
          })
        end
      end,
    },

    -- Mason for managing LSP servers
    {
      "williamboman/mason.nvim",
      dependencies = { "williamboman/mason-lspconfig.nvim" },
    },

    -- Autocompletion
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-d>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
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
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
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
      end,
    },

    -- Treesitter for better syntax highlighting and more
    {
      "nvim-treesitter/nvim-treesitter",
      dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          -- Install these parsers automatically
          ensure_installed = languages_config.treesitter_parsers or {},
          -- Install parsers synchronously (only applied to `ensure_installed`)
          sync_install = false,
          -- Automatically install missing parsers when entering buffer
          auto_install = true,
          -- Don't enable highlighting by default (we'll do it in GUIMode)
          highlight = {
            enable = false,
          },
          indent = {
            enable = true,
          },
          textobjects = {
            select = {
              enable = true,
              -- Automatically jump forward to textobj, similar to targets.vim
              lookahead = true,
              keymaps = {
                -- You can use the capture groups defined in textobjects.scm
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

    -- Code linter
    {
      "mfussenegger/nvim-lint",
      config = function()
        local nvim_lint = require("lint")

        -- Set up linters based on config
        nvim_lint.linters_by_ft = languages_config.linters_by_ft or {}

        -- Use autocmd to trigger linting on changes
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
          callback = function()
            require("lint").try_lint()
          end,
        })
      end,
    },
  })

  -- Add a command to run the linter
  vim.api.nvim_create_user_command("Lint", function()
    require("lint").try_lint()
  end, {})

  -- Add a command to analyze color schemes
  vim.api.nvim_create_user_command("ColorAnalyze", function()
    -- Load the color analysis module
    local ok, color_analyze = pcall(require, "config.color_analyze")
    if not ok then
      vim.notify("Color analysis module not found", vim.log.levels.ERROR)
      return
    end
    -- Run the analysis
    local output = color_analyze.run_analysis()
    -- Create buffer and display results
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    vim.api.nvim_win_set_buf(0, buf)
    -- Make buffer read-only and set options for better viewing
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    -- Notify user about next steps
    local msg = "Color analysis complete - try opening different filetypes to see more language highlights"
    vim.notify(msg, vim.log.levels.INFO)
  end, {})

  -- Add a command to force reinstallation of TreeSitter parsers
  vim.api.nvim_create_user_command("TSReinstall", function()
    local cache_dir = vim.fn.stdpath("cache")
    local parser_dir = cache_dir .. "/treesitter"
    -- Check if the directory exists
    if vim.fn.isdirectory(parser_dir) == 1 then
      -- Remove the parser directory
      vim.fn.delete(parser_dir, "rf")
      vim.notify("TreeSitter parser cache deleted. Restart Neovim to reinstall parsers.", vim.log.levels.INFO)
    else
      vim.notify("TreeSitter parser cache not found at " .. parser_dir, vim.log.levels.WARN)
    end
    -- Ask user to restart Neovim
    print("Please restart Neovim for changes to take effect.")
  end, {})

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
                  (vim.env.NVIM_GUI or vim.env.TERM_PROGRAM == "neovide") or
                  vim.g.neovide or vim.g.GuiLoaded

    local gui_status = in_gui and "Yes" or "No"

    return {
      "",
      "Neovim settings:",
      "  termguicolors: " .. tostring(vim.opt.termguicolors:get()),
      "  GUI environment: " .. gui_status,
      "  Basic mode: " .. tostring(vim.g.basic_mode or "Not set"),
      "  Vim version: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
    }
  end

  -- Helper function to get TreeSitter information for diagnostics
  local function get_treesitter_info()
    local ts_ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")
    local ts_status = {}

    if not ts_ok then
      return {
        "",
        "TreeSitter: Not installed or not available",
      }
    end

    -- Get list of installed parsers
    local installed = {}
    pcall(function()
      installed = ts_parsers.available_parsers()
    end)

    table.insert(ts_status, "")
    table.insert(ts_status, "TreeSitter:")
    table.insert(ts_status, "  Installed: Yes")
    table.insert(ts_status, "  Parsers installed: " .. #installed)
    table.insert(ts_status, "  Highlighting enabled: " .. tostring(not vim.g.basic_mode))

    if #installed > 0 then
      table.insert(ts_status, "")
      table.insert(ts_status, "  Installed parsers:")
      table.sort(installed) -- Sort parsers alphabetically

      -- Create a formatted list of parsers (5 per line)
      local line = "    "
      for i, parser in ipairs(installed) do
        line = line .. parser
        if i < #installed then
          line = line .. ", "
        end

        -- Start a new line every 5 parsers
        if i % 5 == 0 and i < #installed then
          table.insert(ts_status, line)
          line = "    "
        end
      end

      -- Add the last line if not empty
      if line ~= "    " then
        table.insert(ts_status, line)
      end
    end

    return ts_status
  end

  -- Helper function to get available commands for diagnostics
  local function get_command_info()
    return {
      "",
      "Available Commands:",
      "  :BasicMode - Switch to basic color mode",
      "  :GUIMode - Switch to GUI mode with lw-rubber and tree-sitter",
      "  :Diagnostics - Display system and terminal diagnostics with color test",
      "  :TSReinstall - Force reinstallation of TreeSitter parsers on next restart",
      "  :ColorAnalyze - Show current color scheme highlight information",
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
    -- First, an ANSI 16-color test
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "ANSI 16-Color Test:",
      "  Normal FG colors (30-37, 90-97):",
      "  \27[30m■\27[0m \27[31m■\27[0m \27[32m■\27[0m \27[33m■\27[0m",
      "  \27[34m■\27[0m \27[35m■\27[0m \27[36m■\27[0m \27[37m■\27[0m",
      "  \27[90m■\27[0m \27[91m■\27[0m \27[92m■\27[0m \27[93m■\27[0m",
      "  \27[94m■\27[0m \27[95m■\27[0m \27[96m■\27[0m \27[97m■\27[0m",
      "  Normal BG colors (40-47, 100-107):",
      "  \27[40m \27[0m \27[41m \27[0m \27[42m \27[0m \27[43m \27[0m",
      "  \27[44m \27[0m \27[45m \27[0m \27[46m \27[0m \27[47m \27[0m",
      "  \27[100m \27[0m \27[101m \27[0m \27[102m \27[0m \27[103m \27[0m",
      "  \27[104m \27[0m \27[105m \27[0m \27[106m \27[0m \27[107m \27[0m",
      "",
      "Terminal 256-Color Test (16-255):",
    })

    -- Add all 256 colors, 16 per line for compactness
    local line = "  "
    for i = 16, 255 do
      -- Add escape sequence for color
      line = line .. string.format("\27[48;5;%dm \27[0m", i)

      -- Start a new line every 16 colors
      if i % 16 == 15 then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, {line})
        line = "  "
      end
    end

    -- Add the last line if not complete
    if line ~= "  " then
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, {line})
    end

    -- Add information about ColorAnalyze command
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "",
      "Use :ColorAnalyze to run a comprehensive analysis that:",
      "- Compares BasicMode and GUIMode highlighting",
      "- Identifies optimal 256-color mappings for GUI colors",
      "- Shows differences between mode configurations",
      "- Generates highlight commands for perfect matching",
      "",
      "The ColorAnalyze tool will temporarily switch between modes to compare them,",
      "then restore your original mode when finished."
    })
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

    -- Add GUI-specific recommendations
    local in_gui = vim.fn.has('gui_running') == 1 or
                  (vim.env.NVIM_GUI or vim.env.TERM_PROGRAM == "neovide") or
                  vim.g.neovide or vim.g.GuiLoaded

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
        "Recommendations for Basic Mode:",
        "  1. Use :BasicMode to apply enhanced 256-color mode that works in any modern terminal",
        "  2. Make sure termguicolors is OFF in Basic mode for maximum compatibility",
        "  3. This config uses the full 256-color palette for vibrant syntax highlighting",
        "  4. Consider using iTerm2 or Alacritty for even better color support",
        "  5. If using macOS Terminal, go to Preferences > Profiles > [Your Profile] > Advanced",
        "     and ensure 'Report Terminal Type' is set to xterm-256color"
      })
    end

    -- Make the buffer read-only
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true

    vim.notify("System diagnostics created", vim.log.levels.INFO)
  end, {})

  -- Key repeat fix is now handled by DYLD injection in ~/.config/nvim/qt-keyrepeat-fix

  -- Set up GitHub Copilot panel command
  vim.keymap.set('n', '<leader>p', function()
    vim.cmd('Copilot panel')
  end, { noremap = true, silent = true, desc = "Open GitHub Copilot panel" })

  -- Process lazy-loading plugins
  if languages_config.lazy_plugins then
    lazy.setup(languages_config.lazy_plugins)
  end
end

-- Run the setup
init.setup()