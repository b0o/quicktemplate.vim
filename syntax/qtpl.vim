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
    \ s:pb.agrp(['s', 'd', 'f', 'v', 'z']),
    \ s:pb.grp(
      \ s:pb.agrp(['q', 'j', 'u']),
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

      " \ s:pb.nla(s:pb.grp(s:pb.agrp([s:pats.plainTagMods, s:pats.funcTagMods]), '\S')),
      " \ s:pb.nla(s:pb.grp(s:pb.agrp([s:pats.plainTagMods, s:pats.funcTagMods]), '\S')),

      " \ s:pb.nla(s:pb.grp(s:pb.agrp([s:pats.plainTagMods, s:pats.funcTagMods]), '\S'))

  " \ s:sb.match('tag_mods_plain',
  "   \ s:pb.make(pb.pla(s:pats.tagOpen), s:pats.plainTagMods),
  "   \ 'contained'
  " \ ),

" let g:foo = s:syns

hi def link qtpl_region_outer           Comment
hi def link qtpl_keyword_todo           Underlined
hi def link qtpl_tag_open               SpecialChar
hi def link qtpl_tag_mods_func          String
hi def link qtpl_tag_mods_plain         Number
hi def link qtpl_tag_mods_error         Error
hi def link qtpl_tag_close              SpecialChar

" call s:syns.exec()

" \ 'foo'
" \ )
"
" \ s:sb.match('tag_open', s:pb.make(s:pats.tagOpen, s:pats.plainTagMods), '')

" let s:synQtplOpenTag  = 'syn match qtplOpenTag '
" let s:synQtplOpenTag .= s:pb.make(s:pats.tagOpen, s:pats.plainTagMods)
" let s:synQtplOpenTag .= ' contained'
" let s:synQtplOpenTag .= ' skipnl'




" let g:qtpl_debug = s:synQtplOpenTag


" execute s:synQtplOpenTag



" let s:pats.catTag             = 'cat\s+"\\\\\|\\"'

" let s:pat = '/' . s:pats.tagOpen . '\(\([svdfqzju]=\?\)\|\([sqju]\(z=\?\)\?\)\|\(=\([uqj]\?[h]\?\)\?\)\)\?\_s\{1,}/'


" let s:pat = s:make_pat(s:pats.tagOpen) " , s:pats.tagMods)
" let g:qtpl_debug = s:pat
" syn region qtplGoCodeRegion
"   \ contains=@qtplGo
"   \ contained
"   \ start=/{%\(\([svdfqzju]=\?\)\|\([sqju]\(z=\?\)\?\)\|\(=\([uqj]\?[h]\?\)\?\)\)\?\_s\{1,}/
"   \ end=/%}/
"   " \ matchgroup=qtplDelim
"
" syn region qtplPlainRegion
"   \ contains=@qtplHtml
"   \ contained
"   \ start=/{%\(\(\([svdfqzju]=\?\)\|\([sqju]\(z=\?\)\?\)\|\(=\([uqj]\?[h]\?\)\?\)\)\?\_s\{1,}\)\_s\{0,}plain\_s\{0,}%}/
"   \ end=/{%\_s\{0,}endplain\_s\{0,}%}/
"   " \ matchgroup=qtplTag
"
" syn region qtplFuncRegion
"   \ contains=@qtplHtml,qtplGoCodeRegion,qtplPlainRegion
"   \ contained
"   \ start=/{%\(\(\([svdfqzju]=\?\)\|\([sqju]\(z=\?\)\?\)\|\(=\([uqj]\?[h]\?\)\?\)\)\?\_s\{1,}\)\_s\{0,}func\s\{1,}\h\w\{0,}\s\{0,}(.*)\s\{0,}%}/
"   \ end=/{%\_s\{0,}endfunc\_s\{0,}%}/
"   " \ matchgroup=qtplTag
"
" hi def link qtplTag           SpecialChar
" hi def link qtplDelim         SpecialChar

let b:current_syntax = "qtpl"

" Leftover regexes and experiments:
"
" \([0-9A-Za-z_,\s]\{0,}\)\{0,}
" \(\s\{0,}\h\w\{0,}\s{0,}\h\w\{0,}\s{0,}\)\{0,}
" syn region qtplPlainRegion  matchgroup=qtplTag start=/{%\(\([svdfqzjuh=]\)\{,3}\_s\{1,}\)\?plain\_s\{0,}%}/ end=/{%\_s\{0,}endplain\_s\{0,}%}/ contained contains=@qtplHtml
" syn region qtplFuncRegion   matchgroup=qtplTag start=/{%\(\([svdfqzjuh=]\)\{,3}\_s\{1,}\)\?func\s{1,}\w\{1}\_s{0,}%}/ end=/{%\_s\{0,}endfunc\_s\{0,}%}/ contained contains=@qtplHtml
"
"
" hi def link qtplTag       Number
" hi def link qtplKeyword   Keyword
" hi def link GoCodeRegion NONE
"
"
" Paired tags which contain output text/html
" includes {% func %} and {% plain %}
"
" syn region qtplGoCodeRegion start="{%\([svdfqzjuh=]\)\{,3}\<\(end\(func\|plain\)\)\@!"rs=e,hs=e keepend end="%}"re=s,he=s-1 contains=@qtplGo contained
"
" syn region qtplOutputTagRegion start="{%\([svdfqzjuh=]\)\{0,3}\_s\z(func\|plain\)\_s.*\_s%}\C" keepend end="{%\_send\z1\_s%}" contains=@qtplHtml,qtplGoCodeRegion contained
"
"
" syn keyword     qtplKeyword        endfunc endplain
"
" syn match qtplTag /{%/
" syn match qtplTag /%}/ contained display
"
" syn match qtplTag /{%/


" vim: sw=2 ts=2 et
