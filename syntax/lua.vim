" This syntax file is disabled in favor of treesitter
" If treesitter is not available, remove this line to re-enable
finish

if exists("b:current_syntax")
  finish
endif

" Enable 256 colors
set t_Co=256

" Keywords
syn keyword luaStatement return local function end if then else elseif do for in pairs while repeat until break
syn keyword luaOperator and or not
syn keyword luaConstant nil true false

" Functions and Variables
syn match luaFunc /\v[a-zA-Z_][a-zA-Z0-9_]*\(/
syn match luaFunc /\vfunction\s+[a-zA-Z_][a-zA-Z0-9_]*/
syn match luaTable /\v[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*/
syn match luaVar /\v[a-zA-Z_][a-zA-Z0-9_]*/

" Strings
syn region luaString start=+"+ skip=+\\\\"+ end=+"+ contains=luaSpecial
syn region luaString start=+'+ skip=+\\\\'+ end=+'+ contains=luaSpecial
syn region luaString start=+\[\[+ end=+\]\]+

" Comments
syn match luaComment /--.*$/ contains=luaTodo
syn region luaComment start=/--\[\[/ end=/\]\]/ contains=luaTodo
syn keyword luaTodo contained TODO FIXME XXX

" Numbers
syn match luaNumber /\v<\d+>/
syn match luaNumber /\v<\d+\.\d+>/
syn match luaNumber /\v<0x[\da-fA-F]+>/

" Set colors (simple, standard terminal colors)
hi def link luaStatement Magenta
hi def link luaOperator Yellow
hi def link luaConstant Cyan
hi def link luaFunc Green
hi def link luaTable Blue
hi def link luaVar White
hi def link luaString Green
hi def link luaComment Gray
hi def link luaTodo Red
hi def link luaNumber Cyan

let b:current_syntax = "lua"
