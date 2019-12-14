scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License

function! v3m#page#get_v3m(bufnr) abort
  let v3m = getbufvar(a:bufnr, "v3m")
  if type(v3m) != v:t_dict
    let v3m ={}
    call setbufvar(a:bufnr, "v3m", v3m)
  endif
  return v3m
endfunction

function! v3m#page#get_page(bufnr) abort
  return v3m#page#get_param(a:bufnr, 'page', [])
endfunction

function! v3m#page#clear_page(bufnr) abort
  let page = v3m#page#get_page(a:bufnr)

  if !empty(page)
    call remove(page, 0, -1)
  endif
endfunction

function! v3m#page#get_meta(bufnr) abort
  return v3m#page#get_param(a:bufnr, 'meta', [])
endfunction

function! v3m#page#clear_meta(bufnr) abort
  let meta = v3m#page#get_meta(a:bufnr)

  if !empty(meta)
    call remove(meta, 0, -1)
  endif
endfunction

function! v3m#page#get_fragments(bufnr) abort
  return v3m#page#get_param(a:bufnr, 'fragments', {})
endfunction

function! v3m#page#clear_fragments(bufnr) abort
  call v3m#page#set_param(a:bufnr, 'fragments', {})
endfunction

function! v3m#page#get_forms(bufnr) abort
  return v3m#page#get_param(a:bufnr, 'forms', {})
endfunction

function! v3m#page#clear_forms(bufnr) abort
  call v3m#page#set_param(a:bufnr, 'forms', {})
endfunction

function! v3m#page#get_param(bufnr, param_name, default='') abort
  let v3m = v3m#page#get_v3m(a:bufnr)
  if has_key(v3m, a:param_name)
    let param = v3m[a:param_name]
  else
    let param = a:default
    let v3m[a:param_name] = param
  endif
  return param
endfunction

function! v3m#page#set_param(bufnr, param_name, value) abort
  let v3m = v3m#page#get_v3m(a:bufnr)
  let v3m[a:param_name] = a:value
endfunction

