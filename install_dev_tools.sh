#!/bin/bash
#
# Install language servers and linters for Neovim setup
# This script ensures all development tools referenced in your Neovim configuration are installed
# It reads configuration from languages.lua and installs all servers and linters defined there
# It uses Mason when possible, falls back to homebrew, npm, and then to other installation methods
#

set -e  # Exit on any error

# Process arguments
QUIET_MODE=0
SHOW_HELP=0

for arg in "$@"; do
  case "$arg" in
    --quiet|-q)
      QUIET_MODE=1
      ;;
    --help|-h)
      SHOW_HELP=1
      ;;
  esac
done

# Show help if requested
if [ "$SHOW_HELP" -eq 1 ]; then
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  --quiet, -q     Run in quiet mode with minimal output"
  echo "  --help, -h      Show this help message"
  echo
  echo "Description:"
  echo "  This script installs language servers and linters used by Neovim."
  echo "  It reads configuration from $HOME/.config/nvim/config/languages.lua"
  echo "  and installs all tools listed in language_servers and linters sections."
  echo "  The script uses Mason, Homebrew, npm, gem, pip, cargo, etc. as needed."
  exit 0
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

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Extract language servers and linters from the shared config file
CONFIG_FILE="$HOME/.config/nvim/config/languages.lua"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file $CONFIG_FILE not found"
  echo
  echo "Please make sure the configuration file exists. This file contains"
  echo "the list of language servers and linters that need to be installed."
  echo
  echo "You can create it by running:"
  echo "  mkdir -p $HOME/.config/nvim/config"
  echo "  touch $HOME/.config/nvim/config/languages.lua"
  echo
  echo "And then add the necessary configuration."
  exit 1
fi

# Function to extract arrays from Lua config
extract_lua_array() {
  local array_name="$1"
  local temp_file
  temp_file=$(mktemp)

  # Create a small Lua script to print the array contents
  cat > "$temp_file" << EOF
local config = dofile('$CONFIG_FILE')
for _, item in ipairs(config.$array_name) do
  print(item)
end
EOF

  # Run the script with Lua and capture output
  if command_exists lua; then
    lua "$temp_file"
  else
    # Fallback to using Neovim's Lua interpreter if lua isn't available
    nvim --headless -l "$temp_file" -c "q" 2>/dev/null
  fi

  rm "$temp_file"
}

# Function to get installation method for a server or linter
get_install_method() {
  local item_type="$1"  # "server" or "linter"
  local item_name="$2"
  local method="$3"     # "mason", "brew", "npm", etc.

  local table_name=""
  if [ "$item_type" = "server" ]; then
    table_name="server_install_info"
  else
    table_name="linter_install_info"
  fi

  local temp_file
  temp_file=$(mktemp)

  # Create a small Lua script to get the installation method
  cat > "$temp_file" << EOF
local config = dofile('$CONFIG_FILE')
local item_info = config.${table_name}['$item_name']
if item_info and item_info['$method'] then
  print(item_info['$method'])
end
EOF

  # Run the script with Lua and capture output
  local result=""
  if command_exists lua; then
    result=$(lua "$temp_file")
  else
    # Fallback to using Neovim's Lua interpreter if lua isn't available
    result=$(nvim --headless -l "$temp_file" -c "q" 2>/dev/null)
  fi

  rm "$temp_file"
  echo "$result"
}

# Extract language servers and linters
LANGUAGE_SERVERS=()
while read -r server; do
  LANGUAGE_SERVERS+=("$server")
done < <(extract_lua_array "language_servers")

LINTERS=()
while read -r linter; do
  LINTERS+=("$linter")
done < <(extract_lua_array "linters")

# Track installed and failed items
INSTALLED_SERVERS=()
FAILED_SERVERS=()
INSTALLED_LINTERS=()
FAILED_LINTERS=()

# command_exists() function now defined at the top of the file

# Helper function for installation commands
run_install_command() {
  local cmd_prefix="$1"
  local cmd_args="$2"
  local display_name="$3"

  echo "Installing $display_name with $cmd_prefix..."
  if $cmd_prefix "$cmd_args"; then
    return 0
  else
    return 1
  fi
}

# Check if a package is already installed
is_package_installed() {
  local package_type="$1"  # "server" or "linter"
  local package_name="$2"

  # Check if available through Mason
  local mason_path="$HOME/.local/share/nvim/mason/bin"
  local mason_package_name

  if [ "$package_type" = "server" ]; then
    mason_package_name=$(get_install_method "server" "$package_name" "mason")
  else
    mason_package_name=$(get_install_method "linter" "$package_name" "mason")
  fi

  # Check if the binary exists in Mason
  if [ -n "$mason_package_name" ] && [ -f "$mason_path/$mason_package_name" ]; then
    return 0
  fi

  # Check if the package directory exists in Mason
  if [ -n "$mason_package_name" ] && [ -d "$HOME/.local/share/nvim/mason/packages/$mason_package_name" ]; then
    return 0
  fi

  # Special case for linters
  if [ "$package_type" = "linter" ]; then
    if command_exists "$package_name"; then
      return 0
    fi

    # Special check for clippy
    if [ "$package_name" = "clippy" ] && command_exists rustup && rustup component list | grep -q "clippy.*installed"; then
      return 0
    fi
  fi

  # For servers, check common executable names
  if [ "$package_type" = "server" ]; then
    case "$package_name" in
      "lua_ls")
        command_exists lua-language-server && return 0 ;;
      "rust_analyzer")
        command_exists rust-analyzer && return 0 ;;
      "pyright")
        command_exists pyright && return 0 ;;
      "vtsls")
        command_exists vtsls && return 0 ;;
      "ruby_lsp")
        command_exists ruby-lsp && return 0 ;;
      "bashls")
        command_exists bash-language-server && return 0 ;;
      "luau_lsp")
        command_exists luau-lsp && return 0 ;;
      "taplo")
        command_exists taplo && return 0 ;;
      "yamlls")
        command_exists yaml-language-server && return 0 ;;
    esac
  fi

  # Default to not installed
  return 1
}

# Generic function to install a package (server or linter)
install_package() {
  local package_type="$1"  # "server" or "linter"
  local package_name="$2"
  local tracking_list_name="$3"  # Variable name for tracking list (without nameref)
  local failed_list_name="$4"    # Variable name for failed list (without nameref)

  if [ $QUIET_MODE -eq 0 ]; then
    colored_echo "\n${BOLD}=== Installing $package_type: $package_name ===${RESET}"
  fi

  # Add package to installed list preemptively
  if [ "$tracking_list_name" = "INSTALLED_SERVERS" ]; then
    INSTALLED_SERVERS+=("$package_name")
  elif [ "$tracking_list_name" = "INSTALLED_LINTERS" ]; then
    INSTALLED_LINTERS+=("$package_name")
  fi

  # Check if already installed
  if is_package_installed "$package_type" "$package_name"; then
    if [ $QUIET_MODE -eq 0 ]; then
      colored_echo "${GREEN}$package_name is already installed${RESET}"
    fi
    return 0
  fi

  # Try Mason installation first if available
  if command_exists nvim && [ -d "$HOME/.local/share/nvim/mason" ]; then
    local mason_name
    mason_name=$(get_install_method "$package_type" "$package_name" "mason")
    if [ -n "$mason_name" ]; then
      if [ "$package_type" = "server" ]; then
        if install_with_mason "$package_name" "$mason_name"; then
          return 0
        fi
      else
        if install_linter_with_mason "$package_name" "$mason_name"; then
          return 0
        fi
      fi
    fi
  fi

  # Try Homebrew installation if available
  if command_exists brew; then
    local brew_package
    brew_package=$(get_install_method "$package_type" "$package_name" "brew")
    if [ -n "$brew_package" ]; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name with Homebrew..."
      fi
      if brew install "$brew_package"; then
        return 0
      fi
    fi
  fi

  # Try npm installation if available
  if command_exists npm; then
    local npm_package
    npm_package=$(get_install_method "$package_type" "$package_name" "npm")
    if [ -n "$npm_package" ]; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name with npm..."
      fi
      if npm install -g "$npm_package"; then
        return 0
      fi
    fi
  fi

  # Try pip installation if available
  if command_exists pip3; then
    local pip_package
    pip_package=$(get_install_method "$package_type" "$package_name" "pip")
    if [ -n "$pip_package" ]; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name with pip..."
      fi
      if pip3 install "$pip_package"; then
        return 0
      fi
    fi
  fi

  # Try gem installation if available
  if command_exists gem; then
    local gem_package
    gem_package=$(get_install_method "$package_type" "$package_name" "gem")
    if [ -n "$gem_package" ]; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name with gem..."
      fi
      if gem install "$gem_package"; then
        return 0
      fi
    fi
  fi

  # Try cargo installation if available
  if command_exists cargo; then
    local cargo_package
    cargo_package=$(get_install_method "$package_type" "$package_name" "cargo")
    if [ -n "$cargo_package" ]; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name with cargo..."
      fi
      if cargo install "$cargo_package"; then
        return 0
      fi
    fi
  fi

  # Try luarocks installation if available
  if command_exists luarocks; then
    local luarocks_package
    luarocks_package=$(get_install_method "$package_type" "$package_name" "luarocks")
    if [ -n "$luarocks_package" ]; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name with LuaRocks..."
      fi
      if luarocks install --local "$luarocks_package"; then
        return 0
      fi
    fi
  fi

  # Try rustup installation if available
  if command_exists rustup; then
    local rustup_command
    rustup_command=$(get_install_method "$package_type" "$package_name" "rustup")
    if [ -n "$rustup_command" ]; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name with rustup..."
      fi
      if rustup "$rustup_command"; then
        return 0
      fi
    fi
  fi

  # Special case for GitHub installation (only for servers currently)
  if [ "$package_type" = "server" ]; then
    local github_repo
    github_repo=$(get_install_method "server" "$package_name" "github")
    if [ -n "$github_repo" ] && command_exists git; then
      if [ $QUIET_MODE -eq 0 ]; then
        echo "Installing $package_name from GitHub ($github_repo)..."
      fi

      # Extract repo and tag/branch
      local repo_url
      local tag_or_branch

      # Parse GitHub repo#tag format
      if [[ "$github_repo" == *"#"* ]]; then
        repo_url="https://github.com/${github_repo%%#*}.git"
        tag_or_branch="${github_repo#*#}"
      else
        repo_url="https://github.com/$github_repo.git"
        tag_or_branch="main"
      fi

      # Special case for luau_lsp
      if [[ "$repo_url" == *"JohnnyMorganz/luau-lsp"* ]]; then
        if command_exists cmake; then
          local temp_dir
          temp_dir=$(mktemp -d)
          cd "$temp_dir" || {
            echo "Failed to create or change to temporary directory"
            return 1
          }

          # Clone the repo
          git clone "$repo_url"
          cd luau-lsp || {
            echo "Failed to change to luau-lsp directory"
            return 1
          }
          git checkout "$tag_or_branch"

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

          return 0
        fi
      fi
    fi
  fi

  colored_echo "${RED}Failed to install $package_name - no suitable installation method found${RESET}"
  # Remove from installed list since installation failed
  if [ "$tracking_list_name" = "INSTALLED_SERVERS" ]; then
    # Filter out the failed package from installed list
    local i=0
    local new_installed_servers=()
    for server in "${INSTALLED_SERVERS[@]}"; do
      if [ "$server" != "$package_name" ]; then
        new_installed_servers[i]="$server"
        ((i++))
      fi
    done
    INSTALLED_SERVERS=("${new_installed_servers[@]}")

    # Add to failed list
    if [ "$failed_list_name" = "FAILED_SERVERS" ]; then
      FAILED_SERVERS+=("$package_name")
    fi
  elif [ "$tracking_list_name" = "INSTALLED_LINTERS" ]; then
    # Filter out the failed package from installed list
    local i=0
    local new_installed_linters=()
    for linter in "${INSTALLED_LINTERS[@]}"; do
      if [ "$linter" != "$package_name" ]; then
        new_installed_linters[i]="$linter"
        ((i++))
      fi
    done
    INSTALLED_LINTERS=("${new_installed_linters[@]}")

    # Add to failed list
    if [ "$failed_list_name" = "FAILED_LINTERS" ]; then
      FAILED_LINTERS+=("$package_name")
    fi
  fi
  return 1
}

# Wrapper function for installing language servers
install_language_server() {
  local server="$1"
  install_package "server" "$server" "INSTALLED_SERVERS" "FAILED_SERVERS"
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

# Wrapper function for installing linters
install_linter() {
  local linter="$1"
  install_package "linter" "$linter" "INSTALLED_LINTERS" "FAILED_LINTERS"
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

# Function to install TreeSitter parsers
install_treesitter_parsers() {
  colored_echo "${BLUE}Installing TreeSitter parsers...${RESET}"

  # Check if nvim exists
  if ! command_exists nvim; then
    echo -e "${YELLOW}Neovim not found. TreeSitter installation requires Neovim.${RESET}"
    echo -e "${YELLOW}Please install Neovim first: https://neovim.io/${RESET}"
    echo
    return 1
  fi

  # Skip TreeSitter installation via scripting approach - it's too complex
  # Instead load all parsers directly from the languages.lua file and install via native nvim commands
  echo "Installing TreeSitter parsers..."

  # Extract treesitter parsers from config
  PARSERS=()
  while read -r parser; do
    PARSERS+=("$parser")
  done < <(extract_lua_array "treesitter_parsers")

  # Ensure nvim-treesitter is properly installed first
  echo "Ensuring nvim-treesitter is installed..."
  nvim --headless --noplugin --clean -c "packadd nvim-treesitter" -c "qa!" > /dev/null 2>&1 || true

  # Install each parser using nvim's command mode
  for parser in "${PARSERS[@]}"; do
    echo "Checking parser: $parser"
    # Use an empty/minimal Neovim config for this
    nvim --headless --noplugin --clean -c "packadd nvim-treesitter" -c "TSInstallSync! $parser" -c "qa!" > /dev/null 2>&1 || true
  done

  echo "TreeSitter parsers installation completed."

  # Check if parsers are installed - try multiple possible locations
  local possible_dirs=(
    "$HOME/.local/share/nvim/lazy/nvim-treesitter/parser"
    "$HOME/.local/share/nvim/site/pack/*/start/nvim-treesitter/parser"
    "$HOME/.local/share/nvim/site/pack/*/opt/nvim-treesitter/parser"
  )

  local found=false
  for dir_pattern in "${possible_dirs[@]}"; do
    # Use globbing to expand the pattern
    for dir in $dir_pattern; do
      if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
        colored_echo "${GREEN}TreeSitter parsers have been successfully installed in $dir.${RESET}"
        found=true
        break 2
      fi
    done
  done

  if [ "$found" = true ]; then
    return 0
  else
    colored_echo "${RED}Failed to install TreeSitter parsers.${RESET}"
    return 1
  fi
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
  colored_echo "${BOLD}=== Neovim Development Tools Installer ===${RESET}"
  if [ $QUIET_MODE -eq 0 ]; then
    echo "This script will install language servers and linters for Neovim"
    echo "Based on configuration in $HOME/.config/nvim/config/languages.lua"
    echo "Use --quiet or -q for less verbose output"
  fi

  # Check prerequisites
  check_prerequisites

  # Bootstrap Mason if needed
  bootstrap_mason || {
    colored_echo "${RED}Failed to bootstrap Mason. Continuing with alternative installation methods.${RESET}"
  }

  # Install TreeSitter parsers
  install_treesitter_parsers || {
    colored_echo "${YELLOW}Failed to install TreeSitter parsers. Some syntax highlighting may not work properly.${RESET}"
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

  # Configure nvim-qt on macOS to disable press-and-hold behavior
  if [[ "$(uname)" == "Darwin" ]] && command_exists nvim-qt; then
    colored_echo "\n${BOLD}=== Configuring nvim-qt for macOS ===${RESET}"

    # Try multiple domain approaches - at least one should work
    # Main nvim-qt domain
    defaults write org.equalsraf.neovim ApplePressAndHoldEnabled -bool false

    # Alternative bundled app domain
    nvim_qt_path=$(which nvim-qt)
    if [[ -L "$nvim_qt_path" ]]; then
      # Follow symlink to actual application
      nvim_qt_path=$(readlink "$nvim_qt_path")
    fi

    # Check if it's an app bundle
    if [[ "$nvim_qt_path" == *.app* ]]; then
      # Extract the bundle identifier
      app_dir=$(dirname "$nvim_qt_path")
      if [[ -f "$app_dir/Info.plist" ]]; then
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_dir/Info.plist" 2>/dev/null)
        if [[ -n "$bundle_id" ]]; then
          # Set for the specific bundle ID
          defaults write "$bundle_id" ApplePressAndHoldEnabled -bool false
        fi
      fi
    fi

    # Global setting as a fallback
    defaults write -g ApplePressAndHoldEnabled -bool false

    colored_echo "${GREEN}Configured nvim-qt to disable press-and-hold behavior for key repeat${RESET}"
    colored_echo "${BLUE}This allows key repeating (like holding 'j' to move down) to work properly${RESET}"
    colored_echo "${YELLOW}Note: You may need to restart nvim-qt for changes to take effect${RESET}"
    colored_echo "${YELLOW}If key repeat still doesn't work, you may need to restart your Mac${RESET}"
  fi
}

# Run the main function
main
