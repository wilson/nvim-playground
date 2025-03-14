-- Configuration for language servers and linters
-- This file is shared between init.lua and install_language_servers.sh

local M = {}

-- Language servers to be installed and configured
M.language_servers = {
  "lua_ls",         -- Lua language server
  "rust_analyzer",  -- Rust language server
  "pyright",        -- Python language server
  "ruby_lsp",       -- Ruby language server (was ruby_ls)
  "vtsls",          -- TypeScript/JavaScript language server (was tsserver)
  "html",           -- HTML language server
  "cssls",          -- CSS language server
  "jsonls",         -- JSON language server
  "taplo",          -- TOML language server
  "yamlls",         -- YAML language server
  "luau_lsp",       -- Luau language server
  "bashls",         -- Bash language server
}

-- Linters to be installed and configured
M.linters = {
  "luacheck",  -- Lua linter
  "ruff",      -- Python linter (replaces pylint)
  "mypy",      -- Python type checker
  "eslint",    -- JavaScript/TypeScript linter
  "rubocop",   -- Ruby linter
  "clippy",    -- Rust linter
}

-- Mapping of linters to file types
M.linters_by_ft = {
  lua = {"luacheck"},
  python = {"ruff", "mypy"},  -- ruff instead of pylint
  javascript = {"eslint"},
  typescript = {"eslint"},
  ruby = {"rubocop"},
  rust = {"clippy"}
}

-- Treesitter parsers to install
M.treesitter_parsers = {
  -- Programming languages
  "lua", "rust", "python", "ruby", "javascript", "typescript", "html", "css",
  -- Config file formats
  "json", "toml", "yaml", "xml",
  -- Documentation formats
  "markdown", "markdown_inline",
  -- Vim/Neovim specific formats
  "vim", "vimdoc", "query",
  -- Core languages
  "c", "bash"
}

-- Server-specific configurations for LSP
-- These will be passed to the respective language server setup
M.server_settings = {
  -- Lua language server configuration
  lua_ls = {
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
        },
        diagnostics = {
          globals = { "vim" },  -- Recognize vim global
        },
        workspace = {
          -- Make server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
      },
    },
  },
  -- Rust analyzer configuration
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        imports = {
          granularity = {
            group = "module",
          },
        },
        checkOnSave = {
          command = "clippy",
        },
        inlayHints = {
          enable = true,
          typeHints = {
            enable = true,
          },
          parameterHints = {
            enable = true,
          },
        },
      },
    },
  },
  -- Python configuration
  pyright = {
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          useLibraryCodeForTypes = true,
        },
      },
    },
  },
  -- Ruby LSP configuration
  ruby_lsp = {
    init_options = {
      formatter = true,
    },
    settings = {
      rubocop = {
        enable = true,
        configFilePath = ".rubocop.yml",
      },
    },
  },
  -- JSON configuration with schema support
  jsonls = {
    settings = {
      json = {
        validate = { enable = true },
      },
    },
    setup = function(server)
      -- Check if schemastore plugin is available
      local has_schemastore, schemastore = pcall(require, "schemastore")
      -- Only apply schema settings if schemastore is available
      if has_schemastore then
        server.settings.json.schemas = schemastore.json.schemas()
      end
    end,
  },
  -- YAML configuration
  yamlls = {
    settings = {
      yaml = {
        schemaStore = {
          enable = true,
          url = "https://www.schemastore.org/api/json/catalog.json",
        },
      },
    },
    setup = function(server)
      -- Will only be used if schemastore plugin is installed
      local has_schemastore, schemastore = pcall(require, "schemastore")
      if has_schemastore then
        server.settings.yaml.schemas = schemastore.yaml.schemas()
      end
    end,
  },
  -- TOML configuration
  taplo = {
    settings = {
      taplo = {
        diagnostics = {
          enable = true,
        },
        formatter = {
          enable = true,
        },
      },
    },
  },
  -- TypeScript/JavaScript configuration
  vtsls = {
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
        format = {
          enable = true,
          indentSize = 2,
        },
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
        format = {
          enable = true,
          indentSize = 2,
        },
      },
    },
  },
  -- Bash language server
  bashls = {
    filetypes = { "sh", "bash" },
    settings = {
      bashIde = {
        shellcheckPath = "shellcheck",
      },
    },
  },
}

-- Installation methods for language servers
M.server_install_info = {
  lua_ls = {
    mason = "lua-language-server",
    brew = "lua-language-server",
    npm = "@lua-language-server/lua-language-server",
  },
  rust_analyzer = {
    mason = "rust-analyzer",
    brew = "rust-analyzer",
    rustup = "component add rust-analyzer",
  },
  pyright = {
    mason = "pyright",
    brew = "pyright",
    npm = "pyright",
  },
  ruby_lsp = {
    mason = "ruby-lsp",
    gem = "ruby-lsp",
  },
  vtsls = {
    mason = "vtsls",
    npm = "typescript @vtsls/language-server",
  },
  html = {
    mason = "html-lsp",
    npm = "vscode-langservers-extracted",
  },
  cssls = {
    mason = "css-lsp",
    npm = "vscode-langservers-extracted",
  },
  jsonls = {
    mason = "json-lsp",
    npm = "vscode-langservers-extracted",
  },
  taplo = {
    mason = "taplo",
    brew = "taplo-cli",
    cargo = "taplo-cli",
  },
  yamlls = {
    mason = "yaml-language-server",
    npm = "yaml-language-server",
  },
  luau_lsp = {
    mason = "luau-lsp",
    github = "JohnnyMorganz/luau-lsp#v1.40.0",
  },
  bashls = {
    mason = "bash-language-server",
    npm = "bash-language-server",
  },
}

-- Installation methods for linters
M.linter_install_info = {
  luacheck = {
    mason = "luacheck",
    brew = "luacheck",
    luarocks = "luacheck",
  },
  ruff = {
    mason = "ruff",
    brew = "ruff",
    pip = "ruff",
  },
  mypy = {
    mason = "mypy",
    brew = "mypy",
    pip = "mypy",
  },
  eslint = {
    mason = "eslint_d",
    npm = "eslint",
  },
  rubocop = {
    mason = "rubocop",
    gem = "rubocop",
  },
  clippy = {
    rustup = "component add clippy",
  },
}

return M