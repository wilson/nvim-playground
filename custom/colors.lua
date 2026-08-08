local M = {}

-- Easily switch your preferred theme here
M.default_theme = "moonfly"

function M.enable_basic_mode(is_explicit)
  if is_explicit then vim.g.explicit_mode_change = true end

  local terminal = require("custom.terminal")
  terminal.apply_basic_mode(M.default_theme)

  if is_explicit then
    if vim.v.vim_did_enter == 1 then
      vim.notify("Basic color mode applied", vim.log.levels.INFO)
    end
    vim.g.explicit_mode_change = nil
  end
end

function M.enable_gui_mode(is_explicit)
  if is_explicit then vim.g.explicit_mode_change = true end

  local gui = require("custom.gui")
  gui.apply_gui_mode(M.default_theme)

  if is_explicit then
    if vim.v.vim_did_enter == 1 then
      vim.notify("Switched to GUI mode with tree-sitter highlights", vim.log.levels.INFO)
    end
    vim.g.explicit_mode_change = nil
  end
end

function M.setup()
  -- Initialize defaults
  vim.opt.termguicolors = false
  vim.opt.background = "dark"
  vim.g.basic_mode = true

  -- Explicitly apply the basic mode syntax to ensure it's active
  local terminal = require("custom.terminal")
  pcall(function() terminal.apply_basic_mode() end)

  -- Enforce high contrast for visible whitespace characters
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      vim.api.nvim_set_hl(0, "Whitespace", { fg = "#ff0055", bold = true })
      vim.api.nvim_set_hl(0, "NonText", { fg = "#ff0055", bold = true })
      vim.api.nvim_set_hl(0, "SpecialKey", { fg = "#ff0055", bold = true })
    end,
    desc = "Apply high contrast to whitespace characters",
  })

  -- Setup Commands
  vim.api.nvim_create_user_command("BasicMode", function()
    M.enable_basic_mode(true)
  end, {})

  vim.api.nvim_create_user_command("GUIMode", function()
    M.enable_gui_mode(true)
  end, {})

  -- Auto-detect GUI environment at startup
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if vim.g.explicit_mode_change or vim.g._init_colors_done then return end

      local utils = require("custom.utils")
      local in_gui = utils.is_gui_environment()
      local is_apple = utils.is_apple_terminal()

      if (in_gui or not is_apple) and vim.g.basic_mode then
        local old_notify = vim.notify
        vim.notify = function() end
        pcall(function() M.enable_gui_mode(false) end)
        vim.notify = old_notify
      else
        -- If staying in Basic mode, ensure the theme is applied now that plugins are loaded
        if vim.g.basic_mode then
          local terminal = require("custom.terminal")
          pcall(function() terminal.apply_basic_mode(M.default_theme) end)
        end
      end
      vim.g._init_colors_done = true
    end,
    desc = "Auto-detect GUI environment at startup",
  })

  -- Load GUI specific events (for legacy GUI wrappers that load late)
  require("custom.gui").setup()
end

return M
