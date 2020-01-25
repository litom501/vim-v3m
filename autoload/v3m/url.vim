scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License

let s:v3m = '[v3m]'
let s:v3m_error = s:v3m . '[ERROR]'
let s:v3m_warn  = s:v3m . '[WARN ]'

" normalize url. e.g. completion protcol
"function! v3m#url#normalize(url, domain='') abort
function! v3m#url#normalize(url, domain) abort
  if a:url == ''
    echoerr s:v3m_error 'Invalid argument.'
  endif

  " ~/ ./ ../
  let is_local_path = matchstrpos(a:url, '^\(\/\|\~\/\|\.\/\|\.\.\/\)')[1] != -1

  if is_local_path
    if a:domain == ''
      " local path
      return a:url
    else
      let url = a:domain . a:url
    endif
  else
    let url = a:url
  endif

  if match(url, '://') < 0
    return 'https://' . url
  else
    return url
  endif
endfunction

function! v3m#url#_parse_path(str) abort
  let path = s:divide(a:str, '?')
  if !empty(path)
    let query = s:divide(path[1], '#')
    if empty(query)
      return [ path[0], path[1], '' ]
    else
      return [ path[0], query[0], query[1] ]
    endif
  else
    let query = s:divide(a:str, '#')
    if empty(query)
      return [ a:str, '', '' ]
    else
      return [ query[0], '', query[1] ]
    endif
  endif
endfunction

function! s:divide(str, delim) abort
  let strpos = matchstrpos(a:str, a:delim)
  if strpos[1] == -1
    return []
  else
    if len(a:str) == strpos[1] + 1
      return [ strpart(a:str, 0, strpos[1]), '' ]
    else
      return [ strpart(a:str, 0, strpos[1]), strpart(a:str, strpos[1] + 1) ]
    endif
  endif
endfunction

function! v3m#url#_parse_domain(str) abort
  let strpos = matchstrpos(a:str, ':')
  if strpos[1] == -1
    return [ a:str, '']
  else
    if len(a:str) == strpos[1] + 1
      echoerr s:v3m_error 'Invalid domain'
    else
      return [ strpart(a:str, 0, strpos[1]), strpart(a:str, strpos[1] + 1) ]
    endif
  endif

endfunction

function! v3m#url#parse(url) abort
  let rv = #{ scheme:'', domain:'', port:'', path:'', query:'', fragment:'' }
  if a:url == ''
    echoerr s:v3m_error 'Invalid argument. url is empty.'
  endif

  if a:url[0] == '/'
    let path = v3m#url#_parse_path(a:url)

    let rv.path = path[0]
    let rv.query = path[1]
    let rv.fragment = path[2]

    return rv
  endif

  let strpos = matchstrpos(a:url, '://')

  if strpos[1] == -1
    let path = v3m#url#_parse_path(a:url)

    let rv.path = path[0]
    let rv.query = path[1]
    let rv.fragment = path[2]

    return rv
  else
    if len(a:url) == strpos[2]
      " e.g. url == https://
      echoerr s:v3m_error 'Invalid url'
    else
      let rv['scheme'] = strpart(a:url, 0, strpos[1])
      let strpos2 = matchstrpos(a:url, '/', strpos[2])
      if strpos2[1] == -1
        let domain = v3m#url#_parse_domain(strpart(a:url, strpos[2]))
        let rv['domain'] = domain[0]
        let rv['port'] = domain[1]

        return rv
      else
        let domain = v3m#url#_parse_domain(strpart(a:url, strpos[2], strpos2[1] - strpos[2]))
        let rv['domain'] = domain[0]
        let rv['port'] = domain[1]

        let path = v3m#url#_parse_path(strpart(a:url, strpos2[1]))
        let rv['path'] = path[0]
        let rv['query'] = path[1]
        let rv['fragment'] = path[2]

        return rv
      endif
    endif
  endif

endfunction

function! v3m#url#domain(url) abort
  if a:url == ''
    echoerr s:v3m_error 'Invalid argument.'
  endif

  if a:url[0] == '/'
    return ''
  endif

  let strpos = matchstrpos(a:url, '://')

  if strpos[1] == -1
    return ''
  else
    if len(a:url) == strpos[2]
      " e.g. url == https://
      echoerr s:v3m_error 'Invalid url'
    else
      let strpos2 = matchstrpos(a:url, '/', strpos[2])
      if strpos2[1] == -1
        return strpart(a:url, strpos[2])
      else
        return strpart(a:url, strpos[2], strpos2[1] - strpos[2])
      endif
    endif
  endif

endfunction

function! v3m#url#resolve(url, base_url) abort
  let url = v3m#url#parse(a:url)
  let base_url = v3m#url#parse(a:base_url)
  if url['domain'] != ''
    return a:url
  elseif url['scheme'] == '' && base_url['scheme'] == ''
    return v3m#url#_resolve_path(url['path'], base_url['path'])
  else
    let resolved_path = v3m#url#_resolve_path(url['path'], base_url['path'])
    let rv = base_url['scheme'] . '://'
    let rv .= base_url['domain']
    if base_url['port'] != ''
      let rv .= ':' . base_url['port']
    endif
    if resolved_path[0] != '/'
      let rv .= '/'
    endif
    let rv .= resolved_path
    if url['query'] != ''
      let rv .= '?' . url['query']
    endif
    if url['fragment'] != ''
      let rv .= '#' . url['fragment']
    endif
    return rv
  end
endfunction

function! v3m#url#is_same_page(url_1, url_2) abort
  let parsed_1 = v3m#url#parse(a:url_1)
  let parsed_2 = v3m#url#parse(a:url_2)

  return parsed_1['domain'] ==# parsed_2['domain'] 
        \ && parsed_1['path'] ==# parsed_2['path']
        \ && parsed_1['query'] ==# parsed_2['query']
endfunction

function s:split(path) abort
  if empty(a:path)
    let path = []
  else
    let path = split(a:path, '/', 1)
  endif
  return path
endfunction

function! v3m#url#_resolve_path(path, base_path) abort
  if empty(a:base_path)
    return a:path
  endif

  let path = s:split(a:path)
  let base_path = s:split(a:base_path)

  " empty
  if empty(path)
    return a:base_path
  " absolute
  elseif path[0] == ''
    return a:path
  " relative
  else
    let back_level = s:absolute_level(path)
    if len(base_path) < back_level
      echoerr s:v3m_error 'Invalid url' back_level a:path a:base_path
    endif
    let path = path[back_level:]
    if base_path[-1] != ''
      let base_path = base_path[0:-2]
    endif
    if back_level > 0
      if base_path[-1] == ''
        let offset = 2
      else
        let offset = 1
      endif
      let base_path = base_path[0 : -1 * (back_level + offset)]
    endif
    if !empty(base_path) && base_path[-1] != ''
      call add(base_path, '')
    elseif !empty(base_path) && len(base_path) == 1 && base_path[0] == ''
      call add(base_path, '')
    endif
    return join(base_path, '/') . join(path, '/')
  endif

endfunction

function! s:absolute_level(path) abort
  let level = 0
  for i in range(len(a:path))
    let element = a:path[i]
    if element == '..'
      let level += 1
    else
      break
    endif
  endfor
  return level
endfunction

" FIXME encode non-ascii characters
function! v3m#url#percent_encode(str) abort
  let len = strlen(a:str)
  let rv = []
  for i in range(len)
    let c = a:str[i]
    if has_key(s:percent_encodings, c)
      let value = s:percent_encodings[c]
      call add(rv, value)
    else
      call add(rv, c)
    endif
  endfor
  return join(rv, '')
endfunction

function! v3m#url#percent_decode(str) abort
  let rv = []
  let start = 0
  while 1
    let pos = matchstrpos(a:str, '%[a-fA-F0-9][a-fA-F0-9]' , start)

    if pos[1] == -1
      call add(rv, strpart(a:str, start))
      break
    endif

    let part = strpart(a:str, pos[1], 3)
    let part = toupper(part)

    let byte = str2nr(part[1:2], 16)
    call add(rv, strpart(a:str, start, pos[1] - start))
    " FIXME Check how to decode without using printf.
    call add(rv, printf('\x%x', byte))
    let start = pos[1] + 3

  endwhile
  "return join(rv, '')
  return eval('"' . join(rv, '') . '"')
endfunction

let s:percent_encodings = {
  \':': '%3A',
  \'/': '%2F',
  \'?': '%3F',
  \'#': '%23',
  \'[': '%5B',
  \']': '%5D',
  \'@': '%40',
  \ }

let s:percent_decodings = {}
for key in keys(s:percent_encodings)
  let value = s:percent_encodings[key]
  let s:percent_decodings[value] =  key
endfor
