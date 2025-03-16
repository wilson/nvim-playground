-----------------------------------------------------------
-- Module: Core Initialization
-- Handles initial setup of Neovim including bootstrapping lazy.nvim
-----------------------------------------------------------

-- Module initialization
local init = {}

-- Fix the Lua package path to include our config directory
-- This ensures require("config.xyz") will work properly
local config_dir = vim.fn.stdpath("config")
package.path = config_dir .. "/?.lua;" .. package.path

-- Helper function to safely require a module with better error reporting
local function safe_require(module_name)
  local ok, result = pcall(require, module_name)
  if not ok then
    return nil, tostring(result)
  end
  return result
end

-- Helper function to safely load the language configuration
local function load_language_config()
  local result, err = safe_require("config.languages")
  if not result then
    vim.notify("Failed to load language configuration: " .. (err or "unknown error"), vim.log.levels.WARN)
    return {}
  end
  return result
end

function init.basic_setup()
  -- Basic settings
  vim.opt.number = true               -- Show line numbers
  vim.opt.relativenumber = false      -- Use absolute line numbers
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
  vim.opt.shortmess:append("I")       -- Disable intro message
end

-- Setup basic color mode
function init.setup_basic_mode()
  -- Load the color modes module
  local color_modes, err = safe_require("config.color_modes")
  if color_modes then
    color_modes.init()
  else
    vim.notify("Failed to load color_modes module: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Main setup function
function init.setup()
  -- Basic settings first
  init.basic_setup()

  -- Default leader key
  vim.g.mapleader = "\\"
  vim.g.maplocalleader = "\\"

  -- Initialize basic color mode
  init.setup_basic_mode()

  -- Load languages configuration
  local languages_config = load_language_config()

  -- We no longer need to print available modules at startup
  -- local debug_modules = ""
  -- for _, file in ipairs(vim.fn.glob(vim.fn.stdpath("config") .. "/config/*.lua", false, true)) do
  --   local module_name = vim.fn.fnamemodify(file, ":t:r")
  --   debug_modules = debug_modules .. module_name .. " "
  -- end
  -- vim.notify("Available modules: " .. debug_modules, vim.log.levels.INFO)

  -- Load and initialize plugin manager
  local plugins, err = safe_require("config.plugins")
  if plugins then
    plugins.init(languages_config)
    plugins.setup_treesitter_commands()
  else
    vim.notify("Failed to load plugins module: " .. tostring(err), vim.log.levels.ERROR)
  end

  -- Set up commands
  local commands, commands_err = safe_require("config.commands")
  if commands then
    commands.setup()
  else
    vim.notify("Failed to load commands module: " .. tostring(commands_err), vim.log.levels.ERROR)
  end

  -- Set up diagnostics
  local diagnostics, diag_err = safe_require("config.diagnostics")
  if diagnostics then
    diagnostics.setup()
  else
    vim.notify("Failed to load diagnostics module: " .. tostring(diag_err), vim.log.levels.ERROR)
  end

  -- Key repeat fix is now handled by DYLD injection in ~/.config/nvim/qt-keyrepeat-fix
end

-- Run the setup
init.setup()