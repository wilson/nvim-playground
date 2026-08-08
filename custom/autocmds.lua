-----------------------------------------------------------
-- Filetype-specific overrides
-----------------------------------------------------------
local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "make",
    callback = function()
      vim.opt_local.expandtab = false
    end,
    desc = "Ensure hard tabs are used in Makefiles",
  })

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
end

return M
