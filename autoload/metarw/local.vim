"=============================================================================
" FILE: autoload/metarw/local.vim
" AUTHOR: sgur <sgurrr+vim@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================


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
  let dirs = []
  let files = []
  for p in glob(a:path.'*', 1, 1)
    if isdirectory(p)
      call add(dirs,
            \ {'label': fnamemodify(p, ':t').'/', 'fakepath': 'local:'.p.'/'})
    else
      call add(files,
            \ {'label': fnamemodify(p, ':t'), 'fakepath': 'local:'.p})
    endif
  endfor
  return sort(dirs, '<SID>sort') + sort(files, '<SID>sort')
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


function! metarw#local#fallback_dir(path)
  if isdirectory(a:path)
    let l:path = substitute(a:path, '\\', '/', 'g')
    execute 'edit local:'.l:path
    execute 'bwipeout' l:path
  endif
endfunction

