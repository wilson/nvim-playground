------------------------------------------
-- Commands Module
-- Sets up user commands that aren't part of other modules
------------------------------------------

local M = {}

-- Setup ColorAnalyze command
function M.setup_color_analyze()
  vim.api.nvim_create_user_command("ColorAnalyze", function()
    -- Load the color analysis module
    local ok, color_analyze = pcall(require, "config.color_analyze")
    if not ok then
      vim.notify("Color analysis module not found", vim.log.levels.ERROR)
      return
    end
    -- Run the analysis
    local output = color_analyze.run_analysis()
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

-- Setup all commands
function M.setup()
  -- Set up ColorAnalyze command
  M.setup_color_analyze()
end

return M