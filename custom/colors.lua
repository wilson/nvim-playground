-----------------------------------------------------------
-- Color scheme configuration
-----------------------------------------------------------
local M = {
  default_theme = "moonfly"
}

function M.enable_terminal_mode(is_explicit)
  if is_explicit then vim.g.explicit_mode_change = true end

  local terminal = _G.require_and_setup("custom.terminal", false)
  if terminal then
    terminal.apply_terminal_mode(M.default_theme)
  end

  if is_explicit then
    if vim.v.vim_did_enter == 1 then
      vim.notify("Terminal color mode applied", vim.log.levels.INFO)
    end
    vim.g.explicit_mode_change = nil
  end
end

function M.enable_gui_mode(is_explicit)
  if is_explicit then vim.g.explicit_mode_change = true end

  local gui = _G.require_and_setup("custom.gui", false)
  if gui then
    gui.apply_gui_mode(M.default_theme)
  end

  if is_explicit then
    if vim.v.vim_did_enter == 1 then
      vim.notify("Switched to GUI mode with tree-sitter highlights", vim.log.levels.INFO)
    end
    vim.g.explicit_mode_change = nil
  end
end

function M.setup()
  vim.opt.termguicolors = false
  vim.opt.background = "dark"

  -- Setup Commands
  vim.api.nvim_create_user_command("TerminalMode", function()
    M.enable_terminal_mode(true)
  end, {})

  vim.api.nvim_create_user_command("GUIMode", function()
    M.enable_gui_mode(true)
  end, {})

  -- Auto-detect UI environment at startup
  vim.api.nvim_create_autocmd("UIEnter", {
    callback = function()
      if vim.g.explicit_mode_change or vim.g._init_colors_done then return end

      local utils = _G.require_and_setup("custom.utils", false)
      if not utils then return end

      local in_gui = utils.is_gui_environment()
      local is_apple = utils.is_apple_terminal()

      if in_gui or not is_apple then
        pcall(function() M.enable_gui_mode(false) end)
      else
        pcall(function() M.enable_terminal_mode(false) end)
      end
      vim.g._init_colors_done = true
    end,
    desc = "Auto-detect UI environment at startup",
  })

  -- Load GUI specific events (for legacy GUI wrappers that load late)
  _G.require_and_setup("custom.gui")
end

return M
