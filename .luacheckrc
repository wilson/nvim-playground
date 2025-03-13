-- Luacheck configuration file for Neovim configuration

-- Allow globals defined by Neovim
globals = {
  "vim",
  "table"
}

-- Ignore some warnings
ignore = {
  "212", -- Unused argument (often used in callbacks)
  "213", -- Unused loop variable
}

-- File-specific configuration
files["config/color_analyze.lua"] = {
  -- Ignore cyclomatic complexity in color_analyze.lua
  ignore = {"631"}  -- Ignore warning about line being too complex
}

-- Quiet mode
quiet = 1

-- Set max line length
max_line_length = 120

-- Misc options
cache = true
self = false
codes = true
