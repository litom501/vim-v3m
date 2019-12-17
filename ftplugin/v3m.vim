if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

if !hasmapto('<Plug>(v3m-next-link)')
  nmap <buffer> <unique>  <Tab> <Plug>(v3m-next-link)
endif
if !hasmapto('<Plug>(v3m-previous-link)')
  nmap <buffer> <unique>  <S-Tab> <Plug>(v3m-previous-link)
endif

if !hasmapto('<Plug>(v3m-open-link)')
  nmap <buffer> <unique> <CR> <Plug>(v3m-open-link)
  nmap <buffer> <unique>  <C-]> <Plug>(v3m-open-link)
endif
if !hasmapto('<Plug>(v3m-open-link-new)')
  nmap <buffer> <unique>  <C-W>] <Plug>(v3m-open-link-new)
endif
if !hasmapto('<Plug>(v3m-open-link-tab)')
  nmap <buffer> <unique>  <S-O> <Plug>(v3m-open-link-tab)
endif
if !hasmapto('<Plug>(v3m-show-cursor-link)')
  nmap <buffer> <unique> c <Plug>(v3m-show-cursor-link)
endif

if !hasmapto('<Plug>(v3m-back-history)')
  nmap <buffer> <unique>  <BS> <Plug>(v3m-back-history)
endif
if !hasmapto('<Plug>(v3m-show-locationbar)')
  nmap <buffer> <unique>  <C-L> <Plug>(v3m-show-locationbar)
endif
if !hasmapto('<Plug>(v3m-open-homepage)')
  nmap <buffer> <unique>  <S-B> <Plug>(v3m-open-homepage)
endif

if !hasmapto('<Plug>(v3m-reload-page)')
  nmap <buffer> <unique>  <S-R> <Plug>(v3m-reload-page)
endif
if !hasmapto('<Plug>(v3m-show-history)')
  nmap <buffer> <unique>  <S-H> <Plug>(v3m-show-history)
endif

" vim: ts=2 sw=2 et
