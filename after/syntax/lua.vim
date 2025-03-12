" Vim syntax file for Lua - Terminal.app optimized version
" Language:    Lua
" Maintainer:  Wilson
" Last Change: 2024 Mar 12
" Description: Lua syntax file optimized for Terminal.app with limited color support

" Quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" Keywords
syntax keyword luaStatement        break do else elseif end for goto if in
syntax keyword luaStatement        repeat return then until while
syntax keyword luaStatement        local

syntax keyword luaOperator         and or not

" Functions
syntax keyword luaFunction         function

" Tables
syntax keyword luaTable            table
syntax match luaTableMethod        "\<table\.\(insert\|maxn\|remove\|sort\|concat\|unpack\)\>"

" String methods
syntax match luaStringMethod       "\<string\.\(byte\|char\|find\|format\|gmatch\|gsub\|len\|lower\|match\|rep\|reverse\|sub\|upper\)\>"

" Basic Lua functions
syntax keyword luaFunc             assert collectgarbage dofile error getmetatable
syntax keyword luaFunc             ipairs load loadfile next pairs pcall print
syntax keyword luaFunc             rawequal rawget rawset require select setmetatable
syntax keyword luaFunc             tonumber tostring type unpack xpcall

" Constants
syntax keyword luaConstant         nil true false

" Comments
syntax match luaComment           "--.*$" contains=luaTodo
syntax region luaComment          start="--\[\[" end="\]\]" contains=luaTodo
syntax keyword luaTodo            TODO FIXME XXX contained

" Strings
syntax region luaString           start=+'+ end=+'+ skip=+\\'+ contains=luaEscape
syntax region luaString           start=+"+ end=+"+ skip=+\\"+ contains=luaEscape
syntax region luaString           start=+\[\[+ end=+\]\]+ 

" Numbers
syntax match luaNumber            "\<\d\+\>"
syntax match luaNumber            "\<\d\+\.\d*\%([eE][-+]\=\d\+\)\=\>"
syntax match luaNumber            "\.\d\+\%([eE][-+]\=\d\+\)\=\>"
syntax match luaNumber            "\<\d\+[eE][-+]\=\d\+\>"
syntax match luaNumber            "\<0[xX][[:xdigit:].]\+\%([pP][-+]\=\d\+\)\=\>"

" Special escaped characters in strings
syntax match luaEscape            "\\[\\abfnrtv'\"]\|\\\d\{1,3}" contained
syntax match luaEscape            "\\x[[:xdigit:]]\{2}" contained

" Vim specific
syntax keyword luaVimKeyword       vim

" Neovim API
syntax match luaNeovimAPI          "\<vim\.\(api\|fn\|opt\|g\|b\|w\|o\|env\|cmd\|keymap\|notify\)\>"

" Define terminal-friendly colors (using cterm attributes)
hi def link luaStatement        Statement
hi def link luaOperator         Operator
hi def link luaFunction         Function
hi def link luaTable            Type
hi def link luaTableMethod      Function
hi def link luaStringMethod     Function
hi def link luaFunc             Function
hi def link luaConstant         Constant
hi def link luaComment          Comment
hi def link luaTodo             Todo
hi def link luaString           String
hi def link luaNumber           Number
hi def link luaEscape           Special
hi def link luaVimKeyword       Type
hi def link luaNeovimAPI        Type

" Terminal.app specific highlighting with ANSI colors
hi Statement   ctermfg=1 cterm=bold
hi Operator    ctermfg=7
hi Function    ctermfg=2 cterm=bold
hi Type        ctermfg=3 cterm=bold
hi Constant    ctermfg=5
hi Comment     ctermfg=8 cterm=italic
hi Todo        ctermfg=0 ctermbg=3
hi String      ctermfg=2
hi Number      ctermfg=5
hi Special     ctermfg=6

let b:current_syntax = "lua"