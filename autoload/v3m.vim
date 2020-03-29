scriptencoding utf-8
" A web browser interface plugin for Vim
" Author  : Koji Sato <litom501+vim@gmail.com>
" License : MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:v3m = '[v3m]'
let s:v3m_error = s:v3m . '[ERROR]'
let s:v3m_warn  = s:v3m . '[WARN ]'
let s:v3m_debug = s:v3m . '[DEBUG]'

let s:default_max_col = float2nr(80 * 1.5)

let s:mode_normal = 0
let s:mode_reload = -1
let s:mode_back = -2

function! s:debug() abort
  if exists('g:v3m#debug')
    return g:v3m#debug
  else
    return 0
  endif
endfunction

function! s:is_reload(mode) abort
  return a:mode == -1
endfunction

function! s:is_back(mode) abort
  return a:mode == -2
endfunction

function! s:get_url(v3m_uri) abort
  let prefix = 'v3m://'
  if len(a:v3m_uri) >= len(prefix) && a:v3m_uri[0:len(prefix) - 1] ==# prefix
    return a:v3m_uri[len(prefix):]
  else
    return ''
  endif
endfunction

function! v3m#open_v3m(url) abort
  let prefix = 'v3m://'
  if len(a:url) >= len(prefix) && a:url[0:len(prefix) - 1] ==# prefix
    call v3m#open(a:url[len(prefix):], 0)
  else
    echoerr s:v3m_error 'Invalid argument. :' a:url
  endif
endfunction

function! v3m#get_current_url() abort
  let bufnr = bufnr('%')
  call s:validate_v3m_buffer(bufnr)

  let url = v3m#page#get_param(bufnr, 'url', '')
  return matchstr(url, '\zs[^ ]*\ze')
endfunction

function! v3m#input_location() abort
  let bufnr = bufnr('%')
  call s:validate_v3m_buffer(bufnr)

  let url = v3m#page#get_param(bufnr, 'url', '')
  let new_url = input(s:v3m . ' Location : ', url, 'file')
  if !empty(new_url)
    call v3m#open(new_url, 0)
  endif
endfunction

function! v3m#show_cursor_link() abort
  let url = v3m#get_curlink()
  if !empty(url)
    call input('link : ', url)
  endif
endfunction

function! s:validate_v3m_buffer(bufnr) abort
  if !s:is_v3m_buffer(a:bufnr)
    echoerr s:v3m_error 'The buffer is not v3m buffer. : ' a:bufnr
  end
endfunction

"function! v3m#open(url='', mode = 0) abort
function! v3m#open(url, mode) abort
  let bare_url = trim(a:url)

  if empty(bare_url)
    if exists("g:v3m#homepage")
      let bare_url = trim(g:v3m#homepage)
    else
      echoerr s:v3m_error 'Invalid arguments. URL is empty'
    endif
  endif

  let url = v3m#url#normalize(bare_url, '')
  let bufname = v3m#create_bufname(url, 1)
  let bufnr = bufnr('%')

  if !s:is_reload(a:mode) && !s:is_back(a:mode)
    let prev_url = v3m#page#get_param(bufnr, 'url', '')
    if prev_url != ''
      let history = v3m#page#get_param(bufnr, 'history', [])
      call add(history, prev_url)

      if v3m#url#is_same_page(prev_url, url)
        let parsed_url = v3m#url#parse(url)
        call v3m#goto_name(bufnr, parsed_url['fragment'])
        return
      endif
    endif
  endif

  call s:configure_buffer(bufnr)
  call setbufvar(bufnr, '&modifiable', 1)
  execute 'normal I' . 'Loading... : ' . url
  call setpos('.', [bufnr, 1, 1, 0])
  call setbufvar(bufnr, '&modifiable', 0)

  call v3m#util#rename_buffer(bufnr, bufname)

  call v3m#page#set_param(bufnr, 'url', url)
  call v3m#page#set_param(bufnr, 'domain', v3m#url#domain(url))

  call v3m#page#clear_meta(bufnr)
  call v3m#page#clear_page(bufnr)
  call v3m#page#clear_fragments(bufnr)
  call v3m#page#clear_forms(bufnr)

  let win_cols = winwidth(win_getid())
  let max_cols = getbufvar(bufnr, 'v3m_max_cols', get(g:, 'v3m_max_cols', s:default_max_col))
  let cols = min([win_cols, max_cols])

  call v3m#handler#job_start(url, bufnr, cols)
endfunction

function! v3m#rename_buffer_by_url(bufnr, url) abort
  let normalized_url = v3m#url#normalize(a:url, '')
  let bufname = v3m#create_bufname(normalized_url, 1)

  call v3m#util#rename_buffer(a:bufnr, bufname)
  call v3m#page#set_param(a:bufnr, 'url', a:url)
  call v3m#page#set_param(a:bufnr, 'domain', v3m#url#domain(a:url))
endfunction

function! v3m#create_bufname(url, reuse_buffer) abort
  let cnt = 1
  let bufname = 'v3m://' . a:url

  while bufnr(bufname) != -1
    if a:reuse_buffer && bufname == bufname('%')
      break
    endif

    let bufname = 'v3m://' . a:url . ' ' . cnt
    let cnt = cnt + 1
  endwhile

  return bufname
endfunction

function! s:configure_buffer(bufnr) abort
  let current_bufnr = bufnr('%')

  if a:bufnr != current_bufnr
    execute 'buffer ' . a:bufnr
  endif

  setlocal filetype=v3m
  setlocal noswapfile
  setlocal modifiable

  " supress message "--No lines in buffer--
  silent call deletebufline('%', 1, '$')
  setlocal nonumber
  setlocal buftype=nofile
  setlocal nolist
  setlocal nowrap

  if a:bufnr != current_bufnr
    execute 'buffer ' . current_bufnr
  endif
endfunction

function! s:is_v3m_buffer(bufnr) abort
  let v3m = getbufvar(a:bufnr, "v3m")
  return type(v3m) == v:t_dict
endfunction

function! v3m#goto_name(bufnr, name) abort
  if a:name != ''
    let fragments = v3m#page#get_fragments(a:bufnr)
    let name = v3m#url#percent_decode(a:name)
    if has_key(fragments, name)
      let pos = fragments[name]
      call setpos('.', [ a:bufnr, pos['lnum'], pos['col'], 0])
      return 1
    endif
  else
    return 0
  endif
endfunction

"function! s:is_same_page(url_1, url_2) abort
"  let parsed_1 = v3m#url#parse(a:url_1)
"  let parsed_2 = v3m#url#parse(a:url_2)
"
"  if parsed_1['domain'] ==# parsed_2['domain']
"    return parsed_1['path'] ==# parsed_2['path']
"  else
"    return 0
"  endif
"endfunction

function! v3m#reload() abort
  let bufnr = bufnr('%')
  call s:validate_v3m_buffer(bufnr)
  let url = v3m#page#get_param(bufnr, 'url', '')
  call v3m#open(url, s:mode_reload)
endfunction

function! v3m#back() abort
  let bufnr = bufnr('%')
  call s:validate_v3m_buffer(bufnr)
  let history = v3m#page#get_param(bufnr, 'history', [])
  if len(history) > 0
    let url = remove(history, -1)
    call v3m#open(url, s:mode_back)
  endif
endfunction

function! v3m#back_history() abort
  let bufnr = bufnr('%')
  call s:validate_v3m_buffer(bufnr)

  let history = v3m#page#get_param(bufnr, 'history', [])

  if len(history) == 0
    echo s:v3m 'No history'
    return
  endif

  let list = map(copy(history), {idx, val -> printf("%2d : %s", idx + 1, val)})
  echo s:v3m 'History'
  let num = inputlist(list)
  if num != 0
    let removes = remove(history, num - 1, -1)
    call v3m#open(removes[0], s:mode_back)
  endif
endfunction

function! s:action(input) abort
  let attributes = s:meta_attributs(a:input)
  let fid = attributes['fid']
  let name = attributes['name']
  let value = attributes['value']
  let type = attributes['type']
"  echo 'input' a:input
"  echo 'fid' fid
"  echo 'name' name
"  echo 'value' value
"  echo 'type' type

  let bufnr = bufnr('%')
  let form = v3m#page#get_forms(bufnr)[fid]
  let charset = v3m#page#get_param(bufnr, 'charset', '')

  if type ==# 'text'
    let inputs = get(form, 'input_alt')
    if !empty(inputs)
      let i = get(inputs, name)
      if !empty(i)
        let current_value = get(i, '#current_value', value)
        let entry = input(name . ' : ', current_value)
        if !empty(entry)
          let i['#current_value'] = entry
        endif
      endif
    endif
  elseif type ==# 'submit'
    let inputs = get(form, 'input_alt')
    let query = ''

    for key in keys(inputs)
      let input_type = get(inputs[key], 'type')
      if input_type ==# 'submit'
        continue
      endif
      if !empty(query)
        let query .= '&'
      endif
      let v = get(inputs[key], '#current_value', value)
      if !empty(charset)
        let v = iconv(v, 'utf-8', charset)
        let v = v3m#util#str2percent(v)
      endif
      let query .= key . '=' . v
    endfor

    let form_int = get(form, 'form_int')

    if !empty(form_int)
      let action = get(form_int, 'action')
      if !empty(action)
        let query = tr(query, ' ', '+')
        let href = action . '?' . query
        let domain = v3m#page#get_param(bufnr, 'domain', '')
        let current_url = v3m#page#get_param(bufnr, 'url', '')
        let current_url = v3m#url#normalize(current_url, '')
        let url = v3m#url#normalize(v3m#url#resolve(href, current_url), domain)

        call v3m#open(url, 0)
      endif
    endif
  endif
endfunction

" Use when considering history.
function! v3m#open_link() abort
  let url = v3m#get_curlink()

  if !empty(url)
    call v3m#open(url, 0)
  else
    let input = s:get_cur_forminput()
    if !empty(input)
      call s:action(input)
    endif

  endif
endfunction

function! v3m#next_link(back) abort
  let bufnr = bufnr('%')
  let current_line = line('.')
  let current_col = col('.')
  let meta = v3m#page#get_meta(bufnr)

  if !a:back
    let line_range = range(line('.'), line('$'))
  else
    let line_range = range(1, line('.'))
    call reverse(line_range)
  endif

  for i in line_range
    let props = v3m#util#get_prop(bufnr, i, -1)
    let links_meta = []

    " links
    let links = v3m#util#filter(props,
                    \{ idx, value -> v3m#util#filter_array_by_map_value('type', 'v3m#link')(idx, value) })
    for link in links
      let data = meta[link['id']]
      let attributes = data['attributes']
      let href = v3m#util#find_by_map_value(attributes, 'attr_name', 'href', 0)
      if !empty(href)
        call add(links_meta, meta[link['id']])
      endif
    endfor

    " form input
    let links = v3m#util#filter(props,
                    \{ idx, value -> v3m#util#filter_array_by_map_value('type', 'v3m#form')(idx, value) })
    for link in links
      let data = meta[link['id']]
      let attributes = data['attributes']
      let form_element = v3m#util#find_by_map_value(attributes, 'attr_name', 'type', 0)
      if !empty(form_element) && get(form_element, 'attr_value') !=? 'hidden'
        call add(links_meta, meta[link['id']])
      endif
    endfor

    if len(links_meta) == 0
      continue
    endif

    call sort(links_meta, "s:sort_link")
    if a:back
      call reverse(links_meta)
    endif

    if i == current_line
      for j in range(len(links_meta))
        let col = links_meta[j]['col']
        if !a:back
          let exists_next_link = current_col < col
        else
          let end_col = links_meta[j]['end_col']
          let exists_next_link = current_col > end_col
        endif
        if exists_next_link
          let lnum = links_meta[j]['lnum']
          call setpos('.', [ bufnr, lnum, col, 0])
          return
        endif
      endfor
    else
      let lnum = links_meta[0]['lnum']
      let col = links_meta[0]['col']

      call setpos('.', [ bufnr, lnum, col, 0])
      return

    endif
  endfor
endfunction

function! s:sort_link(link1, link2) abort
  if a:link1['lnum'] < a:link2['lnum']
    return -1
  elseif a:link1['lnum'] > a:link2['lnum']
    return 1
  else
    if a:link1['col'] < a:link2['col']
      return -1
    elseif a:link1['col'] > a:link2['col']
      return 1
    else
      if a:link1['end_lnum'] < a:link2['end_lnum']
        return -1
      elseif a:link1['end_lnum'] > a:link2['end_lnum']
        return 1
      else
        if a:link1['end_col'] < a:link2['end_col']
          return -1
        elseif a:link1['end_col'] > a:link2['end_col']
          return 1
        else
          return 0
        endif
      endif
    endif
  endif

endfunction

function! v3m#get_curprop() abort
  return v3m#util#get_prop('%', line('.'), col('.'))
endfunction

function! s:get_cur_forminput() abort
  let bufnr = bufnr('%')
  let props = v3m#util#get_prop(bufnr, line('.'), col('.'))
  let inputs = v3m#util#filter(props,
                    \{ idx, value -> v3m#util#filter_array_by_map_value('type', 'v3m#form')(idx, value) })

  let meta = v3m#page#get_meta(bufnr)

  if len(inputs) > 0
    for input in inputs
      let metadata = meta[input['id']]
      if metadata['tag'] ==# 'input_alt'
        return metadata
      endif
    endfor
  else
    return ''
  endif
endfunction

function! s:meta_attributs(meta) abort
  let rv = {}
  for attr in a:meta['attributes']
    let rv[attr['attr_name']] = attr['attr_value']
  endfor

  return rv
endfunction

function! v3m#get_curlink() abort
  let bufnr = bufnr('%')
  let props = v3m#util#get_prop(bufnr, line('.'), col('.'))
  let links = v3m#util#filter(props,
                    \{ idx, value -> v3m#util#filter_array_by_map_value('type', 'v3m#link')(idx, value) })
  let meta = v3m#page#get_meta(bufnr)

  if len(links) > 0
    let link = meta[links[0]['id']]
    let attributes = link['attributes']
    let href = v3m#util#find_by_map_value(attributes, 'attr_name', 'href', 1)['attr_value']
    let href = v3m#util#decode_char_entity_ref(href)
    let domain = v3m#page#get_param(bufnr, 'domain', '')
    let current_url = v3m#page#get_param(bufnr, 'url', '')
    let current_url = v3m#url#normalize(current_url, '')
    let url = v3m#url#normalize(v3m#url#resolve(href, current_url), domain)

    return url
  else
    return ''
  endif
endfunction

let &cpo = s:save_cpo
" vim: ts=2 sw=2 et
