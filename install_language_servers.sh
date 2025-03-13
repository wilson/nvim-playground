#!/bin/bash
# 
# Install language servers for Neovim setup
# This script ensures all language servers referenced in your Neovim configuration are installed
# It uses homebrew when possible, falls back to npm, and then to other installation methods
#

set -e  # Exit on any error

# Process arguments
QUIET_MODE=0
if [ "$1" = "--quiet" ] || [ "$1" = "-q" ]; then
  QUIET_MODE=1
  shift
fi

# Check if script is run in a terminal that supports colors
# We need to ensure the output is properly formatted for the terminal
# The -e flag to echo is needed to interpret escape sequences
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  # Text formatting with echo -e required
  BOLD="\033[1m"
  RED="\033[31m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  RESET="\033[0m"
  
  # Function to print colored text
  colored_echo() {
    echo -e "$@"
  }
else
  # No color if not in a terminal or redirected
  BOLD=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  RESET=""
  
  # Function to print text without color
  colored_echo() {
    # Strip color codes when printing
    local text="$*"
    # Use parameter expansion instead of sed
    echo "${text//\x1b\[[0-9;]*m/}"
  }
fi

# Language servers extracted from init.lua
LANGUAGE_SERVERS=(
  # From mason-lspconfig ensure_installed (line 174-181)
  "lua_ls"         # Lua language server
  "rust_analyzer"  # Rust language server
  "pyright"        # Python language server
  "ruby_ls"        # Ruby language server
  "tsserver"       # TypeScript/JavaScript language server
  "html"           # HTML language server
  "cssls"          # CSS language server
  "jsonls"         # JSON language server
  "taplo"          # TOML language server
  "yamlls"         # YAML language server
  "luau_lsp"       # Luau language server
  "bashls"         # Bash language server
)

# Linters referenced in init.lua (line 193-200)
LINTERS=(
  "luacheck"  # Lua linter
  "pylint"    # Python linter
  "mypy"      # Python type checker
  "eslint"    # JavaScript/TypeScript linter
  "rubocop"   # Ruby linter
  "clippy"    # Rust linter
)

# Track installed and failed items
INSTALLED_SERVERS=()
FAILED_SERVERS=()
INSTALLED_LINTERS=()
FAILED_LINTERS=()

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Helper function for installation commands
run_install_command() {
  local cmd_prefix="$1"
  local cmd_args="$2"
  local display_name="$3"
  
  echo "Installing $display_name with $cmd_prefix..."
  if $cmd_prefix $cmd_args; then
    return 0
  else
    return 1
  fi
}

# Check if a language server is already installed
is_language_server_installed() {
  local server="$1"
  local mason_path="$HOME/.local/share/nvim/mason/bin"
  
  # Check if available through Mason
  if [ -f "$mason_path/$server" ]; then
    return 0
  fi
  
  # Check common executables based on server name
  case "$server" in
    "lua_ls")
      command_exists lua-language-server && return 0 ;;
    "rust_analyzer")
      command_exists rust-analyzer && return 0 ;;
    "pyright")
      command_exists pyright && return 0 ;;
    "tsserver")
      command_exists typescript-language-server && return 0 ;;
    "bashls")
      command_exists bash-language-server && return 0 ;;
    "luau_lsp")
      command_exists luau-lsp && return 0 ;;
    "taplo")
      command_exists taplo && return 0 ;;
    "yaml-language-server")
      command_exists yaml-language-server && return 0 ;;
  esac
  
  # Default to not installed
  return 1
}

# Install language server
install_language_server() {
  local server="$1"
  if [ $QUIET_MODE -eq 0 ]; then
    colored_echo "\n${BOLD}=== Installing $server ===${RESET}"
  fi
  
  # Add server to installed list preemptively
  INSTALLED_SERVERS+=("$server")
  
  # Check if already installed
  if is_language_server_installed "$server"; then
    if [ $QUIET_MODE -eq 0 ]; then
      colored_echo "${GREEN}$server is already installed${RESET}"
    fi
    return 0
  fi
  
  # Try different installation methods based on server
  case "$server" in
    "lua_ls")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "lua-language-server" && return 0
      elif command_exists brew; then
        run_install_command "brew" "install lua-language-server" "lua-language-server" && return 0
      elif command_exists npm; then
        run_install_command "npm" "install -g @lua-language-server/lua-language-server" "lua-language-server" && return 0
      fi
      ;;
      
    "rust_analyzer")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "rust-analyzer" && return 0
      elif command_exists brew; then
        echo "Installing rust-analyzer with Homebrew..."
        brew install rust-analyzer && return 0
      elif command_exists rustup; then
        echo "Installing rust-analyzer with rustup..."
        rustup component add rust-analyzer && return 0
      fi
      ;;
      
    "pyright")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "pyright" && return 0
      elif command_exists brew; then
        echo "Installing pyright with Homebrew..."
        brew install pyright && INSTALLED_SERVERS+=("$server") && return 0
      elif command_exists npm; then
        echo "Installing pyright with npm..."
        npm install -g pyright && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
      
    "ruby_ls")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "ruby-lsp" && return 0
      elif command_exists gem; then
        echo "Installing ruby-lsp with gem..."
        gem install ruby-lsp && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
      
    "tsserver")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "typescript-language-server" && return 0
      elif command_exists npm; then
        echo "Installing typescript-language-server with npm..."
        npm install -g typescript typescript-language-server && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
      
    "html")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "html-lsp" && return 0
      elif command_exists npm; then
        echo "Installing vscode-langservers-extracted with npm..."
        npm install -g vscode-langservers-extracted && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;

    "cssls")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "css-lsp" && return 0
      elif command_exists npm; then
        echo "Installing vscode-langservers-extracted with npm..."
        npm install -g vscode-langservers-extracted && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;

    "jsonls")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "json-lsp" && return 0
      elif command_exists npm; then
        echo "Installing vscode-langservers-extracted with npm..."
        npm install -g vscode-langservers-extracted && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
      
    "taplo")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "taplo" && return 0
      elif command_exists brew; then
        echo "Installing taplo-cli with Homebrew..."
        brew install taplo-cli && INSTALLED_SERVERS+=("$server") && return 0
      elif command_exists cargo; then
        echo "Installing taplo-cli with cargo..."
        cargo install taplo-cli && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
      
    "yamlls")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "yaml-language-server" && return 0
      elif command_exists npm; then
        echo "Installing yaml-language-server with npm..."
        npm install -g yaml-language-server && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
      
    "luau_lsp")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "luau-lsp" && return 0
      elif command_exists git && command_exists cmake; then
        echo "Building luau-lsp from GitHub with CMake..."
        
        # Create a temporary directory
        local temp_dir
        temp_dir=$(mktemp -d)
        cd "$temp_dir" || {
          echo "Failed to create or change to temporary directory"
          return 1
        }
        
        # Clone the repo
        git clone https://github.com/JohnnyMorganz/luau-lsp.git
        cd luau-lsp || {
          echo "Failed to change to luau-lsp directory"
          return 1
        }
        git checkout v1.40.0  # Latest release tag
        
        # Build following README instructions
        mkdir build
        cd build || {
          echo "Failed to change to build directory"
          return 1
        }
        cmake .. -DCMAKE_BUILD_TYPE=Release || {
          echo "Failed to run cmake configuration"
          return 1
        }
        cmake --build . --target Luau.LanguageServer.CLI --config Release || {
          echo "Failed to build Luau.LanguageServer.CLI"
          return 1
        }
        
        # Install to a location in PATH
        if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
          echo "Installing to /usr/local/bin/luau-lsp"
          cp CLI/Luau.LanguageServer.CLI /usr/local/bin/luau-lsp
        elif [ -d "$HOME/.local/bin" ]; then
          echo "Installing to $HOME/.local/bin/luau-lsp"
          mkdir -p "$HOME/.local/bin"
          cp CLI/Luau.LanguageServer.CLI "$HOME/.local/bin/luau-lsp"
        else
          echo "Installing to current working directory"
          cp CLI/Luau.LanguageServer.CLI "$HOME/luau-lsp"
          echo "You should move $HOME/luau-lsp to a directory in your PATH"
        fi
        
        # Clean up
        cd "$OLDPWD"
        rm -rf "$temp_dir"
        
        INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
      
    "bashls")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_with_mason "$server" "bash-language-server" && return 0
      elif command_exists npm; then
        echo "Installing bash-language-server with npm..."
        npm install -g bash-language-server && INSTALLED_SERVERS+=("$server") && return 0
      fi
      ;;
  esac
  
  colored_echo "${RED}Failed to install $server - no suitable installation method found${RESET}"
  # Remove from installed list since installation failed
  INSTALLED_SERVERS=("${INSTALLED_SERVERS[@]/$server}")
  FAILED_SERVERS+=("$server")
  return 1
}

# Install a linter using Mason
install_linter_with_mason() {
  local linter_name="$1"
  local mason_name="${2:-$linter_name}" # Use the provided mason name or default to linter name
  
  echo "Installing $linter_name with Mason..."
  # Check if already installed by Mason
  if [ -f "$HOME/.local/share/nvim/mason/bin/$mason_name" ] || \
     ls "$HOME/.local/share/nvim/mason/packages/$mason_name" &>/dev/null; then
    colored_echo "${GREEN}$linter_name is already installed via Mason${RESET}"
    return 0
  fi
  
  # Create temp file for nvim output
  local NVIM_OUTPUT
  NVIM_OUTPUT=$(mktemp)
  nvim --headless -c "MasonInstall $mason_name" -c "sleep 1500m" -c "qa" > "$NVIM_OUTPUT" 2>&1
  rm -f "$NVIM_OUTPUT"
  
  # Check if installation was successful
  if [ -f "$HOME/.local/share/nvim/mason/bin/$mason_name" ] || \
     ls "$HOME/.local/share/nvim/mason/packages/$mason_name" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

# Install linter
install_linter() {
  local linter="$1"
  if [ $QUIET_MODE -eq 0 ]; then
    colored_echo "\n${BOLD}=== Installing linter: $linter ===${RESET}"
  fi
  
  # Add linter to installed list preemptively
  INSTALLED_LINTERS+=("$linter")
  
  # Check if already installed
  if command_exists "$linter"; then
    if [ $QUIET_MODE -eq 0 ]; then
      colored_echo "${GREEN}$linter is already installed${RESET}"
    fi
    return 0
  fi
  
  # Special case for clippy which is checked differently
  if [ "$linter" = "clippy" ] && rustup component list | grep -q "clippy.*installed"; then
    if [ $QUIET_MODE -eq 0 ]; then
      colored_echo "${GREEN}clippy is already installed${RESET}"
    fi
    return 0
  fi
  
  # Try different installation methods based on linter
  case "$linter" in
    "luacheck")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_linter_with_mason "$linter" "luacheck" && return 0
      elif command_exists brew; then
        echo "Installing luacheck with Homebrew..."
        brew install luacheck && INSTALLED_LINTERS+=("$linter") && return 0
      elif command_exists luarocks; then
        echo "Installing luacheck with LuaRocks..."
        luarocks install --local luacheck && INSTALLED_LINTERS+=("$linter") && return 0
      fi
      ;;
      
    "pylint")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_linter_with_mason "$linter" "pylint" && return 0
      elif command_exists brew; then
        echo "Installing pylint with Homebrew..."
        brew install pylint && INSTALLED_LINTERS+=("$linter") && return 0
      elif command_exists pip3; then
        echo "Installing pylint with pip..."
        pip3 install pylint && INSTALLED_LINTERS+=("$linter") && return 0
      fi
      ;;
      
    "mypy")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_linter_with_mason "$linter" "mypy" && return 0
      elif command_exists brew; then
        echo "Installing mypy with Homebrew..."
        brew install mypy && INSTALLED_LINTERS+=("$linter") && return 0
      elif command_exists pip3; then
        echo "Installing mypy with pip..."
        pip3 install mypy && INSTALLED_LINTERS+=("$linter") && return 0
      fi
      ;;
      
    "eslint")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_linter_with_mason "$linter" "eslint_d" && return 0
      elif command_exists npm; then
        echo "Installing eslint with npm..."
        npm install -g eslint && INSTALLED_LINTERS+=("$linter") && return 0
      fi
      ;;
      
    "rubocop")
      if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
        install_linter_with_mason "$linter" "rubocop" && return 0
      elif command_exists gem; then
        echo "Installing rubocop with gem..."
        gem install rubocop && INSTALLED_LINTERS+=("$linter") && return 0
      fi
      ;;
      
    "clippy")
      if command_exists rustup; then
        echo "Installing clippy with rustup..."
        rustup component add clippy && INSTALLED_LINTERS+=("$linter") && return 0
      fi
      ;;
  esac
  
  colored_echo "${RED}Failed to install $linter - no suitable installation method found${RESET}"
  # Remove from installed list since installation failed
  INSTALLED_LINTERS=("${INSTALLED_LINTERS[@]/$linter}")
  FAILED_LINTERS+=("$linter")
  return 1
}

# Check prerequisites
check_prerequisites() {
  local missing=()
  local warnings=()
  
  if ! command_exists brew; then
    missing+=("Homebrew (https://brew.sh/)")
  fi
  
  if ! command_exists npm; then
    missing+=("Node.js and npm (brew install node)")
  fi
  
  if ! command_exists cargo; then
    missing+=("Rust and Cargo (brew install rustup-init)")
  elif ! command_exists rustup; then
    warnings+=("rustup command not found, but cargo exists. Some Rust tools may not install correctly")
  fi
  
  if ! command_exists pip3; then
    missing+=("Python and pip (brew install python)")
  fi
  
  if ! command_exists gem; then
    missing+=("Ruby and gem (brew install ruby)")
  fi
  
  # Display missing prerequisites
  if [ ${#missing[@]} -gt 0 ]; then
    colored_echo "${YELLOW}Missing prerequisites:${RESET}"
    for prereq in "${missing[@]}"; do
      echo "  - $prereq"
    done
    colored_echo "\n${YELLOW}Some language servers may not install correctly without these prerequisites.${RESET}"
    colored_echo "${YELLOW}Install them with Homebrew first for best results.${RESET}"
    
    # Ask user if they want to continue anyway
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Installation cancelled."
      exit 1
    fi
  fi
  
  # Display warnings
  if [ ${#warnings[@]} -gt 0 ]; then
    colored_echo "${YELLOW}Warnings:${RESET}"
    for warning in "${warnings[@]}"; do
      echo "  - $warning"
    done
    echo
  fi
  
  return 0
}

# Function to bootstrap Mason if it's not already set up
bootstrap_mason() {
  local mason_path="$HOME/.local/share/nvim/mason"
  
  # Check if nvim exists
  if ! command_exists nvim; then
    echo -e "${YELLOW}Neovim not found. Mason installation requires Neovim.${RESET}"
    echo -e "${YELLOW}Please install Neovim first: https://neovim.io/${RESET}"
    echo
    return 1
  fi
  
  # Check if Mason is already set up
  if [ -d "$mason_path" ] && [ -d "$mason_path/bin" ]; then
    colored_echo "${GREEN}Mason is already installed.${RESET}"
    return 0
  fi
  
  colored_echo "${BLUE}Bootstrapping Mason for Neovim...${RESET}"
  
  # Create a temporary init.lua to bootstrap Mason
  local TEMP_INIT
  TEMP_INIT=$(mktemp)
  cat > "$TEMP_INIT" << 'EOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  print("Installing lazy.nvim...")
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

-- Set leader key for lazy
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Lazy setup for Mason
require("lazy").setup({
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
      print("Mason has been installed successfully!")
    end
  }
})
EOF

  # Run Neovim with the temporary init.lua to install Mason
  echo "Installing Mason plugin for Neovim..."
  local NVIM_OUTPUT
  NVIM_OUTPUT=$(mktemp)
  nvim --headless -u "$TEMP_INIT" -c "sleep 2000m" -c "qa" > "$NVIM_OUTPUT" 2>&1
  rm -f "$NVIM_OUTPUT"
  
  # Clean up
  rm "$TEMP_INIT"
  
  # Verify installation
  if [ -d "$mason_path" ]; then
    colored_echo "${GREEN}Mason has been successfully installed.${RESET}"
    return 0
  else
    colored_echo "${RED}Failed to install Mason.${RESET}"
    return 1
  fi
}

# Suppress Homebrew hints and cleanup messages
suppress_brew_messages() {
  # Check if environment variables are already set
  if [[ -z "${HOMEBREW_NO_ENV_HINTS}" ]]; then
    export HOMEBREW_NO_ENV_HINTS=1
  fi
  if [[ -z "${HOMEBREW_NO_INSTALL_CLEANUP}" ]]; then
    export HOMEBREW_NO_INSTALL_CLEANUP=1
  fi
}

# Suppress npm funding messages
suppress_npm_messages() {
  # Set npm config to suppress funding messages
  if command_exists npm; then
    npm config set fund false &>/dev/null || true
  fi
}

# Install a language server using Mason
install_with_mason() {
  local server_name="$1"
  local mason_name="${2:-$server_name}" # Use the provided mason name or default to server name
  
  echo "Installing $server_name with Mason..."
  # Check if already installed by Mason
  if [ -f "$HOME/.local/share/nvim/mason/bin/$mason_name" ] || \
     ls "$HOME/.local/share/nvim/mason/packages/$mason_name" &>/dev/null; then
    colored_echo "${GREEN}$server_name is already installed via Mason${RESET}"
    return 0
  fi
  
  # Create temp file for nvim output
  local NVIM_OUTPUT
  NVIM_OUTPUT=$(mktemp)
  nvim --headless -c "MasonInstall $mason_name" -c "sleep 1500m" -c "qa" > "$NVIM_OUTPUT" 2>&1
  rm -f "$NVIM_OUTPUT"
  
  # Check if installation was successful
  if [ -f "$HOME/.local/share/nvim/mason/bin/$mason_name" ] || \
     ls "$HOME/.local/share/nvim/mason/packages/$mason_name" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

# Main function
main() {
  colored_echo "${BOLD}=== Neovim Language Server Installer ===${RESET}"
  if [ $QUIET_MODE -eq 0 ]; then
    echo "This script will install language servers and linters for Neovim"
    echo "Use --quiet or -q for less verbose output"
  fi
  
  # Check prerequisites
  check_prerequisites
  
  # Bootstrap Mason if needed
  bootstrap_mason || {
    colored_echo "${RED}Failed to bootstrap Mason. Continuing with alternative installation methods.${RESET}"
  }
  
  # Suppress tool messages
  suppress_brew_messages
  suppress_npm_messages
  
  # Install language servers
  if [ $QUIET_MODE -eq 0 ]; then
    colored_echo "\n${BOLD}=== Installing Language Servers ===${RESET}"
  fi
  for server in "${LANGUAGE_SERVERS[@]}"; do
    install_language_server "$server"
  done
  
  # Install linters
  if [ $QUIET_MODE -eq 0 ]; then
    colored_echo "\n${BOLD}=== Installing Linters ===${RESET}"
  fi
  for linter in "${LINTERS[@]}"; do
    install_linter "$linter"
  done
  
  # Summary
  colored_echo "\n${BOLD}=== Installation Summary ===${RESET}"
  colored_echo "${GREEN}Successfully installed language servers (${#INSTALLED_SERVERS[@]}/${#LANGUAGE_SERVERS[@]}):${RESET}"
  for server in "${INSTALLED_SERVERS[@]}"; do
    echo "  - $server"
  done
  
  if [ ${#FAILED_SERVERS[@]} -gt 0 ]; then
    colored_echo "\n${RED}Failed to install language servers (${#FAILED_SERVERS[@]}/${#LANGUAGE_SERVERS[@]}):${RESET}"
    for server in "${FAILED_SERVERS[@]}"; do
      echo "  - $server"
    done
  fi
  
  colored_echo "\n${GREEN}Successfully installed linters (${#INSTALLED_LINTERS[@]}/${#LINTERS[@]}):${RESET}"
  for linter in "${INSTALLED_LINTERS[@]}"; do
    echo "  - $linter"
  done
  
  if [ ${#FAILED_LINTERS[@]} -gt 0 ]; then
    colored_echo "\n${RED}Failed to install linters (${#FAILED_LINTERS[@]}/${#LINTERS[@]}):${RESET}"
    for linter in "${FAILED_LINTERS[@]}"; do
      echo "  - $linter"
    done
  fi
  
  # Final note
  colored_echo "\n${BLUE}Note: Some language servers may require additional configuration.${RESET}"
  colored_echo "${BLUE}For more information, visit: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md${RESET}"
  
  # Remind about nvim Mason
  colored_echo "\n${BLUE}You can manage language servers directly in Neovim with:${RESET}"
  colored_echo "${BLUE}  :Mason${RESET}"
}

# Run the main function
main