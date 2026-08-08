local M = {}

function M.setup()
  -- Global diagnostic keymaps
  vim.keymap.set('n', '<leader>w', vim.diagnostic.open_float, { noremap = true, silent = true, desc = "Show diagnostics float" })
  vim.keymap.set('n', '<leader>W', vim.diagnostic.setloclist, { noremap = true, silent = true, desc = "Show diagnostics list" })
end

function M.setup_lsp(bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
end

return M
