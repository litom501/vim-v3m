scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License

" data structure
"
" tag {
"   tag_type
"   tag_name
"   attributes* {
"     attr_name
"     attr_value
"   }
" }
"
" metadata {
"   id
"   tag
"   type
"   lnum
"   col
"   end_lnum
"   end_col
"   atttributes
" }
"
" form[fid]* {
"   form_int {
"     method
"     action
"     name
"   }
"   input_alt[name]* {
"     type
"     name
"     value
"     maxlength
"     #displaylength
"     #current_value
"   }
" }
"
" fragments* {
"   lnum
"   col
" }

let s:v3m = '[v3m]'
let s:v3m_error = s:v3m . '[ERROR]'
let s:v3m_warn  = s:v3m . '[WARN ]'
let s:v3m_debug = s:v3m . '[DEBUG]'

let s:visible_1_tags = [ 'b', 'u' ]
let s:visible_2_tags = [ '_symbol' ]
let s:invisible_tags = [ 'title_alt', 'link', 'noscript', '_id' ]
let s:form_tags = [ 'form_int', 'input_alt' ]
" 未整理
let s:known_tags = [ 'pre_int', 'label', 'span' ]

function! s:tag_a_to_proptype(tag) abort
  let tag_name = a:tag['tag_name']

  if tag_name ==? 'a'
    let type = ''
    for attr in a:tag['attributes']
        if attr['attr_name'] ==? 'href'
          let attr_value = attr['attr_value']
          if !empty(attr_value)
            return 'v3m#link'
          endif
        endif
    endfor
    if  empty(type)
      return 'v3m#anchor'
    endif
  else
    echoerr s:v3m_error ':' 'Invalid argument ''' . a:tag . ''''
  endif
endfunction

function! s:create_tag2proptype() abort
  let rv = {}
  let rv['a'] = function("<SID>tag_a_to_proptype")

  for tag in s:visible_1_tags
    let rv[tag] = 'v3m#visible_1'
  endfor

  for tag in s:visible_2_tags
    let rv[tag] = 'v3m#visible_2'
  endfor

  for tag in s:form_tags
    let rv[tag] = 'v3m#form'
  endfor

  for tag in s:invisible_tags
    let rv[tag] = 'v3m#ignore'
  endfor

  for tag in s:known_tags
    let rv[tag] = 'v3m#other'
  endfor

  return rv
endfunc

let s:tag2proptype = s:create_tag2proptype()

function! s:get_proptype(tag) abort
  let tag_name = tolower(a:tag['tag_name'])

  if !has_key(s:tag2proptype, tag_name)
    return 'v3m#unknown'
  endif

  let Proptype = s:tag2proptype[tag_name]

  if type(Proptype) == v:t_func
    return Proptype(a:tag)
  else
    return Proptype
  endif
endfunction

function! s:configure_prop_type() abort
  if empty(prop_type_get('v3m#link'))
    call prop_type_add('v3m#link', #{ highlight: 'v3mLink', priority: 10 })
  endif

  if empty(prop_type_get('v3m#visible_1'))
    call prop_type_add('v3m#visible_1', #{ highlight: 'v3mVisible1', priority: 6 })
  endif

  if empty(prop_type_get('v3m#visible_2'))
    call prop_type_add('v3m#visible_2', #{ highlight: 'v3mVisible2', priority: 6 })
  endif

  if empty(prop_type_get('v3m#other'))
    call prop_type_add('v3m#other', #{ highlight: 'v3mOther', priority: 5 })
  endif

  if empty(prop_type_get('v3m#form'))
    call prop_type_add('v3m#form', #{ priority: 4 })
  endif

  if empty(prop_type_get('v3m#anchor'))
    call prop_type_add('v3m#anchor', #{ priority: 4 })
  endif

  if empty(prop_type_get('v3m#ignore'))
    call prop_type_add('v3m#ignore', #{ priority: 0 })
  endif

  if empty(prop_type_get('v3m#unknown'))
    call prop_type_add('v3m#unknown', #{ highlight: 'v3mUnknown', priority: 0 })
  endif

endfunction

call s:configure_prop_type()

function! v3m#parse#create_prop(bufnr, id, tag, end_lnum, end_col) abort
  let type = s:get_proptype(a:tag)
  let prop = #{
        \ bufnr: a:bufnr,
        \ id: a:id,
        \ type: type,
        \ end_lnum: a:end_lnum,
        \ end_col: a:end_col,
        \}
  return prop
endfunction

function! s:contains(list, tag_name) abort
  let tag_name = tolower(a:tag_name)
  return index(a:list, tag_name) != -1
endfunction

function! v3m#parse#create_metadata(id, last_tag, props) abort
  let data = #{
        \ id: a:id,
        \ tag: a:last_tag['tag_name'],
        \ type: a:props['type'],
        \ lnum: a:last_tag['=lnum'],
        \ col: a:last_tag['=col'],
        \ end_lnum: a:props['end_lnum'],
        \ end_col: a:props['end_col'],
        \ attributes: a:last_tag['attributes'],
        \}
  return data
endfunction

function! v3m#parse#attributes(str) abort
  return s:parse_attributes(a:str, [])
endfunction

function! s:parse_attributes(str, rv) abort
  let str = trim(a:str, ' ')
  let strlen = len(str)
  if strlen == 0
    return a:rv
  endif

  let start_idx = 0
  let strpos = matchstrpos(str, '\s*=\s*', start_idx)
  let empty_value = 0
  if strpos[1] == -1
    let strpos = matchstrpos(str, '[^\s]\+\zs\s*', start_idx)
    if strpos[1] == -1
      echoerr s:v3m_error ':' 'Invalid argument ''' . a:str . ''''
    else
      let empty_value = 1
    endif
  endif

  let attr_name = strpart(str, start_idx, strpos[1] - start_idx)

  if empty_value == 0
    if strlen <= strpos[2]
      " end
      let attr_value = ''
      call add(a:rv, { 'attr_name': attr_name, 'attr_value': attr_value })
      return a:rv
    endif

    if str[strpos[2]] == "'"
      let pat = "'"
      let start = strpos[2] + 1
      let offset = 1
    elseif str[strpos[2]] == '"'
      let pat = '"'
      let start = strpos[2] + 1
      let offset = 1
    else
      let pat = '\( \|$\)'
      let start = strpos[2]
      let offset = 0
    endif

    let idx = match(str, pat, start)
    if idx == -1
      let attr_value = ''
      call add(a:rv, { 'attr_name': attr_name, 'attr_value': attr_value })
      return s:parse_attributes(strpart(str, start), a:rv)
    else
      let attr_value = v3m#util#trim_quote(strpart(str, strpos[2], idx - strpos[2] + offset))
      call add(a:rv, { 'attr_name': attr_name, 'attr_value': attr_value })
      return s:parse_attributes(strpart(str, idx + 1), a:rv)
    endif
  else
    let attr_value = ''
    call add(a:rv, { 'attr_name': attr_name, 'attr_value': attr_value })
    return s:parse_attributes(strpart(str, strpos[2] + 1), a:rv)
  endif

endfunction

function! v3m#parse#tag(element) abort
  let len = len(a:element)
  if len == 0
    throw 'Invalid argument. Argument is empty.'
  endif

  if a:element[0] != '<'
    throw 'Invalid argument. no left angle bracket.'
  endif

  if a:element[len - 1] != '>'
    throw 'Invalid argument. no right angle bracket.'
  endif

  if len < 3
    throw 'Invalid argument. Argument is an invalid value.'
  endif

  let content = strpart(a:element, 1, len - 2)
  if content[0] == '/' && len(content) < 2
    throw 'Invalid argument. Argument is an invalid close tag.'
  endif

  if content[0] == '/'
    let tag_type = 'close'
    let start_idx = 1
  else
    let tag_type = 'open'
    let start_idx = 0
  endif

  let idx = match(content, '\( \|$\)', start_idx)
  let tag_name = strpart(content, start_idx, idx - start_idx)

  let rv = {
        \ 'tag_type': tag_type,
        \ 'tag_name': tag_name
        \}

  if tag_type == 'open'
    let attributes = v3m#parse#attributes(strpart(content, idx))
    let rv['attributes'] = attributes
  endif

  return rv
endfunction

function! v3m#parse#split_elements(line) abort
  let elements = []
  let start = 0
  let len = strlen(a:line)
  while start < len
    let idx = stridx(a:line, '<', start)
    if idx == -1
      call add(elements, strpart(a:line, start))
      let start = len
    else
      if start != idx
        call add(elements, strpart(a:line, start, idx - start))
        let start = idx
      endif
      let idxClose = stridx(a:line, '>', start)
      if idxClose == -1
        echoerr s:v3m_error ':' 'Couldn''t find a right angle bracket ''>'' : ' a:line start
        call add(elements, strpart(a:line, start))
        let start = len
      else
        call add(elements, strpart(a:line, start, idxClose + 1 - start))
        let start = idxClose + 1
      endif
    endif
  endwhile
  return elements
endfunction

function! v3m#parse#add_tag_data(url, meta, fragments, forms, prop_list, bufnr, open_tag, end_lnum='', end_col='') abort
  let open_lnum = a:open_tag['=lnum']
  let open_col = a:open_tag['=col']

  if a:end_lnum == ''
    let end_lnum = open_lnum
  else
    let end_lnum = a:end_lnum
  endif
  if a:end_col == ''
    let end_col = open_col
  else
    let end_col = a:end_col
  endif

  let tag_name = a:open_tag['tag_name']
  let id = len(a:meta)

  let prop = v3m#parse#create_prop(a:bufnr, id, a:open_tag, end_lnum, end_col)
  let data = v3m#parse#create_metadata(id, a:open_tag, prop)
  if prop['type'] ==# 'v3m#form'
    call s:add_form(a:forms, a:open_tag)
  endif

  call add(a:meta, data)
  call add(a:prop_list, { 'tag': tag_name, 'attrs': a:open_tag['attributes'], 'lnum': open_lnum, 'col': open_col, 'props': prop})
  call v3m#parse#add_fragments(a:fragments, a:open_tag)
endfunction

" If tag has fragment identifiers, The information is added to fragments.
function! v3m#parse#add_fragments(fragments, tag) abort
  for attr in a:tag['attributes']
      if s:is_fragment_attr(a:tag['tag_name'], attr['attr_name'])
        let attr_value = attr['attr_value']
        let attr_value = v3m#util#decode_char_entity_ref(attr_value)
        if !empty(attr_value)
          let a:fragments[attr_value] = #{ lnum: a:tag['=lnum'], col: a:tag['=col'] }
        endif
      endif
  endfor
endfunction

" If attr_name is fragment identifier, true is returned.
function! s:is_fragment_attr(tag_name, attr_name) abort
  if a:attr_name ==? 'id'
    return 1
  endif

  return a:tag_name ==? 'a' && a:attr_name ==? 'name'
endfunction

function! s:is_form_tag(tag) abort
  let tag_name = a:tag['tag_name']
  if tag_name ==# 'form_int'
    return 1
  elseif tagname ==# 'input_alt'
    return 1
  else
    " unknown form tag
    return 0
  end
endfunction

function! s:get_attributes(tag) abort
  let rv = {}
  for attr in a:tag['attributes']
    let rv[attr['attr_name']] = attr['attr_value']
  endfor

  return rv
endfunction

function! s:get_form(forms, fid) abort
  if !has_key(a:forms, a:fid)
    let form = {}
    let a:forms[a:fid] = form
  else
    let form = a:forms[a:fid]
  endif
  return form
endfunction

function! s:add_form(forms, tag) abort
  let attributes = s:get_attributes(a:tag)
  let fid = get(attributes, 'fid')
  if empty(fid)
    return
  endif

  let form = s:get_form(a:forms, fid)
  let tag_name = a:tag['tag_name']
  if tag_name ==# 'form_int'
    let data = #{
          \ method: get(attributes, 'method', ''),
          \ action: get(attributes, 'action', ''),
          \ name: get(attributes, 'name', ''),
          \}
    let form['form_int'] = data
  elseif tag_name ==# 'input_alt'
    let name = get(attributes, 'name', '')
    let value = get(attributes, 'value', '')
    let data = {
          \ 'type': get(attributes, 'type', ''),
          \ 'name': name,
          \ 'value': value,
          \ 'maxlength': get(attributes, 'maxlength', ''),
          \ '#displaylength': 0,
          \ '#current_value': value,
          \}
    if has_key(form, 'input_alt')
      let inputs = form['input_alt']
    else
      let inputs = {}
      let form['input_alt'] = inputs
    endif
    let inputs[name] = data
  else
    " unknown form tag
  end
endfunction
