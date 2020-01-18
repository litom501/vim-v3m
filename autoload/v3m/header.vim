scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License


function! v3m#header#get_header_to(source, from) abort
  if len(a:source) < a:from
    return -1
  endif
  if matchstrpos(a:source[a:from], '^HTTP.*\r')[1] != 0
    return -1
  endif
  return index(a:source, "\r", a:from)
endfunction

function! v3m#header#get_content_type_type(content_type) abort
  let list = matchlist(a:content_type, '\c^[ ]*\([^ ;]\+\)[ ]*;\?')
  if empty(list)
    return ''
  else
    return list[1]
  endif
endfunction

function! v3m#header#get_content_type_charset(content_type) abort
  let list = matchlist(a:content_type, '\c;[ ]*charset=\(\%(\w\|\-\)*\)')
  if empty(list)
    return ''
  else
    return list[1]
  endif
endfunction

function! v3m#header#parse_response_header(response_headers) abort
  if len(a:response_headers) == 0
    return {}
  endif
  let status_line = matchlist(a:response_headers[0], 'HTTP/\([^ ]\+\) \([^ ]\+\) \(.*\)\r')
  if empty(status_line)
    echom 'empty status_line' a:response_headers
    return {}
  endif

  let list = {}
  let list[':HTTP-Version'] = status_line[1]
  let list[':Status-Code'] = status_line[2]
  let list[':Reason-Phrase'] = status_line[3]

  for i in range(len(a:response_headers))
    let pos = matchstrpos(a:response_headers[i], '^[^:]\+\zs:.*\r$')
    if pos[1] == -1
      continue
    else
      let key = a:response_headers[i][0:pos[1]-1]
      let value = trim(a:response_headers[i][pos[1]+1:])
      let list[key] = value
    endif
  endfor

  return list
endfunction
