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
    -- JSON/YAML Schema Store
    {
      "b0o/schemastore.nvim",
      priority = 950, -- Load early to ensure it's available for LSP setup
    },

    -- Mason for managing LSP servers
    {
      "williamboman/mason.nvim",
      priority = 900, -- Load before lspconfig
      config = function()
        require("mason").setup({})
      end
    },
    -- Mason-lspconfig bridge
    {
      "williamboman/mason-lspconfig.nvim",
      dependencies = {
        "williamboman/mason.nvim",
      },
      priority = 800, -- Load after mason but before lspconfig
      config = function()
        require("mason-lspconfig").setup({
          ensure_installed = languages_config.language_servers or {},
          automatic_installation = true,
        })
      end,
    },
    -- LSP Configuration
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
      },
      priority = 700, -- Load after mason and mason-lspconfig
      config = function()
        -- Set up LSP keymaps and configurations
        local lspconfig = require("lspconfig")

        -- Global on_attach function for all language servers
        local on_attach = function(client, bufnr)
          -- Set up buffer-local keymaps, etc.
          -- Common LSP functionality
          local opts = { noremap=true, silent=true, buffer=bufnr }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
        end

        -- Global capabilities for all language servers
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
        if cmp_ok then
          capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
        end

        -- Let mason-lspconfig handle the setup
        local server_settings = languages_config.server_settings or {}
        -- Hook into mason-lspconfig's setup_handlers
        require("mason-lspconfig").setup_handlers({
          -- Default handler for installed servers
          function(server_name)
            local server_config = {
              on_attach = on_attach,
              capabilities = capabilities,
            }
            -- If there are server-specific settings, add them
            if server_settings[server_name] then
              -- Add settings if provided
              if server_settings[server_name].settings then
                server_config.settings = server_settings[server_name].settings
              end
              -- Add other properties like filetypes if specified
              for k, v in pairs(server_settings[server_name]) do
                if k ~= "settings" and k ~= "setup" then
                  server_config[k] = v
                end
              end
              -- If the server has a custom setup function, call it
              if server_settings[server_name].setup then
                -- Create a copy of the server config for the setup function
                local setup_config = vim.deepcopy(server_config)
                server_settings[server_name].setup(setup_config)
                -- Update the server_config with any changes made by the setup function
                server_config = setup_config
              end
            end
            -- Configure the server
            lspconfig[server_name].setup(server_config)
          end,
        })
      end,
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