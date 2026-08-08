-----------------------------------------------------------
-- Neovim startup procedure.
-----------------------------------------------------------
local init = {}

-- Add the current (a.k.a. NeoVim config) dir to the Lua package path.
local config_dir = vim.fn.stdpath("config")
package.path = config_dir .. "/?.lua;" .. package.path

-- Safely require a module and optionally run a setup function on it.
-- Pass false as the second argument to disable the default "setup()" call.
_G.require_and_setup = function(module_name, setup_func_name, ...)
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

function init.setup()
  init.setup_vim_options()

  -- Configuration (alphabetized, no load order dependencies permitted)
  _G.require_and_setup("custom.autocmds")
  _G.require_and_setup("custom.colors")
  _G.require_and_setup("custom.commands")
  _G.require_and_setup("custom.diagnostics")
  _G.require_and_setup("custom.keymaps")
  _G.require_and_setup("custom.packages")
end

function init.setup_vim_options()
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
  vim.opt.hidden = true               -- Allow hidden buffers
  vim.opt.splitbelow = true           -- Split below current window
  vim.opt.splitright = true           -- Split right of current window
  vim.opt.mouse = "a"                 -- Enable mouse in all modes
  vim.opt.shortmess:append("I")       -- Disable intro message
  vim.opt.listchars = {tab = "▸ ",    -- Character representations
                       trail = "•",
                       extends = "»",
                       precedes = "«",
                       nbsp = "✗"}
end

-- Make it so
init.setup()
