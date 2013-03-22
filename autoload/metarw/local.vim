
function! metarw#local#read(fakepath)
  let _ = s:parse_incomplete_fakepath(a:fakepath)
  return _.file_given_p ? s:view_file(_.path) :
        \ _.dir_given_p ? s:list_dir(_.path) : ['error', 'cannot read']
endfunction


function! s:view_file(path)
  let parent_dir = fnamemodify(a:path, ':p:h').'/'
  execute 'nnoremap <buffer> U :<C-u>edit local:'.parent_dir.'<CR>'
  execute 'nnoremap <buffer> <BS> :<C-u>edit local:'.parent_dir.'<CR>'
  execute 'nnoremap <buffer> <CR> :<C-u>edit '.a:path.'<CR>'
  setlocal readonly
  return ['read', a:path]
endfunction


function! s:list_dir(path)
  let _ = ['browse', s:list_dir_contents(a:path)]
  let parent_dir = fnamemodify(a:path, ':p:h:h').'/'
  call insert(_[1],
        \ { 'label' : '..'
        \ , 'fakepath' : 'local:'.parent_dir})
  execute 'nnoremap <buffer> U :<C-u>edit local:'.parent_dir.'<CR>'
  execute 'nnoremap <buffer> <BS> :<C-u>edit local:'.parent_dir.'<CR>'
  return _
endfunction


function! s:list_dir_contents(path)
  return sort(map(glob(a:path.'*', 1, 1)
        \ , '{"label": s:dir_label(v:val), "fakepath": s:dir_fakepath(v:val)}')
        \ , '<SID>sort')
endfunction


function! s:sort(v1, v2)
  return a:v1.label == a:v2.label ? 0
        \ : a:v1.label > a:v2.label ? 1 : -1
endfunction


function! s:dir_label(str)
  return (isdirectory(a:str) ? '+': '') . fnamemodify(a:str, ':t')
endfunction


function! s:dir_fakepath(str)
  return 'local:'.v:val.(isdirectory(v:val) ? '/' : '')
endfunction


function!metarw#local#write(fakepath, line1, line2, append_p)
  let _ = s:parse_incomplete_fakepath(a:fakepath)
  if _.file_given_p
    let result = ['write', _.path]
  else
    let result = ['error', 'cannot write']
  endif
  return result
endfunction


function! metarw#local#complete(arglead, cmdline, cursorpos)
  let _ = s:parse_incomplete_fakepath(a:arglead)
  let [dir, fname] = s:split_path(_.path)
  return [map(glob(dir.fname.'*', 1, 1), '"local:".v:val'), 'local:'.dir, fname]
endfunction


function! s:split_path(path)
  let matchend = matchend(a:path, '.\+[\\/]')
  return matchend == -1 ? ['.', a:path]
        \ : [_.path[: matchend-1], _.path[matchend :]]
endfunction


function! s:parse_incomplete_fakepath(fakepath)
  let _ = {}

  let fragments = split(a:fakepath, ':', !0)
  if  len(fragments) <= 1
    echoerr 'Unexpected a:fakepath:' string(a:fakepath)
    throw 'metarw:local#e1'
  endif

  " let _.given_fakepath = a:fakepath
  " let _.scheme = fragments[0]

  " {flie-dir}
  let _.path = fnamemodify(join(fragments[1:],':'), ':p')
  let _.scheme = fragments[0]
  let _.given_fakepath = _.scheme.':'._.path

  let _.file_given_p = filereadable(_.path)
  let _.dir_given_p  = isdirectory(_.path)

  if _.dir_given_p && _.path !~# '[\\/]$'
    let _.path .= '/'
  endif

  return _
endfunction
