" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}





command! -nargs=? SBMake call subway#make_station(<f-args>)
command! SBDestroy call subway#destroy_station()





" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
