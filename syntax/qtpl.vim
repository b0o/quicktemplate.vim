" qtpl.vim: Vim syntax file for Quicktemplate syntax

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" Load embedded syntaxes
syn include @qtplGo   syntax/go.vim
unlet! b:current_syntax
syn include @qtplHtml syntax/html.vim
unlet! b:current_syntax

" Instantiate new builder objects
let s:pb = pb#new('+')
let s:sb = sb#new('qtpl_')

""" PATTERNS

" Building blocks of patterns for Quicktemplate syntax
let s:pats                      = {}

let s:pats.bof                  = '\%^'
let s:pats.eof                  = '\%$'

let s:pats.tagOpen              = '{%'
let s:pats.tagClose             = '%}'

let s:pats.blockEnd             = 'end'

let s:pats.blocks               = {}

let s:pats.blocks.func          = 'func'
let s:pats.blocks.comment       = 'comment'
let s:pats.blocks.plain         = 'plain'
let s:pats.blocks.collapseSpace = 'collapsespace'
let s:pats.blocks.stripSpace    = 'stripspace'
let s:pats.blocks.switch        = 'switch'
let s:pats.blocks.case          = 'case'
let s:pats.blocks.default       = 'default'

let s:pats.blocks.codeTag       = 'code'
let s:pats.blocks.packageTag    = 'package'
let s:pats.blocks.importTag     = 'import'
let s:pats.blocks.catTag        = 'cat'
let s:pats.blocks.interfaceTag  = 'interface'

" Modifiers for tags which specify output behavior of the tag
" Similar to printf verbs
let s:pats.plainTagMods =
\ s:pb.grp(
  \ s:pb.agrp(
    \ s:pb.agrp('s', 'd', 'f', 'v', 'z'),
    \ s:pb.grp(
      \ s:pb.agrp('q', 'j', 'u'),
      \ s:pb.opt('z')
    \ ),
  \ ),
  \ s:pb.opt('=')
\ )

" Modifiers for func tags which specify output behavior of the tag
" Similar to printf verbs
let s:pats.funcTagMods =
\ s:pb.grp(
  \ '=',
  \ s:pb.opt(s:pb.agrp('q', 'j', 'u')),
  \ s:pb.opt('h')
\ )

""" SYNTAX

" Everything in the outermost scope is considered a comment
call s:sb.region('region_outer',
  \ s:pb.make(s:pats.bof),
  \ s:pb.make(s:pats.eof),
  \ 'contains=CONTAINED'
\ )

" Keywords like TODO in the outer region
call s:sb.keyword('keyword_todo',
  \ 'contained',
  \ 'containedby=' . s:sb.ref('region_outer'),
  \ 'TODO FIXME XXX BUG NOTE'
\ )

" Opening sequence for qtpl tags
" Ex:
" {%=uh Foo() %}
" ^^
call s:sb.match('tag_open',
  \ s:pb.make(s:pats.tagOpen),
  \ 'contained'
\ )

" Closing sequence for qtpl tags
" Ex:
" {%=uh Foo() %}
"             ^^
call s:sb.match('tag_close',
  \ s:pb.make(s:pats.tagClose),
  \ 'contained'
\ )

" Modifiers which can appear after an
" opening sequence of an opening qtpl tag
" of the plain catagory (TODO: Reword this)
" Closing sequence for qtpl tags
" Ex:
" {%s= mystr %}
"   ^^
call s:sb.match('tag_mods_plain',
  \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen)), s:pats.plainTagMods, s:pb.pla('\_s')),
  \ 'contained'
\ )

" Modifiers which can appear after an
" opening sequence of an opening qtpl
" function call tag
" Ex:
" {%=uh myFunc() %}
"   ^^^
call s:sb.match('tag_mods_func',
  \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen)), s:pats.funcTagMods, s:pb.pla('\_s')),
  \ 'contained'
\ )

" Any invalid sequence adjacent to an
" opening qtpl tag sequence
" Ex:
" {%nope myFunc() %}
"   ^^^^
" TODO: shouldn't match in cases where a valid
" tag keyword is directly adjacent to its opening
" tag sequence in certain cases
" Ex: (should not match)
" {%plain%}
call s:sb.match('tag_mods_error',
  \ s:pb.make(
    \ s:pb.plb(s:pb.grp(s:pats.tagOpen)),
    \ s:pb.nla(s:pb.grp(s:pb.agrp(s:pats.plainTagMods, s:pats.funcTagMods), '\_s')),
    \ '\S\+',
    \ s:pb.pla('\_s')
  \ ),
  \ 'contained'
\ )

call s:sb.exec()

hi def link qtpl_region_outer           Comment
hi def link qtpl_keyword_todo           Underlined
hi def link qtpl_tag_open               SpecialChar
hi def link qtpl_tag_mods_func          String
hi def link qtpl_tag_mods_plain         Number
hi def link qtpl_tag_mods_error         Error
hi def link qtpl_tag_close              SpecialChar

let b:current_syntax = "qtpl"

" vim: sw=2 ts=2 et
