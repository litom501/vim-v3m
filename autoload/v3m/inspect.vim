scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License

let s:v3m = '[v3m]'
let s:v3m_error = s:v3m . '[ERROR]'
let s:v3m_warn  = s:v3m . '[WARN ]'
let s:v3m_debug = s:v3m . '[DEBUG]'

function! v3m#inspect#dump(bufnr='%') abort
  let bufnr = bufnr(a:bufnr)
  let v3m = getbufvar(bufnr, 'v3m', '')

  if empty(v3m)
    echoerr s:v3m_error 'bufnr' bufnr 'is not v3m buffer. '
  endif

  new

  "page
  call setline(1, v3m['page'])

  " url
  call append('$', '-- url')
  call append('$', v3m['url'])

  " domain
  call append('$', '-- domain')
  call append('$', v3m['domain'])

  " meta
  call append('$', '-- meta')
  call append('$', map(copy(v3m['meta']), { i, v -> printf("%s", v)}))

  " fragments
  call append('$', '-- fragments')
  "call append('$', map(copy(v3m['fragments']), { k, v -> printf("%s : %s", k, v)}))
  "call append('$', map(copy(v3m['fragments']), { k, v -> printf("%s ", k)}))
  call append('$', printf("%s", v3m['fragments']))

  " forms
  call append('$', '-- forms')
  "call append('$', map(copy(v3m['forms']), { k, v -> printf("%s : %s", k, v)}))
  call append('$', printf("%s", v3m['forms']))

  set nomodified

endfunction

function! v3m#inspect#cursor() abort
  let bufnr = bufnr('%')
  let props = v3m#util#get_prop(bufnr, line('.'), col('.'))
  let links = filter(copy(props),
                    \{ idx, value -> v3m#util#filter_array_by_map_value('type', 'v3m#link')(idx, value) })

  let meta = v3m#page#get_meta(bufnr)

  " clear message
  "echom ''

  if len(links) > 0
    let link = meta[links[0]['id']]
    let attributes = link['attributes']
    let href = v3m#util#find_by_map_value(attributes, 'attr_name', 'href')
    if has_key(href, 'attr_value')
      let href = v3m#util#decode_char_entity_ref(href['attr_value'])
    else
      let href = ''
    endif

    let domain = v3m#page#get_param(bufnr, 'domain')
    let current_url = v3m#page#get_param(bufnr, 'url')
    let current_url = v3m#url#normalize(current_url)
    let url = v3m#url#normalize(v3m#url#resolve(href, current_url))

    echom s:v3m_debug 'links' links
    echom s:v3m_debug printf("meta : %s", meta[links[0]['id']])
    echom s:v3m_debug printf("       href : %s", href)
    echom s:v3m_debug printf("     domain : %s", domain)
    echom s:v3m_debug printf("current url : %s", current_url)
    echom s:v3m_debug printf("   link url : %s", url)
  else
    for prop in props
      let data = meta[prop['id']]

      echom s:v3m_debug printf("prop : %s", data)
    endfor
  endif
endfunction
