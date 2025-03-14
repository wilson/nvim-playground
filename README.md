# Neovim Configuration

A modular Neovim configuration with support for GUI and terminal environments.

## Features

- Modular design with clean separation of concerns
- Automatic GUI detection with enhanced features
- Language server integration via Mason
- Configurable color modes for different environments

## Installation

```bash
# Install language servers, linters, and TreeSitter parsers
./install_dev_tools.sh
```

## Commands

- `:BasicMode` - Switch to basic ANSI colors
- `:GUIMode` - Switch to GUI mode with true colors
- `:ColorAnalyze` - Analyze color scheme information
- `:Diagnostics` - Show terminal and system diagnostics