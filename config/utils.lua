------------------------------------------
-- Utilities Module
-- Common functions and utilities used across the configuration
------------------------------------------

local M = {}

-- Function to check if running in a GUI environment
function M.is_gui_environment()
  -- Focused primarily on nvim-qt detection based on diagnostics results

  -- Check for nvim-qt's nvim_qt_detected marker (set in our autocmds)
  -- This appears to be the most reliable indicator
  if vim.g.nvim_qt_detected then
    return true
  end

  -- Check for nvim-qt's GuiLoaded global
  if vim.g.GuiLoaded then
    return true
  end

  -- Check for basic Neovim GUI detection
  if vim.fn.has('gui_running') == 1 then
    return true
  end

  -- Simple fallback for other GUI environments
  if vim.g.neovide or vim.env.NVIM_GUI then
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

-- Safely get an environment variable with error handling
function M.safe_get_env(var_name)
  local value = "not set"
  pcall(function()
    if vim.env and vim.env[var_name] then
      value = vim.env[var_name]
    end
  end)
  return value
end

-- Check if Neovim is running in headless mode
function M.is_headless()
  return #vim.api.nvim_list_uis() == 0
end

-- Font availability testing function
function M.is_font_available(font_name)
  -- Return cached result if available
  if not M._font_cache then
    M._font_cache = {}
  end

  -- Extract the base font name (without size)
  local font_base = font_name:match("^([^:]+)")

  -- Return from cache if we've already checked this font
  if M._font_cache[font_base] ~= nil then
    return M._font_cache[font_base]
  end

  -- Check for macOS system fonts first (efficient check)
  if vim.fn.has("macunix") == 1 then
    if font_base == "SF Mono" then
      -- Check user fonts directory directly - use safer method than glob
      local sf_fonts_path = vim.fn.expand("~/Library/Fonts/SF-Mono-Regular.otf")
      local available = vim.fn.filereadable(sf_fonts_path) == 1
      M._font_cache[font_base] = available
      return available
    elseif font_base == "Menlo" or font_base == "Monaco" then
      -- These are always available on macOS
      M._font_cache[font_base] = true
      return true
    end
  end

  -- Check common system font variants - more reliable than globbing
  local common_font_check = M.check_common_font_locations(font_base)
  if common_font_check ~= nil then
    return common_font_check
  end

  -- General approach (fallback): try setting the font and see if it takes
  local original_guifont = vim.o.guifont

  -- Try setting the font
  vim.o.guifont = font_name

  -- Check if the setting took effect
  local is_available = vim.o.guifont == font_name

  -- Restore original font if necessary
  if not is_available then
    vim.o.guifont = original_guifont
  end

  -- Cache the result
  M._font_cache[font_base] = is_available
  return is_available
end

-- Helper function to check for fonts in common system locations
function M.check_common_font_locations(font_base)
  if vim.fn.has("macunix") == 1 then
    -- Check common system font variants - more reliable than globbing
    local font_variants = {
      "Regular", "Bold", "Italic", "BoldItalic", "Medium", "Light"
    }

    -- Try common paths for this font family
    local base_paths = {
      vim.fn.expand("~/Library/Fonts/"),
      "/Library/Fonts/"
    }

    -- Check for each font variant with each extension in each base path
    for _, base_path in ipairs(base_paths) do
      for _, variant in ipairs(font_variants) do
        local ttf_path = base_path .. font_base .. "-" .. variant .. ".ttf"
        local otf_path = base_path .. font_base .. "-" .. variant .. ".otf"

        -- Check if any variant exists
        if vim.fn.filereadable(ttf_path) == 1 or vim.fn.filereadable(otf_path) == 1 then
          M._font_cache[font_base] = true
          return true
        end
      end
    end
  end

  -- No direct matches found, continue with other checks
  return nil
end

return M