-- Font handling module for Neovim configuration
local M = {}

-- Cache of fonts we've already checked
M._font_cache = {}

-- Font testing function to check if a font is available
function M.is_font_available(font_name)
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

  -- For nvim-qt, check in a way that avoids warnings
  -- Try to identify if the font is installed by checking for files
  -- in common font directories based on the platform
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
    if M.is_font_available(font) then
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
