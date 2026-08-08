------------------------------------------
-- Commands Module
-- Sets up user commands that aren't part of other modules
------------------------------------------

local M = {}

-- Setup ColorAnalyze command
function M.setup_color_analyze()
  vim.api.nvim_create_user_command("ColorAnalyze", function()
    -- Load the color analysis module
    local color_analyze = _G.require_and_setup("custom.color_analyze", false)
    if not color_analyze then return end
    -- Run the analysis
    local output = color_analyze.run_analysis()

    -- Strip trailing whitespace from all lines globally to prevent error highlights
    for i, line in ipairs(output) do
      output[i] = line:gsub("%s+$", "")
    end

    -- Create buffer and display results
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    vim.api.nvim_win_set_buf(0, buf)
    -- Make buffer read-only and set options for better viewing
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    -- Notify user about next steps
    local msg = "Color analysis complete - try opening different filetypes to see more language highlights"
    vim.notify(msg, vim.log.levels.INFO)
  end, {})
end

-- Setup FontMessages command
function M.setup_font_messages()
  -- Load the fonts module
  local fonts = _G.require_and_setup("custom.fonts", false)
  if not fonts then return end

  -- Create the FontMessages command via the fonts module
  fonts.setup_commands()
end

-- Setup all commands
function M.setup()
  -- Set up ColorAnalyze command
  M.setup_color_analyze()

  -- Set up FontMessages command
  M.setup_font_messages()
end

return M