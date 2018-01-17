" qtpl.vim: Vim syntax file for Quicktemplate syntax

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" syn case match

" Define embedded syntaxes
syn include @qtplGo   syntax/go.vim
unlet! b:current_syntax

syn include @qtplHtml syntax/html.vim
unlet! b:current_syntax

" Everything in the outermost scope is considered a comment
syn region  qtpl_region_outer start=/\%^/ end=/\%$/ contains=CONTAINED

" Keywords like TODO in the outer region
syn keyword qtpl_keyword_todo contained    containedby=qtpl_region_outer    TODO FIXME XXX BUG NOTE

" Pattern builder utility functions
let s:pb = {}

" Delimiter for patterns generated with s:make_pat
" Delimits the start and end of the pattern, and cannot
" appear anywhere within the pattern
let s:pb.delim = '+'

" Join a list of patterns with the given separator
func! s:pb.join(ps, s)
  return join(a:ps, a:s)
endfunc

" Wrap the given pattern with an open and close pattern
func! s:pb.wrap(o, p, c)
  return a:o . a:p . a:c
endfunc

" grp: group
" Given a variadic number of patterns as arguments,
" join them and wrap with group delimiters
" Boolean AND
func! s:pb.grp(...)
  return s:pb.lgrp(a:000)
endfunc

" lgrp: list group
" Given a list of atoms, combine them into a group
" Boolean AND
func! s:pb.lgrp(ps)
  return s:pb.wrap('\(', s:pb.join(a:ps, ''), '\)')
endfunc

" Group which matches any atom given a list of patterns
" Boolean OR
func! s:pb.agrp(ps)
  return s:pb.grp(s:pb.join(a:ps, '\|'))
endfunc

" Given a list of atoms, combine them into a collection of atoms
" See :h E69
func! s:pb.col(ps)
  return s:pb.wrap('\[', s:pb.join(a:ps, ''), ']')
endfunc

" Given a list of atoms, combine them into a sequence of optional
" atoms
" See :h E69
func! s:pb.seq(ps)
  return s:pb.wrap('\%[', s:pb.join(a:ps, ''), ']')
endfunc

" Matches {min,max} of the specified atom
" See :h /multi
func! s:pb.multi(p, min, max)
  return s:pb.join([a:p, '\{', a:min, ',', a:max, '}'], '')
endfunc

" Matches 0 or 1 of the specified atom (greedy)
func! s:pb.opt(p)
  return a:p . '\?'
endfunc

" Positive lookahead
func! s:pb.pla(p)
  return a:p . '\@='
endfunc

" Negative lookahead
func! s:pb.nla(p)
  return a:p . '\@!'
endfunc

" Positive lookbehind
func! s:pb.plb(p)
  return a:p . '\@<='
endfunc

" Negative lookbehind
func! s:pb.nlb(p)
  return a:p . '\@<!'
endfunc

" NO-OP
" returns empty string
func! s:pb.nop(...)
  return ''
endfunc

" Passthrough
" returns first argument
func! s:pb.pt(a)
  return a:a
endfunc

" Joins a variable number of pattern pieces together
" between pattern delimiters to create a complete pattern
func! s:pb.make(...)
  return s:pb.wrap(s:pb.delim, s:pb.join(extend(['\C'], a:000), ''), s:pb.delim)
endfunc

" Building blocks of patterns for Quicktemplate syntax
let s:pats        = {}
let s:pats.blocks = {}

let s:pats.tagOpen              = '{%'
let s:pats.tagClose             = '%}'

let s:pats.blockEnd             = 'end'

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
let s:pats.plainTagMods = s:pb.agrp([
  \ s:pb.agrp(['d', 'f', 'v', 'z']),
  \ s:pb.grp(
    \ s:pb.agrp(['q', 'j', 'u']),
    \ s:pb.opt('z')
  \ )
\ ])

" Modifiers for func tags which specify output behavior of the tag
" Similar to printf verbs
let s:pats.funcTagMods = s:pb.grp(
  \ '=',
  \ s:pb.opt(s:pb.agrp(['q', 'j', 'u'])),
  \ s:pb.opt('h')
\ )


" Syntax builder
let s:sb = { 'prefix': 'qtpl_' }

" Builds a 'syntax match ...' command
func! s:sb.match(name, pat, ...)
  return {
  \ 'name': s:sb.prefix . a:name,
  \ 'pat':  a:pat,
  \ 'opts': a:000,
  \ 'cmd':  join(['syn match', s:sb.prefix . a:name, a:pat, join(a:000, ' ')], ' ')
  \ }
endfunc

" A disabled match
func! s:sb.xmatch(...)
  return {
  \ 'name': '',
  \ 'pat':  '',
  \ 'opts': [],
  \ 'cmd':  ''
  \ }
endfunc

" Object which holds all syntax definitions
let s:syns = {}
let s:syns.objs = []

" Push a new obj (from sb) onto the list
func! s:syns.push(...)
  call extend(s:syns.objs, a:000)
endfunc

" Execute all syntax commands in syns.objs
func! s:syns.exec()
  for l:obj in s:syns.objs
    execute l:obj.cmd
  endfor
endfunc

call s:syns.push(
  \ s:sb.match('tag_open',
    \ s:pb.make(s:pats.tagOpen),
    \ 'contained'
  \ ),
  \ s:sb.match('tag_mods_error',
    \ s:pb.make(
      \ s:pb.plb(s:pb.grp(s:pats.tagOpen)),
      \ s:pb.nla(s:pb.grp(s:pb.agrp([s:pats.plainTagMods, s:pats.funcTagMods]), '\_s')),
      \ '\S\+',
      \ s:pb.pla('\_s')
    \ ),
    \ 'contained'
  \ ),
  \ s:sb.match('tag_mods_plain',
    \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen)), s:pats.plainTagMods, s:pb.pla('\_s')),
    \ 'contained'
  \ ),
  \ s:sb.match('tag_mods_func',
    \ s:pb.make(s:pb.plb(s:pb.grp(s:pats.tagOpen)), s:pats.funcTagMods, s:pb.pla('\_s')),
    \ 'contained'
  \ ),
  \ s:sb.match('tag_close',
    \ s:pb.make(s:pats.tagClose),
    \ 'contained'
  \ )
\ )
      " \ s:pb.nla(s:pb.grp(s:pb.agrp([s:pats.plainTagMods, s:pats.funcTagMods]), '\S')),
      " \ s:pb.nla(s:pb.grp(s:pb.agrp([s:pats.plainTagMods, s:pats.funcTagMods]), '\S')),

      " \ s:pb.nla(s:pb.grp(s:pb.agrp([s:pats.plainTagMods, s:pats.funcTagMods]), '\S'))

  " \ s:sb.match('tag_mods_plain',
  "   \ s:pb.make(pb.pla(s:pats.tagOpen), s:pats.plainTagMods),
  "   \ 'contained'
  " \ ),
call s:syns.exec()

let g:foo = s:syns

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
