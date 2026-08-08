-- Font handling module for Neovim configuration
local M = {}

-- Use the font availability checking from utils.lua
local utils = _G.require_and_setup("custom.utils", false)

-- Cache for pre-validated fonts to avoid trying unavailable fonts
M._validated_fonts = {}

-- Font message history (persistent storage)
M._font_message_history = {}

-- Floating window for persistent font notifications
M._notification_win = nil
M._notification_buf = nil
M._notification_timer = nil

-- Create a persistent notification window for font messages
function M.create_persistent_notification(msg, level)
  -- Determine level formatting
  local level_prefix, highlight_group
  if level == "error" then
    level_prefix = "ERROR"
    highlight_group = "ErrorMsg"
  elseif level == "warning" then
    level_prefix = "WARNING"
    highlight_group = "WarningMsg"
  elseif level == "debug" then
    level_prefix = "DEBUG"
    highlight_group = "Comment"
  else
    level_prefix = "INFO"
    highlight_group = "Normal"
  end

  -- Format lines with timestamp
  local timestamp = os.date("%H:%M:%S")
  local header = string.format("[%s] %s", timestamp, level_prefix)

  -- Split message by newlines if it contains them
  local msg_lines = {}
  for line in string.gmatch(msg, "[^\r\n]+") do
    table.insert(msg_lines, line)
  end

  -- Start with header lines
  local lines = {
    header,
    string.rep("─", #header),
  }

  -- Add message lines
  for _, line in ipairs(msg_lines) do
    table.insert(lines, line)
  end

  -- Add footer
  table.insert(lines, "")
  table.insert(lines, "Press any key to dismiss. Run :FontMessages to view all notifications.")

  -- Close existing notification if it exists
  if M._notification_win and vim.api.nvim_win_is_valid(M._notification_win) then
    vim.api.nvim_win_close(M._notification_win, true)
  end

  -- Cancel existing timer
  if M._notification_timer then
    vim.fn.timer_stop(M._notification_timer)
    M._notification_timer = nil
  end

  -- Create buffer if needed or reuse existing one
  if not M._notification_buf or not vim.api.nvim_buf_is_valid(M._notification_buf) then
    M._notification_buf = vim.api.nvim_create_buf(false, true)
  end

  -- Ensure buffer is modifiable before setting content
  vim.bo[M._notification_buf].modifiable = true

  -- Set buffer content
  vim.api.nvim_buf_set_lines(M._notification_buf, 0, -1, false, lines)

  -- Set buffer options (make read-only after content is set)
  vim.bo[M._notification_buf].modifiable = false
  vim.bo[M._notification_buf].buftype = "nofile"

  -- Calculate window dimensions
  local width = 60
  local height = #lines
  local col = vim.o.columns - width - 4
  local row = 2

  -- Create floating window for the notification
  local float_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    anchor = "NW",
    style = "minimal",
    border = "rounded"
  }

  -- Create the window
  M._notification_win = vim.api.nvim_open_win(M._notification_buf, false, float_opts)

  -- Set window options
  vim.wo[M._notification_win].wrap = true
  vim.wo[M._notification_win].cursorline = false

  -- Add highlighting
  local ns_id = vim.api.nvim_create_namespace("font_notification")

  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(M._notification_buf, ns_id, 0, -1)

  -- Apply highlights
  utils.add_highlight(M._notification_buf, ns_id, highlight_group, 0, 0, -1) -- Header
  utils.add_highlight(M._notification_buf, ns_id, "Special", 1, 0, -1) -- Separator

  -- Highlight all message lines
  for i = 1, #msg_lines do
    utils.add_highlight(M._notification_buf, ns_id, highlight_group, i + 1, 0, -1)
  end

  -- Highlight footer (last line)
  utils.add_highlight(M._notification_buf, ns_id, "Question", #lines - 1, 0, -1)

  -- Add key mappings to close the notification
  vim.api.nvim_buf_set_keymap(M._notification_buf, "n", "q",
    ":lua require('custom.fonts')._close_notification()<CR>",
    {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(M._notification_buf, "n", "<Esc>",
    ":lua require('custom.fonts')._close_notification()<CR>",
    {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(M._notification_buf, "n", "<CR>",
    ":lua require('custom.fonts')._close_notification()<CR>",
    {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(M._notification_buf, "n", "<Space>",
    ":lua require('custom.fonts')._close_notification()<CR>",
    {noremap = true, silent = true})

  -- Auto-close after 30 seconds
  M._notification_timer = vim.fn.timer_start(30000, function()
    M._close_notification()
  end)

  return M._notification_win
end

-- Close the notification window
function M._close_notification()
  if M._notification_win and vim.api.nvim_win_is_valid(M._notification_win) then
    vim.api.nvim_win_close(M._notification_win, true)
    M._notification_win = nil
  end

  if M._notification_timer then
    vim.fn.timer_stop(M._notification_timer)
    M._notification_timer = nil
  end
end

-- Helper function to log font messages in a consistent way
-- This logs messages to our custom notification system only
-- We no longer write to :messages to avoid cluttering it
-- @param msg String: The message to log
-- @param level String: The message level (warning, error, debug, info)
function M.log_font_message(msg, level)
  -- Validate input
  if type(msg) ~= "string" or msg == "" then return end
  level = level or "info"

  -- Store in our internal font message history
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  table.insert(M._font_message_history, {
    timestamp = timestamp,
    level = level,
    message = msg
  })

  -- Keep message history to a reasonable size (last 100 messages)
  if #M._font_message_history > 100 then
    table.remove(M._font_message_history, 1)
  end

  -- Always show important messages in our persistent notification system
  -- Skip debug messages unless in debug mode
  if level == "error" or level == "warning" or
     (level == "debug" and vim.env.NVIM_FONT_DEBUG) or
     (level == "info" and vim.env.NVIM_FONT_DEBUG) then
    if vim.v.vim_did_enter == 1 then
      M.create_persistent_notification(msg, level)
    else
      vim.schedule(function()
        M.create_persistent_notification(msg, level)
      end)
    end
  end
end

-- Show all font notifications in a popup format (similar to Neovim's notification history)
function M.show_notification_history()
  if #M._font_message_history == 0 then
    -- Create a notification about the empty history
    M.create_persistent_notification("No font messages have been logged in this session.", "info")
    return
  end

  -- Create a new buffer for all font notifications
  local buf = vim.api.nvim_create_buf(false, true)

  -- Prepare header
  local lines = {
    "Font Notifications History",
    "========================",
    "",
    "The following font-related notifications were shown in this session:",
    ""
  }

  -- Add each notification with a separator
  for i, entry in ipairs(M._font_message_history) do
    local level_str = entry.level:upper()
    table.insert(lines, string.format("%d. [%s] %s:", i, entry.timestamp, level_str))

    -- Split the message into lines and add each one
    for line in string.gmatch(entry.message, "[^\r\n]+") do
      table.insert(lines, "   " .. line)
    end

    -- Add separator
    table.insert(lines, string.rep("-", 70))
    table.insert(lines, "")
  end

  -- Add footer
  table.insert(lines, "Use 'q' to close this window or press g< to see Neovim's notification history")

  -- Set buffer content (ensure it's modifiable first)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Set buffer options
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "fontnotifications"

  -- Create a floating window
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded"
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set window options
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = true

  -- Add highlights
  local ns_id = vim.api.nvim_create_namespace("font_notifications_history")

  -- Highlight header
  utils.add_highlight(buf, ns_id, "Title", 0, 0, -1)
  utils.add_highlight(buf, ns_id, "Special", 1, 0, -1)

  -- Highlight each notification title line
  for i, line in ipairs(lines) do
    if line:match("^%d+%. %[%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%]") then
      -- Define highlighting based on level in the line
      if line:match("ERROR:") then
        utils.add_highlight(buf, ns_id, "ErrorMsg", i-1, 0, -1)
      elseif line:match("WARNING:") then
        utils.add_highlight(buf, ns_id, "WarningMsg", i-1, 0, -1)
      elseif line:match("DEBUG:") then
        utils.add_highlight(buf, ns_id, "Comment", i-1, 0, -1)
      elseif line:match("INFO:") then
        utils.add_highlight(buf, ns_id, "Statement", i-1, 0, -1)
      end
    elseif line:match("^%-%-%-%-%-") then
      -- Separator lines
      utils.add_highlight(buf, ns_id, "NonText", i-1, 0, -1)
    end
  end

  -- Add keymap to close the window with 'q'
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q',
    ':q<CR>', {silent = true, noremap = true})

  return win
end

-- Setup font-related commands
function M.setup_commands()
  -- Create a command to show all notifications in a history view
  vim.api.nvim_create_user_command("FontMessages", function()
    M.show_notification_history()
  end, {})

  -- Create a test command to trigger a font fallback message (for debugging)
  -- We've removed the debug test command as it's no longer needed

  -- Add an initial startup message that will be logged after the UI is fully initialized
  -- This helps ensure that :FontMessages always has at least one entry
  vim.schedule(function()
    M.log_font_message("Font message logging system active. Run :FontMessages to view the log at any time.", "info")
  end)

  -- Special handling to ensure fallback messages are visible
  -- Check if font info has already been logged
  vim.schedule(function()
    local has_fallback = false
    for _, entry in ipairs(M._font_message_history) do
      if entry.message:match("Using fallback font") then
        has_fallback = true
        break
      end
    end
  end)
end

-- Helper function to read font preferences from JSON
function M.read_font_config()
  local config_path = vim.fn.stdpath("config") .. "/custom/fonts.json"
  if vim.fn.filereadable(config_path) == 1 then
    local content = vim.fn.readfile(config_path)
    -- Join lines in case readfile returns multiple lines
    local ok, decoded = pcall(vim.fn.json_decode, table.concat(content, "\n"))
    if ok and type(decoded) == "table" then
      return decoded
    else
      M.log_font_message("Failed to parse config/fonts.json", "error")
    end
  end
  return nil
end

-- Helper function to get platform-specific font preferences
function M.get_preferred_fonts()
  local config = M.read_font_config()

  if not config then
    return {}
  end

  local default_size = config.default_size or "h14"
  local platform_fonts = {}

  if vim.fn.has("macunix") == 1 then
    platform_fonts = config.macos or {}
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    platform_fonts = config.windows or {}
  else
    platform_fonts = config.universal or {}
  end

  local preferred_fonts = {}

  for _, font in ipairs(platform_fonts) do
    if not font:match(":[hH]%d+$") then
      font = font .. ":" .. default_size
    end
    table.insert(preferred_fonts, font)
  end

  if config.universal then
    for _, uni_font in ipairs(config.universal) do
      if not uni_font:match(":[hH]%d+$") then
        uni_font = uni_font .. ":" .. default_size
      end
      local found = false
      for _, pref_font in ipairs(preferred_fonts) do
        if pref_font == uni_font then
          found = true
          break
        end
      end
      if not found then
        table.insert(preferred_fonts, uni_font)
      end
    end
  end

  return preferred_fonts, default_size
end

-- Helper to apply a font setting
function M.apply_font(font)
  -- Set the Vim option
  vim.o.guifont = font

  -- Also set nvim-qt specific setting if available
  if vim.fn.exists(":GuiFont") == 2 then
    vim.cmd("GuiFont " .. font)
  end

  return font
end

-- Helper to create appropriate font notification messages
function M.create_font_notification(font, is_fallback, is_debug)
  local base_font = font:match("^([^:]+)")
  local msg

  if is_fallback then
    msg = "Using fallback font: " .. font

    -- Add more detail about why
    if base_font == "Menlo" or base_font == "Monaco" then
      msg = msg .. "\nReason: Using built-in system font (preferred font unavailable)"
    elseif base_font == "Courier New" then
      msg = msg .. "\nReason: Using standard fallback font (preferred fonts unavailable)"
    else
      msg = msg .. "\nReason: Using available font (preferred fonts unavailable)"
    end

    -- Log the warning message
    M.log_font_message(msg, "warning")
  elseif is_debug then
    -- In debug mode, show detailed info about the font we're using
    msg = "Using font: " .. font

    -- Add validation method for debug mode
    if base_font == "Menlo" or base_font == "Monaco" then
      msg = msg .. "\nDetection: Built-in macOS system font (always available)"
    elseif base_font == "Courier New" then
      msg = msg .. "\nDetection: Standard fallback font (widely available)"
    else
      msg = msg .. "\nDetection: Font files found in system directories"
    end

    -- Log the debug info
    M.log_font_message(msg, "debug")
  end
end

-- Set the best available font using a file-system based approach
-- Note: This function only attempts to set fonts that have been pre-validated
-- via file system checks to be safe for nvim-qt (no "Unknown font" errors). This means:
-- 1. Only fonts with detected font files will be considered available
-- 2. Built-in fonts (Menlo, Monaco) are always considered available on macOS
-- 3. The system will fall back to platform-specific defaults if no available fonts are found
function M.set_best_font()
  -- Get platform-specific font preferences
  local preferred_fonts, default_size = M.get_preferred_fonts()

  -- If no config could be loaded, bypass selection
  if not preferred_fonts or #preferred_fonts == 0 then
    M.log_font_message("No fonts configured in fonts.json or file missing, bypassing automatic font selection.", "warning")
    return nil
  end

  -- Clear existing validations
  M._validated_fonts = {}

  -- Try each font in order of preference
  for i, font in ipairs(preferred_fonts) do
    local base_font = font:match("^([^:]+)")
    local is_available

    -- Special case for macOS built-in fonts
    if vim.fn.has("macunix") == 1 and (base_font == "Menlo" or base_font == "Monaco") then
      is_available = true
    else
      is_available = utils.check_system_font_dir_for_font(base_font)
    end

    M._validated_fonts[font] = is_available

    if is_available then
      -- Apply the font settings
      M.apply_font(font)

      -- Determine if this is a fallback or debug situation
      local is_fallback = (i > 1)  -- Not the first choice font
      local is_debug = vim.env.NVIM_FONT_DEBUG

      -- Create appropriate notifications if needed
      if is_fallback or is_debug then
        M.create_font_notification(font, is_fallback, is_debug)
      end

      return font
    end
  end

  -- Log detection result for debugging
  if vim.env.NVIM_FONT_DEBUG then
    M.log_font_message("No preferred fonts detected - validated fonts: " ..
      vim.inspect(M._validated_fonts), "debug")
  end

  -- If all preferred fonts failed, use a platform-specific fallback
  local fallback = vim.fn.has("macunix") == 1 and "Menlo:" or "Courier New:"
  fallback = fallback .. (default_size or "h14")

  -- Apply fallback font
  M.apply_font(fallback)

  -- Log this fallback selection directly
  M.log_font_message("Last resort fallback font selected: " .. fallback, "warning")

  -- Log a critical error since we couldn't find any fonts
  local error_msg = "Font error: No fonts available! Using " .. fallback:match("^([^:]+)") .. " as a last resort"
  M.log_font_message(error_msg, "error")

  return fallback
end

return M
