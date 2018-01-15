" Filetype detection
" Based on https://github.com/fatih/vim-go/blob/master/ftdetect/gofiletype.vim

" We take care to preserve the user's fileencodings and fileformats,
" because those settings are global (not buffer local), yet we want
" to override them for loading qtpl files, which are defined to be UTF-8.
let s:current_fileformats = ''
let s:current_fileencodings = ''

" define fileencodings to open as utf-8 encoding even if it's ascii.
function! s:qtplfiletype_pre(type)
  let s:current_fileformats = &g:fileformats
  let s:current_fileencodings = &g:fileencodings
  set fileencodings=utf-8 fileformats=unix
  let &l:filetype = a:type
endfunction

" restore fileencodings as others
function! s:qtplfiletype_post()
  let &g:fileformats = s:current_fileformats
  let &g:fileencodings = s:current_fileencodings
endfunction

augroup qtpl-filetype
  autocmd!
  au BufNewFile  *.qtpl setfiletype qtpl | setlocal fileencoding=utf-8 fileformat=unix
  au BufRead     *.qtpl call s:qtplfiletype_pre("qtpl")
  au BufReadPost *.qtpl call s:qtplfiletype_post()
augroup end

" vim: sw=2 ts=2 et
