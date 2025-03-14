------------------------------------------
-- Diagnostics Module
-- Functionality for system diagnostics and environment information
------------------------------------------

local M = {}

-- Get the utility functions
local utils = require("config.utils")

-- Helper function to get environment information for diagnostics
function M.get_env_info()
  -- Table to store environment information
  local env_info = {
    "Terminal Diagnostics",
    "===================",
    "",
    "Environment variables:",
  }

  -- Safely get environment variables with error checking
  local function safe_get_env(var_name)
    local value = "not set"
    pcall(function()
      if vim.env and vim.env[var_name] then
        value = vim.env[var_name]
      end
    end)
    return value
  end

  -- Add critical environment variables
  table.insert(env_info, "  TERM: " .. safe_get_env("TERM"))
  table.insert(env_info, "  COLORTERM: " .. safe_get_env("COLORTERM"))
  table.insert(env_info, "  TERM_PROGRAM: " .. safe_get_env("TERM_PROGRAM"))

  -- Add additional useful environment variables if they exist
  local optional_vars = {"TMUX", "SSH_CLIENT", "DISPLAY", "XDG_SESSION_TYPE"}
  for _, var in ipairs(optional_vars) do
    local value = safe_get_env(var)
    if value ~= "not set" then
      table.insert(env_info, "  " .. var .. ": " .. value)
    end
  end

  return env_info
end

-- Helper function to get Neovim settings for diagnostics
function M.get_nvim_settings()
  -- Safely check for GUI environment
  local gui_status = "No"
  pcall(function()
    gui_status = utils.is_gui_environment() and "Yes" or "No"
  end)

  -- Safely get termguicolors setting
  local termguicolors = "Unknown"
  pcall(function()
    termguicolors = tostring(vim.opt.termguicolors:get())
  end)

  -- Safely get version info with multiple methods
  local version = "Unknown"

  -- Try primary method: Using vim.version() function
  pcall(function()
    if vim.version and type(vim.version) == "function" then
      local v = vim.version()
      if v and type(v) == "table" and v.major and v.minor and v.patch then
        version = v.major .. "." .. v.minor .. "." .. v.patch
      end
    end
  end)

  -- Fallback method: Using nvim -v output captured via system command
  if version == "Unknown" then
    pcall(function()
      -- Get nvim version using external command
      local output = vim.fn.system("nvim --version | head -n 1")
      if output and type(output) == "string" then
        -- Extract version using pattern matching
        local ver = output:match("NVIM v([0-9]+%.[0-9]+%.[0-9]+)")
        if ver then
          version = ver
        end
      end
    end)
  end

  -- Start with basic settings
  local settings = {
    "",
    "Neovim settings:",
    "  termguicolors: " .. termguicolors,
    "  GUI environment: " .. gui_status,
    "  Basic mode: " .. tostring(vim.g.basic_mode or "Not set"),
    "  Vim version: " .. version,
  }

  -- Add GUI-specific information when in a GUI environment
  if gui_status == "Yes" then
    -- Create a section for GUI-specific info
    table.insert(settings, "")
    table.insert(settings, "GUI information:")

    -- Simple and reliable nvim-qt detection
    local gui_client = "Unknown"

    -- Based on our diagnostics, nvim-qt detection seems to work well
    if vim.g.nvim_qt_detected or vim.g.GuiLoaded then
      gui_client = "nvim-qt"
    elseif vim.fn.has('gui_running') == 1 then
      -- Check if nvim-qt is in the parent process path
      local is_nvim_qt = false
      pcall(function()
        if vim.fn.has('unix') == 1 then
          local ppid_cmd = vim.fn.system("ps -o ppid= -p " .. vim.fn.getpid() .. " | tr -d ' \n'")
          if ppid_cmd and #ppid_cmd > 0 then
            local parent_cmd = vim.fn.system("ps -o command= -p " .. ppid_cmd .. " | tr -d '\n'")
            if parent_cmd and parent_cmd:match("nvim%-qt") then
              is_nvim_qt = true
            end
          end
        end
      end)

      -- Set client based on detection
      if is_nvim_qt then
        gui_client = "nvim-qt"
      else
        gui_client = "GUI environment"
      end
    end

    -- Get nvim-qt process info and version if possible
    local gui_app_name = ""
    pcall(function()
      if vim.fn.has('unix') == 1 then
        -- Get nvim info
        local nvim_version = vim.version()
        local nvim_version_str = nvim_version and string.format("%d.%d.%d",
          nvim_version.major, nvim_version.minor, nvim_version.patch) or ""

        -- Start with basic info
        gui_app_name = " (neovim " .. nvim_version_str

        -- Get parent process for nvim-qt
        local ppid_cmd = vim.fn.system("ps -o ppid= -p " .. vim.fn.getpid() .. " | tr -d ' \n'")
        if ppid_cmd and #ppid_cmd > 0 then
          local parent_path = vim.fn.system("ps -o command= -p " .. ppid_cmd .. " | head -c 60")

          -- Extract nvim-qt version from path if possible
          local nvim_qt_version = parent_path:match("neovim%-qt/([%d%.]+)/") or ""
          if nvim_qt_version ~= "" then
            gui_app_name = gui_app_name .. " + nvim-qt " .. nvim_qt_version
          end
        end

        gui_app_name = gui_app_name .. ")"
      end
    end)

    table.insert(settings, "  GUI client: " .. gui_client .. gui_app_name)

    -- Get font information with improved detection
    pcall(function()
      local font = "Unknown"
      local font_source = ""

      -- Check various font sources in order of preference
      if vim.o.guifont and vim.o.guifont ~= "" then
        font = vim.o.guifont
        font_source = "guifont"
      elseif vim.g.GuiFont and vim.g.GuiFont ~= "" then
        font = vim.g.GuiFont
        font_source = "GuiFont"
      elseif vim.fn.exists("+guifont") == 1 then
        -- Try getting via direct command
        local ok, cmd_font = pcall(vim.api.nvim_exec2, "set guifont?", {output = true})
        if ok and cmd_font and cmd_font.output then
          local stripped = cmd_font.output:gsub("guifont=", ""):gsub("^%s*(.-)%s*$", "%1")
          if stripped ~= "" then
            font = stripped
            font_source = "set guifont?"
          end
        end
      end

      -- Check if we're using default Courier New (likely not deliberately set)
      local is_default = font:match("^Courier") ~= nil

      -- Add font info
      table.insert(settings, "  Font: " .. font ..
                          (font_source ~= "" and " (from " .. font_source .. ")" or ""))

      -- Add a helpful note if using default font
      if is_default then
        table.insert(settings, "  Font tip: Set custom font with: vim.o.guifont = 'SF Mono:h13'")
      end

      -- Add SF Mono installation instructions if on macOS
      if vim.fn.has("macunix") == 1 and (font:match("SF Mono") or is_default) then
        table.insert(settings, "")
        table.insert(settings, "  SF Mono installation:")
        table.insert(settings, "    If 'Unknown font' errors occur, install SF Mono by running:")
        table.insert(settings, "    mkdir -p ~/Library/Fonts")
        table.insert(settings, "    cp /System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SF-*.otf ~/Library/Fonts/")
        table.insert(settings, "    The install_dev_tools.sh script will attempt to install these fonts automatically")
      end
    end)

    -- Try to get window dimensions
    pcall(function()
      local width = vim.api.nvim_win_get_width(0)
      local height = vim.api.nvim_win_get_height(0)
      if width > 0 and height > 0 then
        table.insert(settings, "  Window size: " .. width .. "×" .. height)
      end
    end)

    -- Check for macOS key repeat fix
    pcall(function()
      if vim.fn.has('mac') == 1 and vim.g.GuiLoaded then
        local env_var = os.getenv("DYLD_INSERT_LIBRARIES")
        local has_fix = env_var and env_var:match("KeyRepeatFix") ~= nil
        table.insert(settings, "  Key repeat fix: " .. (has_fix and "Active" or "Not active"))
      end
    end)

    -- Check for full GUI features
    pcall(function()
      local features = {}
      -- nvim-qt specific features
      if vim.g.GuiLoaded then
        if vim.fn.exists('*GuiClipboard') == 1 then table.insert(features, "clipboard") end
        if vim.fn.exists('*GuiScrollBar') == 1 then table.insert(features, "scrollbar") end
        if vim.fn.exists('*GuiTabline') == 1 then table.insert(features, "tabline") end
        if vim.fn.exists('*GuiPopupmenu') == 1 then table.insert(features, "popupmenu") end
        if vim.fn.exists('*GuiWindowOpacity') == 1 then table.insert(features, "opacity") end
      end

      -- Check for general GUI capabilities
      if vim.fn.has('clipboard') == 1 then table.insert(features, "system-clipboard") end
      if vim.fn.has('mouse') == 1 then table.insert(features, "mouse") end
      if vim.opt.termguicolors:get() then table.insert(features, "true-color") end

      if #features > 0 then
        table.insert(settings, "  GUI features: " .. table.concat(features, ", "))
      end
    end)

    -- Add GUI environment variables if any are present
    pcall(function()
      local gui_env_vars = {}
      local env_var_names = {"QT_QPA_PLATFORM", "WAYLAND_DISPLAY", "DISPLAY", "NVIM_QT_PATH"}

      for _, var_name in ipairs(env_var_names) do
        local value = os.getenv(var_name)
        if value and value ~= "" then
          table.insert(gui_env_vars, var_name .. "=" .. value)
        end
      end

      if #gui_env_vars > 0 then
        table.insert(settings, "  GUI environment vars: " .. table.concat(gui_env_vars, ", "))
      end
    end)
  end

  return settings
end

-- Helper function to get TreeSitter information for diagnostics
function M.get_treesitter_info()
  local ts_status = {}

  -- Default headers in case of errors
  table.insert(ts_status, "")
  table.insert(ts_status, "TreeSitter:")

  -- Safely try to get TreeSitter parser info
  local ts_ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")

  if not ts_ok then
    table.insert(ts_status, "  Installed: No (or not loaded)")
    table.insert(ts_status, "  Status: Not available - " .. (type(ts_parsers) == "string" and ts_parsers:sub(1, 50) or "Unknown error"))
    return ts_status
  end

  -- Safely get list of installed parsers
  local installed = {}
  local parsers_ok = pcall(function()
    if ts_parsers and type(ts_parsers.available_parsers) == "function" then
      installed = ts_parsers.available_parsers() or {}
    end
  end)

  -- If failed to get parsers, report the error
  if not parsers_ok then
    table.insert(ts_status, "  Installed: Yes, but parser list unavailable")
    table.insert(ts_status, "  Error: Could not retrieve parser list")
    return ts_status
  end

  -- Make sure installed is a table we can work with
  if type(installed) ~= "table" then
    installed = {}
  end

  -- Add basic info
  table.insert(ts_status, "  Installed: Yes")
  table.insert(ts_status, "  Parsers installed: " .. #installed)

  -- Safely check highlighting status
  local highlight_status = "Unknown"
  pcall(function()
    highlight_status = tostring(not vim.g.basic_mode)
  end)
  table.insert(ts_status, "  Highlighting enabled: " .. highlight_status)

  -- Just show a summary of parsers instead of listing them all
  if #installed > 0 then
    -- Get the top 5 most commonly used parsers as examples
    local popular_parsers = {"lua", "vim", "javascript", "typescript", "python", "rust", "c", "cpp"}
    local examples = {}
    local count = 0

    -- Try to find a few popular parsers to show as examples
    pcall(function()
      for _, parser in ipairs(popular_parsers) do
        if count >= 3 then break end -- Show up to 3 examples

        -- Check if this popular parser is installed
        for _, installed_parser in ipairs(installed) do
          if installed_parser == parser then
            table.insert(examples, parser)
            count = count + 1
            break
          end
        end
      end
    end)

    -- If we couldn't find popular parsers, use the first few
    if #examples == 0 and #installed > 0 then
      pcall(function()
        -- Sort for consistency
        table.sort(installed)
        -- Take up to 3 from the front
        for i = 1, math.min(3, #installed) do
          if type(installed[i]) == "string" then
            table.insert(examples, installed[i])
          end
        end
      end)
    end

    -- Add summary info
    table.insert(ts_status, "")
    table.insert(ts_status, "  Parser summary: " .. #installed .. " parsers installed")

    -- Add examples if we found any
    if #examples > 0 then
      table.insert(ts_status, "  Examples: " .. table.concat(examples, ", ") .. ", ...")
    end
  end

  return ts_status
end

-- Helper function to get available commands for diagnostics
function M.get_command_info()
  return {
    "",
    "Available Commands:",
    "  :BasicMode - Switch to basic color mode",
    "  :GUIMode - Switch to GUI mode with lw-rubber and tree-sitter",
    "  :Diagnostics - Display system and terminal diagnostics with color test",
    "  :TSReinstall - Force reinstallation of TreeSitter parsers on next restart",
    "  :ColorAnalyze - Show current color scheme highlight information",
    "  <leader>p - Open GitHub Copilot panel",
    "",
    "Color Test (shows colored blocks):",
  }
end

-- Highlight the Available Commands section
local function highlight_commands_section(buf, lines)
  local ns_id = vim.api.nvim_create_namespace("diagnostics_commands")
  -- Find and highlight just the section header
  for i = 1, #lines do
    if lines[i] == "Available Commands:" then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "Label", i - 1, 0, -1)
      break
    end
  end
  -- Find and highlight the Color Test header
  for i = 1, #lines do
    if lines[i] == "Color Test (shows colored blocks):" then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "Label", i - 1, 0, -1)
      break
    end
  end
end

-- Helper function to generate terminal diagnostics information
function M.get_terminal_diagnostics_info()
  local info = {}

  -- Safely combine all sections with error handling
  local function safe_extend(section_getter)
    pcall(function()
      local section = section_getter()
      if type(section) == "table" then
        vim.list_extend(info, section)
      else
        table.insert(info, "Error: Section returned non-table value")
      end
    end)
  end

  -- Add each section with error handling
  safe_extend(M.get_env_info)
  safe_extend(M.get_nvim_settings)
  safe_extend(M.get_treesitter_info)
  safe_extend(M.get_command_info)

  -- If no info was collected, add a fallback message
  if #info == 0 then
    table.insert(info, "Terminal Diagnostics")
    table.insert(info, "===================")
    table.insert(info, "")
    table.insert(info, "Failed to collect diagnostic information.")
    table.insert(info, "Please check Neovim logs for errors.")
  end

  return info
end

-- Helper function to add color test blocks to the diagnostics buffer
function M.add_color_test_blocks(buf)
  -- Verify the buffer is valid
  if not buf or buf < 1 or not vim.api.nvim_buf_is_valid(buf) then
    vim.notify("Invalid buffer for color test blocks", vim.log.levels.ERROR)
    return
  end

  -- Check if buffer is modifiable
  if not vim.api.nvim_buf_get_option(buf, "modifiable") then
    vim.notify("Buffer is not modifiable for color test blocks", vim.log.levels.ERROR)
    return
  end

  -- Use Neovim's built-in syntax highlighting for a better approach
  -- Create extmarks with different highlight groups

  -- First, create the section headers
  local ok, err = pcall(function()
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "ANSI 16-Color Test:",
      "  Normal FG colors (30-37, 90-97):",
      "  X X X X", -- Using X instead of ■ which may not render properly
      "  X X X X",
      "  X X X X",
      "  X X X X",
      "  Normal BG colors (40-47, 100-107):",
      "  XX XX XX XX XX XX XX XX",
      "  XX XX XX XX XX XX XX XX",
      "",
      "Terminal 256-Color Test (16-255):",
    })
  end)

  if not ok then
    vim.notify("Error adding color test headers: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Get the current line count
  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Create a namespace for our extmarks
  local ns_id = vim.api.nvim_create_namespace("diagnostics_colors")

  -- Add ANSI 16 foreground colors (lines 3-6)
  local ansi_colors = {
    {30, 31, 32, 33}, -- Line 3 - black, red, green, yellow
    {34, 35, 36, 37}, -- Line 4 - blue, magenta, cyan, white
    {90, 91, 92, 93}, -- Line 5 - bright black, bright red, bright green, bright yellow
    {94, 95, 96, 97}  -- Line 6 - bright blue, bright magenta, bright cyan, bright white
  }

  -- Apply foreground colors
  for i, row in ipairs(ansi_colors) do
    local line_num = line_count - 9 + i - 1
    for j, color in ipairs(row) do
      local col_start = 2 + (j-1)*2
      local col_end = col_start + 1

      -- Create a unique highlight group for this color
      local hl_group = "DiagColor" .. color

      -- We need both cterm and gui colors for compatibility with both modes
      -- Map ANSI color to corresponding GUI color
      local gui_colors = {
        [30] = "#000000", [31] = "#CC0000", [32] = "#4E9A06", [33] = "#C4A000",
        [34] = "#3465A4", [35] = "#75507B", [36] = "#06989A", [37] = "#D3D7CF",
        [90] = "#555753", [91] = "#EF2929", [92] = "#8AE234", [93] = "#FCE94F",
        [94] = "#729FCF", [95] = "#AD7FA8", [96] = "#34E2E2", [97] = "#EEEEEC",
      }

      vim.cmd(string.format("highlight %s ctermfg=%d guifg=%s",
            hl_group, color, gui_colors[color] or "#FFFFFF"))

      -- Apply highlight using extmark
      vim.api.nvim_buf_add_highlight(buf, ns_id, hl_group, line_num, col_start, col_end)
    end
  end

  -- Apply background colors on lines 8-9
  local bg_colors_1 = {40, 41, 42, 43, 44, 45, 46, 47} -- Standard colors
  local bg_colors_2 = {100, 101, 102, 103, 104, 105, 106, 107} -- Bright colors

  -- First line of background colors (standard BG colors)
  for j, color in ipairs(bg_colors_1) do
    local col_start = 2 + (j-1)*3
    local col_end = col_start + 2

    -- Create highlight group for background
    local hl_group = "DiagBgColor" .. color

    -- Map terminal background colors to GUI colors
    local gui_bg_colors = {
      [40] = "#000000", [41] = "#CC0000", [42] = "#4E9A06", [43] = "#C4A000",
      [44] = "#3465A4", [45] = "#75507B", [46] = "#06989A", [47] = "#D3D7CF",
      [100] = "#555753", [101] = "#EF2929", [102] = "#8AE234", [103] = "#FCE94F",
      [104] = "#729FCF", [105] = "#AD7FA8", [106] = "#34E2E2", [107] = "#EEEEEC",
    }

    vim.cmd(string.format("highlight %s ctermbg=%d guibg=%s",
          hl_group, color, gui_bg_colors[color] or "#000000"))

    -- Apply highlight using extmark
    vim.api.nvim_buf_add_highlight(buf, ns_id, hl_group, line_count - 4, col_start, col_end)
  end

  -- Second line of background colors (bright BG colors)
  for j, color in ipairs(bg_colors_2) do
    local col_start = 2 + (j-1)*3
    local col_end = col_start + 2

    -- Create highlight group for background
    local hl_group = "DiagBgColor" .. color

    -- Use the same GUI color map as the first set
    local gui_bg_colors = {
      [40] = "#000000", [41] = "#CC0000", [42] = "#4E9A06", [43] = "#C4A000",
      [44] = "#3465A4", [45] = "#75507B", [46] = "#06989A", [47] = "#D3D7CF",
      [100] = "#555753", [101] = "#EF2929", [102] = "#8AE234", [103] = "#FCE94F",
      [104] = "#729FCF", [105] = "#AD7FA8", [106] = "#34E2E2", [107] = "#EEEEEC",
    }

    vim.cmd(string.format("highlight %s ctermbg=%d guibg=%s",
          hl_group, color, gui_bg_colors[color] or "#000000"))

    -- Apply highlight using extmark
    vim.api.nvim_buf_add_highlight(buf, ns_id, hl_group, line_count - 3, col_start, col_end)
  end

  -- Add 256 color palette - use a clearer approach
  -- Create blocks of 16 colors per line with visible characters
  for block = 0, 14 do
    local color_line = "  "
    for _ = 0, 15 do -- Use underscore for unused loop variable
      color_line = color_line .. "XX "
    end
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {color_line})

    -- Get the line we just added
    local line_num = vim.api.nvim_buf_line_count(buf) - 1

    -- Add highlights for this row
    for i = 0, 15 do
      local color_idx = 16 + block * 16 + i
      if color_idx <= 255 then
        local col_start = 2 + i*3
        local col_end = col_start + 2

        -- Create highlight group for the color
        local hl_group = "DiagColor" .. color_idx

        -- Convert 256-color index to GUI color
        -- For simplicity, we'll use a programmatic approach for the 256-color palette
        local gui_color

        -- Generate a hex color for the 256-color palette
        -- Basic 16 ANSI colors (0-15) - handled by special case in code
        -- 216 colors color cube (16-231): indexed by r, g, b with 6 steps each
        -- 24 grayscale colors (232-255): from dark to light
        if color_idx >= 232 then
          -- Grayscale ramp (232-255)
          local gray_val = math.floor(((color_idx - 232) / 23) * 255)
          gui_color = string.format("#%02x%02x%02x", gray_val, gray_val, gray_val)
        else
          -- Color cube (16-231)
          local r = math.floor((color_idx - 16) / 36) * 51
          local g = math.floor(((color_idx - 16) % 36) / 6) * 51
          local b = ((color_idx - 16) % 6) * 51
          gui_color = string.format("#%02x%02x%02x", r, g, b)
        end

        vim.cmd(string.format("highlight %s ctermbg=%d guibg=%s",
              hl_group, color_idx, gui_color))

        -- Apply highlight
        vim.api.nvim_buf_add_highlight(buf, ns_id, hl_group, line_num, col_start, col_end)
      end
    end
  end

  -- Add a separator line
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {""})

  -- Add information about ColorAnalyze command with proper highlighting
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
    "ColorAnalyze Command:",
    "-------------------",
    "Run :ColorAnalyze for a comprehensive color analysis that:",
    "• Compares BasicMode and GUIMode highlighting",
    "• Identifies optimal 256-color mappings for GUI colors",
    "• Shows differences between mode configurations",
    "• Generates highlight commands for perfect matching",
    "",
    "The ColorAnalyze tool will temporarily switch between modes to compare them,",
    "then restore your original mode when finished."
  })

  -- Apply highlighting to the header
  local text_line_count = vim.api.nvim_buf_line_count(buf)
  local text_ns_id = vim.api.nvim_create_namespace("diagnostics_text")
  vim.api.nvim_buf_add_highlight(buf, text_ns_id, "Title", text_line_count - 11, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, text_ns_id, "Special", text_line_count - 10, 0, -1)
end

-- Add GUI/terminal specific recommendations to the diagnostics buffer
function M.add_recommendations(buf)
  local ns_id = vim.api.nvim_create_namespace("diagnostics_recommendations")

  if utils.is_gui_environment() then
    -- GUI environment recommendations - completely rewritten to avoid GUI Mode confusion
    -- First, add the header
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "",
      "Graphical Environment Detected:",
      "------------------------------",
    })
    -- Get current line count after adding header
    local line_count = vim.api.nvim_buf_line_count(buf)
    -- Highlight the header
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", line_count - 3, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", line_count - 2, 0, -1)
    -- Add and highlight each bullet point separately
    -- Bullet point 1
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"• You are running in a graphical environment (nvim-qt, neovide, etc.)"})
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", line_count, 0, 1) -- Highlight bullet
    -- Bullet point 2
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"• Make sure termguicolors is ON"})
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", line_count + 1, 0, 1) -- Highlight bullet
    -- Bullet point 3
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"• This mode offers better color support and visual features"})
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", line_count + 2, 0, 1) -- Highlight bullet
    -- Bullet point 4 with correct command
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"• Use the :GUIMode command for proper settings"})
    local last_line = line_count + 3
    -- Highlight just the bullet point
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", last_line, 0, 1)
  else
    -- Basic mode recommendations
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "",
      "Recommendations for Basic Mode:",
      "------------------------------",
      "1. Use :BasicMode to apply enhanced 256-color mode that works in any modern terminal",
      "2. Make sure termguicolors is OFF in Basic mode for maximum compatibility",
      "3. This config uses the full 256-color palette for vibrant syntax highlighting",
      "4. Consider using iTerm2 or Alacritty for even better color support",
      "5. If using macOS Terminal, go to Preferences > Profiles > [Your Profile] > Advanced",
      "   and ensure 'Report Terminal Type' is set to xterm-256color"
    })

    -- Add highlighting
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", line_count - 8, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", line_count - 7, 0, -1)

    -- Highlight numbers and key terms
    for i = 6, 1, -1 do
      local line_num = line_count - i
      -- Highlight the number
      vim.api.nvim_buf_add_highlight(buf, ns_id, "Number", line_num, 0, 1)

      -- Highlight special terms
      if i == 6 then
        -- Highlight the command name
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Identifier", line_num, 5, 14)
      elseif i == 5 then
        -- Highlight termguicolors
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Type", line_num, 13, 25)
      elseif i == 3 then
        -- Highlight terminal names
        vim.api.nvim_buf_add_highlight(buf, ns_id, "String", line_num, 16, 21)
        vim.api.nvim_buf_add_highlight(buf, ns_id, "String", line_num, 25, 33)
      elseif i == 1 then
        -- Highlight terminal type
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Type", line_num, 18, 33)
      end
    end
  end
end

-- Setup diagnostics command
function M.setup()
  -- Create diagnostic function for terminal settings
  vim.api.nvim_create_user_command("Diagnostics", function()
    -- Error handler for the diagnostics command
    local function handle_diagnostic_error(msg)
      vim.notify("Error in Diagnostics command: " .. msg, vim.log.levels.ERROR)
      -- Try to provide a minimal diagnostic buffer even if there's an error
      pcall(function()
        local err_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(err_buf)
        vim.api.nvim_buf_set_lines(err_buf, 0, -1, false, {
          "Diagnostics Error",
          "================",
          "",
          "Failed to generate complete diagnostics due to an error:",
          msg,
          "",
          "Please check your Neovim configuration or report this issue."
        })
        vim.bo[err_buf].modifiable = false
        vim.bo[err_buf].readonly = true
        vim.bo[err_buf].buftype = "nofile"
      end)
    end

    -- Main diagnostics logic with error handling
    local ok, err = pcall(function()
      -- Create a new buffer to display terminal diagnostic information
      local buf = vim.api.nvim_create_buf(false, true)
      if not buf or buf < 1 then
        error("Failed to create diagnostics buffer")
      end

      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].buftype = "nofile"

      -- Get terminal information
      local lines = M.get_terminal_diagnostics_info()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

      -- Create a namespace for syntax highlighting
      local ns_id = vim.api.nvim_create_namespace("diagnostics_header")

      -- Add highlighting for headers (safely with pcall)
      pcall(function()
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", 0, 0, -1)
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", 1, 0, -1)
      end)

      -- Only highlight section headers and keep the rest plain
      -- This avoids any offset issues with variable/setting names
      pcall(function()
        -- Highlight just the "Environment variables:" header
        for i = 1, #lines do
          if lines[i] == "Environment variables:" then
            vim.api.nvim_buf_add_highlight(buf, ns_id, "Label", i - 1, 0, -1)
            break
          end
        end
      end)

      pcall(function()
        -- Highlight just the "Neovim settings:" header
        for i = 1, #lines do
          if lines[i] == "Neovim settings:" then
            vim.api.nvim_buf_add_highlight(buf, ns_id, "Label", i - 1, 0, -1)
            break
          end
        end
      end)

      -- Highlight the commands section headers
      pcall(function()
        highlight_commands_section(buf, lines)
      end)

      -- Add color test blocks with proper highlighting
      pcall(function()
        M.add_color_test_blocks(buf)
      end)

      -- Add GUI-specific recommendations with highlighting
      pcall(function()
        M.add_recommendations(buf)
      end)

      -- Make the buffer read-only
      vim.bo[buf].modifiable = false
      vim.bo[buf].readonly = true
      vim.bo[buf].filetype = "diagnostics"

      vim.notify("System diagnostics created", vim.log.levels.INFO)
    end)

    -- Handle any errors that occurred
    if not ok and err then
      handle_diagnostic_error(tostring(err))
    end
  end, {})
end

return M