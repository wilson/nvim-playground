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

-- Extract highlight attributes from highlight command output
local function extract_hl_attributes(hl_str)
  local ctermfg = hl_str:match("ctermfg=(%S+)")
  local ctermbg = hl_str:match("ctermbg=(%S+)")
  local cterm = hl_str:match("cterm=(%S+)")
  local gui = hl_str:match("gui=(%S+)")
  return ctermfg, ctermbg, cterm, gui
end

-- Format colors to hex format
local function format_colors(hl)
  local fg = "none"
  local bg = "none"

  if hl.fg and type(hl.fg) == "number" then
    fg = string.format("#%06x", hl.fg)
  end

  if hl.bg and type(hl.bg) == "number" then
    bg = string.format("#%06x", hl.bg)
  end
  return fg, bg
end

-- Get highlight information with format
function M.get_hl_format(group_name)
  local ctermfg, ctermbg, cterm, gui

  -- Safely get highlight attributes
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, {name = group_name})
  if not ok or not hl then
    hl = {}
  end

  -- Safely get terminal color codes
  local cmd_ok, result = pcall(vim.api.nvim_exec2, "highlight " .. group_name, {output = true})
  if cmd_ok and result and result.output then
    ctermfg, ctermbg, cterm, gui = extract_hl_attributes(result.output)
  end

  -- Format colors as hex
  local fg, bg = format_colors(hl)

  -- Build attribute list safely
  local attrs = {}
  if hl.bold == true then table.insert(attrs, "bold") end
  if hl.italic == true then table.insert(attrs, "italic") end
  if hl.underline == true then table.insert(attrs, "underline") end
  local attr_str = #attrs > 0 and table.concat(attrs, ",") or gui or cterm or "none"

  -- Return a safe result with no functions or complex objects
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

  -- Convert hex to decimal
  local r_dec = tonumber(r, 16) or 0
  local g_dec = tonumber(g, 16) or 0
  local b_dec = tonumber(b, 16) or 0

  -- Define the cube values statically to avoid creating functions during LSP operations
  local values = {0, 95, 135, 175, 215, 255}

  -- Find closest cube value without using a nested function
  local function find_closest_value(comp)
    -- Initialize with first value
    local min_diff = math.abs(comp - values[1])
    local closest_idx = 0

    -- Check remaining values
    for i = 2, 6 do
      local diff = math.abs(comp - values[i])
      if diff < min_diff then
        min_diff = diff
        closest_idx = i - 1
      end
    end

    return closest_idx
  end
  -- Get indices
  local r_idx = find_closest_value(r_dec)
  local g_idx = find_closest_value(g_dec)
  local b_idx = find_closest_value(b_dec)

  -- Calculate color cube index (16-231)
  local cube_idx = 16 + (36 * r_idx) + (6 * g_idx) + b_idx

  -- Calculate grayscale
  local gray = (r_dec + g_dec + b_dec) / 3
  local gray_idx = math.floor((gray - 8) / 10) + 232
  gray_idx = math.max(232, math.min(255, gray_idx))

  -- Choose between color cube and grayscale based on standard deviation
  local std_dev = math.sqrt(((r_dec - gray)^2 + (g_dec - gray)^2 + (b_dec - gray)^2) / 3)

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
    -- Base colors from the configuration
    ["#abb2bf"] = "249", -- Normal fg
    ["#21252b"] = "235", -- Normal bg
    ["#e06c75"] = "168", -- Statement (pink/red)
    ["#98c379"] = "108", -- String (green)
    ["#bf79c3"] = "139", -- Number, Boolean (purple)
    ["#61afef"] = "75",  -- Function (blue)
    ["#d19a66"] = "173", -- Search (orange)
    ["#df334a"] = "167", -- Error (bright red)
    ["#c678dd"] = "176", -- PreProc (light purple)
    ["#3b4049"] = "237", -- Visual background
    ["#e0e0e0"] = "252", -- Light gray (Identifier)

    -- ANSI terminal to GUI mappings
    ["#000000"] = "0",   -- Black
    ["#CC0000"] = "1",   -- Red
    ["#4E9A06"] = "2",   -- Green
    ["#C4A000"] = "3",   -- Yellow
    ["#3465A4"] = "4",   -- Blue
    ["#75507B"] = "5",   -- Magenta
    ["#06989A"] = "6",   -- Cyan
    ["#D3D7CF"] = "7",   -- White/Light gray
    ["#555753"] = "8",   -- Gray
    ["#EF2929"] = "9",   -- Bright red
    ["#8AE234"] = "10",  -- Bright green
    ["#FCE94F"] = "11",  -- Bright yellow
    ["#729FCF"] = "12",  -- Bright blue
    ["#AD7FA8"] = "13",  -- Bright magenta
    ["#34E2E2"] = "14",  -- Bright cyan
    ["#EEEEEC"] = "15"   -- Bright white
  }

  return known_mappings
end

-- Gather highlights from current mode
function M.capture_current_highlights()
  local results = {}
  for _, group in ipairs(M.highlight_groups) do
    -- Check if the highlight group exists first
    if vim.fn.hlID(group) > 0 then
      local ok, info = pcall(M.get_hl_format, group)
      if ok then
        table.insert(results, info)
      end
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
  local current_mode = vim.g.basic_mode and "BasicMode" or "GUIMode"
  local current_colorscheme = vim.g.colors_name or "default"

  -- Store the current state to restore after analysis
  local starting_mode = vim.g.basic_mode

  -- First, capture current state
  local current_results = M.capture_current_highlights()

  -- Create placeholder for other mode results
  local other_mode = starting_mode and "GUIMode" or "BasicMode"
  local other_results = {}

  -- Safely try to switch modes and capture other state
  local switch_ok, _ = pcall(function()
    -- Switch modes
    if vim.g.basic_mode then
      -- Currently in BasicMode, switch to GUIMode
      vim.cmd("GUIMode")
    else
      -- Currently in GUIMode, switch to BasicMode
      vim.cmd("BasicMode")
    end

    -- Wait for highlighting to apply
    vim.cmd("redraw!")
    vim.cmd("sleep 200m") -- Ensure highlighting is fully applied

    -- Capture the other mode's results
    other_results = M.capture_current_highlights()

    -- Restore original mode
    if starting_mode then
      vim.cmd("BasicMode")
    else
      vim.cmd("GUIMode")
    end
    vim.cmd("redraw!")
  end)

  if not switch_ok then
    vim.notify("Error switching color modes. Analysis will be limited.", vim.log.levels.WARN)
  end

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