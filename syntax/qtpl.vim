" qtpl.vim: Vim syntax file for Quicktemplate syntax

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" Don't source the plug-in when it's already been loaded or &compatible is set.
if &cp || exists('g:loaded_quicktemplate')
  finish
endif

" Ensure builder.vim has been loaded
try
  call type(g:builder#version)
catch
  echomsg "Warning: The plugin 'quicktemplate.vim' depends on the plugin 'builder.vim' which seems not to be installed! For more information please review the installation instructions in the README."
  let g:loaded_quicktemplate = 1
  finish
endtry

" Load embedded syntaxes
syn include @qtpl_syn_go   syntax/go.vim
unlet! b:current_syntax
syn include @qtpl_syn_html syntax/html.vim
unlet! b:current_syntax

" Instantiate new builder objects
let s:pb = pb#new('+')
let s:sb = sb#new('qtpl_')

""" PATTERNS

" Building blocks of patterns for Quicktemplate syntax
let s:pats = {}

let s:pats.bof      = '\%^'
let s:pats.eof      = '\%$'
let s:pats.tagOpen  = '{%'
let s:pats.tagClose = '%}'

let s:pats.todo     = s:pb.grp(s:pb.agrp('TODO', 'FIXME', 'XXX', 'BUG', 'NOTE'), s:pb.opt(':'))

" tags are singlular quicktemplate directives with no inner
" container.
let s:pats.tags           = {}
let s:pats.tags.code      = 'code'
let s:pats.tags.package   = 'package'
let s:pats.tags.import    = 'import'
let s:pats.tags.cat       = 'cat'
let s:pats.tags.interface = s:pb.agrp('interface', 'iface')
let s:pats.tags.case      = 'case'
let s:pats.tags.default   = 'default'
let s:pats.tags.newline   = 'newline'
let s:pats.tags.space     = 'space'

" blocks are pairs of quicktemplate tags (an opening tag and a closing tag)
" which contain additional code
let s:pats.blocks               = {}
let s:pats.blockEnd             = 'end'

let s:pats.blocks.func          = 'func'
let s:pats.blocks.comment       = 'comment'
let s:pats.blocks.plain         = 'plain'
let s:pats.blocks.collapseSpace = 'collapsespace'
let s:pats.blocks.stripSpace    = 'stripspace'
let s:pats.blocks.switch        = 'switch'
let s:pats.blocks.if            = 'if'

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
call s:sb.region('global',
  \ s:pb.make(s:pats.bof),
  \ s:pb.make(s:pats.eof),
\ )

" Keywords like TODO in the outer region
call s:sb.match('match_todo',
  \ s:pb.make(s:pats.todo),
  \ s:sb.contained('global'),
\ )

call s:sb.match('tag_open',
  \ s:pb.make(s:pats.tagOpen),
  \ s:sb.contained('global'),
  \ s:sb.next('@tag_keyword'),
  \ 'skipwhite',
  \ 'skipnl',
\ )

for [k, v] in items(s:pats.blocks)
  let start_keyword = 'tag_' . v . '_start_keyword'
  let start_close   = 'tag_' . v . '_start_close'
  let body          = 'tag_' . v . '_body'
  let end_open      = 'tag_' . v . '_end_open'
  let end_keyword   = 'tag_' . v . '_end_keyword'
  let end_close     = 'tag_' . v . '_end_close'

  " Match the keyword, e.g.:
  " {% plain %}
  "    ^^^^^
  call s:sb.keyword(start_keyword,
    \ v,
    \ s:sb.contained(),
    \ s:sb.next(start_close),
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_keyword',       [start_keyword])
  call s:sb.clusteradd('tag_start_keyword', [start_keyword])
  call s:sb.hi(start_keyword, 'Keyword')

  " Match the tag closing sequence, e.g.:
  " {% plain %}
  "          ^^
  "   this is inside the plain tag...
  " {% endplain %}
  call s:sb.match(start_close,
    \ s:pb.make(s:pats.tagClose),
    \ s:sb.contained(),
    \ s:sb.next(body),
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_close',       [start_close])
  call s:sb.clusteradd('tag_start_close', [start_close])
  call s:sb.hi(start_close, 'SpecialChar')

  " Match the tag body, e.g.:
  " {% plain %}
  "   this is inside the plain tag...
  " ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  " {% endplain %}
  call s:sb.region(body,
    \ s:pb.make('.'),
    \ s:pb.make(
      \ s:pats.tagOpen,
      \ '\_s*',
      \ s:pats.blockEnd . v,
      \ '\_s*',
      \ s:pats.tagClose
    \ ) . 'me=s-2',
    \ s:sb.contained(),
    \ s:sb.next(end_open),
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_body', [body])
  call s:sb.hi(body, 'String') " TODO

  " Match the end tag opening sequence, e.g.:
  " {% plain %}
  "   this is inside the plain tag...
  " {% endplain %}
  " ^^
  call s:sb.match(end_open,
    \ s:pb.make(s:pats.tagOpen),
    \ s:sb.contained(),
    \ s:sb.next(end_keyword),
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_open',       [end_open])
  call s:sb.clusteradd('tag_end_open',   [end_open])
  call s:sb.hi(end_open, 'SpecialChar')

  " Match the end keyword, e.g.:
  " {% plain %}
  "   this is inside the plain tag...
  " {% endplain %}
  "    ^^^^^^^^
  call s:sb.keyword(end_keyword,
    \ s:pats.blockEnd . v,
    \ s:sb.contained(),
    \ s:sb.next(end_close),
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_keyword',     [end_keyword])
  call s:sb.clusteradd('tag_end_keyword', [end_keyword])
  call s:sb.hi(end_keyword, 'Keyword')

  " Match the end tag closing sequence, e.g.:
  " {% plain %}
  "   this is inside the plain tag...
  " {% endplain %}
  "             ^^
  call s:sb.match(end_close,
    \ s:pb.make(s:pats.tagClose),
    \ s:sb.contained(),
  \ )
  call s:sb.clusteradd('tag_close',       [end_close])
  call s:sb.clusteradd('tag_end_close',   [end_close])
  call s:sb.hi(end_close, 'SpecialChar')
endfor

let g:sb = s:sb
let g:pb = s:pb

" " Contents of a qtpl tag
" call s:sb.region('region_tag',
"   \ s:pb.make(s:pats.tagOpen),
"   \ s:pb.make(s:pats.tagClose),
"   \ 'containedin=' . s:sb.ref('global'),
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl',
" \ )
"
" " Opening sequence for qtpl tags
" " Ex:
" " {%=uh Foo() %}
" " ^^
" call s:sb.match('tag_open',
"   \ s:pb.make(s:pats.tagOpen),
"   \ 'containedin=' . s:sb.ref('region_tag'),
"   \ 'nextgroup='   . s:sb.ref('@tag_mods') . ',' . s:sb.ref('@tag_def_keyword'),
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"   " \ 'nextgroup='   . s:sb.ref('tag_mods') . ',' . s:sb.ref('tag_def_keyword'),
"
" " Modifiers which can appear after an
" " opening sequence of an opening qtpl tag
" " of the plain catagory (TODO: Reword this)
" " Closing sequence for qtpl tags
" " Ex:
" " {%s= mystr %}
" "   ^^
" call s:sb.match('tag_mods_plain',
"   \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen)), s:pats.plainTagMods, s:pb.pla('\_s')),
"   \ 'containedin=' . s:sb.ref('region_tag'),
"   \ 'nextgroup=' . s:sb.ref('@tag_def_keyword'),
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" " Modifiers which can appear after an
" " opening sequence of an opening qtpl
" " function call tag
" " Ex:
" " {%=uh myFunc() %}
" "   ^^^
" call s:sb.match('tag_mods_func',
"   \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen)), s:pats.funcTagMods, s:pb.pla('\_s')),
"   \ 'containedin=' . s:sb.ref('region_tag'),
"   \ 'nextgroup=' . s:sb.ref('@tag_def_keyword'),
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" call s:sb.cluster('tag_mods', [
"   \ 'tag_mods_plain',
"   \ 'tag_mods_func'
" \ ])
"
" " Any invalid sequence adjacent to an
" " opening qtpl tag sequence
" " Ex:
" " {%nope myFunc() %}
" "   ^^^^
" " TODO: shouldn't match in cases where a valid
" " tag keyword is directly adjacent to its opening
" " tag sequence in certain cases
" " Ex: (should not match)
" " {%space%}
" call s:sb.match('tag_mods_error',
"   \ s:pb.make(
"     \ s:pb.plb(s:pb.grp(s:pats.tagOpen)),
"     \ s:pb.nla(s:pb.grp(s:pb.agrp(s:pats.plainTagMods, s:pats.funcTagMods), '\_s')),
"     \ '\S\+',
"     \ s:pb.pla('\_s')
"   \ ),
"   \ 'containedin=' . s:sb.ref('region_tag')
" \ )
"
" call s:sb.match('tag_def_block_keyword_go',
"   \ s:pb.make(
"     \ s:pb.agrp(
"       \ s:pats.blocks.func
"     \ )
"   \ ),
"   \ 'nextgroup=' . s:sb.ref('tag_def_block_go'),
"   \ 'keepend',
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" call s:sb.region('tag_def_block_go',
"   \ s:pb.make('.'),
"   \ s:pb.make(
"     \ s:pats.tagClose,
"   \ ) . 'me=e-2',
"   \ 'nextgroup=' . s:sb.ref('tag_def_close_block_go'),
"   \ 'keepend',
"   \ 'contained',
"   \ 'contains=@qtpl_syn_go',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" call s:sb.match('tag_def_block_keyword_plain',
"   \ s:pb.make(
"     \ s:pb.agrp(
"       \ s:pats.blocks.plain
"     \ )
"   \ ),
"   \ 'nextgroup=' . s:sb.ref('tag_def_block_plain'),
"   \ 'keepend',
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" call s:sb.region('tag_def_block_plain',
"   \ s:pb.make('.'),
"   \ s:pb.make(
"     \ s:pats.tagClose,
"   \ ) . 'me=e-2',
"   \ 'nextgroup=' . s:sb.ref('tag_def_close_block_plain'),
"   \ 'keepend',
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" " Closing sequence for qtpl tags
" " Ex:
" " {%=uh Foo() %}
" "             ^^
" call s:sb.match('tag_close_inline',
"   \ s:pb.make(s:pats.tagClose),
"   \ 'keepend',
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" " Closing sequence for qtpl tags
" " Ex:
" " {%=uh Foo() %}
" "             ^^
" call s:sb.match('tag_def_close_block_plain',
"   \ s:pb.make(s:pats.tagClose),
"   \ 'nextgroup=' . s:sb.ref('tag_body_block_plain'),
"   \ 'keepend',
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" call s:sb.region('tag_body_block_plain',
"   \ s:pb.make('.'),
"   \ s:pb.make(
"     \ s:pats.tagOpen,
"     \ '\_s*',
"     \ s:pats.blockEnd . s:pats.blocks.plain,
"     \ '\_s*',
"     \ s:pats.tagClose
"   \ ) . 'me=s-2',
"   \ 'keepend',
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"     "
"
"
" " Closing sequence for qtpl tags
" " Ex:
" " {%=uh Foo() %}
" "             ^^
" call s:sb.match('tag_def_close_block_go',
"   \ s:pb.make(s:pats.tagClose),
"   \ 'keepend',
"   \ 'contained',
"   \ 'skipwhite',
"   \ 'skipnl'
" \ )
"
" call s:sb.match('tag_def_keyword_inline',
"   \ s:pb.make(
"     \ s:pb.agrp(
"       \ s:pats.tags.package,
"       \ s:pats.tags.import,
"       \ s:pats.tags.code
"     \ )
"   \ ),
"   \ 'nextgroup=' . s:sb.ref('tag_def_inline'),
"   \ 'skipwhite',
"   \ 'skipnl',
"   \ 'keepend',
"   \ 'contained',
" \ )
"
" call s:sb.cluster('tag_def_keyword', [
"     \ 'tag_def_block_keyword_go',
"     \ 'tag_def_block_keyword_plain',
"     \ 'tag_def_keyword_inline'
"   \ ]
" \ )
"
" call s:sb.cluster('tag_close', [
"     \ 'tag_def_close_block_go',
"     \ 'tag_def_close_block_plain',
"     \ 'tag_close_inline'
"   \ ]
" \ )
"
"
" call s:sb.region('tag_def_inline',
"   \ s:pb.make('.'),
"   \ s:pb.make(
"     \ s:pats.tagClose,
"   \ ) . 'me=e-2',
"   \ 'keepend',
"   \ 'contained',
"   \ 'contains=@qtpl_syn_go',
"   \ 'skipwhite',
"   \ 'nextgroup=' . s:sb.ref('tag_close_inline'),
"   \ 'skipnl'
" \ )

" Build and execute all of the syntax rules
" we defined above
call s:sb.exec()

" TODO: integrate highlight rules into sb
hi def link qtpl_global               Comment
hi def link qtpl_match_todo           Underlined

hi def link qtpl_tag_open             SpecialChar
hi def link qtpl_tag_close            SpecialChar
"
" hi def link qtpl_tag_error_no_mods              Error
"
" " old
"
" hi def link qtpl_tag_open                    SpecialChar
" hi def link qtpl_tag_close                   SpecialChar
" hi def link qtpl_tag_def_close_block_go          SpecialChar
" hi def link qtpl_tag_def_close_block_plain       SpecialChar
" hi def link qtpl_tag_close_inline            SpecialChar
"
" " hi def link qtpl_tag_mods                  String
" hi def link qtpl_tag_mods_func               String
" hi def link qtpl_tag_mods_plain              Number
" hi def link qtpl_tag_mods_error              Error
"
" " hi def link qtpl_tag_def_keyword           Keyword
" hi def link qtpl_tag_def_block_keyword       Keyword
" hi def link qtpl_tag_def_block_keyword_go    Keyword
" hi def link qtpl_tag_def_block_keyword_plain Keyword
" hi def link qtpl_tag_def_keyword_inline      Keyword
"
" hi def link qtpl_tag_body_block_plain        Constant
"
let b:current_syntax = "qtpl"

" vim: sw=2 ts=2 et
