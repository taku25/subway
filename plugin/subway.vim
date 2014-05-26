" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}




command! SBCentralMake call subway#make_station("central")
command! SBCentralDestroy call subway#destroy_station("central")

command! -nargs=? SBMake call subway#make_station(<f-args>)
command! -nargs=? SBDestroy call subway#destroy_station(<f-args>)
command! -nargs=? SBToggle call subway#toggle_station(<f-args>)



nnoremap <silent> <C-m> :SBToggle<CR>  

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
