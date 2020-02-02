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
  let page = v3m#page#get_page(a:bufnr)
  let meta = v3m#page#get_meta(a:bufnr)
  let fragments = v3m#page#get_fragments(a:bufnr)
  let forms = v3m#page#get_forms(a:bufnr)
  let url = v3m#page#get_param(a:bufnr, 'url', '')
  let tag_stack = []

  call setbufvar(a:bufnr, '&modifiable', 1)

  for i in range(len(page))
    let col = 1

    let elements = v3m#parse#split_elements(page[i])
    let texts = []
    let prop_list = []

    for element in elements
      if element[0] != '<'
        let str = v3m#util#decode_char_entity_ref(element)
        let col += strlen(str)
        call add(texts, str)
      else
        let tag = v3m#parse#tag(element)
        if tag['tag_type'] ==# 'open'
          let tag['=lnum'] = i + 1
          let tag['=col'] = col

          call add(tag_stack, tag)
        elseif tag['tag_type'] ==# 'close'
          let tag_name = tag['tag_name']

          while len(tag_stack) > 0
            let open_tag = remove(tag_stack, len(tag_stack) - 1)
            let open_tag_name = open_tag['tag_name']

            call v3m#parse#add_tag_data(url, meta, fragments, forms, prop_list, a:bufnr, open_tag, i + 1, col)
            if open_tag['tag_type'] ==# 'open' && tag_name ==? open_tag_name
              break
            else
              " unclosed tag
            endif
          endwhile
        else
          echoerr s:v3m_error ':' 'Unknown tag_type.'
        endif
      endif

    endfor

    while len(tag_stack) > 0
      let open_tag = remove(tag_stack, len(tag_stack) - 1)

      " unclosed tag
      call v3m#parse#add_tag_data(url, meta, fragments, forms, prop_list, a:bufnr, open_tag, '', '')
    endwhile

    call setbufline(a:bufnr, i + 1, join(texts, ''))

    for prop in prop_list
      try
        call prop_add(prop['lnum'], prop['col'], prop['props'])
      catch /.*/
        echoerr s:v3m_error printf('lnum, col : %d, %d(prop : %s), max lnum : %d', prop['lnum'], prop['col'], prop['props'], line('$'))
      endtry
    endfor
  endfor

  let parsed_url = v3m#url#parse(url)
  if parsed_url['fragment'] != ''
    call v3m#goto_name(a:bufnr, parsed_url['fragment'])
  endif

  call setbufvar(a:bufnr, '&modifiable', 0)
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

"function! s:get_header_to(source, from) abort
"  if len(a:source) < a:from
"    return -1
"  endif
"  if matchstrpos(a:source[a:from], '^HTTP.*\r')[1] != 0
"    return -1
"  endif
"  return index(a:source, "\r", a:from)
"endfunction

"" TODO test
"function! s:get_content_type_type(content_type) abort
"  let list = matchlist(a:content_type, '\c^[ ]*\([^ ;]\+\)[ ]*;')
"  if empty(list)
"    return ''
"  else
"    return list[1]
"  endif
"endfunction

"function! s:get_content_type_charset(content_type) abort
"  let list = matchlist(a:content_type, '\c;[ ]*charset=\(\%(\w\|\-\)*\)')
"  if empty(list)
"    return ''
"  else
"    return list[1]
"  endif
"endfunction

"function! s:parse_response_header(response_headers) abort
"  if len(a:response_headers) == 0
"    return {}
"  endif
"  let status_line = matchlist(a:response_headers[0], 'HTTP/\([^ ]\+\) \([^ ]\+\) \(.*\)\r')
"  if empty(status_line)
"    echom 'empty status_line' a:response_headers
"    return {}
"  endif
"
"  let list = {}
"  let list[':HTTP-Version'] = status_line[1]
"  let list[':Status-Code'] = status_line[2]
"  let list[':Reason-Phrase'] = status_line[3]
"
"  for i in range(len(a:response_headers))
"    let pos = matchstrpos(a:response_headers[i], '^[^:]\+\zs:.*\r$')
"    if pos[1] == -1
"      continue
"    else
"      let key = a:response_headers[i][0:pos[1]-1]
"      let value = trim(a:response_headers[i][pos[1]+1:])
"      let list[key] = value
"    endif
"  endfor
"
"  return list
"endfunction

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

