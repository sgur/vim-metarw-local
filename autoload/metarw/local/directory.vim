"=============================================================================
" FILE: autoload/metarw/local/directory.vim
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

function! metarw#local#directory#setup(path)
  let parent_dir = fnamemodify(a:path, ':p:h:h').'/'
  execute 'nnoremap <buffer> U :<C-u>edit local:'.parent_dir.'<CR>'
  execute 'nnoremap <buffer> <BS> :<C-u>edit local:'.parent_dir.'<CR>'
  execute 'nnoremap <buffer> D :<C-u>call <SID>rm('''.a:path.''')<CR>'
  execute 'nnoremap <buffer> R :<C-u>call <SID>mv('''.a:path.''')<CR>'
  return [{ 'label' : '..', 'fakepath' : 'local:'.parent_dir}]
        \ + s:list(a:path)
endfunction


function! s:list(path)
  let dirs = []
  let files = []
  for p in glob(a:path.'*', 1, 1)
    if isdirectory(p)
      call add(dirs,
            \ {'path': p, 'label': fnamemodify(p, ':t').'/', 'fakepath': 'local:'.p.'/'})
    else
      call add(files,
            \ {'path': p, 'label': fnamemodify(p, ':t'), 'fakepath': 'local:'.p})
    endif
  endfor
  return map(sort(dirs, '<SID>sort') + sort(files, '<SID>sort')
        \ , '{"label" : s:label(v:val), "fakepath" : v:val.fakepath}')
endfunction


function! s:sort(v1, v2)
  return a:v1.label == a:v2.label ? 0
        \ : a:v1.label > a:v2.label ? 1 : -1
endfunction


function! s:label(path)
  return printf("%-30S\t%-S\t%10S\t%10s"
        \ , a:path.label
        \ , strftime("%c", getftime(a:path.path))
        \ , getfsize(a:path.path)
        \ , getfperm(a:path.path))
endfunction


function! s:confirm(operation, path)
  echohl WarningMsg
  let answer = input(a:operation.': '.a:path.' (y/N)? ')
  echohl None
  return answer =~? '^y\(es\)\?$' ? 1 : 0
endfunction


function! s:get_target(dir)
  return substitute(a:dir, '\\', '/', 'g').matchstr(getline('.'), '\S\+')
endfunction


function! s:redraw()
  edit
endfunction


function! s:error(msg)
  redraw
  echohl Error
  execute 'echo '''a:msg.''''
  echohl None
endfunction


function! s:rm(dir)
  let path = s:get_target(a:dir)
  if !s:confirm('Delete', path)
    return
  endif
  if isdirectory(path)
    let cmd = has('win32') ? 'rmdir /S /Q ' : 'rm -rf '
    call system(cmd . fnameescape(expand(path)))
    if v:shell_error != 0
      call s:error('Removing '.path.' failed.')
    endif
  else
    if filewritable(path) != 1 || delete(path)
      call s:error('Removing '.path.' failed.')
    endif
  endif
  call s:redraw()
endfunction


function! s:mv(dir)
  let src = s:get_target(a:dir)
  let dest = input('Move '.src.' -> ', src, 'file')
  if isdirectory(dest)
    let dest .= '/'.fnamemodify(src, ':t')
  endif
  if !s:confirm('Move', src.' -> '.dest)
    return
  endif
  try
    if filewritable(src) != 1 || rename(src, dest)
      call s:error('Moving '.src.' failed.')
    endif
  endtry
  call s:redraw()
endfunction
