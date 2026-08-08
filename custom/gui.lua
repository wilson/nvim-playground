local M = {}

function M.apply_gui_mode(theme)
  vim.g.basic_mode = false
  vim.opt.termguicolors = true

  local utils = require("custom.utils")
  if utils.is_gui_environment() then
    local fonts = require("custom.fonts")
    fonts.set_best_font()
  end

  if theme then
    local ok = pcall(vim.cmd, "colorscheme " .. theme)
    if not ok then
      vim.notify("Colorscheme '" .. theme .. "' not found. Colorscheme not applied.", vim.log.levels.WARN)
    end
  end

  if vim.fn.exists(":TSEnable") == 2 then
    pcall(vim.cmd, "TSEnable highlight")
  end

  -- Apply GUI appearance settings
  if vim.fn.exists("*GuiLinespace") == 1 then vim.cmd("GuiLinespace 1") end
  if vim.fn.exists("*GuiPopupmenu") == 1 then vim.cmd("GuiPopupmenu 0") end
  if vim.fn.exists("*GuiTabline") == 1 then vim.cmd("GuiTabline 0") end
  if vim.fn.has("macunix") == 1 and vim.fn.exists("*GuiMacPrefix") == 1 then
    vim.cmd("GuiMacPrefix e")
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "GUIModeApplied" })
end

function M.setup()
  -- Legacy GUI clients might still fire these events later
  vim.api.nvim_create_autocmd("User", {
    pattern = {"GuiLoaded", "GUIEnter"},
    callback = function()
      if vim.g.basic_mode then
        vim.schedule(function()
          pcall(vim.cmd, "GUIMode")
        end)
      end
    end,
    desc = "Enable GUI mode for legacy GUI clients"
  })
end

return M
