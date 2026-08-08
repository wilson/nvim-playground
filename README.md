# Neovim Configuration

A modular Neovim configuration with support for GUI and terminal environments.

## Features

- Cross-platform on macOS, FreeBSD, Linux, and Windows (MSYS2)
- Modular design with clean separation of concerns
- Automatic GUI detection with enhanced features
- Language server integration via Mason
- Configurable color modes for different environments

## Installation

```sh
# Install language servers, linters, and TreeSitter parsers
make install
```

## Commands

- `:TerminalMode` - Switch to basic ANSI colors
- `:GUIMode` - Switch to GUI mode with true colors
- `:ColorAnalyze` - Analyze color scheme information
- `:Diagnostics` - Show terminal and system diagnostics

## Development

```sh
# Run shellcheck and luacheck on the relevant files
make lint
```
