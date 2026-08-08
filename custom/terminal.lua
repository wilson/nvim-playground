local M = {}

function M.apply_256_fallback_syntax()
  vim.cmd([[
    " Clear existing highlight groups, but preserve syntax match rules
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

    " Diffs (vimdiff)
    highlight DiffAdd          cterm=NONE ctermfg=NONE ctermbg=22
    highlight DiffChange       cterm=NONE ctermfg=NONE ctermbg=24
    highlight DiffDelete       cterm=NONE ctermfg=NONE ctermbg=52
    highlight DiffText         cterm=NONE ctermfg=NONE ctermbg=60

    " Git commits and diff files
    highlight gitcommitSummary   cterm=bold ctermfg=252 ctermbg=NONE
    highlight gitcommitOverflow  cterm=NONE ctermfg=203 ctermbg=NONE
    highlight gitcommitBlank     cterm=NONE ctermfg=203 ctermbg=NONE
    highlight gitcommitComment   cterm=NONE ctermfg=242 ctermbg=NONE
    highlight gitcommitHeader    cterm=NONE ctermfg=176 ctermbg=NONE
    highlight gitcommitFile      cterm=bold ctermfg=81  ctermbg=NONE
    highlight gitcommitType      cterm=NONE ctermfg=214 ctermbg=NONE
    highlight gitcommitBranch    cterm=bold ctermfg=204 ctermbg=NONE

    highlight diffAdded          cterm=NONE ctermfg=114 ctermbg=NONE
    highlight diffRemoved        cterm=NONE ctermfg=203 ctermbg=NONE
    highlight diffFile           cterm=bold ctermfg=81  ctermbg=NONE
    highlight diffNewFile        cterm=bold ctermfg=114 ctermbg=NONE
    highlight diffIndexLine      cterm=NONE ctermfg=81  ctermbg=NONE
    highlight diffLine           cterm=NONE ctermfg=117 ctermbg=NONE
    highlight diffSubname        cterm=NONE ctermfg=242 ctermbg=NONE

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
end

function M.apply_terminal_mode(theme)
  local utils = require("custom.utils")
  if utils.is_headless() then
    return
  end

  local was_gui_mode = not vim.g.terminal_mode

  if vim.fn.exists(":TSBufDisable") == 2 then
    pcall(vim.cmd, "TSBufDisable highlight")
  end

  vim.opt.termguicolors = false
  vim.g.terminal_mode = true
  vim.opt.background = "dark"

  if theme then
    local ok = pcall(vim.cmd, "colorscheme " .. theme)
    if not ok then
      vim.notify("Colorscheme '" .. theme .. "' not found. Colorscheme not applied.", vim.log.levels.WARN)
    end
  end

  M.apply_256_fallback_syntax()

  if was_gui_mode then
    if vim.bo.filetype and vim.bo.filetype ~= "" then
      local ft = vim.bo.filetype
      vim.cmd("set ft=")
      vim.cmd("set ft=" .. ft)
    end
  end
end

return M
