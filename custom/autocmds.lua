local M = {}

function M.setup()
  -- Filetype specific overrides
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "make",
    callback = function()
      vim.opt_local.expandtab = false
    end,
    desc = "Ensure hard tabs are used in Makefiles",
  })
end

return M
