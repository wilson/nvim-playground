" Vim syntax file for Rust - Terminal.app optimized version
" Language:    Rust
" Maintainer:  Wilson
" Last Change: 2024 Mar 12
" Description: Rust syntax file optimized for Terminal.app with limited color support

" Quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" Keywords
syntax keyword rustKeyword          break continue else for if in let loop 
syntax keyword rustKeyword          match return while where use pub mod crate
syntax keyword rustKeyword          unsafe extern unsafe async await move

syntax keyword rustConditional      if else
syntax keyword rustRepeat           loop while for
syntax keyword rustTypedef          type
syntax keyword rustStructure        struct enum union trait impl
syntax keyword rustOperator         as

" Functions and macros
syntax keyword rustFunction         fn
syntax match   rustMacro            "\w\+!"

" Storage classes
syntax keyword rustStorageClass     static const mut ref

" Error handling
syntax keyword rustException        panic unwrap expect
syntax match   rustResult           "Ok\|Err"
syntax match   rustOption           "Some\|None"

" Types
syntax keyword rustType             i8 i16 i32 i64 i128 isize
syntax keyword rustType             u8 u16 u32 u64 u128 usize
syntax keyword rustType             f32 f64 bool char str
syntax keyword rustType             Box Vec String
syntax match   rustType             "&'*\w\+"

" Self
syntax keyword rustSelf             self Self

" Constants
syntax keyword rustConstant         true false

" Comments
syntax match rustComment            "//.*$" contains=rustTodo
syntax region rustComment           start="/\*" end="\*/" contains=rustTodo
syntax keyword rustTodo             TODO FIXME XXX contained

" Strings
syntax region rustString            start=+"+ end=+"+ skip=+\\"+ contains=rustEscape
syntax region rustString            start='r\z(#*\)"' end='"\z1'

" Characters
syntax match rustChar               "'[^'\\]'"
syntax match rustChar               "'\\[nrt0']'"
syntax match rustChar               "'\\x[[:xdigit:]]\{2}'"
syntax match rustChar               "'\\u{[[:xdigit:]]\{1,6}}'"

" Numbers
syntax match rustNumber             "\<[0-9][0-9_]*\>"
syntax match rustNumber             "\<0x[[:xdigit:]_]\+\>"
syntax match rustNumber             "\<0o[0-7_]\+\>"
syntax match rustNumber             "\<0b[01_]\+\>"
syntax match rustNumber             "\<[0-9][0-9_]*\(\.[0-9][0-9_]*\)\?\([eE][+-]\?[0-9_]\+\)\?\>"

" Special escaped characters in strings
syntax match rustEscape             contained "\\[nr\"']"
syntax match rustEscape             contained "\\x\x\{2}"
syntax match rustEscape             contained "\\u{\x\{1,6}}"

" Special attributes
syntax region rustAttribute         start="#!\?\[" end="\]" contains=rustString

" Link definitions
hi def link rustKeyword            Keyword
hi def link rustConditional        Conditional
hi def link rustRepeat             Repeat
hi def link rustTypedef            Typedef
hi def link rustStructure          Structure
hi def link rustOperator           Operator
hi def link rustFunction           Function
hi def link rustMacro              Macro
hi def link rustStorageClass       StorageClass
hi def link rustException          Exception
hi def link rustResult             Special
hi def link rustOption             Special
hi def link rustType               Type
hi def link rustSelf               Special
hi def link rustConstant           Constant
hi def link rustComment            Comment
hi def link rustTodo               Todo
hi def link rustString             String
hi def link rustChar               Character
hi def link rustNumber             Number
hi def link rustEscape             Special
hi def link rustAttribute          PreProc

" Terminal.app specific highlighting using ANSI colors (0-15)
hi Keyword      ctermfg=1 cterm=bold
hi Conditional  ctermfg=1 cterm=bold
hi Repeat       ctermfg=1 cterm=bold
hi Typedef      ctermfg=3 cterm=bold
hi Structure    ctermfg=3 cterm=bold
hi Operator     ctermfg=7
hi Function     ctermfg=2 cterm=bold
hi Macro        ctermfg=5 cterm=bold
hi StorageClass ctermfg=1
hi Exception    ctermfg=1 cterm=bold
hi Special      ctermfg=6
hi Type         ctermfg=3 cterm=bold
hi Constant     ctermfg=5
hi Comment      ctermfg=8 cterm=italic
hi Todo         ctermfg=0 ctermbg=3
hi String       ctermfg=2
hi Character    ctermfg=2
hi Number       ctermfg=5
hi PreProc      ctermfg=6

let b:current_syntax = "rust"