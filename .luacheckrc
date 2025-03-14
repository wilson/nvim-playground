-- Neovim Lua linting configuration

-- Using LuaJIT specification
std = "luajit"

-- Global settings
unused = true                -- Report unused variables
unused_args = true           -- Report unused function arguments
unused_secondaries = true    -- Report unused loop variables
redefined = true             -- Report redefined variables in same scope
self = true                  -- Warn when self is used outside methods

-- Line length constraints
max_line_length = false      -- Don't enforce max line length (let formatter handle this)
max_code_line_length = 120   -- But do warn on extremely long code lines
max_string_line_length = 180 -- Allow longer strings
max_comment_line_length = 120 -- Keep comments reasonably sized

-- Function complexity
max_cyclomatic_complexity = 15  -- Allow for moderately complex functions

-- Neovim globals
globals = {
  "vim",
}

-- Warnings to ignore
ignore = {
  "631",  -- Line too long - let formatter handle this
}

-- File-specific settings
files["**/color_analyze.lua"] = {
  max_cyclomatic_complexity = 20,  -- Color analysis is inherently complex
}

files["**/diagnostics.lua"] = {
  max_cyclomatic_complexity = 55,  -- Diagnostics has very complex formatting logic for UI visualization
  -- This file has a single large function that creates a nicely formatted diagnostic buffer
  -- Refactoring it completely would be a larger task than we want to undertake now
}

-- Skip external files
exclude_files = {
  "lazy/*",
  "mason/*",
}
