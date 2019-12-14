scriptencoding utf-8
" A web browser interface plugin for Vim
" Author     : Koji Sato <litom501+vim@gmail.com>
" License    : MIT License

let s:v3m = '[v3m]'
let s:v3m_error = s:v3m . '[ERROR]'
let s:v3m_warn  = s:v3m . '[WARN ]'
let s:v3m_debug = s:v3m . '[DEBUG]'

let s:buffers = {}

function! v3m#handler#job_start(url, bufnr, cols) abort
  let options = '-halfdump -o ext_halfdump=-1 -cols ' . a:cols
  let cmd = 'w3m ' . options . ' ' . a:url
  let job = job_start(cmd, #{
        \   out_cb: "v3m#handler#default_out",
        \   close_cb: "v3m#handler#default_close",
        \   err_cb: "v3m#handler#default_error",
        \ })
  let channel = job_getchannel(job)
  let info = ch_info(channel)
  let id = info['id']
  call setbufvar(a:bufnr, 'id', id)
  let s:buffers[id] = a:bufnr
endfunction

function! s:get_bufnr(channel) abort
  let info = ch_info(a:channel)
  let id = info['id']
  let bufnr = s:buffers[id]
  return bufnr
endfunction

function! v3m#handler#default_out(channel, msg) abort
  let page = v3m#page#get_page(s:get_bufnr(a:channel))
  call add(page, a:msg)
  "let status = ch_status(a:channel)
endfunction

function! v3m#handler#default_close(channel) abort
  let bufnr = s:get_bufnr(a:channel)

  let page = v3m#page#get_page(bufnr)
  let meta = v3m#page#get_meta(bufnr)
  let fragments = v3m#page#get_fragments(bufnr)
  let forms = v3m#page#get_forms(bufnr)
  let url = v3m#page#get_param(bufnr, 'url')
  let tag_stack = []

  call setbufvar(bufnr, '&modifiable', 1)

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

            call v3m#parse#add_tag_data(url, meta, fragments, forms, prop_list, bufnr, open_tag, i + 1, col)
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
      call v3m#parse#add_tag_data(url, meta, fragments, forms, prop_list, bufnr, open_tag)
    endwhile


    call setbufline(bufnr, i + 1, join(texts, ''))

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
    call v3m#goto_name(bufnr, parsed_url['fragment'])
  endif

  call setbufvar(bufnr, '&modifiable', 0)
endfunction

function! v3m#handler#default_error(channel, msg) abort
  let bufnr = s:get_bufnr(a:channel)
  let url = v3m#page#get_param(bufnr, 'url')
  call setbufvar(bufnr, '&modifiable', 1)
  call deletebufline('%', 1, '$')
  call setbufline(bufnr, 1, 'ERROR')
  call setbufline(bufnr, 2, '  Connection refused.')
  call setbufline(bufnr, 3, '')
  call setbufline(bufnr, 4, printf('  %s', url))
  call setbufvar(bufnr, '&modifiable', 0)
endfunction

