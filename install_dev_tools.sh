#!/usr/bin/env zsh
#
# Install language servers and linters for Neovim setup
# This script ensures all development tools referenced in your Neovim configuration are installed
# It reads configuration from languages.lua and installs all servers and linters defined there
# It uses Mason when possible, falls back to homebrew/pkg, npm, and then to other installation methods
#
# NOTE: This script is compatible with both bash and zsh, but uses zsh shebang for FreeBSD compatibility
# For linting purposes, use: shellcheck --shell=bash install_dev_tools.sh
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
  echo "  The script uses Mason, Homebrew/pkg, npm, gem, pip, cargo, etc. as needed."
  exit 0
fi

# Detect operating system
OS_TYPE="unknown"
if [[ "$(uname)" == "Darwin" ]]; then
  OS_TYPE="macos"
elif [[ "$(uname)" == "FreeBSD" ]]; then
  OS_TYPE="freebsd"
elif [[ "$(uname)" == "Linux" ]]; then
  OS_TYPE="linux"
fi

# NOTE: For FreeBSD users, you may need to adjust package names in
# ~/.config/nvim/config/languages.lua if the installation fails with pkg.
# Common naming patterns for FreeBSD packages are:
# - Python packages: py-packagename or py39-packagename
# - Ruby gems: rubygem-packagename
# - Node packages: npm-packagename
# Search the FreeBSD ports collection with: pkg search packagename

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
  # We also define a mock vim object to avoid errors in the languages.lua file
  cat > "$temp_file" << 'EOF'
-- Mock vim object to avoid errors in language config
vim = {
  api = {
    nvim_get_runtime_file = function() return {} end
  }
}

-- Now load the config and extract the requested array
local config = dofile('CONFIG_FILE_PLACEHOLDER')
for _, item in ipairs(config.ARRAY_NAME_PLACEHOLDER) do
  print(item)
end
EOF

  # Replace placeholders with actual values
  sed -i '' "s|CONFIG_FILE_PLACEHOLDER|$CONFIG_FILE|g" "$temp_file"
  sed -i '' "s|ARRAY_NAME_PLACEHOLDER|$array_name|g" "$temp_file"

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
  local method="$3"     # "mason", "brew", "pkg", "npm", etc.

  local table_name=""
  if [ "$item_type" = "server" ]; then
    table_name="server_install_info"
  else
    table_name="linter_install_info"
  fi

  local temp_file
  temp_file=$(mktemp)

  # Create a small Lua script to get the installation method
  # Include the same mock vim object for consistency
  cat > "$temp_file" << 'EOF'
-- Mock vim object to avoid errors in language config
vim = {
  api = {
    nvim_get_runtime_file = function() return {} end
  }
}

-- Get the installation method
local config = dofile('CONFIG_FILE_PLACEHOLDER')
local item_info = config.TABLE_NAME_PLACEHOLDER['ITEM_NAME_PLACEHOLDER']
if item_info and item_info['METHOD_PLACEHOLDER'] then
  print(item_info['METHOD_PLACEHOLDER'])
end
EOF

  # Replace placeholders with actual values
  sed -i '' "s|CONFIG_FILE_PLACEHOLDER|$CONFIG_FILE|g" "$temp_file"
  sed -i '' "s|TABLE_NAME_PLACEHOLDER|${table_name}|g" "$temp_file"
  sed -i '' "s|ITEM_NAME_PLACEHOLDER|$item_name|g" "$temp_file"
  sed -i '' "s|METHOD_PLACEHOLDER|$method|g" "$temp_file"

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
# Define default language servers in case we can't read from config
DEFAULT_LANGUAGE_SERVERS=("lua_ls" "pyright" "bashls" "tsserver" "jsonls" "yamlls")
DEFAULT_LINTERS=("luacheck" "shellcheck" "eslint_d")

# Try to extract from config first
LANGUAGE_SERVERS=()
while read -r server; do
  LANGUAGE_SERVERS+=("$server")
done < <(extract_lua_array "language_servers" 2>/dev/null)

# If no servers found or error occurred, use defaults
if [ ${#LANGUAGE_SERVERS[@]} -eq 0 ]; then
  colored_echo "${YELLOW}Could not read language servers from config. Using defaults.${RESET}"
  LANGUAGE_SERVERS=("${DEFAULT_LANGUAGE_SERVERS[@]}")
fi

LINTERS=()
while read -r linter; do
  LINTERS+=("$linter")
done < <(extract_lua_array "linters" 2>/dev/null)

# If no linters found or error occurred, use defaults
if [ ${#LINTERS[@]} -eq 0 ]; then
  colored_echo "${YELLOW}Could not read linters from config. Using defaults.${RESET}"
  LINTERS=("${DEFAULT_LINTERS[@]}")
fi

# Track installed and failed items
INSTALLED_SERVERS=()
FAILED_SERVERS=()
INSTALLED_LINTERS=()
FAILED_LINTERS=()

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

# Try to install a package using a specific method
try_install_with_method() {
  local package_type="$1"  # "server" or "linter"
  local package_name="$2"
  local install_method="$3"  # "mason", "brew", "pkg", "npm", etc.
  local install_cmd="$4"     # Command to run for installation
  # Get package info from config
  local pkg_info
  pkg_info=$(get_install_method "$package_type" "$package_name" "$install_method")
  if [ -n "$pkg_info" ]; then
    if [ $QUIET_MODE -eq 0 ]; then
      echo "Installing $package_name with $install_method..."
    fi

    # All package managers now use the same command format
    if $install_cmd "$pkg_info"; then
      return 0
    fi
  fi
  return 1
}

# Handle github installation specially
try_github_install() {
  local package_name="$1"
  local github_repo="$2"

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
  return 1
}

# Update tracking lists when installation fails
update_tracking_lists() {
  local package_type="$1"
  local package_name="$2"
  local tracking_list_name="$3"
  local failed_list_name="$4"

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

  # Try OS-specific package manager first
  if [[ "$OS_TYPE" == "freebsd" ]] && command_exists pkg; then
    if try_install_with_method "$package_type" "$package_name" "pkg" "pkg install -y"; then
      return 0
    fi
  elif [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
    if try_install_with_method "$package_type" "$package_name" "brew" "brew install"; then
      return 0
    fi
  fi

  # Try various package managers
  local package_managers=("npm" "pip3" "gem" "cargo" "luarocks" "rustup")
  local commands=("npm install -g" "pip3 install" "gem install" "cargo install" "luarocks install --local" "rustup")

  for i in "${!package_managers[@]}"; do
    local pkg_manager="${package_managers[$i]}"
    local install_cmd="${commands[$i]}"

    # Skip if package manager is not available
    if ! command_exists "$pkg_manager"; then
      continue
    fi

    if try_install_with_method "$package_type" "$package_name" "$pkg_manager" "$install_cmd"; then
      return 0
    fi
  done

  # Special case for GitHub installation (only for servers currently)
  if [ "$package_type" = "server" ]; then
    local github_repo
    github_repo=$(get_install_method "server" "$package_name" "github")
    if try_github_install "$package_name" "$github_repo"; then
      return 0
    fi
  fi

  colored_echo "${RED}Failed to install $package_name - no suitable installation method found${RESET}"
  # Remove from installed list since installation failed
  update_tracking_lists "$package_type" "$package_name" "$tracking_list_name" "$failed_list_name"
  return 1
}

# Wrapper function for installing language servers
install_language_server() {
  local server="$1"
  install_package "server" "$server" "INSTALLED_SERVERS" "FAILED_SERVERS"
}

# Common function for Mason installations
mason_install_package() {
  local package_type="$1"
  local package_name="$2"
  local mason_name="${3:-$package_name}"

  if [ $QUIET_MODE -eq 0 ]; then
    echo "Installing $package_name with Mason..."
  fi

  # Check if already installed by Mason
  if [ -f "$HOME/.local/share/nvim/mason/bin/$mason_name" ] || \
     ls "$HOME/.local/share/nvim/mason/packages/$mason_name" &>/dev/null; then
    if [ $QUIET_MODE -eq 0 ]; then
      colored_echo "${GREEN}$package_name is already installed via Mason${RESET}"
    fi
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

# Install a linter using Mason
install_linter_with_mason() {
  mason_install_package "linter" "$1" "$2"
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

  # OS-specific package manager check
  if [[ "$OS_TYPE" == "freebsd" ]]; then
    if ! command_exists pkg; then
      missing+=("FreeBSD pkg package manager")
    fi
  elif [[ "$OS_TYPE" == "macos" ]]; then
    if ! command_exists brew; then
      missing+=("Homebrew (https://brew.sh/)")
    fi
  fi

  if ! command_exists npm; then
    if [[ "$OS_TYPE" == "freebsd" ]]; then
      missing+=("Node.js and npm (pkg install node npm)")
    elif [[ "$OS_TYPE" == "macos" ]]; then
      missing+=("Node.js and npm (brew install node)")
    else
      missing+=("Node.js and npm")
    fi
  fi

  if ! command_exists cargo; then
    if [[ "$OS_TYPE" == "freebsd" ]]; then
      missing+=("Rust and Cargo (pkg install rust cargo)")
    elif [[ "$OS_TYPE" == "macos" ]]; then
      missing+=("Rust and Cargo (brew install rustup-init)")
    else
      missing+=("Rust and Cargo")
    fi
  elif ! command_exists rustup; then
    warnings+=("rustup command not found, but cargo exists. Some Rust tools may not install correctly")
  fi

  if ! command_exists pip3; then
    if [[ "$OS_TYPE" == "freebsd" ]]; then
      missing+=("Python and pip (pkg install python3 py39-pip)")
    elif [[ "$OS_TYPE" == "macos" ]]; then
      missing+=("Python and pip (brew install python)")
    else
      missing+=("Python and pip")
    fi
  fi

  if ! command_exists gem; then
    if [[ "$OS_TYPE" == "freebsd" ]]; then
      missing+=("Ruby and gem (pkg install ruby rubygem-*)")
    elif [[ "$OS_TYPE" == "macos" ]]; then
      missing+=("Ruby and gem (brew install ruby)")
    else
      missing+=("Ruby and gem")
    fi
  fi

  # Display missing prerequisites
  if [ ${#missing[@]} -gt 0 ]; then
    colored_echo "${YELLOW}Missing prerequisites:${RESET}"
    for prereq in "${missing[@]}"; do
      echo "  - $prereq"
    done
    colored_echo "\n${YELLOW}Some language servers may not install correctly without these prerequisites.${RESET}"
    if [[ "$OS_TYPE" == "freebsd" ]]; then
      colored_echo "${YELLOW}Install them with pkg first for best results.${RESET}"
    elif [[ "$OS_TYPE" == "macos" ]]; then
      colored_echo "${YELLOW}Install them with Homebrew first for best results.${RESET}"
    else
      colored_echo "${YELLOW}Install them with your system's package manager for best results.${RESET}"
    fi

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
  # Define a list of common parsers in case we can't read from config
  DEFAULT_PARSERS=("lua" "vim" "vimdoc" "query" "python" "bash" "c" "cpp" "javascript" "typescript")
  
  # Try to extract from config first
  PARSERS=()
  while read -r parser; do
    PARSERS+=("$parser")
  done < <(extract_lua_array "treesitter_parsers" 2>/dev/null)
  
  # If no parsers found or error occurred, use defaults
  if [ ${#PARSERS[@]} -eq 0 ]; then
    colored_echo "${YELLOW}Could not read TreeSitter parsers from config. Using defaults.${RESET}"
    PARSERS=("${DEFAULT_PARSERS[@]}")
  fi

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
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

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
  # Only do this on macOS
  if [[ "$OS_TYPE" == "macos" ]]; then
    # Check if environment variables are already set
    if [[ -z "${HOMEBREW_NO_ENV_HINTS}" ]]; then
      export HOMEBREW_NO_ENV_HINTS=1
    fi
    if [[ -z "${HOMEBREW_NO_INSTALL_CLEANUP}" ]]; then
      export HOMEBREW_NO_INSTALL_CLEANUP=1
    fi
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
  mason_install_package "server" "$1" "$2"
}

# Main function
main() {
  colored_echo "${BOLD}=== Neovim Development Tools Installer ===${RESET}"
  if [ $QUIET_MODE -eq 0 ]; then
    echo "This script will install language servers and linters for Neovim"
    echo "Based on configuration in $HOME/.config/nvim/config/languages.lua"
    echo "Use --quiet or -q for less verbose output"
    echo "Current OS: $OS_TYPE"
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

  # Run Lazy sync to ensure all plugins are installed and up to date
  colored_echo "\n${BOLD}=== Running Lazy Sync ===${RESET}"
  colored_echo "${BLUE}Ensuring all plugins are installed and up to date...${RESET}"

  if command_exists nvim; then
    # Simple approach: Run a direct command to sync plugins non-interactively
    echo "Running Lazy sync..."

    # Run the sync command directly, with all output redirected to prevent hanging
    nvim --headless -c "lua require('lazy').sync({show = false})" -c "qa!" >/dev/null 2>&1
    # Report success
    colored_echo "${GREEN}Lazy sync completed.${RESET}"
  else
    colored_echo "${RED}Neovim not found. Skipping Lazy sync.${RESET}"
  fi

  # Final note
  colored_echo "\n${BLUE}Note: Some language servers may require additional configuration.${RESET}"
  colored_echo "${BLUE}For more information, visit: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md${RESET}"

  # Remind about nvim Mason
  colored_echo "\n${BLUE}You can manage language servers directly in Neovim with:${RESET}"
  colored_echo "${BLUE}  :Mason${RESET}"
  
  # On macOS, install SF Mono fonts if they're not already in the user's Fonts directory
  if [[ "$OS_TYPE" == "macos" ]]; then
    # Check if fonts are already installed - use safer glob check
    if ! test -n "$(find ~/Library/Fonts -name "SF-*.otf" 2>/dev/null)"; then
      colored_echo "\n${BOLD}=== Installing SF Mono Fonts ===${RESET}"
      colored_echo "${BLUE}SF Mono fonts not found in user font directory.${RESET}"
      
      # Check if source fonts exist - use safer glob check
      if test -n "$(find /System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts -name "SF-*.otf" 2>/dev/null)"; then
        # Create font directory if it doesn't exist
        mkdir -p ~/Library/Fonts
        
        # Copy fonts
        colored_echo "${BLUE}Copying SF Mono fonts from Terminal.app to ~/Library/Fonts/${RESET}"
        cp /System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SF-*.otf ~/Library/Fonts/
        
        if [ $? -eq 0 ]; then
          colored_echo "${GREEN}SF Mono fonts installed successfully.${RESET}"
        else
          colored_echo "${RED}Failed to copy SF Mono fonts.${RESET}"
        fi
      else
        colored_echo "${YELLOW}SF Mono fonts not found in Terminal.app. Skipping font installation.${RESET}"
      fi
    else
      if [ $QUIET_MODE -eq 0 ]; then
        colored_echo "\n${GREEN}SF Mono fonts are already installed in ~/Library/Fonts/${RESET}"
      fi
    fi
  fi

  # OS-specific notes
  if [[ "$OS_TYPE" == "macos" ]] && command_exists nvim-qt; then
    colored_echo "\n${BOLD}=== macOS Key Repeat Information ===${RESET}"
    colored_echo "${GREEN}Key repeat functionality for nvim-qt on macOS is now handled automatically${RESET}"
    colored_echo "${BLUE}The qt-keyrepeat-fix directory contains a DYLD injection library that fixes key repeat${RESET}"
    colored_echo "${BLUE}No additional configuration needed - the fix is applied automatically when nvim-qt starts${RESET}"
  elif [[ "$OS_TYPE" == "freebsd" ]]; then
    colored_echo "\n${BOLD}=== FreeBSD Information ===${RESET}"
    colored_echo "${BLUE}On FreeBSD, make sure the required dependencies are installed via pkg:${RESET}"
    colored_echo "${BLUE}  pkg install neovim node npm python3 py39-pip ruby${RESET}"
    colored_echo "${BLUE}FreeBSD doesn't require the macOS-specific key repeat fix${RESET}"
  fi
}

# Run the main function
main