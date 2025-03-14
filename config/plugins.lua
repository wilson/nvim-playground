------------------------------------------
-- Plugins Module
-- Handles plugin configuration and setup
------------------------------------------

local M = {}

-- Configure Lazy.nvim and set up plugins
function M.setup(languages_config)
  -- Define plugin specs
  local plugins = {
    -- Color scheme
    {
      "VonHeikemen/little-wonder",
      lazy = false,
      priority = 1000, -- Load before other plugins
      config = function()
        -- Only set colorscheme in GUI mode (not Basic mode)
        if not vim.g.basic_mode then
          vim.opt.termguicolors = true
          -- Make sure the colorscheme is available by checking if the plugin path exists
          local plugin_path = vim.fn.expand("~/.local/share/nvim/lazy/little-wonder")
          if vim.fn.isdirectory(plugin_path) == 1 then
            pcall(vim.cmd, "colorscheme lw-rubber")
          else
            vim.notify("little-wonder plugin not found. Colorscheme not applied.", vim.log.levels.WARN)
          end
          -- Force apply GUI mode settings
          vim.api.nvim_exec_autocmds("User", { pattern = "GUIModeApplied" })
        end
      end,
    },

    -- GitHub Copilot
    {
      "github/copilot.vim",
      lazy = false, -- Load immediately to ensure it's properly recognized
    },

    -- LSP Configuration
    {
      "neovim/nvim-lspconfig",
      config = function()
        -- Set up LSP keymaps and configurations
        local lspconfig = require("lspconfig")

        -- Configure Mason integration if available
        local mason_ok, _ = pcall(require, "mason")
        local mason_lspconfig_ok, _ = pcall(require, "mason-lspconfig")

        if mason_ok and mason_lspconfig_ok then
          require("mason").setup({})
          require("mason-lspconfig").setup({
            ensure_installed = languages_config.lsp_servers or {},
            automatic_installation = true,
          })
        end

        -- Use a loop to conveniently call 'setup' on multiple servers
        local servers = languages_config.lsp_servers or {}
        for _, lsp in ipairs(servers) do
          lspconfig[lsp].setup({
            on_attach = function(client, bufnr) end,
            capabilities = require("cmp_nvim_lsp").default_capabilities(),
          })
        end
      end,
    },

    -- Mason for managing LSP servers
    {
      "williamboman/mason.nvim",
      dependencies = { "williamboman/mason-lspconfig.nvim" },
    },

    -- Autocompletion
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-d>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "buffer" },
            { name = "path" },
          }),
        })
      end,
    },

    -- Treesitter for better syntax highlighting and more
    {
      "nvim-treesitter/nvim-treesitter",
      dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          -- Install these parsers automatically
          ensure_installed = languages_config.treesitter_parsers or {},
          -- Install parsers synchronously (only applied to `ensure_installed`)
          sync_install = false,
          -- Automatically install missing parsers when entering buffer
          auto_install = true,
          -- Don't enable highlighting by default (we'll do it in GUIMode)
          highlight = {
            enable = false,
          },
          indent = {
            enable = true,
          },
          textobjects = {
            select = {
              enable = true,
              -- Automatically jump forward to textobj, similar to targets.vim
              lookahead = true,
              keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
              },
            },
          },
        })
      end,
    },

    -- Code linter
    {
      "mfussenegger/nvim-lint",
      config = function()
        local nvim_lint = require("lint")

        -- Set up linters based on config
        nvim_lint.linters_by_ft = languages_config.linters_by_ft or {}

        -- Use autocmd to trigger linting on changes
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
          callback = function()
            require("lint").try_lint()
          end,
        })
      end,
    },
  }

  return plugins
end

-- Initialize Lazy.nvim
function M.init(languages_config)
  -- Configure lazy.nvim plugin manager if it exists
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

  -- Ensure lazy.nvim is installed
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Initialize plugins with lazy.nvim
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    vim.notify("Failed to load lazy.nvim plugin manager. Plugins will not be available.", vim.log.levels.WARN)
    return
  end

  -- Configure plugins with lazy.nvim
  lazy.setup(M.setup(languages_config))

  -- Add a command to run the linter
  vim.api.nvim_create_user_command("Lint", function()
    require("lint").try_lint()
  end, {})

  -- Process any lazy-loading plugins from languages config
  if languages_config.lazy_plugins then
    lazy.setup(languages_config.lazy_plugins)
  end
  -- Set up GitHub Copilot panel command
  vim.keymap.set('n', '<leader>p', function()
    vim.cmd('Copilot panel')
  end, { noremap = true, silent = true, desc = "Open GitHub Copilot panel" })
end

-- Setup TSReinstall command
function M.setup_treesitter_commands()
  -- Add a command to force reinstallation of TreeSitter parsers
  vim.api.nvim_create_user_command("TSReinstall", function()
    local cache_dir = vim.fn.stdpath("cache")
    local parser_dir = cache_dir .. "/treesitter"
    -- Check if the directory exists
    if vim.fn.isdirectory(parser_dir) == 1 then
      -- Remove the parser directory
      vim.fn.delete(parser_dir, "rf")
      vim.notify("TreeSitter parser cache deleted. Restart Neovim to reinstall parsers.", vim.log.levels.INFO)
    else
      vim.notify("TreeSitter parser cache not found at " .. parser_dir, vim.log.levels.WARN)
    end
    -- Ask user to restart Neovim
    print("Please restart Neovim for changes to take effect.")
  end, {})
end

return M