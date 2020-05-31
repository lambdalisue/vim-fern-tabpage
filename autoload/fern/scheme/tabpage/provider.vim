let s:Promise = vital#fern#import('Async.Promise')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:root = {
      \ 'name': 'TabPages',
      \ 'status': 1,
      \ '_kind': 'root',
      \}

function! fern#scheme#tabpage#provider#new() abort
  return {
        \ 'get_root' : funcref('s:provider_get_root'),
        \ 'get_parent' : funcref('s:provider_get_parent'),
        \ 'get_children' : funcref('s:provider_get_children'),
        \}
endfunction

function! s:provider_get_root(url) abort
  return copy(s:root)
endfunction

function! s:provider_get_parent(node, ...) abort
  if a:node._kind ==# 'window'
    return s:Promise.resolve(s:node_tabpage(a:node._tabpagenr))
  endif
  return s:Promise.resolve(s:root)
endfunction

function! s:provider_get_children(node, ...) abort
  if a:node._kind ==# 'root'
    let candidates = range(1, tabpagenr('$'))
    return s:AsyncLambda.map(candidates, { v -> s:node_tabpage(v) })
  elseif a:node._kind ==# 'tabpage'
    let tabpagenr = a:node._tabpagenr
    let candidates = range(1, tabpagewinnr(tabpagenr, '$'))
    return s:AsyncLambda.map(candidates, { v -> s:node_window(tabpagenr, v) })
  else
    return s:Promise.reject('the node is leaf')
  endif
endfunction

function! s:node_tabpage(tabpagenr) abort
  return {
        \ 'name': printf('TabPage %d', a:tabpagenr),
        \ 'status': 1,
        \ '_kind': 'tabpage',
        \ '_tabpagenr': a:tabpagenr,
        \}
endfunction

function! s:node_window(tabpagenr, winnr) abort
  let winid = win_getid(a:winnr, a:tabpagenr)
  let bufname = bufname(winbufnr(winid))
  return {
        \ 'name': empty(bufname) ? '(No Name)' : fnamemodify(bufname, ':t'),
        \ 'status': 0,
        \ 'bufname': bufname,
        \ '_kind': 'window',
        \ '_tabpagenr': a:tabpagenr,
        \ '_winnr': a:winnr,
        \}
endfunction
