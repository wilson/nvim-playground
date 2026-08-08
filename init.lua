-----------------------------------------------------------
-- Module: Init
-- Handles Neovim startup, configures lazy.nvim
-----------------------------------------------------------

local init = {}

-- Add the current (a.k.a. NeoVim config) dir to the Lua package path.
local config_dir = vim.fn.stdpath("config")
package.path = config_dir .. "/?.lua;" .. package.path

-- Helper function to safely require a module and optionally run a setup function on it
_G.require_and_setup = function(module_name, setup_func_name, ...)
  -- Default to "setup", but allow explicit false to disable calling any setup hook
  if setup_func_name == nil then
    setup_func_name = "setup"
  elseif setup_func_name == false then
    setup_func_name = nil
  end
  local ok, result = pcall(require, module_name)
  if not ok then
    vim.notify("Failed to load module " .. module_name .. ": " .. tostring(result), vim.log.levels.ERROR)
    return nil
  end

  if setup_func_name and type(result[setup_func_name]) == "function" then
    result[setup_func_name](...)
  elseif setup_func_name then
    vim.notify("Setup function '" .. setup_func_name .. "' not found in module " .. module_name, vim.log.levels.ERROR)
  end

  return result
end

function init.core_option_setup()
  vim.g.mapleader = "\\"
  vim.g.maplocalleader = "\\"

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
  vim.opt.listchars = {tab = "▸ ", trail = "•", extends = "»", precedes = "«", nbsp = "✗"} -- Character representations
  vim.opt.hidden = true               -- Allow hidden buffers
  vim.opt.splitbelow = true           -- Split below current window
  vim.opt.splitright = true           -- Split right of current window
  vim.opt.mouse = "a"                 -- Enable mouse in all modes
  vim.opt.shortmess:append("I")       -- Disable intro message
end

-- Full setup process.
function init.setup()
  init.core_option_setup()

  -- Configuration (alphabetized)
  require_and_setup("custom.autocmds")
  require_and_setup("custom.colors")
  require_and_setup("custom.commands")
  require_and_setup("custom.diagnostics")
  require_and_setup("custom.keymaps")
  require_and_setup("custom.packages")
end

-- Make it so
init.setup()
