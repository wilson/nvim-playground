-- Font handling module for Neovim configuration
local M = {}

-- Use the font availability checking from utils.lua
local utils = require("config.utils")

-- Cache for pre-validated fonts to avoid trying unavailable fonts
M._validated_fonts = {}

-- Pre-validate fonts by testing availability without trying to set them
function M.prevalidate_fonts()
  -- Define standard font preferences for different platforms
  local font_preferences = {
    -- macOS fonts
    macos = {
      "SF Mono:h13",     -- Apple SF Mono (included with macOS)
      "Menlo:h13",       -- macOS default monospace
      "Monaco:h13",      -- Classic macOS monospace
    },
    -- Windows fonts
    windows = {
      "Consolas:h13",        -- Windows/Office monospace
      "Cascadia Code:h13",   -- Modern Windows Terminal font
      "Segoe UI Mono:h13",   -- Windows UI font
    },
    -- Cross-platform and Linux fonts
    universal = {
      "DejaVu Sans Mono:h13", -- Open source font
      "Liberation Mono:h13",  -- Red Hat font
      "Ubuntu Mono:h13",      -- Ubuntu default
      "Courier New:h13"       -- Widely available fallback
    }
  }

  -- Clear existing validations
  M._validated_fonts = {}

  -- Select OS-appropriate fonts to check
  local fonts_to_check = {}

  if vim.fn.has("macunix") == 1 then
    vim.list_extend(fonts_to_check, font_preferences.macos)
    vim.list_extend(fonts_to_check, font_preferences.universal)
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    vim.list_extend(fonts_to_check, font_preferences.windows)
    vim.list_extend(fonts_to_check, font_preferences.universal)
  else
    -- Linux, FreeBSD, etc.
    vim.list_extend(fonts_to_check, font_preferences.universal)
  end

  -- Pre-check all fonts without attempting to set them
  for _, font in ipairs(fonts_to_check) do
    local base_font = font:match("^([^:]+)")

    -- Use the file-based font detection only, avoiding any attempt to set the font
    -- This prevents the "unknown font" error messages
    local is_available

    -- Special case for macOS built-in fonts
    if vim.fn.has("macunix") == 1 and (base_font == "Menlo" or base_font == "Monaco") then
      is_available = true
    else
      -- Only check for actual font file existence, never try to set the font
      -- This is the safest approach to avoid "Unknown font" errors
      is_available = utils.check_system_font_dir_for_font(base_font)
    end

    -- Store validation result
    M._validated_fonts[font] = is_available
  end
end

-- Set the best available font using a file-system based approach
-- Note: This function only attempts to set fonts that have been pre-validated
-- via file system checks to be safe for nvim-qt (no "Unknown font" errors). This means:
-- 1. Only fonts with detected font files will be considered available
-- 2. Built-in fonts (Menlo, Monaco) are always considered available on macOS
-- 3. The system will fall back to platform-specific defaults if no available fonts are found
function M.set_best_font()
  -- Ensure fonts are pre-validated
  if vim.tbl_isempty(M._validated_fonts) then
    M.prevalidate_fonts()
  end

  -- Define font preferences in order based on current OS
  local preferred_fonts

  if vim.fn.has("macunix") == 1 then
    preferred_fonts = {
      "SF Mono:h13",   -- Apple SF Mono
      "Menlo:h13",     -- macOS default monospace
      "Monaco:h13"     -- Classic macOS monospace
    }
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    preferred_fonts = {
      "Consolas:h13",      -- Windows/Office monospace
      "Cascadia Code:h13", -- Modern Windows Terminal font
      "Segoe UI Mono:h13"  -- Windows UI font
    }
  else
    -- Linux, FreeBSD, etc.
    preferred_fonts = {
      "DejaVu Sans Mono:h13", -- Common Linux font
      "Liberation Mono:h13",  -- Red Hat font
      "Ubuntu Mono:h13"       -- Ubuntu default
    }
  end

  -- Final fallbacks based on platform
  if vim.fn.has("macunix") == 1 then
    -- On macOS, Menlo is always available and is a better fallback than monospace
    table.insert(preferred_fonts, "Menlo:h13")
  else
    -- On Linux/Unix/Windows, typically Courier or Courier New are safe
    table.insert(preferred_fonts, "Courier New:h13")
    -- monospace can cause issues in nvim-qt ("not a fixed pitch font" error)
    -- table.insert(preferred_fonts, "monospace:h13")
  end

  -- Try each font in order of preference with detailed logging
  for _, font in ipairs(preferred_fonts) do
    -- Only try fonts that were pre-validated
    if M._validated_fonts[font] then
      -- Extract base font name for logging
      local base_font = font:match("^([^:]+)")

      -- Set the Vim option
      vim.o.guifont = font

      -- Also set nvim-qt specific setting if available
      if vim.fn.exists("*GuiFont") == 1 then
        pcall(vim.cmd, "GuiFont " .. font)
      end

      -- Notify which font was selected with detailed information
      vim.schedule(function()
        -- Build a more detailed notification
        local msg = "Using font: " .. font

        -- Add validation method
        if base_font == "Menlo" or base_font == "Monaco" then
          msg = msg .. "\nDetection: Built-in macOS system font (always available)"
        elseif base_font == "Courier New" then
          msg = msg .. "\nDetection: Standard fallback font (widely available)"
        else
          msg = msg .. "\nDetection: Font files found in system directories"
        end

        -- Add a note if we had to use something other than first choice
        if preferred_fonts[1] ~= font then
          msg = msg .. "\nNote: Using fallback font (preferred fonts unavailable)"
        end

        vim.notify(msg, vim.log.levels.INFO)
      end)

      return font
    end
  end

  -- If all preferred fonts failed, use a platform-specific fallback
  local fallback = vim.fn.has("macunix") == 1 and "Menlo:h13" or "Courier New:h13"
  vim.o.guifont = fallback

  if vim.fn.exists("*GuiFont") == 1 then
    -- Use a safe, known font that won't cause "not a fixed pitch font" errors
    pcall(vim.cmd, "GuiFont! " .. fallback)
  end

  vim.schedule(function()
    vim.notify("No preferred fonts available, using " .. fallback:match("^([^:]+)"), vim.log.levels.WARN)
  end)

  return fallback
end

return M
