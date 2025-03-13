-- Configuration for language servers and linters
-- This file is shared between init.lua and install_language_servers.sh

local M = {}

-- Language servers to be installed and configured
M.language_servers = {
  "lua_ls",         -- Lua language server
  "rust_analyzer",  -- Rust language server
  "pyright",        -- Python language server
  "ruby_ls",        -- Ruby language server
  "tsserver",       -- TypeScript/JavaScript language server
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
  ruby_ls = {
    mason = "ruby-lsp",
    gem = "ruby-lsp",
  },
  tsserver = {
    mason = "typescript-language-server",
    npm = "typescript typescript-language-server",
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