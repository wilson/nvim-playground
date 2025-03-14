-- Font handling module for Neovim configuration
local M = {}

-- Use the font availability checking from utils.lua
local utils = require("config.utils")

-- Set the best available font
function M.set_best_font()
  -- Define font preferences in order
  local fonts = {
    "SF Mono:h13",         -- Apple SF Mono
    "Menlo:h13",           -- macOS default monospace
    "Monaco:h13",          -- Classic macOS monospace
    "Consolas:h13",        -- Windows/Office monospace
    "DejaVu Sans Mono:h13" -- Open source font
  }

  -- Try each font in order of preference
  for _, font in ipairs(fonts) do
    if utils.is_font_available(font) then
      -- Set the Vim option
      vim.o.guifont = font

      -- Also set nvim-qt specific setting if available
      if vim.fn.exists("*GuiFont") == 1 then
        pcall(vim.cmd, "GuiFont " .. font)
      end

      -- Notify which font was selected
      vim.schedule(function()
        vim.notify("Using font: " .. font, vim.log.levels.INFO)
      end)

      return font
    end
  end

  -- If all preferred fonts failed, use a generic fallback
  local fallback = "monospace:h13"
  vim.o.guifont = fallback

  if vim.fn.exists("*GuiFont") == 1 then
    pcall(vim.cmd, "GuiFont " .. fallback)
  end

  vim.schedule(function()
    vim.notify("No preferred fonts available, using system default", vim.log.levels.WARN)
  end)

  return fallback
end

return M
