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

-- Initialize font cache and logging tables
function M.init_font_detection()
  if not M._font_cache then
    M._font_cache = {}
  end

  if not M._font_detection_log then
    M._font_detection_log = {}
  end
end

-- Check if a font name is in the built-in macOS system fonts
function M.check_macos_builtin_font(font_base, verbose)
  -- SF Mono is handled separately now in is_font_available
  -- so we don't need to check for it here

  -- Built-in macOS system fonts
  if font_base == "Menlo" or font_base == "Monaco" then
    if verbose then
      table.insert(M._font_detection_log[font_base],
        "Built-in system font: " .. font_base .. " is available by default on macOS")
    end

    return true
  end

  return nil -- Not a built-in macOS font
end

-- Log font detection result and update cache
function M.log_font_result(font_base, is_available, verbose)
  M._font_cache[font_base] = is_available

  if verbose then
    if is_available then
      table.insert(M._font_detection_log[font_base], "✓ Font found and marked as available")
    else
      table.insert(M._font_detection_log[font_base], "✗ Font not found in any location")
      table.insert(M._font_detection_log[font_base], "Cached as unavailable for future checks")
    end
  end

  return is_available
end

-- Font availability testing function with detailed logging capabilities
function M.is_font_available(font_name, verbose)
  -- Initialize cache and logging
  M.init_font_detection()

  -- Extract the base font name (without size)
  local font_base = font_name:match("^([^:]+)")

  -- Initialize log for this font if verbose mode
  if verbose then
    M._font_detection_log[font_base] = M._font_detection_log[font_base] or {}
    table.insert(M._font_detection_log[font_base], "Checking availability of font: " .. font_base)
  end

  -- Return from cache if we've already checked this font
  if M._font_cache[font_base] ~= nil then
    if verbose then
      table.insert(M._font_detection_log[font_base], "Using cached result: " ..
        (M._font_cache[font_base] and "Available" or "Not available"))
    end
    return M._font_cache[font_base]
  end

  -- We need special handling for SF Mono since it's a macOS font with a special naming scheme
  if font_base == "SF Mono" and vim.fn.has("macunix") == 1 then
    local sf_mono_path = vim.fn.expand("~/Library/Fonts/SF-Mono-Regular.otf")
    if vim.fn.filereadable(sf_mono_path) == 1 then
      if verbose then
        table.insert(M._font_detection_log[font_base],
          "✓ Found SF Mono at " .. sf_mono_path)
      end
      return M.log_font_result(font_base, true, verbose)
    end
  end

  -- Check for built-in macOS system fonts
  if vim.fn.has("macunix") == 1 then
    local builtin_result = M.check_macos_builtin_font(font_base, verbose)
    if builtin_result ~= nil then
      return M.log_font_result(font_base, builtin_result, verbose)
    end
  end

  -- Check for fonts in standard system directories
  if verbose then
    table.insert(M._font_detection_log[font_base], "Searching system font directories")
  end

  local common_font_check = M.check_common_font_locations(font_base, verbose)
  if common_font_check ~= nil then
    return common_font_check
  end

  -- No font files found - mark as unavailable
  return M.log_font_result(font_base, false, verbose)
end

-- Helper function to check if a font exists in system font directories
function M.check_system_font_dir_for_font(font_base)
  -- Special case for SF Mono on macOS
  if font_base == "SF Mono" and vim.fn.has("macunix") == 1 then
    -- Mac users typically install SF Mono with this naming pattern from Terminal.app
    local sf_mono_path = vim.fn.expand("~/Library/Fonts/SF-Mono-Regular.otf")
    if vim.fn.filereadable(sf_mono_path) == 1 then
      return true
    end
  end

  -- Get the standard font paths for the current OS
  local font_paths = M.get_system_font_dirs()
  local variants = M.get_common_font_variants()

  -- Check if the font exists in any of the system font directories
  for _, path in ipairs(font_paths) do
    -- Check with variants
    for _, variant in ipairs(variants) do
      local ttf_path = path .. font_base .. "-" .. variant .. ".ttf"
      local otf_path = path .. font_base .. "-" .. variant .. ".otf"

      if vim.fn.filereadable(ttf_path) == 1 or vim.fn.filereadable(otf_path) == 1 then
        return true
      end

      -- Special case for SF Mono which uses a different naming convention
      if font_base == "SF Mono" then
        local sf_path = path .. "SF-Mono-" .. variant .. ".otf"
        if vim.fn.filereadable(sf_path) == 1 then
          return true
        end
      end
    end

    -- Check without variants (e.g., Arial.ttf rather than Arial-Regular.ttf)
    local ttf_path = path .. font_base .. ".ttf"
    local otf_path = path .. font_base .. ".otf"

    if vim.fn.filereadable(ttf_path) == 1 or vim.fn.filereadable(otf_path) == 1 then
      return true
    end
  end

  return false
end

-- Get the standard font directories for the current OS
function M.get_system_font_dirs()
  if vim.fn.has("macunix") == 1 then
    return {
      vim.fn.expand("~/Library/Fonts/"),
      "/Library/Fonts/",
      "/System/Library/Fonts/", -- System fonts
      "/System/Library/Fonts/Supplemental/" -- Additional system fonts
    }
  elseif vim.fn.has("unix") == 1 then
    -- Linux and FreeBSD
    return {
      vim.fn.expand("~/.local/share/fonts/"),
      vim.fn.expand("~/.fonts/"),
      "/usr/local/share/fonts/",
      "/usr/share/fonts/"
    }
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- Windows
    return {
      vim.fn.expand("$WINDIR/Fonts/")
    }
  else
    -- Fallback to common Unix paths
    return {
      vim.fn.expand("~/.fonts/"),
      "/usr/share/fonts/"
    }
  end
end

-- Get common font variants to check for
function M.get_common_font_variants()
  return {
    "Regular", "Bold", "Italic", "BoldItalic", "Medium", "Light",
    "MediumItalic", "LightItalic", "Thin", "ThinItalic", "Heavy", "HeavyItalic"
  }
end


-- Helper function to check font file existence and handle logging
function M.check_font_file(path, font_base, verbose, is_variant, variant_name)
  local exists = vim.fn.filereadable(path) == 1

  if exists and verbose then
    local ext = path:match("%.([^.]+)$"):upper()
    local message

    if is_variant then
      message = "  ✓ Found " .. ext .. " variant " .. variant_name .. ": " .. path
    else
      message = "  ✓ Found " .. ext .. " font without variant suffix: " .. path
    end

    table.insert(M._font_detection_log[font_base], message)
  end

  return exists
end

-- Check for font variants in a specific directory
function M.check_font_variants_in_dir(base_path, font_base, variants, verbose)
  -- Check variant fonts (e.g., Font-Regular.ttf)
  for _, variant in ipairs(variants) do
    local ttf_path = base_path .. font_base .. "-" .. variant .. ".ttf"
    local otf_path = base_path .. font_base .. "-" .. variant .. ".otf"

    if M.check_font_file(ttf_path, font_base, verbose, true, variant) or
       M.check_font_file(otf_path, font_base, verbose, true, variant) then

      if verbose then
        table.insert(M._font_detection_log[font_base], "  ✓ Font found, marking as available")
      end

      M._font_cache[font_base] = true
      return true
    end
  end

  -- Check base font with no variant (e.g., Font.ttf)
  local ttf_path = base_path .. font_base .. ".ttf"
  local otf_path = base_path .. font_base .. ".otf"

  if M.check_font_file(ttf_path, font_base, verbose, false) or
     M.check_font_file(otf_path, font_base, verbose, false) then

    M._font_cache[font_base] = true
    return true
  end

  return false
end

function M.check_common_font_locations(font_base, verbose)
  -- Only macOS is currently fully implemented
  if vim.fn.has("macunix") ~= 1 then
    return nil
  end

  -- Get font variants and paths
  local font_variants = M.get_common_font_variants()
  local base_paths = M.get_system_font_dirs()

  -- Log directories being checked
  if verbose then
    table.insert(M._font_detection_log[font_base], "Checking system font directories:")
    for _, base_path in ipairs(base_paths) do
      table.insert(M._font_detection_log[font_base], "  • " .. base_path)
    end
  end

  -- Check each directory for the font
  for _, base_path in ipairs(base_paths) do
    if M.check_font_variants_in_dir(base_path, font_base, font_variants, verbose) then
      return true
    end
  end

  -- No font found after checking all directories
  if verbose then
    table.insert(M._font_detection_log[font_base], "  ✗ Font not found in any system directories")
  end

  return nil
end

return M
