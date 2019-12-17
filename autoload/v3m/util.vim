scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License

function! v3m#util#get_prop(bufnr, lnum, col=-1) abort
  let props = {
        \ 'bufnr': a:bufnr
        \}
  let prop_list = prop_list(a:lnum, props)

  if type(a:col) == v:t_number && a:col == -1
    return prop_list
  endif
  let rv = []

  for prop in prop_list
    let col = prop['col']
    let start = prop['start']
    let end = prop['end']
    let length = prop['length']

    let current_byte = col([a:lnum, a:col])

    if !start && !end
      call add(rv, prop)
    elseif start
      let start_byte = col([a:lnum, col])
      if current_byte >= start_byte
        if end
          if current_byte <= start_byte + length
            call add(rv, prop)
          else
            continue
          endif
        else
          call add(rv, prop)
        endif
      else
        continue
      endif
    elseif end
      let end_byte = col([a:lnum, col]) + length
      if current_byte < end_byte
        call add(rv, prop)
      endif
    endif
  endfor

  return rv
endfunction

function! v3m#util#filter(list, comparator) abort
  let rv = []
  for idx in range(len(a:list))
    let value = a:list[idx]
    let b = a:comparator(idx, value)
    if b
      call add(rv, value)
    endif
  endfor
  return rv
endfunction

function! v3m#util#filter_array_by_map_value(key, value) abort
  return { idx, value -> value[a:key] ==# a:value }
endfunction

function! v3m#util#find_by_map_value(list, key, value, ignore_value_case=0) abort
  for v in a:list
    if a:ignore_value_case && v[a:key] ==? a:value
      return v
    elseif !a:ignore_value_case && v[a:key] ==# a:value
      return v
    endif
  endfor
  return {}
endfunction

function! v3m#util#rename_buffer(bufnr, bufname) abort
  let prev_bufname = bufname(a:bufnr)

  let current_bufnr = bufnr('%')
  if current_bufnr != a:bufnr
    execute 'buffer ' . a:bufnr
  endif
  execute 'silent file ' . fnameescape(a:bufname)

  if prev_bufname != '' && a:bufname !=# prev_bufname
    let prev_bufnr = bufnr('^' . prev_bufname . '$')
    if prev_bufnr != -1 && prev_bufnr != current_bufnr
      execute 'bwipeout ' . prev_bufnr
    endif
  endif

  if current_bufnr != a:bufnr
    execute 'buffer ' . current_bufnr
  endif
endfunction

function! v3m#util#trim_quote(str) abort
  let len = len(a:str)
  if len >= 2
    if a:str[0] == "'" || a:str[0] == '"'
      if a:str[0] ==  a:str[len - 1]
        return strpart(a:str, 1, len - 2)
      endif
    endif
  endif

  return a:str
endfunction

function! v3m#util#str2utf8(str) abort
  let rv = []
  for i in range(len(a:str))
    call add(rv, char2nr(a:str[i], 1))
  endfor

  return rv
endfunction

function! v3m#util#utf82str(utf8) abort
  let rv = []
  for i in range(len(a:utf8))
    " FIXME Check how to decode without using printf.
    call add(rv, printf("\\x%x", a:utf8[i]))
  endfor
  return eval('"' . join(rv,'') . '"')
endfunction

" FIXME TEST
function! v3m#util#str2percent(str) abort
  let rv = []
  for i in range(len(a:str))
    call add(rv, printf("%%%x", char2nr(a:str[i])))
  endfor
  return eval('"' . join(rv,'') . '"')
endfunction

function! v3m#util#entityref2char(ref_name) abort
      let ref_name = strpart(a:ref_name, 1, strlen(a:ref_name) - 2)
      let strlen = strlen(ref_name)

      if strlen >= 1 && ref_name[0] ==# '#'
        if strlen >= 2 && ref_name[1] ==# 'x'
          " hex
          let str = strpart(ref_name, 2, strlen - 2)
          if str =~ '^[0-9a-fA-F]\+$'
            let code = str2nr(str, 16)
          else
            return ''
          endif
        else
          " decimal
          let str = strpart(ref_name, 1, strlen - 1)
          if str =~ '^[0-9]\+$'
            let code = str2nr(str, 10)
          else
            return ''
          endif
        endif

        return nr2char(code, 1)
      elseif has_key(s:char_entity_ref, ref_name)
        let code = s:char_entity_ref[ref_name]
        if type(code) == v:t_number
          return nr2char(code, 1)
        else
          return code
        endif
      else
        return ''
      endif
endfunction

function! v3m#util#decode_char_entity_ref(str) abort
  let rv = []
  let start = 0
  let len = strlen(a:str)

  while start < len
    let strpos = matchstrpos(a:str, '&\(#[0-9]\+\|#x[0-9a-fA-F]\+\|\a\+\);', start)

    let mstart = strpos[1]
    let mend = strpos[2]

    if mstart == -1
      call add(rv, strpart(a:str, start))
      let start = len
    else
      if start != mstart
        call add(rv, strpart(a:str, start, mstart - start))
        let start = mstart
      endif

      let char = v3m#util#entityref2char(strpos[0])
      if char ==# ''
        call add(rv, strpos[0])
      " 0x200b : zero width no-break space
      elseif char ==# nr2char(0x200b)
        call add(rv, '')
      else
        call add(rv, char)
      endif

"      let ref_name = strpart(strpos[0], 1, strlen(strpos[0]) - 2)
"      let strlen = strlen(ref_name)
"
"      if strlen >= 1 && ref_name[0] ==# '#'
"        if strlen >= 2 && ref_name[1] ==# 'x'
"          let code = str2nr(strcharpart(ref_name, 2, strlen - 2), 16)
"        else
"          let code = str2nr(strcharpart(ref_name, 1, strlen - 1), 10)
"        endif
"        " 0x200b : zero width no-break space
"        if code != 0x200b
"          call add(rv, nr2char(code, 1))
"        endif
"      elseif has_key(s:char_entity_ref, ref_name)
"        let code = s:char_entity_ref[ref_name]
"        if type(code) == v:t_number
"          call add(rv, nr2char(code, 1))
"        else
"          call add(rv, code)
"        endif
"      else
"        call add(rv, strpos[0])
"      endif
      let start = mend
    endif
  endwhile

  return join(rv, '')
endfunction

let s:char_entity_ref = {
\ 'amp': '&',
\ 'lt': '<',
\ 'gt': '>',
\ 'quot': '"',
\ 'nbsp':0xA0,
\ 'iexcl':0xA1,
\ 'cent':0xA2,
\ 'pound':0xA3,
\ 'curren':0xA4,
\ 'yen':0xA5,
\ 'brvbar':0xA6,
\ 'sect':0xA7,
\ 'uml':0xA8,
\ 'copy':0xA9,
\ 'ordf':0xAA,
\ 'laquo':0xAB,
\ 'not':0xAC,
\ 'shy':0xAD,
\ 'reg':0xAE,
\ 'macr':0xAF,
\ 'deg':0xB0,
\ 'plusmn':0xB1,
\ 'sup2':0xB2,
\ 'sup3':0xB3,
\ 'acute':0xB4,
\ 'micro':0xB5,
\ 'para':0xB6,
\ 'middot':0xB7,
\ 'cedil':0xB8,
\ 'sup1':0xB9,
\ 'ordm':0xBA,
\ 'raquo':0xBB,
\ 'frac14':0xBC,
\ 'frac12':0xBD,
\ 'frac34':0xBE,
\ 'iquest':0xBF,
\ 'Agrave':0xC0,
\ 'Aacute':0xC1,
\ 'Acirc':0xC2,
\ 'Atilde':0xC3,
\ 'Auml':0xC4,
\ 'Aring':0xC5,
\ 'AElig':0xC6,
\ 'Ccedil':0xC7,
\ 'Egrave':0xC8,
\ 'Eacute':0xC9,
\ 'Ecirc':0xCA,
\ 'Euml':0xCB,
\ 'Igrave':0xCC,
\ 'Iacute':0xCD,
\ 'Icirc':0xCE,
\ 'Iuml':0xCF,
\ 'ETH':0xD0,
\ 'Ntilde':0xD1,
\ 'Ograve':0xD2,
\ 'Oacute':0xD3,
\ 'Ocirc':0xD4,
\ 'Otilde':0xD5,
\ 'Ouml':0xD6,
\ 'times':0xD7,
\ 'Oslash':0xD8,
\ 'Ugrave':0xD9,
\ 'Uacute':0xDA,
\ 'Ucirc':0xDB,
\ 'Uuml':0xDC,
\ 'Yacute':0xDD,
\ 'THORN':0xDE,
\ 'szlig':0xDF,
\ 'agrave':0xE0,
\ 'aacute':0xE1,
\ 'acirc':0xE2,
\ 'atilde':0xE3,
\ 'auml':0xE4,
\ 'aring':0xE5,
\ 'aelig':0xE6,
\ 'ccedil':0xE7,
\ 'egrave':0xE8,
\ 'eacute':0xE9,
\ 'ecirc':0xEA,
\ 'euml':0xEB,
\ 'igrave':0xEC,
\ 'iacute':0xED,
\ 'icirc':0xEE,
\ 'iuml':0xEF,
\ 'eth':0xF0,
\ 'ntilde':0xF1,
\ 'ograve':0xF2,
\ 'oacute':0xF3,
\ 'ocirc':0xF4,
\ 'otilde':0xF5,
\ 'ouml':0xF6,
\ 'divide':0xF7,
\ 'oslash':0xF8,
\ 'ugrave':0xF9,
\ 'uacute':0xFA,
\ 'ucirc':0xFB,
\ 'uuml':0xFC,
\ 'yacute':0xFD,
\ 'thorn':0xFE,
\ 'yuml':0xFF,
\ 'rarr':0x021D2,
\ }
" rarr -> html5 entity name
" https://dev.w3.org/html5/html-author/charref

" vim: tabstop=2 shiftwidth=2 expandtab
