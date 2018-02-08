" qtpl.vim: Vim plugin for Quicktemplate syntax highlighting

""" SETUP

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
let g:sb = s:sb

""" PATTERNS

" Building blocks of patterns for Quicktemplate syntax
let s:pats = {}

let s:pats.bof      = '\%^'
let s:pats.eof      = '\%$'
let s:pats.tagOpen  = '{%'
let s:pats.tagClose = '%}'

let s:pats.todo     = s:pb.grp(s:pb.agrp('TODO', 'FIXME', 'XXX', 'BUG', 'NOTE'), s:pb.opt(':'))

" Modifiers for tags which specify output behavior of the tag
" Similar to printf verbs
let s:pats.plainTagMods =
\ s:pb.grp(
  \ s:pb.agrp(
    \ s:pb.agrp('d', s:pb.grp('f', s:pb.opt(s:pb.grp('\.\d\+'))), 'v', 'z'),
    \ s:pb.grp(
      \ s:pb.agrp('s', 'q', 'j', 'u'),
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
call s:sb.hi('global', 'Comment')

" Keywords like TODO in the outer region
call s:sb.match('todo',
  \ s:pb.make(s:pats.todo),
  \ s:sb.contained('global'),
\ )
call s:sb.hi('todo', 'TODO')

" Opening qtpl tags found within the global scope
call s:sb.match('global_tag_open',
  \ s:pb.make(s:pats.tagOpen),
  \ s:sb.contained('global'),
  \ s:sb.next('@tag_start_keyword'),
  \ 'skipwhite',
  \ 'skipempty',
\ )
call s:sb.hi('global_tag_open', 'SpecialChar')

" Opening qtpl tags found within a block-level scope
call s:sb.match('block_tag_open',
  \ s:pb.make(s:pats.tagOpen),
  \ s:sb.contained('@block', '@html_container'),
  \ s:sb.next('@tag_mods'),
  \ 'skipwhite',
  \ 'skipempty',
\ )
call s:sb.hi('block_tag_open', 'SpecialChar')

call s:sb.cluster('tag_open', [
  \ 'global_tag_open',
  \ 'block_tag_open'
\ ])

" Modifiers which can appear after an
" opening sequence of a starting qtpl tag
" denoting a value placeholder
" Ex:
" {%s= mystr %}
"   ^^
call s:sb.match('tag_ph_value_mods',
  \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen . '\_s*')), s:pats.plainTagMods, s:pb.pla('\_s')),
  \ s:sb.contained(),
  \ s:sb.next('tag_ph_value_contents'),
  \ 'skipwhite',
  \ 'skipempty',
\ )
call s:sb.hi('tag_ph_value_mods', 'Function')

" Modifiers which can appear after an
" opening sequence of a starting qtpl tag
" denoting a function call placeholder
" Ex:
" {%=uh myFunc() %}
"   ^^^
call s:sb.match('tag_ph_func_mods',
  \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen . '\_s*')), s:pats.funcTagMods, s:pb.pla('\_s')),
  \ s:sb.contained(),
  \ s:sb.next('tag_ph_func_contents'),
  \ 'skipwhite',
  \ 'skipempty',
\ )
call s:sb.hi('tag_ph_func_mods', 'Function')

call s:sb.cluster('tag_mods', [
  \ 'tag_ph_value_mods',
  \ 'tag_ph_func_mods'
\ ])

call s:sb.region('tag_ph_value_contents',
  \ s:pb.make('.'),
  \ s:pb.make(s:pats.tagClose) . 'me=s-1',
  \ s:sb.contained(),
  \ s:sb.contains('@syn_go'),
  \ s:sb.next('tag_ph_close'),
  \ 'skipwhite',
  \ 'skipempty',
  \ 'keepend',
\ )

call s:sb.region('tag_ph_func_contents',
  \ s:pb.make('.'),
  \ s:pb.make(s:pats.tagClose) . 'me=s-1',
  \ s:sb.contained(),
  \ s:sb.contains('@syn_go'),
  \ s:sb.next('tag_ph_close'),
  \ 'skipwhite',
  \ 'skipempty',
  \ 'keepend',
\ )

call s:sb.match('tag_ph_close',
  \ s:pb.make(s:pats.tagClose),
  \ s:sb.contained(),
  \ 'skipwhite',
  \ 'skipempty',
\ )
call s:sb.clusteradd('tag_close',       ['tag_ph_close'])
call s:sb.clusteradd('tag_start_close', ['tag_ph_close'])
call s:sb.hi('tag_ph_close', 'SpecialChar')

let s:pats.tags = [
  \ {
    \ 'name'          : 'func',
    \ 'containedin'   : ['global'],
    \ 'clusters'      : ['block', 'func'],
    \ 'start_keyword' : 'func',
    \ 'end_keyword'   : 'endfunc',
    \ 'body_args'     : ['fold'],
    \ 'contains'      : ['@syn_html'],
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'cat',
    \ 'containedin'   : ['global', '@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'cat',
    \ 'start_contents_start'   : s:pb.make('"'),
    \ 'start_contents_skip'    : s:pb.make('\\\\\|\\"'),
    \ 'start_contents_end'     : s:pb.make('"'),
    \ 'start_contents_contains': ['!@goStringGroup'],
    \ 'start_contents_hi'      : 'String',
  \ },
  \ {
    \ 'name'          : 'interface',
    \ 'containedin'   : ['global'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : s:pb.agrp('iface', 'interface'),
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'code',
    \ 'containedin'   : ['global', '@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'code',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
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
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'comment',
    \ 'containedin'   : ['global', '@block', '@html_container'],
    \ 'clusters'      : ['blockcomment'],
    \ 'start_keyword' : 'comment',
    \ 'end_keyword'   : 'endcomment',
    \ 'body_args'     : ['fold'],
    \ 'hi'            : 'Comment',
  \ },
  \ {
    \ 'name'          : 'plain_global',
    \ 'containedin'   : ['global'],
    \ 'clusters'      : ['blockcomment'],
    \ 'start_keyword' : 'plain',
    \ 'end_keyword'   : 'endplain',
    \ 'body_args'     : ['fold'],
    \ 'hi'            : 'Comment',
  \ },
  \ {
    \ 'name'          : 'plain_block',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['blockcomment'],
    \ 'start_keyword' : 'plain',
    \ 'end_keyword'   : 'endplain',
    \ 'body_args'     : ['fold'],
    \ 'contains'      : ['@syn_html'],
  \ },
  \ {
    \ 'name'          : 'collapsespace',
    \ 'containedin'   : ['global', '@block', '@html_container'],
    \ 'clusters'      : ['block'],
    \ 'start_keyword' : 'collapsespace',
    \ 'end_keyword'   : 'endcollapsespace',
    \ 'body_args'     : ['transparent', 'fold'],
  \ },
  \ {
    \ 'name'          : 'stripspace',
    \ 'containedin'   : ['global', '@block', '@html_container'],
    \ 'clusters'      : ['block'],
    \ 'start_keyword' : 'stripspace',
    \ 'end_keyword'   : 'endstripspace',
    \ 'body_args'     : ['transparent', 'fold'],
  \ },
  \ {
    \ 'name'          : 'space',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'space',
  \ },
  \ {
    \ 'name'          : 'newline',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'newline',
  \ },
  \ {
    \ 'name'          : 'switch',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'switch',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'endswitch',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'endswitch',
  \ },
  \ {
    \ 'name'          : 'case',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'case',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'default',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'default',
  \ },
  \ {
    \ 'name'          : 'for',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'for',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'endfor',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'endfor',
  \ },
  \ {
    \ 'name'          : 'break',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'break',
  \ },
  \ {
    \ 'name'          : 'continue',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'continue',
  \ },
  \ {
    \ 'name'          : 'if',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'if',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'endif',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'endif',
  \ },
  \ {
    \ 'name'          : 'else',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'else',
  \ },
  \ {
    \ 'name'          : 'elseif',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'elseif',
    \ 'start_contents_start'   : s:pb.make('.'),
    \ 'start_contents_end'     : s:pb.make(s:pats.tagClose) . 'me=s-1',
    \ 'start_contents_contains': ['@syn_go'],
  \ },
  \ {
    \ 'name'          : 'return',
    \ 'containedin'   : ['@block', '@html_container'],
    \ 'clusters'      : ['inline'],
    \ 'start_keyword' : 'return',
  \ },
\ ]

for obj in s:pats.tags
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
      \ 'skipempty',
      \ 'keepend',
    \ )

    if has_key(obj, 'start_contents_hi')
      call s:sb.hi(start_contents, obj.start_contents_hi)
    endif
  endif

  " Match the keyword, e.g.:
  " {% plain %}
  "    ^^^^^
  call s:sb.match(start_keyword,
    \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen . '\_s*')), obj.start_keyword, s:pb.pla(s:pb.agrp('\_s\+', s:pats.tagClose))),
    \ s:sb.next(start_keyword_nextgroup),
    \ s:sb.lcontained(obj.containedin),
    \ 'skipwhite',
    \ 'skipempty',
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
    \ 'skipempty',
  \ )
  call s:sb.clusteradd('tag_close',       [start_close])
  call s:sb.clusteradd('tag_start_close', [start_close])
  call s:sb.hi(start_close, 'SpecialChar')

  if index(obj.clusters, 'block') == -1 && index(obj.clusters, 'blockcomment') == -1
    continue
  endif

  let body_skip = ''
  if has_key(obj, 'skip')
    let body_skip = 'skip=' . obj.skip
  endif

  let body_contains = ''
  if has_key(obj, 'contains')
    let body_contains = s:sb.lcontains(obj.contains)
  endif

  let body_args = ''
  if has_key(obj, 'body_args')
    let body_args = join(obj.body_args, ' ')
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
    \ ) . 'me=s-1',
    \ body_skip,
    \ s:sb.contained(),
    \ s:sb.next(end_open),
    \ body_contains,
    \ 'skipwhite',
    \ 'skipempty',
    \ 'extend',
    \ body_args,
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
    \ 'skipempty',
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
    \ 'skipempty',
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

""" EXTERNAL CLUSTERS
" Define a cluster `html_container` which collects all possible
" regions defined within syntax/html.vim and its children

" syntax/html.vim
call s:sb.clusteradd('html_container', [
  \ '!cssStyle',
  \ '!htmlBold',
  \ '!htmlBoldItalic',
  \ '!htmlBoldItalicUnderline',
  \ '!htmlBoldUnderline',
  \ '!htmlBoldUnderlineItalic',
  \ '!htmlComment',
  \ '!htmlCommentPart',
  \ '!htmlCssDefinition',
  \ '!htmlEndTag',
  \ '!htmlEvent',
  \ '!htmlEventDQ',
  \ '!htmlEventSQ',
  \ '!htmlH1',
  \ '!htmlH2',
  \ '!htmlH3',
  \ '!htmlH4',
  \ '!htmlH5',
  \ '!htmlH6',
  \ '!htmlHead',
  \ '!htmlItalic',
  \ '!htmlItalicBold',
  \ '!htmlItalicBoldUnderline',
  \ '!htmlItalicUnderline',
  \ '!htmlItalicUnderlineBold',
  \ '!htmlLink',
  \ '!htmlPreAttr',
  \ '!htmlPreProc',
  \ '!htmlScriptTag',
  \ '!htmlStrike',
  \ '!htmlString',
  \ '!htmlTag',
  \ '!htmlTitle',
  \ '!htmlUnderline',
  \ '!htmlUnderlineBold',
  \ '!htmlUnderlineBoldItalic',
  \ '!htmlUnderlineItalic',
  \ '!htmlUnderlineItalicBold',
  \ '!javaScript',
  \ '!javaScriptExpression',
\ ])

" syntax/javascript.vim
call s:sb.clusteradd('html_container', [
  \ '!javaScriptComment',
  \ '!javaScriptFunctionFold',
  \ '!javaScriptRegexpString',
  \ '!javaScriptStringD',
  \ '!javaScriptStringS',
\ ])

" syntax/css.vim
call s:sb.clusteradd('html_container', [
  \ '!cssAttrRegion',
  \ '!cssAttributeSelector',
  \ '!cssComment',
  \ '!cssDefinition',
  \ '!cssFontDescriptorBlock',
  \ '!cssFontDescriptorFunction',
  \ '!cssFunction',
  \ '!cssInclude',
  \ '!cssKeyFrameWrap',
  \ '!cssMediaBlock',
  \ '!cssPageWrap',
  \ '!cssPseudoClassFn',
  \ '!cssStringQ',
  \ '!cssStringQQ',
  \ '!cssURL',
\ ])

call s:sb.exec()
let b:current_syntax = "qtpl"

" vim: sw=2 ts=2 et
