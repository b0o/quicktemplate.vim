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
syn region qtplOuter start=/\%^/ end=/\%$/ contains=CONTAINED

syn keyword  qtplTodo contained containedby=qtplOuter TODO FIXME XXX BUG NOTE

syn region qtplGoCodeRegion matchgroup=qtplDelim start=/{%\(\([svdfqzju]=\?\)\|\([sqju]\(z=\?\)\?\)\|\(=\([uqj]\?[h]\?\)\?\)\)\?\_s\{1,}code/ end=/%}/ contained contains=@qtplGo
syn region qtplPlainRegion  matchgroup=qtplTag start=/{%\(\(\([svdfqzju]=\?\)\|\([sqju]\(z=\?\)\?\)\|\(=\([uqj]\?[h]\?\)\?\)\)\?\_s\{1,}\)\_s\{0,}plain\_s\{0,}%}/ end=/{%\_s\{0,}endplain\_s\{0,}%}/ contained contains=@qtplHtml
syn region qtplFuncRegion   matchgroup=qtplTag start=/{%\(\(\([svdfqzju]=\?\)\|\([sqju]\(z=\?\)\?\)\|\(=\([uqj]\?[h]\?\)\?\)\)\?\_s\{1,}\)\_s\{0,}func\s\{1,}\h\w\{0,}\s\{0,}(.*)\s\{0,}%}/ end=/{%\_s\{0,}endfunc\_s\{0,}%}/ contained contains=@qtplHtml,qtplGoCodeRegion,qtplPlainRegion

hi def link qtplOuter         Comment
hi def link qtplTag           SpecialChar
hi def link qtplDelim         SpecialChar
hi def link qtplTodo          Underlined

let b:current_syntax = "qtpl"

" \([0-9A-Za-z_,\s]\{0,}\)\{0,}
" \(\s\{0,}\h\w\{0,}\s{0,}\h\w\{0,}\s{0,}\)\{0,}
" syn region qtplPlainRegion  matchgroup=qtplTag start=/{%\(\([svdfqzjuh=]\)\{,3}\_s\{1,}\)\?plain\_s\{0,}%}/ end=/{%\_s\{0,}endplain\_s\{0,}%}/ contained contains=@qtplHtml
" syn region qtplFuncRegion   matchgroup=qtplTag start=/{%\(\([svdfqzjuh=]\)\{,3}\_s\{1,}\)\?func\s{1,}\w\{1}\_s{0,}%}/ end=/{%\_s\{0,}endfunc\_s\{0,}%}/ contained contains=@qtplHtml


" hi def link qtplTag       Number
" hi def link qtplKeyword   Keyword
" hi def link GoCodeRegion NONE


" Paired tags which contain output text/html
" includes {% func %} and {% plain %}

" syn region qtplGoCodeRegion start="{%\([svdfqzjuh=]\)\{,3}\<\(end\(func\|plain\)\)\@!"rs=e,hs=e keepend end="%}"re=s,he=s-1 contains=@qtplGo contained

" syn region qtplOutputTagRegion start="{%\([svdfqzjuh=]\)\{0,3}\_s\z(func\|plain\)\_s.*\_s%}\C" keepend end="{%\_send\z1\_s%}" contains=@qtplHtml,qtplGoCodeRegion contained
"

" syn keyword     qtplKeyword        endfunc endplain

" syn match qtplTag /{%/
" syn match qtplTag /%}/ contained display
"
" syn match qtplTag /{%/


" vim: sw=2 ts=2 et
