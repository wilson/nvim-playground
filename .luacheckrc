-- Strict Lua linter configuration for Neovim config
std = "lua51"  -- Include Lua 5.1 standard library

-- Apply strict checks
unused = true
unused_args = true
unused_secondaries = true
redefined = true
unreachable = true

-- Other strict settings
self = false           -- Check for unused self
allow_defined = false  -- Disallow defining globals
allow_defined_top = false -- Disallow defining globals in top level

-- Max complexity setting
max_cyclomatic_complexity = 10

-- Other performance metrics
max_line_length = 120  -- Standard line length
max_string_line_length = 120
max_comment_line_length = 120
max_code_line_length = 120

-- We don't want to ignore any warnings, but we'll add this for extensibility
ignore = {}

-- Neovim API and related globals
globals = {
  "vim",
  "_G"
}
