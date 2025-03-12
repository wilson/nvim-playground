-- Lua linter configuration
std = {
  globals = {"vim"},
  read_globals = {
    "vim",
    -- Lua standard library
    "pcall", "pairs", "ipairs", "require",
    "string", "table", "math", "os", "io", "coroutine",
    "debug", "assert", "error", "print", "tonumber", "tostring",
    "type", "select", "next", "unpack", "rawget", "rawset", "rawequal",
    "setmetatable", "getmetatable", "collectgarbage", "dofile", "loadfile"
  }
}
-- Increase line length limit
max_line_length = 120
-- Ignore unused self parameter in methods
self = false
-- Ignore whitespace warnings
ignore = {"611", "612", "613", "614"}
-- Be more lenient with line length in comments
max_comment_line_length = 160
