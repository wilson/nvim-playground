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

-- Font availability testing function with detailed logging capabilities
function M.is_font_available(font_name, verbose)
  -- Return cached result if available
  if not M._font_cache then
    M._font_cache = {}
  end

  -- Store font detection steps if verbose logging is enabled
  if not M._font_detection_log then
    M._font_detection_log = {}
  end

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

  -- Check for built-in macOS system fonts first (most efficient)
  if vim.fn.has("macunix") == 1 then
    if font_base == "SF Mono" then
      -- Check user fonts directory directly - use safer method than glob
      local sf_fonts_path = vim.fn.expand("~/Library/Fonts/SF-Mono-Regular.otf")
      local available = vim.fn.filereadable(sf_fonts_path) == 1

      if verbose then
        table.insert(M._font_detection_log[font_base],
          "macOS SF Mono check: " ..
          (available and "✓ Found at " or "✗ Not found at ") .. sf_fonts_path)
      end

      if available then
        M._font_cache[font_base] = true
        return true
      end
    elseif font_base == "Menlo" or font_base == "Monaco" then
      -- These are always available on macOS
      if verbose then
        table.insert(M._font_detection_log[font_base],
          "Built-in system font: " .. font_base .. " is available by default on macOS")
      end

      M._font_cache[font_base] = true
      return true
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
  M._font_cache[font_base] = false

  if verbose then
    table.insert(M._font_detection_log[font_base],
      "✗ Font not found in any location")
    table.insert(M._font_detection_log[font_base], "Cached as unavailable for future checks")
  end

  return false
end

-- Helper function to check if a font exists in system font directories
function M.check_system_font_dir_for_font(font_base)
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

function M.check_common_font_locations(font_base, verbose)
  if vim.fn.has("macunix") == 1 then
    -- Check common system font variants - more reliable than globbing
    local font_variants = M.get_common_font_variants()

    -- Try common paths for this font family
    local base_paths = M.get_system_font_dirs()

    if verbose then
      table.insert(M._font_detection_log[font_base], "Checking system font directories:")
      for _, base_path in ipairs(base_paths) do
        table.insert(M._font_detection_log[font_base], "  • " .. base_path)
      end
    end

    -- Check for each font variant with each extension in each base path
    for _, base_path in ipairs(base_paths) do
      for _, variant in ipairs(font_variants) do
        local ttf_path = base_path .. font_base .. "-" .. variant .. ".ttf"
        local otf_path = base_path .. font_base .. "-" .. variant .. ".otf"

        -- Check if any variant exists
        local ttf_exists = vim.fn.filereadable(ttf_path) == 1
        local otf_exists = vim.fn.filereadable(otf_path) == 1

        if verbose and (ttf_exists or otf_exists) then
          local found_path = ttf_exists and ttf_path or otf_path
          local ext = ttf_exists and "TTF" or "OTF"
          table.insert(M._font_detection_log[font_base], "  ✓ Found " .. ext .. " variant: " .. found_path)
        end

        if ttf_exists or otf_exists then
          M._font_cache[font_base] = true

          if verbose then
            table.insert(M._font_detection_log[font_base], "  ✓ Font found, marking as available")
          end

          return true
        end
      end
    end

    -- Also check for no-suffix variants (e.g., "Arial.ttf" instead of "Arial-Regular.ttf")
    for _, base_path in ipairs(base_paths) do
      local ttf_path = base_path .. font_base .. ".ttf"
      local otf_path = base_path .. font_base .. ".otf"

      local ttf_exists = vim.fn.filereadable(ttf_path) == 1
      local otf_exists = vim.fn.filereadable(otf_path) == 1

      if verbose and (ttf_exists or otf_exists) then
        local found_path = ttf_exists and ttf_path or otf_path
        local ext = ttf_exists and "TTF" or "OTF"
        table.insert(M._font_detection_log[font_base],
          "  ✓ Found " .. ext .. " font without variant suffix: " .. found_path)
      end

      if ttf_exists or otf_exists then
        M._font_cache[font_base] = true
        return true
      end
    end

    if verbose then
      table.insert(M._font_detection_log[font_base], "  ✗ Font not found in any system directories")
    end
  end

  -- No direct matches found, continue with other checks
  return nil
end

return M