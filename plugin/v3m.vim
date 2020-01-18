" A web browser interface plugin for Vim
" Author  : Koji Sato <litom501+vim@gmail.com>
" License : MIT License

if exists("g:loaded_v3m")
  finish
endif

let s:v3m = '[v3m]'
let s:v3m_error = s:v3m . '[ERROR]'
let s:v3m_warn  = s:v3m . '[WARN ]'
let s:v3m_command = 'w3m'

" check features
if has('nvim')
  let s:requirement_features = []
else
  let s:requirement_features = [ 'job', 'channel', 'lambda' ]
endif

let s:has_features = 1
for requirement in s:requirement_features
  let s:has_features = s:has_features && has(requirement)
endfor

if !s:has_features
  echohl ErrorMsg
  echomsg s:v3m_error 'The plugin couldn''t be loaded because the Vim features required is missing. Required Vim features :' join(s:requirement_features, ', ')
  echohl None
endif

let s:save_cpo = &cpo
set cpo&vim

if !executable(s:v3m_command)
  echohl WarningMsg
  "echomsg s:v3m_warn 'プラグインを利用するには、以下のコマンドをインストールしてください。:' . s:v3m_command
  echomsg s:v3m_warn 'To use the plugin, install the following command. : ' . s:v3m_command
  echohl None
endif

augroup v3m
  autocmd!
  autocmd! BufReadCmd v3m://* call v3m#open_v3m(expand('<amatch>'))
augroup END

" https://github.com/vim-jp/issues/issues/616
"-complete=file をつけると、# ゃ % を含む URL を引き渡した際に q-args を展開した時点で、補間が適用されている
"command! -nargs=? -complete=file V3m :execute ':edit v3m://' . fnameescape(<q-args>)
command! -nargs=? V3m :execute ':edit v3m://' . fnameescape(<q-args>)
command! -nargs=? -complete=file V3mLocal :execute ':edit v3m://' . fnameescape(<q-args>)

nnoremap <silent> <Plug>(v3m-open-link)        :<C-U>call v3m#open_link()<CR>
nnoremap <silent> <Plug>(v3m-open-link-tab)    :<C-U>if !empty(v3m#get_curlink())\|execute 'tabnew v3m://' . fnameescape(v3m#get_curlink())\|endif<CR>
nnoremap <silent> <Plug>(v3m-open-link-new)    :<C-U>if !empty(v3m#get_curlink())\|execute 'new v3m://' . fnameescape(v3m#get_curlink())\|endif<CR>
nnoremap <silent> <Plug>(v3m-open-homepage)    :<C-U>call v3m#open('', 0)<CR>
nnoremap <silent> <Plug>(v3m-reload-page)      :<C-U>call v3m#reload()<CR>
nnoremap <silent> <Plug>(v3m-next-link)        :<C-U>call v3m#next_link(0)<CR>
nnoremap <silent> <Plug>(v3m-previous-link)    :<C-U>call v3m#next_link(1)<CR>
nnoremap <silent> <Plug>(v3m-show-locationbar) :<C-U>call v3m#input_location()<CR>
nnoremap <silent> <Plug>(v3m-show-cursor-link) :<C-U>call v3m#show_cursor_link()<CR>
nnoremap <silent> <Plug>(v3m-back-history)     :<C-U>call v3m#back()<CR>
nnoremap <silent> <Plug>(v3m-show-history)     :<C-U>call v3m#back_history()<CR>

nnoremap <silent> <Plug>(v3m-nav-pagedown)     <PageDown>
nnoremap <silent> <Plug>(v3m-nav-pageup)       <PageUp>

nnoremap <silent> <Plug>(v3m-inspect-dump)      :call v3m#inspect#dump()<CR>
nnoremap <silent> <Plug>(v3m-inspect-cursor)      :call v3m#inspect#cursor()<CR>

highlight default link v3mLink Underlined
highlight default link v3mVisible1 Constant
highlight default link v3mVisible2 Type
highlight default link v3mOther Special
highlight default link v3mUnknown Todo

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_v3m = 1
" vim: ts=2 sw=2 et
