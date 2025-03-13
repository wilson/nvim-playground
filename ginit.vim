" This is the GUI-specific configuration file for Neovim
" It's loaded after init.lua when running in GUI mode (like nvim-qt)

" macOS specific settings
if has('macunix')
  " Use Option/Alt key as the GUI prefix (instead of Command)
  if exists('g:GuiLoaded')
    GuiMacPrefix e
  endif
endif

" Set GUI font if running in a GUI
if exists('g:GuiLoaded')
  " For nvim-qt
  GuiFont SF Mono:h11

  " Set appropriate line spacing
  GuiLinespace 1

  " Disable GUI popup menu to use nvim's native popup
  GuiPopupmenu 0

  " Disable GUI tabline to use nvim's native tabline
  GuiTabline 0
elseif exists('g:neovide')
  " For neovide
  set guifont=SF\ Mono:h11
  " Neovide-specific settings can go here
endif
