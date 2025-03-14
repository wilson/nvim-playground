-----------------------------------------------------------
-- Module: Core Initialization
-- Handles initial setup of Neovim including bootstrapping lazy.nvim
-----------------------------------------------------------

-- Module initialization
local init = {}

-- Load other modules as needed

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
  -- Load the color modes module and initialize it
  local ok, color_modes = pcall(require, "config.color_modes")
  if ok then
    color_modes.init()
  else
    vim.notify("Failed to load color_modes module.", vim.log.levels.ERROR)
  end
end

-- Main setup function
function init.setup()
  -- Basic settings first
  init.basic_setup()

  -- Initialize basic color mode
  init.setup_basic_mode()

  -- Default leader key
  vim.g.mapleader = "\\"
  vim.g.maplocalleader = "\\"

  -- Load languages configuration
  local languages_config = load_language_config()

  -- Load and initialize plugin manager
  local plugins = require("config.plugins")
  plugins.init(languages_config)
  plugins.setup_treesitter_commands()

  -- Set up commands
  local commands = require("config.commands")
  commands.setup()

  -- Set up diagnostics
  local diagnostics = require("config.diagnostics")
  diagnostics.setup()

  -- Key repeat fix is now handled by DYLD injection in ~/.config/nvim/qt-keyrepeat-fix
end

-- Run the setup
init.setup()