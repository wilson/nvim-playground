------------------------------------------
-- Utilities Module
-- Common functions and utilities used across the configuration
------------------------------------------

local M = {}

-- Function to check if running in a GUI environment
function M.is_gui_environment()
  -- Simple and reliable GUI detection that works with nvim-qt

  -- Check for nvim-qt's GuiLoaded global
  if vim.g.GuiLoaded then
    return true
  end

  -- Check for nvim-qt's nvim_qt_detected marker (set in our autocmds)
  if vim.g.nvim_qt_detected then
    return true
  end

  -- Check for basic Neovim GUI detection
  if vim.fn.has('gui_running') == 1 then
    return true
  end

  -- Check for Neovide
  if vim.g.neovide then
    return true
  end

  -- Check common GUI environment variables
  if vim.env.NVIM_GUI or vim.env.TERM_PROGRAM == "neovide" then
    return true
  end

  -- Everything else is considered terminal
  return false
end

-- Helper function to safely load modules
function M.require_safe(module_name)
  local ok, module = pcall(require, module_name)
  if not ok then
    vim.notify("Failed to load module: " .. module_name, vim.log.levels.WARN)
    return nil
  end
  return module
end

-- Create a read-only buffer with the given content
function M.create_ro_buffer(lines, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)
  -- Set buffer options
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  -- Set filetype if provided
  if filetype then
    vim.bo[buf].filetype = filetype
  end
  return buf
end

return M