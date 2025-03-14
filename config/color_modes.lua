------------------------------------------
-- Color Modes Module
-- Handles switching between BasicMode and GUIMode
------------------------------------------

local M = {}

-- Function to set up the basic terminal mode colors and settings
function M.force_reset_syntax()
  -- Skip in headless mode
  local utils = require("config.utils")
  if utils.is_headless() then
    return
  end

  -- Using plugin-based highlighting with no buffer/filetype dependencies

  -- Store current state
  local was_gui_mode = not vim.g.basic_mode

  -- Disable treesitter highlighting when in basic mode
  if vim.fn.exists(":TSBufDisable") == 2 then
    pcall(vim.cmd, "TSBufDisable highlight")
  end

  -- Set up for basic color mode
  vim.opt.termguicolors = false
  vim.g.basic_mode = true
  vim.opt.background = "dark"

  -- Apply extensive 256-color terminal highlighting
  vim.cmd([[
    " Clear any existing highlighting
    syntax clear
    hi clear

    " Base UI colors - matching GUI mode with 256-color precision
    highlight Normal           cterm=NONE ctermfg=252 ctermbg=234
    highlight LineNr           cterm=NONE ctermfg=240 ctermbg=235
    highlight CursorLineNr     cterm=NONE ctermfg=214 ctermbg=235
    highlight CursorLine       cterm=NONE ctermfg=NONE ctermbg=236
    highlight EndOfBuffer      cterm=NONE ctermfg=237 ctermbg=234
    highlight VertSplit        cterm=NONE ctermfg=240 ctermbg=235
    highlight SignColumn       cterm=NONE ctermfg=NONE ctermbg=235
    highlight FoldColumn       cterm=NONE ctermfg=242 ctermbg=235
    highlight Folded           cterm=NONE ctermfg=242 ctermbg=235

    " Comments in green-gray
    highlight Comment          cterm=NONE ctermfg=242 ctermbg=NONE

    " Constants in various flavors: numbers, booleans, etc.
    highlight Constant         cterm=NONE ctermfg=141 ctermbg=NONE
    highlight String           cterm=NONE ctermfg=36  ctermbg=NONE
    highlight Character        cterm=NONE ctermfg=114 ctermbg=NONE
    highlight Number           cterm=NONE ctermfg=173 ctermbg=NONE
    highlight Boolean          cterm=NONE ctermfg=173 ctermbg=NONE
    highlight Float            cterm=NONE ctermfg=173 ctermbg=NONE

    " Identifiers: variables, functions
    highlight Identifier       cterm=NONE ctermfg=81  ctermbg=NONE
    highlight Function         cterm=NONE ctermfg=81  ctermbg=NONE

    " Statements: conditionals, loops, etc.
    highlight Statement        cterm=NONE ctermfg=204 ctermbg=NONE
    highlight Conditional      cterm=NONE ctermfg=204 ctermbg=NONE
    highlight Repeat           cterm=NONE ctermfg=204 ctermbg=NONE
    highlight Label            cterm=NONE ctermfg=204 ctermbg=NONE
    highlight Operator         cterm=NONE ctermfg=204 ctermbg=NONE
    highlight Keyword          cterm=NONE ctermfg=204 ctermbg=NONE
    highlight Exception        cterm=NONE ctermfg=204 ctermbg=NONE

    " Preprocessor: macros, includes
    highlight PreProc          cterm=NONE ctermfg=176 ctermbg=NONE
    highlight Include          cterm=NONE ctermfg=176 ctermbg=NONE
    highlight Define           cterm=NONE ctermfg=176 ctermbg=NONE
    highlight Macro            cterm=NONE ctermfg=176 ctermbg=NONE
    highlight PreCondit        cterm=NONE ctermfg=176 ctermbg=NONE

    " Types: int, char, etc.
    highlight Type             cterm=NONE ctermfg=81  ctermbg=NONE
    highlight StorageClass     cterm=NONE ctermfg=81  ctermbg=NONE
    highlight Structure        cterm=NONE ctermfg=81  ctermbg=NONE
    highlight Typedef          cterm=NONE ctermfg=81  ctermbg=NONE

    " Special characters
    highlight Special          cterm=NONE ctermfg=117 ctermbg=NONE
    highlight SpecialChar      cterm=NONE ctermfg=117 ctermbg=NONE
    highlight Tag              cterm=NONE ctermfg=117 ctermbg=NONE
    highlight Delimiter        cterm=NONE ctermfg=245 ctermbg=NONE
    highlight SpecialComment   cterm=NONE ctermfg=242 ctermbg=NONE
    highlight Debug            cterm=NONE ctermfg=225 ctermbg=NONE

    " Visual selection
    highlight Visual           cterm=NONE ctermfg=NONE ctermbg=59
    highlight Search           cterm=NONE ctermfg=232 ctermbg=215
    highlight IncSearch        cterm=NONE ctermfg=232 ctermbg=33
    highlight MatchParen       cterm=bold ctermfg=214 ctermbg=NONE

    " Status line and tabs
    highlight StatusLine       cterm=NONE ctermfg=252 ctermbg=238
    highlight StatusLineNC     cterm=NONE ctermfg=240 ctermbg=236
    highlight TabLine          cterm=NONE ctermfg=240 ctermbg=236
    highlight TabLineFill      cterm=NONE ctermfg=240 ctermbg=236
    highlight TabLineSel       cterm=NONE ctermfg=252 ctermbg=238

    " Code structure for programming languages
    highlight Title            cterm=NONE ctermfg=214 ctermbg=NONE
    highlight Underlined       cterm=underline ctermfg=81 ctermbg=NONE
    highlight Todo             cterm=bold ctermfg=228 ctermbg=234
    highlight Error            cterm=NONE ctermfg=203 ctermbg=234
    highlight ErrorMsg         cterm=NONE ctermfg=203 ctermbg=234
    highlight WarningMsg       cterm=NONE ctermfg=214 ctermbg=234
    highlight Question         cterm=NONE ctermfg=81 ctermbg=NONE
    highlight Directory        cterm=NONE ctermfg=81 ctermbg=NONE

    " Non-text and whitespace
    highlight NonText          cterm=NONE ctermfg=237 ctermbg=NONE
    highlight SpecialKey       cterm=NONE ctermfg=237 ctermbg=NONE
    highlight Whitespace       cterm=NONE ctermfg=237 ctermbg=NONE

    " Completion menu
    highlight Pmenu            cterm=NONE ctermfg=252 ctermbg=238
    highlight PmenuSel         cterm=NONE ctermfg=232 ctermbg=214
    highlight PmenuSbar        cterm=NONE ctermfg=NONE ctermbg=240
    highlight PmenuThumb       cterm=NONE ctermfg=NONE ctermbg=252

    " Diffs
    highlight DiffAdd          cterm=NONE ctermfg=NONE ctermbg=22
    highlight DiffChange       cterm=NONE ctermfg=NONE ctermbg=24
    highlight DiffDelete       cterm=NONE ctermfg=NONE ctermbg=52
    highlight DiffText         cterm=NONE ctermfg=NONE ctermbg=60

    " Spell checking
    highlight SpellBad         cterm=undercurl ctermfg=203 ctermbg=NONE
    highlight SpellCap         cterm=undercurl ctermfg=33 ctermbg=NONE
    highlight SpellRare        cterm=undercurl ctermfg=117 ctermbg=NONE
    highlight SpellLocal       cterm=undercurl ctermfg=36 ctermbg=NONE

    " Messages
    highlight ModeMsg          cterm=bold ctermfg=214 ctermbg=NONE
    highlight MoreMsg          cterm=bold ctermfg=36 ctermbg=NONE

    " Diagnostic highlights
    highlight DiagnosticError       cterm=NONE ctermfg=203 ctermbg=NONE
    highlight DiagnosticWarn        cterm=NONE ctermfg=214 ctermbg=NONE
    highlight DiagnosticInfo        cterm=NONE ctermfg=33 ctermbg=NONE
    highlight DiagnosticHint        cterm=NONE ctermfg=36 ctermbg=NONE
    highlight DiagnosticUnderlineError cterm=underline ctermfg=203 ctermbg=NONE
    highlight DiagnosticUnderlineWarn  cterm=underline ctermfg=214 ctermbg=NONE
    highlight DiagnosticUnderlineInfo  cterm=underline ctermfg=33 ctermbg=NONE
    highlight DiagnosticUnderlineHint  cterm=underline ctermfg=36 ctermbg=NONE
  ]])

  -- If this was a GUI -> Terminal switch, do a full reload
  if was_gui_mode then
    -- Force reload current filetype to refresh syntax settings
    if vim.bo.filetype and vim.bo.filetype ~= "" then
      local ft = vim.bo.filetype
      vim.cmd("set ft=")
      vim.cmd("set ft=" .. ft)
    end
  end
end

-- Set up the commands for switching modes
function M.setup_commands()
  -- Basic ANSI 256 color mode
  vim.api.nvim_create_user_command("BasicMode", function()
    -- Mark that we're explicitly running the command
    vim.g.explicit_mode_change = true
    -- Apply the syntax
    pcall(M.force_reset_syntax)
    -- Only notify after Vim is fully started
    if vim.v.vim_did_enter == 1 then
      vim.notify("Basic color mode applied", vim.log.levels.INFO)
    end
    -- Clear the flag
    vim.g.explicit_mode_change = nil
  end, {})

  -- GUI mode with true colors and TreeSitter
  vim.api.nvim_create_user_command("GUIMode", function()
    -- Mark that we're explicitly running the command
    vim.g.explicit_mode_change = true
    -- Enable GUI mode with tree-sitter
    vim.g.basic_mode = false
    vim.opt.termguicolors = true

    -- Set guifont if in a GUI environment
    local utils = require("config.utils")
    if utils.is_gui_environment() then
      -- Load the fonts module
      local fonts = require("config.fonts")

      -- Pre-validate fonts to avoid "Unknown font" warnings
      -- This checks for font files without trying to set the fonts
      fonts.prevalidate_fonts()

      -- Now set the best available font from pre-validated options
      -- This prevents any warnings or errors from nvim-qt
      fonts.set_best_font()
    end
    -- Make sure the colorscheme is available by checking if the plugin path exists
    local plugin_path = vim.fn.expand("~/.local/share/nvim/lazy/little-wonder")
    if vim.fn.isdirectory(plugin_path) ~= 0 then
      pcall(vim.cmd, "colorscheme lw-rubber")
    else
      vim.notify("little-wonder plugin not found. Colorscheme not applied.", vim.log.levels.WARN)
    end

    -- Enable treesitter highlighting
    if vim.fn.exists(":TSBufEnable") == 2 then
      pcall(vim.cmd, "TSBufEnable highlight")
      -- Also enable highlighting for all installed parsers
      pcall(function()
        local parsers = require("nvim-treesitter.parsers")
        local installed = parsers.available_parsers()
        for _, parser in ipairs(installed) do
          pcall(vim.cmd, "TSEnable highlight " .. parser)
        end
      end)
    end

    -- Fire an event that other code can hook into
    vim.api.nvim_exec_autocmds("User", { pattern = "GUIModeApplied" })

    -- Only notify after Vim is fully started
    if vim.v.vim_did_enter == 1 then
      vim.notify("Switched to GUI mode with tree-sitter highlights", vim.log.levels.INFO)
    end
    -- Clear the flag
    vim.g.explicit_mode_change = nil
  end, {})
end

-- Setup color mode autocmds
function M.setup_autocmds()
  -- Add a special event for nvim-qt GUI detection
  vim.api.nvim_create_autocmd("User", {
    pattern = {"GuiLoaded", "GUIEnter"},
    callback = function()
      -- Mark nvim-qt as detected
      vim.g.nvim_qt_detected = true

      -- Switch to GUI mode immediately for nvim-qt
      if vim.g.basic_mode then
        vim.schedule(function()
          pcall(vim.cmd, "GUIMode")
        end)
      end
    end,
    desc = "Enable GUI mode for nvim-qt"
  })

  -- Create a dedicated event handler for GUI font and appearance settings
  vim.api.nvim_create_autocmd("User", {
    pattern = {"GuiLoaded", "GUIEnter"},
    callback = function()
      -- Use dedicated font handling module for fonts
      local fonts = require("config.fonts")

      -- Pre-validate fonts first to avoid "Unknown font" warnings in nvim-qt
      fonts.prevalidate_fonts()

      -- Now set the best available font from pre-validated options
      fonts.set_best_font()

      -- Apply GUI appearance settings
      if vim.fn.exists("*GuiLinespace") == 1 then
        vim.cmd("GuiLinespace 1")
      end

      -- Disable GUI popup menu to use nvim's native popup
      if vim.fn.exists("*GuiPopupmenu") == 1 then
        vim.cmd("GuiPopupmenu 0")
      end

      -- Disable GUI tabline to use nvim's native tabline
      if vim.fn.exists("*GuiTabline") == 1 then
        vim.cmd("GuiTabline 0")
      end

      -- macOS specific settings
      if vim.fn.has("macunix") == 1 and vim.fn.exists("*GuiMacPrefix") == 1 then
        -- Use Option/Alt key as the GUI prefix (instead of Command)
        vim.cmd("GuiMacPrefix e")
      end
    end,
    desc = "Configure GUI fonts and appearance"
  })

  -- Standard color mode checking for other events
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      -- Don't run if already handled
      if vim.g.explicit_mode_change or vim.g._init_colors_done then
        return
      end

      -- Check for GUI environment
      local utils = require("config.utils")
      local in_gui = utils.is_gui_environment()

      -- Auto-switch to GUI mode when in GUI environment
      if in_gui and vim.g.basic_mode then
        -- Switch to GUI mode quietly
        local old_notify = vim.notify
        vim.notify = function() end
        pcall(vim.cmd, "GUIMode")
        vim.notify = old_notify
      end

      -- Mark as initialized
      vim.g._init_colors_done = true
    end,
    desc = "Auto-detect GUI environment at startup",
  })
end

-- Initialize terminal mode by default
function M.init()
  -- Default to basic color mode (users can switch to GUI mode later)
  vim.opt.termguicolors = false  -- Disable true colors for basic compatibility
  vim.opt.background = "dark"    -- Use dark mode for better contrast

  -- Create a global variable to track which mode we're in
  vim.g.basic_mode = true

  -- Setup autocmds and commands
  M.setup_autocmds()
  M.setup_commands()
end

return M
