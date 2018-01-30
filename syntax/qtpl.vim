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
  \ s:sb.contained('global', '@block'),
  \ s:sb.next('@tag_keyword'),
  \ 'skipwhite',
  \ 'skipnl',
\ )

" let s:pats.tags.interface = s:pb.agrp('interface', 'iface')
" let s:pats.tags.newline   = 'newline'
" let s:pats.tags.space     = 'space'

" \ ]
" let s:pats.xblocks = [
" blocks are pairs of quicktemplate tags (an opening tag and a closing tag)
" which contain additional code
let s:pats.blocks = [
  \ {
    \ 'name'          : 'func',
    \ 'containedin'   : ['global'],
    \ 'clusters'      : ['block', 'func'],
    \ 'start_keyword' : 'func',
    \ 'end_keyword'   : 'endfunc',
    \ 'contains'      : ['@syn_html'],
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-2',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'cat',
    \ 'containedin'   : ['global', '@block'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'cat',
    \ 'start_contents_start'   : s:pb.make('"'),
    \ 'start_contents_skip'    : s:pb.make('\\\\\|\\"'),
    \ 'start_contents_end'     : s:pb.make('"'),
    \ 'start_contents_contains': ['!@goStringGroup'],
    \ 'start_contents_hi'      : 'String',
  \ },
  \ {
    \ 'name'          : 'code',
    \ 'containedin'   : ['global', '@block'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'code',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-2',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'package',
    \ 'containedin'   : ['global'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'package',
    \ 'start_contents_start'   : s:pb.make('\S'),
    \ 'start_contents_end'     : s:pb.make('\_s'),
    \ 'start_contents_hi'      : 'Identifier',
  \ },
  \ {
    \ 'name'          : 'import',
    \ 'containedin'   : ['global'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'import',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-2',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'comment',
    \ 'containedin'   : ['global', '@block'],
    \ 'clusters'      : ['blockcomment'],
    \ 'start_keyword' : 'comment',
    \ 'end_keyword'   : 'endcomment',
    \ 'hi'            : 'Comment',
  \ },
  \ {
    \ 'name'          : 'plain',
    \ 'containedin'   : ['global', '@block'],
    \ 'clusters'      : ['blockcomment'],
    \ 'start_keyword' : 'plain',
    \ 'end_keyword'   : 'endplain',
    \ 'hi'            : 'Comment',
  \ },
  \ {
    \ 'name'          : 'collapsespace',
    \ 'containedin'   : ['global', '@block'],
    \ 'clusters'      : ['block'],
    \ 'start_keyword' : 'collapsespace',
    \ 'end_keyword'   : 'endcollapsespace',
  \ },
  \ {
    \ 'name'          : 'stripspace',
    \ 'containedin'   : ['global', '@block'],
    \ 'clusters'      : ['block'],
    \ 'start_keyword' : 'stripspace',
    \ 'end_keyword'   : 'endstripspace',
  \ },
  \ {
    \ 'name'          : 'space',
    \ 'containedin'   : ['@block'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'space',
  \ },
  \ {
    \ 'name'          : 'newline',
    \ 'containedin'   : ['@block'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'newline',
  \ },
  \ {
    \ 'name'          : 'switch',
    \ 'containedin'   : ['@func'],
    \ 'clusters'      : ['block', 'switch'],
    \ 'start_keyword' : 'switch',
    \ 'end_keyword'   : 'endswitch',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-2',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'case',
    \ 'containedin'   : ['@switch'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'case',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-2',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'default',
    \ 'containedin'   : ['@switch'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'default',
  \ },
  \ {
    \ 'name'          : 'if',
    \ 'containedin'   : ['@func'],
    \ 'clusters'      : ['block', 'if'],
    \ 'start_keyword' : 'if',
    \ 'end_keyword'   : 'endif',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-2',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'else',
    \ 'containedin'   : ['@if'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'else',
  \ },
  \ {
    \ 'name'          : 'elseif',
    \ 'containedin'   : ['@if'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'elseif',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-2',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
\ ]

let s:pats.blockEnd             = 'end'

for obj in s:pats.blocks
  " Predefine group names
  let prefix         = 'tag_' . obj.name
  let start_keyword  = prefix . '_start_keyword'
  let start_contents = prefix . '_start_contents'
  let start_close    = prefix . '_start_close'
  let body           = prefix . '_body'
  let end_open       = prefix . '_end_open'
  let end_keyword    = prefix . '_end_keyword'
  let end_close      = prefix . '_end_close'

  let start_keyword_nextgroup = start_close

  if has_key(obj, 'start_contents_start') && has_key(obj, 'start_contents_end')
    let start_keyword_nextgroup = start_contents

    let start_contents_skip = ''
    if has_key(obj, 'start_contents_skip')
      let start_contents_skip = 'skip=' . obj.start_contents_skip
    endif

    let start_contents_contains = ''
    if has_key(obj, 'start_contents_contains')
      let start_contents_contains = s:sb.lcontains(obj.start_contents_contains)
    endif

      " \ s:sb.contained(),
      " \ s:sb.lcontained(obj.containedin),
    " Match the start tag contents, e.g.:
    " {% func fooBar(a int) bool %}
    "         ^^^^^^^^^^^^^^^^^^
    call s:sb.region(start_contents,
      \ obj.start_contents_start,
      \ obj.start_contents_end,
      \ start_contents_skip,
      \ s:sb.contained(),
      \ start_contents_contains,
      \ s:sb.next(start_close),
      \ 'skipwhite',
      \ 'keepend',
      \ 'skipnl',
    \ )

    if has_key(obj, 'start_contents_hi')
      call s:sb.hi(start_contents, obj.start_contents_hi)
    endif
  endif

  " Match the keyword, e.g.:
  " {% plain %}
  "    ^^^^^
    " \ s:pb.make(s:pb.pla(s:pb.grp(s:pats.tagOpen . '\_s\+')), obj.start_keyword),
  call s:sb.match(start_keyword,
    \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen . '\_s*')), obj.start_keyword, '\_s*'),
    \ s:sb.next(start_keyword_nextgroup),
    \ s:sb.lcontained(obj.containedin),
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_keyword',       [start_keyword])
  call s:sb.clusteradd('tag_start_keyword', [start_keyword])
  call s:sb.hi(start_keyword, 'Keyword')

  let start_close_nextgroup = ''
  if index(obj.clusters, 'block') != -1 || index(obj.clusters, 'blockcomment') != -1
    let start_close_nextgroup = s:sb.next(body)
  endif

  " Match the tag closing sequence, e.g.:
  " {% plain %}
  "          ^^
  "   this is inside the plain tag...
  " {% endplain %}
  call s:sb.match(start_close,
    \ s:pb.make(s:pats.tagClose),
    \ s:sb.contained(),
    \ start_close_nextgroup,
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_close',       [start_close])
  call s:sb.clusteradd('tag_start_close', [start_close])
  call s:sb.hi(start_close, 'SpecialChar')

  if index(obj.clusters, 'block') == -1 && index(obj.clusters, 'blockcomment') == -1
    continue
  endif

  let body_contains = ''
  if has_key(obj, 'contains')
    let body_contains = s:sb.lcontains(obj.contains)
  endif
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
      \ obj.end_keyword,
      \ '\_s*',
      \ s:pats.tagClose
    \ ) . 'me=s-2',
    \ s:sb.contained(),
    \ s:sb.next(end_open),
    \ body_contains,
    \ 'skipwhite',
    \ 'skipnl',
  \ )
  call s:sb.clusteradd('tag_body', [body])
  if has_key(obj, 'clusters')
    for c in obj.clusters
      call s:sb.clusteradd(c, [body])
    endfor
  endif
  if has_key(obj, 'hi')
    call s:sb.hi(body, obj.hi)
  endif

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
    \ obj.end_keyword,
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
