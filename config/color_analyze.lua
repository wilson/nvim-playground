-- Color analysis module for comparing highlight groups between different modes
-- This module is used by the ColorAnalyze command

local M = {}

-- List of highlight groups to analyze
M.highlight_groups = {
  -- Basic syntax highlighting groups
  "Normal", "Comment", "Constant", "String", "Character", "Number", "Boolean",
  "Float", "Identifier", "Function", "Statement", "Conditional", "Repeat",
  "Label", "Operator", "Keyword", "Exception", "PreProc", "Include", "Define",
  "Macro", "PreCondit", "Type", "StorageClass", "Structure", "Typedef",
  "Special", "SpecialChar", "Tag", "Delimiter", "SpecialComment", "Debug",
  "Underlined", "Error", "Todo",

  -- UI elements
  "Directory", "Search", "MatchParen", "Visual", "LineNr", "CursorLine",
  "StatusLine", "StatusLineNC", "Pmenu", "PmenuSel", "SignColumn", "VertSplit",

  -- Added specific highlight groups for programming languages
  -- Lua
  "luaFunction", "luaTable", "luaIn", "luaStatement", "luaFuncCall", "luaSpecial",
  -- Python
  "pythonFunction", "pythonStatement", "pythonBuiltin", "pythonDecorator",
  -- JavaScript/TypeScript
  "jsFunction", "jsGlobalObjects", "jsOperator", "jsThis",
  "tsxTag", "tsxAttrib",
  -- Ruby
  "rubyClass", "rubyDefine", "rubySymbol", "rubyInstanceVariable",
  -- Markup
  "markdownH1", "markdownLink", "htmlTag", "cssClassName"
}

-- Get highlight information with format for Neovim version
function M.get_hl_format(group_name)
  local hl, ctermfg, ctermbg, cterm, gui

  -- Get highlight attributes based on Neovim version (API changed in 0.9)
  if vim.fn.has('nvim-0.9') == 1 then
    -- For Neovim 0.9+
    hl = vim.api.nvim_get_hl(0, {name = group_name})

    -- Try to get terminal color codes
    local hl_str = vim.api.nvim_exec2("highlight " .. group_name, {output = true}).output
    ctermfg = hl_str:match("ctermfg=(%S+)")
    ctermbg = hl_str:match("ctermbg=(%S+)")
    cterm = hl_str:match("cterm=(%S+)")
    gui = hl_str:match("gui=(%S+)")
  else
    -- For older Neovim versions
    hl = vim.api.nvim_get_hl_by_name(group_name, true)
    -- Use vim.cmd to get ANSI codes
    local hl_str = vim.fn.execute("highlight " .. group_name)
    ctermfg = hl_str:match("ctermfg=(%S+)")
    ctermbg = hl_str:match("ctermbg=(%S+)")
    cterm = hl_str:match("cterm=(%S+)")
    gui = hl_str:match("gui=(%S+)")
  end

  -- Format colors as hex
  local fg = hl.fg and string.format("#%06x", hl.fg) or "none"
  local bg = hl.bg and string.format("#%06x", hl.bg) or "none"

  -- Build attribute list
  local attrs = {}
  if hl.bold then table.insert(attrs, "bold") end
  if hl.italic then table.insert(attrs, "italic") end
  if hl.underline then table.insert(attrs, "underline") end
  local attr_str = #attrs > 0 and table.concat(attrs, ",") or gui or cterm or "none"

  return {
    name = group_name,
    fg = fg,
    bg = bg,
    ctermfg = ctermfg or "none",
    ctermbg = ctermbg or "none",
    cterm = cterm or "none",
    gui = gui or "none",
    attr_str = attr_str
  }
end

-- Helper function to convert RGB hex to nearest 256-color code
function M.hex_to_256(hex)
  if hex == "none" or not hex then return "none" end

  -- Parse hex string to RGB
  local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
  if not r then return "none" end

  r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)

  -- Standard 6x6x6 color cube starts at index 16
  -- Each component has 6 possible values: 0, 95, 135, 175, 215, 255
  local function get_cube_index(comp)
    local values = {0, 95, 135, 175, 215, 255}
    local closest_val = values[1]
    local min_diff = math.abs(comp - closest_val)

    for i = 2, 6 do
      local diff = math.abs(comp - values[i])
      if diff < min_diff then
        min_diff = diff
        closest_val = values[i]
      end
    end

    -- Find index (0-5)
    for i = 1, 6 do
      if values[i] == closest_val then
        return i - 1
      end
    end
    return 0
  end

  -- Calculate color cube index (16-231)
  local r_idx = get_cube_index(r)
  local g_idx = get_cube_index(g)
  local b_idx = get_cube_index(b)
  local cube_idx = 16 + (36 * r_idx) + (6 * g_idx) + b_idx

  -- Check grayscale ramp (232-255)
  -- Grayscale ranges from 8 to 238 in 24 steps
  local gray = (r + g + b) / 3
  local gray_idx = math.floor((gray - 8) / 10) + 232
  gray_idx = math.max(232, math.min(255, gray_idx))

  -- Choose between color cube and grayscale based on colorfulness
  local std_dev = math.sqrt(((r - gray)^2 + (g - gray)^2 + (b - gray)^2) / 3)
  if std_dev < 20 then  -- If color is close to grayscale
    return tostring(gray_idx)
  else
    return tostring(cube_idx)
  end
end

-- Function to get known color mappings from our configuration
function M.get_known_mappings()
  -- Extract color definitions from the code
  local known_mappings = {
    -- Base colors from the configuration (from our code analysis)
    ["#abb2bf"] = "249", -- Normal fg
    ["#21252b"] = "235", -- Normal bg
    ["#e06c75"] = "168", -- Comment, Statement (pink/red)
    ["#98c379"] = "108", -- String, Type (green)
    ["#bf79c3"] = "139", -- Number, Boolean, Constant (purple)
    ["#61afef"] = "75", -- Function, Keyword (blue)
    ["#d19a66"] = "173", -- Search, MatchParen (orange)
    ["#737c8c"] = "8",   -- Special (gray)
    ["#df334a"] = "167", -- Error (bright red)
    ["#c678dd"] = "176", -- PreProc (light purple)
    ["#3b4049"] = "237", -- Visual background
    ["#e0e0e0"] = "252", -- Very light gray (Identifier)

    -- Standard ANSI terminal to GUI mappings
    ["#000000"] = "0", -- Black
    ["#CC0000"] = "1", -- Red
    ["#4E9A06"] = "2", -- Green
    ["#C4A000"] = "3", -- Yellow/Brown
    ["#3465A4"] = "4", -- Blue
    ["#75507B"] = "5", -- Magenta
    ["#06989A"] = "6", -- Cyan
    ["#D3D7CF"] = "7", -- White/Light gray
    ["#555753"] = "8", -- Bright black (gray)
    ["#EF2929"] = "9", -- Bright red
    ["#8AE234"] = "10", -- Bright green
    ["#FCE94F"] = "11", -- Bright yellow
    ["#729FCF"] = "12", -- Bright blue
    ["#AD7FA8"] = "13", -- Bright magenta
    ["#34E2E2"] = "14", -- Bright cyan
    ["#EEEEEC"] = "15" -- Bright white
  }

  return known_mappings
end

-- Gather highlights from current mode
function M.capture_current_highlights()
  local results = {}
  for _, group in ipairs(M.highlight_groups) do
    local ok, info = pcall(M.get_hl_format, group)
    if ok and pcall(vim.fn.hlID, group) and vim.fn.hlID(group) > 0 then
      table.insert(results, info)
    end
  end
  return results
end

-- Process results from both modes into a combined structure
function M.combine_mode_results(current_results, current_mode, other_results, other_mode)
  local combined_results = {}
  local seen_groups = {}

  local function process_results(results, mode)
    for _, info in ipairs(results) do
      if not seen_groups[info.name] then
        seen_groups[info.name] = true
        combined_results[info.name] = {}
      end
      combined_results[info.name][mode] = info
    end
  end

  process_results(current_results, current_mode)
  process_results(other_results, other_mode)

  return combined_results
end

-- Create output table with highlight group information
function M.format_highlights_table(combined_results)
  local known_mappings = M.get_known_mappings()
  local output = {}

  -- Column definitions and headers
  local col_width = {
    group = 22,
    gui_fg = 12,
    gui_bg = 12,
    term_fg = 10,
    term_bg = 10,
    suggested = 10,
    attrs = 15
  }

  -- Add table header
  table.insert(output, string.format(
    "%-" .. col_width.group .. "s" ..
    "%-" .. col_width.gui_fg .. "s" ..
    "%-" .. col_width.gui_bg .. "s" ..
    "%-" .. col_width.term_fg .. "s" ..
    "%-" .. col_width.term_bg .. "s" ..
    "%-" .. col_width.suggested .. "s" ..
    "%-" .. col_width.attrs .. "s",
    "Group", "GUI FG", "GUI BG", "Term FG", "Term BG", "Suggested", "Attributes"
  ))

  table.insert(output, string.rep("-", 95))

  -- Sort groups for consistent output
  local sorted_groups = {}
  for group, _ in pairs(combined_results) do
    table.insert(sorted_groups, group)
  end
  table.sort(sorted_groups)

  -- Add data rows
  for _, group in ipairs(sorted_groups) do
    local gui_info = combined_results[group].GUIMode
    local term_info = combined_results[group].BasicMode

    if gui_info then  -- Only show groups that exist in GUIMode
      -- Get current values
      local gui_fg = gui_info.fg or "none"
      local gui_bg = gui_info.bg or "none"
      local term_fg = term_info and term_info.ctermfg or "none"
      local term_bg = term_info and term_info.ctermbg or "none"

      -- Calculate suggested cterm foreground color from GUI color
      local suggested_fg = term_fg

      -- Use known mappings if available, otherwise calculate
      if gui_fg ~= "none" and known_mappings[gui_fg] then
        suggested_fg = known_mappings[gui_fg]
      elseif gui_fg ~= "none" then
        suggested_fg = M.hex_to_256(gui_fg)
      end

      -- Format the suggested column
      local suggested = ""
      if suggested_fg ~= term_fg then
        suggested = suggested_fg
      end

      -- Include gui/cterm attribute differences
      local attrs = gui_info.attr_str or "none"
      if term_info and term_info.attr_str ~= attrs then
        attrs = term_info.attr_str .. " ≠ " .. attrs
      end

      -- Add the row
      table.insert(output, string.format(
        "%-" .. col_width.group .. "s" ..
        "%-" .. col_width.gui_fg .. "s" ..
        "%-" .. col_width.gui_bg .. "s" ..
        "%-" .. col_width.term_fg .. "s" ..
        "%-" .. col_width.term_bg .. "s" ..
        "%-" .. col_width.suggested .. "s" ..
        "%-" .. col_width.attrs .. "s",
        group, gui_fg, gui_bg, term_fg, term_bg, suggested, attrs
      ))
    end
  end

  return output
end

-- Format mapping table for output
function M.format_mapping_table()
  local output = {}
  local known_mappings = M.get_known_mappings()

  table.insert(output, "")
  table.insert(output, "GUI to Terminal Color Mappings:")
  table.insert(output, "============================")

  -- Sort mappings by GUI color
  local mappings = {}
  for hex, term in pairs(known_mappings) do
    table.insert(mappings, {hex = hex, term = term})
  end
  table.sort(mappings, function(a, b) return a.hex < b.hex end)

  -- Output mappings in columns
  local map_width = 25
  local maps_per_row = 3
  for i = 1, #mappings, maps_per_row do
    local row = ""
    for j = 0, maps_per_row-1 do
      if mappings[i+j] then
        local map = mappings[i+j]
        row = row .. string.format("%-" .. map_width .. "s", map.hex .. " → " .. map.term)
      end
    end
    table.insert(output, row)
  end

  return output
end

-- Generate highlight commands for BasicMode
function M.generate_highlight_commands(combined_results)
  local output = {}
  local known_mappings = M.get_known_mappings()

  table.insert(output, "")
  table.insert(output, "Vim Highlight Commands for BasicMode:")
  table.insert(output, "===================================")
  table.insert(output, "Use these commands in your BasicMode configuration:")
  table.insert(output, "")

  -- Key highlight groups
  local key_groups = {
    "Normal", "Comment", "String", "Number", "Boolean", "Float", "Constant",
    "Function", "Keyword", "Type", "Statement", "Conditional", "Repeat",
    "Operator", "PreProc", "Special", "Identifier", "Todo", "Error",
    "Search", "MatchParen", "Visual", "Directory"
  }

  for _, group in ipairs(key_groups) do
    if combined_results[group] and combined_results[group].GUIMode then
      local gui = combined_results[group].GUIMode
      local term = combined_results[group].BasicMode

      -- Calculate best terminal colors
      local best_fg = term and term.ctermfg or "none"

      -- Use known mappings if available, otherwise calculate
      if gui.fg ~= "none" and known_mappings[gui.fg] then
        best_fg = known_mappings[gui.fg]
      elseif gui.fg ~= "none" then
        best_fg = M.hex_to_256(gui.fg)
      end

      -- Build command
      local cmd = "hi " .. group
      if best_fg ~= "none" then cmd = cmd .. " ctermfg=" .. best_fg end
      if gui.attr_str ~= "none" then cmd = cmd .. " cterm=" .. gui.attr_str end

      -- Only add if we have meaningful attributes
      if cmd ~= "hi " .. group then
        table.insert(output, cmd)
      end
    end
  end

  return output
end

-- Main function to run color analysis
function M.run_analysis()
  -- Get current mode state
  local current_mode = vim.g.terminal_app_mode and "BasicMode" or "GUIMode"
  local current_colorscheme = vim.g.colors_name or "default"

  -- Store the current state to restore after analysis
  local starting_mode = vim.g.terminal_app_mode

  -- First, capture current state
  local current_results = M.capture_current_highlights()

  -- Then switch modes to capture the other state
  if vim.g.terminal_app_mode then
    -- Currently in BasicMode, switch to GUIMode
    vim.cmd("GUIMode")
  else
    -- Currently in GUIMode, switch to BasicMode
    vim.cmd("BasicMode")
  end

  -- Wait for highlighting to apply
  vim.cmd("redraw!")
  vim.cmd("sleep 200m") -- Longer sleep to ensure highlighting is fully applied

  -- Get the other mode's results
  local other_mode = vim.g.terminal_app_mode and "BasicMode" or "GUIMode"
  local other_results = M.capture_current_highlights()

  -- Restore original mode
  if starting_mode then
    vim.cmd("BasicMode")
  else
    vim.cmd("GUIMode")
  end

  -- Wait for highlighting to restore
  vim.cmd("redraw!")
  vim.cmd("sleep 200m")

  -- Combine results
  local combined_results = M.combine_mode_results(
    current_results, current_mode, other_results, other_mode
  )

  -- Build output
  local output = {
    "Color Scheme Analysis - " .. current_colorscheme,
    "============================================",
    "",
    "This analysis compares highlight groups between BasicMode and GUIMode",
    "Both modes use the " .. current_colorscheme .. " colorscheme with different settings.",
    ""
  }

  -- Add highlight comparison table
  local highlights_table = M.format_highlights_table(combined_results)
  for _, line in ipairs(highlights_table) do
    table.insert(output, line)
  end

  -- Add terminal color reference
  table.insert(output, "")
  table.insert(output, "Terminal Color Reference:")
  table.insert(output, "========================")
  table.insert(output, "0-7:   Standard ANSI colors (black, red, green, yellow, blue, magenta, cyan, white)")
  table.insert(output, "8-15:  Bright ANSI colors (bright versions of the above)")
  table.insert(output, "16-231: 6×6×6 color cube (216 colors)")
  table.insert(output, "232-255: Grayscale from dark to light (24 steps)")

  -- Add mapping table
  local mapping_table = M.format_mapping_table()
  for _, line in ipairs(mapping_table) do
    table.insert(output, line)
  end

  -- Add highlight commands
  local commands = M.generate_highlight_commands(combined_results)
  for _, line in ipairs(commands) do
    table.insert(output, line)
  end

  return output
end

return M