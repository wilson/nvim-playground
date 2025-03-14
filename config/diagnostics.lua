------------------------------------------
-- Diagnostics Module
-- Functionality for system diagnostics and environment information
------------------------------------------

local M = {}

-- Get the utility functions
local utils = require("config.utils")

-- Helper function to get environment information for diagnostics
function M.get_env_info()
  return {
    "Terminal Diagnostics",
    "===================",
    "",
    "Environment variables:",
    "  TERM: " .. (vim.env.TERM or "not set"),
    "  COLORTERM: " .. (vim.env.COLORTERM or "not set"),
    "  TERM_PROGRAM: " .. (vim.env.TERM_PROGRAM or "not set"),
  }
end

-- Helper function to get Neovim settings for diagnostics
function M.get_nvim_settings()
  local gui_status = utils.is_gui_environment() and "Yes" or "No"

  return {
    "",
    "Neovim settings:",
    "  termguicolors: " .. tostring(vim.opt.termguicolors:get()),
    "  GUI environment: " .. gui_status,
    "  Basic mode: " .. tostring(vim.g.basic_mode or "Not set"),
    "  Vim version: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
  }
end

-- Helper function to get TreeSitter information for diagnostics
function M.get_treesitter_info()
  local ts_ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")
  local ts_status = {}

  if not ts_ok then
    return {
      "",
      "TreeSitter: Not installed or not available",
    }
  end

  -- Get list of installed parsers
  local installed = {}
  pcall(function()
    installed = ts_parsers.available_parsers()
  end)

  table.insert(ts_status, "")
  table.insert(ts_status, "TreeSitter:")
  table.insert(ts_status, "  Installed: Yes")
  table.insert(ts_status, "  Parsers installed: " .. #installed)
  table.insert(ts_status, "  Highlighting enabled: " .. tostring(not vim.g.basic_mode))

  if #installed > 0 then
    table.insert(ts_status, "")
    table.insert(ts_status, "  Installed parsers:")
    table.sort(installed) -- Sort parsers alphabetically

    -- Create a formatted list of parsers (5 per line)
    local line = "    "
    for i, parser in ipairs(installed) do
      line = line .. parser
      if i < #installed then
        line = line .. ", "
      end

      -- Start a new line every 5 parsers
      if i % 5 == 0 and i < #installed then
        table.insert(ts_status, line)
        line = "    "
      end
    end

    -- Add the last line if not empty
    if line ~= "    " then
      table.insert(ts_status, line)
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

-- Helper function to generate terminal diagnostics information
function M.get_terminal_diagnostics_info()
  local info = {}

  -- Combine all sections
  vim.list_extend(info, M.get_env_info())
  vim.list_extend(info, M.get_nvim_settings())
  vim.list_extend(info, M.get_treesitter_info())
  vim.list_extend(info, M.get_command_info())

  return info
end

-- Helper function to add color test blocks to the diagnostics buffer
function M.add_color_test_blocks(buf)
  -- Use Neovim's built-in syntax highlighting for a better approach
  -- Create extmarks with different highlight groups

  -- First, create the section headers
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
    "ANSI 16-Color Test:",
    "  Normal FG colors (30-37, 90-97):",
    "  ■ ■ ■ ■",
    "  ■ ■ ■ ■",
    "  ■ ■ ■ ■",
    "  ■ ■ ■ ■",
    "  Normal BG colors (40-47, 100-107):",
    "                ",
    "                ",
    "",
    "Terminal 256-Color Test (16-255):",
  })

  -- Get the current line count
  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Create a namespace for our extmarks
  local ns_id = vim.api.nvim_create_namespace("diagnostics_colors")

  -- Add ANSI 16 foreground colors (lines 3-6)
  local ansi_colors = {
    {30, 31, 32, 33}, -- Line 3
    {34, 35, 36, 37}, -- Line 4
    {90, 91, 92, 93}, -- Line 5
    {94, 95, 96, 97}  -- Line 6
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
  local bg_colors_1 = {40, 41, 42, 43, 44, 45, 46, 47}
  local bg_colors_2 = {100, 101, 102, 103, 104, 105, 106, 107}

  -- First line of background colors
  for j, color in ipairs(bg_colors_1) do
    local col_start = 2 + (j-1)*2
    local col_end = col_start + 1

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

  -- Second line of background colors
  for j, color in ipairs(bg_colors_2) do
    local col_start = 2 + (j-1)*2
    local col_end = col_start + 1

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

  -- Add 256 color palette
  -- Create blocks of 16 colors per line
  for block = 0, 14 do
    local color_line = "  "
    for i = 0, 15 do
      color_line = color_line .. "  "
    end
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {color_line})

    -- Get the line we just added
    local line_num = vim.api.nvim_buf_line_count(buf) - 1

    -- Add highlights for this row
    for i = 0, 15 do
      local color_idx = 16 + block * 16 + i
      if color_idx <= 255 then
        local col_start = 2 + i*2
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
    -- GUI environment recommendations
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      "",
      "GUI Environment Detected:",
      "------------------------",
      "• You are running in a GUI environment (nvim-qt, neovide, etc.)",
      "• Make sure termguicolors is ON (use :GUIMode if needed)",
      "• GUI mode offers better color support and visual features",
      "• Use :GUIMode to ensure proper GUI settings"
    })

    -- Add highlighting
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", line_count - 7, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", line_count - 6, 0, -1)

    -- Highlight the bullet points
    for i = 5, 2, -1 do
      local line_num = line_count - i
      -- Highlight the bullet
      vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", line_num, 0, 1)
      -- Highlight the command name
      if i == 5 or i == 2 then
        local cmd_start = line_num == line_count - 5 and 35 or 5
        local cmd_end = line_num == line_count - 5 and 45 or 13
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Identifier", line_num, cmd_start, cmd_end)
      end
    end
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
    -- Create a new buffer to display terminal diagnostic information
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].buftype = "nofile"

    -- Get terminal information
    local lines = M.get_terminal_diagnostics_info()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Create a namespace for syntax highlighting
    local ns_id = vim.api.nvim_create_namespace("diagnostics_header")

    -- Add highlighting for headers
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Special", 1, 0, -1)

    -- Highlight environment information
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Label", 3, 0, -1)

    -- Highlight terminal information
    local env_vars_start = 5
    for i = 0, 2 do
      -- Highlight the variable name
      vim.api.nvim_buf_add_highlight(buf, ns_id, "Identifier", env_vars_start + i, 2, 15)
    end

    -- Find the Neovim settings section
    local neovim_settings_idx = nil
    for i = 1, #lines do
      if lines[i] == "Neovim settings:" then
        neovim_settings_idx = i - 1
        break
      end
    end

    if neovim_settings_idx then
      -- Highlight the section header
      vim.api.nvim_buf_add_highlight(buf, ns_id, "Label", neovim_settings_idx, 0, -1)

      -- Highlight setting names
      for i = 1, 4 do
        -- Highlight the setting name
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Identifier", neovim_settings_idx + i, 2, 15)
        -- Highlight values (especially Yes/No for GUI environment)
        if i == 3 then
          -- GUI environment status
          local val = utils.is_gui_environment() and "Yes" or "No"
          local start_col = lines[neovim_settings_idx + i]:find(val, 20)
          if start_col then
            local hl_group = val == "Yes" and "String" or "Comment"
            local col_start = start_col - 1
            local col_end = start_col + #val - 1
            vim.api.nvim_buf_add_highlight(buf, ns_id, hl_group, neovim_settings_idx + i, col_start, col_end)
          end
        end
      end
    end

    -- Add color test blocks with proper highlighting
    M.add_color_test_blocks(buf)

    -- Add GUI-specific recommendations with highlighting
    M.add_recommendations(buf)

    -- Make the buffer read-only
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].filetype = "diagnostics"

    vim.notify("System diagnostics created", vim.log.levels.INFO)
  end, {})
end

return M