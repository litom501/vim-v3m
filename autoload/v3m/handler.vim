scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License

let s:v3m = '[v3m]'
let s:v3m_error = s:v3m . '[ERROR]'
let s:v3m_warn  = s:v3m . '[WARN ]'
let s:v3m_debug = s:v3m . '[DEBUG]'

let s:sequence = 0
function! v3m#handler#job_start(url, bufnr, cols) abort
  let s:sequence += 1
  let s:sequence_options.buffers[s:sequence] = a:bufnr
  let s:sequence_options.urls[s:sequence] = a:url
  let s:sequence_options.cols[s:sequence] = a:cols

  let pos = matchstrpos(a:url, "^http[s]*:")
  if pos[1] == -1
    "local
    let handler = s:local_handler
  else
    let handler = s:remote_handler
  endif

  let jobid = async#job#start(handler.cmd(a:url, a:cols),
        \{
        \   "on_stdout": handler.on_stdout,
        \   "on_exit": handler.on_exit,
        \   "on_stderr": handler.on_stderr,
        \})
  let s:job_context.sequences[jobid] = s:sequence
endfunction

function! v3m#handler#render_page(bufnr)
  let page_info = s:get_page_info(a:bufnr)
  let parse_info = #{
    \ tag_stack: [],
    \ i: 0,
    \ col: -1,
    \ texts: [],
    \ prop_list: [],
    \ page_len: len(page_info.page),
    \}

  call setbufvar(a:bufnr, '&modifiable', 1)

  while parse_info.i < parse_info.page_len
    let parse_info.col = 1
    let parse_info.texts = []
    let parse_info.prop_list = []

    let col = 1

    "let elements = v3m#parse#split_elements(page_info.page[parse_info.i])
    let elements = v3m#parse#split_elements2(page_info.page, parse_info.i)
    let texts = []
    let prop_list = []
    let in_tag = 0
    let tag_element = ''

    let max_offset = 0
    for element in elements
      let max_offset = element.offset

      if element.text[0] != '<'
        if !in_tag
          let str = v3m#util#decode_char_entity_ref(element.text)
          let parse_info.col += strlen(str)

          while len(parse_info.texts) <= element.offset
            call add(parse_info.texts, [])
          endwhile

          call add(parse_info.texts[element.offset], str)
        else
          let tag_element = ' ' . element.text
          if element.text[-1:] == '>'
            call s:add_tag(page_info, parse_info, tag_element)
            let tag_element = ''
            let in_tag = 0
          endif
        endif
      " tag start
      else
        let in_tag = 1

        if element.text[-1:] == '>'
          call s:add_tag(page_info, parse_info, element.text)
          let in_tag = 0
        else
          let tag_element = ' ' . element.text
        endif
      endif
    endfor

    " add unclosed tags
    call s:add_tags(page_info, parse_info, '')

    for i in range(max_offset + 1)
      let line = (len(parse_info.texts) > i) ? join(parse_info.texts[i], '') : ''
      call setbufline(a:bufnr, parse_info.i + 1 + i, line)
    endfor

    call s:add_props(parse_info.prop_list)
    let parse_info.i += (1 + max_offset)

  endwhile

  let parsed_url = v3m#url#parse(page_info.url)
  if parsed_url['fragment'] != ''
    call v3m#goto_name(a:bufnr, parsed_url['fragment'])
  endif

  call setbufvar(a:bufnr, '&modifiable', 0)
endfunction

function! s:add_tag(page_info, parse_info, text) abort
  let tag = v3m#parse#tag(a:text)
  if tag['tag_type'] ==# 'open'
    let tag['=lnum'] = a:parse_info.i + 1
    let tag['=col'] = a:parse_info.col

    call add(a:parse_info.tag_stack, tag)
  elseif tag['tag_type'] ==# 'close'
    let tag_name = tag['tag_name']

    call s:add_tags(a:page_info, a:parse_info, tag_name)
  else
    echoerr s:v3m_error ':' 'Unknown tag_type.'
  endif
endfunction

function! s:get_page_info(bufnr) abort
  return #{
        \   page: v3m#page#get_page(a:bufnr),
        \   meta: v3m#page#get_meta(a:bufnr),
        \   fragments: v3m#page#get_fragments(a:bufnr),
        \   forms: v3m#page#get_forms(a:bufnr),
        \   url: v3m#page#get_param(a:bufnr, 'url', ''),
        \   bufnr: a:bufnr,
        \ }
endfunction

function! s:add_tags(page_info, parse_info, close_tag_name) abort
  while len(a:parse_info.tag_stack) > 0
    let open_tag = remove(a:parse_info.tag_stack, len(a:parse_info.tag_stack) - 1)
    let open_tag_name = open_tag['tag_name']

    if empty(a:close_tag_name)
      let close_lnum = ''
      let close_col = ''
    else
      let close_lnum = a:parse_info.i + 1
      let close_col = a:parse_info.col
    endif
    call v3m#parse#add_tag_data(
          \ a:page_info.url,
          \ a:page_info.meta,
          \ a:page_info.fragments,
          \ a:page_info.forms,
          \ a:parse_info.prop_list,
          \ a:page_info.bufnr,
          \ open_tag,
          \ close_lnum,
          \ close_col)
    if empty(a:close_tag_name)
      " unclosed tag
    elseif open_tag['tag_type'] ==# 'open' && a:close_tag_name ==? open_tag_name
      break
    else
      " unclosed tag
    endif
  endwhile
endfunction

function! s:add_props(prop_list) abort
  for prop in a:prop_list
    try
      call prop_add(prop['lnum'], prop['col'], prop['props'])
    catch /.*/
      echoerr s:v3m_error printf('lnum, col : %d, %d(prop : %s), max lnum : %d', prop['lnum'], prop['col'], prop['props'], line('$'))
    endtry
  endfor
endfunction

function! s:render_page(bufnr, contents) abort
  call setbufvar(a:bufnr, '&modifiable', 1)
  call deletebufline('%', 1, '$')
  for idx in range(len(a:contents))
    call setbufline(a:bufnr, idx+1, a:contents[idx])
  endfor
  call setbufvar(a:bufnr, '&modifiable', 0)
endfunction

function! v3m#handler#render_downloading_page(bufnr) abort
  let url = v3m#page#get_param(a:bufnr, 'url', '')
  let contents = [
        \ 'Downloading...',
        \ '',
        \ printf('  %s', url),
        \]
  call s:render_page(a:bufnr, contents)
endfunction

function! v3m#handler#render_download_page(bufnr) abort
  let url = v3m#page#get_param(a:bufnr, 'url', '')
  let contents = [
        \ 'Download',
        \ '',
        \ printf('  %s', url),
        \]
  call s:render_page(a:bufnr, contents)
endfunction

function! v3m#handler#render_download_cancel_page(bufnr) abort
  let url = v3m#page#get_param(a:bufnr, 'url', '')
  let contents = [
        \ 'Canceled download file',
        \ '',
        \ printf('  %s', url),
        \]
  call s:render_page(a:bufnr, contents)
endfunction

function! v3m#handler#render_error_page(bufnr) abort
  let url = v3m#page#get_param(a:bufnr, 'url', '')
  let contents = [
        \ 'ERROR',
        \ '  Connection refused.',
        \ '',
        \ printf('  %s', url),
        \]
  call s:render_page(a:bufnr, contents)
endfunction

function! s:get_sequence(jobid) abort
  return get(s:job_context.sequences, a:jobid, 0)
endfunction

function! s:remove_sequence(jobid) abort
  call remove(s:job_context.sequences, a:jobid)
endfunction

function! s:get_bufnr(sequence) abort
  let bufnr = s:sequence_options.buffers[a:sequence]
  return bufnr
endfunction

function! s:get_cols(sequence) abort
  let bufnr = s:sequence_options.cols[a:sequence]
  return bufnr
endfunction

function! s:remove_options(sequence) abort
  call remove(s:sequence_options.buffers, a:sequence)
  call remove(s:sequence_options.urls, a:sequence)
  call remove(s:sequence_options.cols, a:sequence)
endfunction

function! s:data_out(jobid, msg, msg_container) abort
  let lastmsg = get(s:job_context.lastmsg, a:jobid, '')
  if lastmsg != ''
    let a:msg[0] = lastmsg . a:msg[0]
  endif

  if len(a:msg) >= 2
    call extend(a:msg_container, a:msg[:-2])
  endif

  let s:job_context.lastmsg[a:jobid] = a:msg[-1]
endfunction

function! s:data_close(jobid, msg_container) abort
  if has_key(s:job_context.lastmsg, a:jobid)
    let lastmsg = get(s:job_context.lastmsg, a:jobid, '')
    if lastmsg != ''
      call add(a:msg_container, lastmsg)
    endif
    call remove(s:job_context.lastmsg, a:jobid)
  endif
endfunction

function! s:default_cmd(url, cols) abort
  let options = '-halfdump -o ext_halfdump=-1 -cols ' . a:cols
  let cmd = 'w3m ' . options . ' ' . a:url
  return cmd
endfunction

function! s:default_out(jobid, msg, event_type) abort
  let sequence = s:get_sequence(a:jobid)
  if !sequence
    echoerr s:v3m_error ':' 'job id is missing.'
    return
  endif
  let page = v3m#page#get_page(s:get_bufnr(sequence))

  call s:data_out(a:jobid, a:msg, page)
endfunction

function! s:default_close_wrap(jobid, exit_code, event_type) abort
  " invoke out_cb after exit_cb
  call timer_start(100, function("s:default_close_wrap_1", [a:jobid, a:exit_code, a:event_type]))
endfunction

function! s:default_close_wrap_1(jobid, exit_code, event_type, timer_id) abort
  call s:default_close(a:jobid, a:exit_code, a:event_type)
endfunction

function! s:default_close(jobid, exit_code, event_type) abort
  let sequence = s:get_sequence(a:jobid)
  if !sequence
    echoerr s:v3m_error ':' 'job id is missing.'
    return
  endif

  let bufnr = s:get_bufnr(sequence)

  if a:exit_code > 0
    call v3m#handler#render_error_page(bufnr)
  endif

  let page = v3m#page#get_page(bufnr)
  call s:data_close(a:jobid, page)

  call v3m#handler#render_page(bufnr)

  let sequence = s:get_sequence(a:jobid)
  call s:remove_options(sequence)
  call s:remove_sequence(a:jobid)
endfunction

function! s:default_error(jobid, msg, event_type) abort
  let sequence = s:get_sequence(a:jobid)
  if !sequence
    echoerr s:v3m_error ':' 'job id is missing.'
    return
  endif

  let bufnr = s:get_bufnr(sequence)
  call v3m#handler#render_error_page(bufnr)
endfunction

function! s:curl_cmd(url, cols) abort
  let options = '-i -L -A ' . s:get_user_agent()
  let cmd = 'curl ' . options . ' ' . a:url
  return cmd
endfunction

function! s:curl_out(jobid, msg, event_type) abort
  let sequence = s:get_sequence(a:jobid)
  if !sequence
    echoerr s:v3m_error ':' 'job id is missing.'
    return
  endif

  let source = v3m#page#get_source(s:get_bufnr(sequence))

  call s:data_out(a:jobid, a:msg, source)
endfunction

function! s:curl_close_wrap(jobid, exit_code, event_type) abort
  call timer_start(100, function("s:curl_close_wrap_1", [a:jobid, a:exit_code, a:event_type]))
endfunction

function! s:curl_close_wrap_1(jobid, exit_code, event_type, timer_id) abort
  call c:curl_close(jobid, exit_code, event_type)
endfunction

function! s:curl_close(jobid, exit_code, event_type) abort
  let sequence = s:get_sequence(a:jobid)
  let bufnr = s:get_bufnr(sequence)
  let cols = s:get_cols(sequence)

  let source = v3m#page#get_source(bufnr)
  call s:data_close(a:jobid, source)

  if len(source) != 0
    " header
    let header_from = -1
    let header_to = -1
    let location = ''

    call v3m#page#clear_response_headers(bufnr)
    let response_headers = v3m#page#get_response_headers(bufnr)

    let header = {}
    while 1
      "let tmp = s:get_header_to(source, header_to + 1)
      let tmp = v3m#header#get_header_to(source, header_to + 1)
      if tmp != -1
        let header_from = header_to + 1
        let header_to = tmp

        let header = v3m#header#parse_response_header(source[header_from:header_to])
        call add(response_headers, header)

        let header = s:normalize_keys(header)
        let location = get(header, 'location', location)
      else
        break
      endif
    endwhile

    if !empty(location)
      let url = v3m#page#get_param(bufnr, 'url', '')
      if !empty(url)
        let location = v3m#url#resolve(location, url)
      endif
      call v3m#rename_buffer_by_url(bufnr, location)
    endif

    " source
    let tmpfile = tempname() . '.html'
    "echom 'tmpfile' tmpfile
    call writefile(source[header_to+1:], tmpfile, 's')
    call v3m#page#clear_source(bufnr)

    let content_type = get(header, 'content-type')
    "let type = s:get_content_type_type(content_type)
    let type = v3m#header#get_content_type_type(content_type)

    " content-type : text
    if len(matchstr(type, '^\ctext/')) != 0
      "let charset = s:get_content_type_charset(content_type)
      let charset = v3m#header#get_content_type_charset(content_type)
      call v3m#page#set_param(bufnr, 'charset', charset)

      let charset_option = empty(charset) ? '' : '-I ' . charset
      let rv = systemlist('w3m -halfdump ' . charset_option . ' -o ext_halfdump=-1 -cols ' . cols . ' ' . fnameescape(tmpfile))
      call delete(tmpfile)

      let page = v3m#page#get_page(bufnr)
      call extend(page, rv)
      call v3m#handler#render_page(bufnr)
    " content-type : non text
    else
      call v3m#handler#render_downloading_page(bufnr)
      redraw

      let url = v3m#page#get_param(bufnr, 'url', '')
      let url_elements = v3m#url#parse(url)

      let path = url_elements.path
      echom 'path' path
      let file = matchstr(path, '[^\/]*$')
      "echom 'file' file
      call inputsave()
      " 'text'(2nd parameter) is not woking
      "let save_path = input('save as : ', file, 'file')
      let save_path = input('save as ('. file . ') : ', '', 'file')
      call inputrestore()
      if !empty(save_path)
        call rename(tmpfile, fnameescape(save_path))
        call v3m#handler#render_download_page(bufnr)
      else
        call delete(tmpfile)
        call v3m#handler#render_download_cancel_page(bufnr)
      endif
    endif
    redraw
  endif

  let sequence = s:get_sequence(a:jobid)
  call s:remove_options(sequence)
  call s:remove_sequence(a:jobid)
endfunction

function! s:normalize_keys(dict) abort
  let rv = {}
  for k in keys(a:dict)
    let rv[tolower(k)] = a:dict[k]
  endfor

  return rv
endfunction

let s:user_agent = ''

function! s:get_user_agent() abort
  if len(s:user_agent) == 0
    let s:user_agent = matchstr(system('w3m -V'), 'w3m version \zs[^,]\+')
  endif
  return s:user_agent
endfunction

function! s:curl_error(jobid, msg, event_type) abort
  "echom 'default_error' a:msg
endfunction

let s:default_handler = {
  \ 'cmd': function('s:default_cmd'),
  \ 'on_stdout': function('s:default_out'),
  \ 'on_exit': function('s:default_close_wrap'),
  \ 'on_stderr': function('s:default_error'),
  \}

let s:curl_w3m_handler = {
  \ 'cmd': function('s:curl_cmd'),
  \ 'on_stdout': function('s:curl_out'),
  \ 'on_exit': function('s:curl_close'),
  \ 'on_stderr': function('s:curl_error'),
  \}

let s:sequence_options = {
  \   'buffers': {},
  \   'urls': {},
  \   'cols': {},
  \}

let s:job_context = {
  \ 'sequences': {},
  \ 'lastmsg': {}
  \}

let s:local_handler = s:default_handler
"let s:remote_handler = s:default_handler
let s:remote_handler = s:curl_w3m_handler

