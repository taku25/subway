" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}



command! SBMakeCentralStation call subway#make_station("central")
command! SBDestroyCentralStation call subway#destroy_station("central")

command! -nargs=? SBMakeStation call subway#make_station(<f-args>)
command! -nargs=? SBDestroyStation call subway#destroy_station(<f-args>)
command! -nargs=? SBToggleStation call subway#toggle_station(<f-args>)
command! SBMovePreviousStation call subway#move_staion(1)
command! SBMoveNextStation call subway#move_staion(0)

command! -nargs=1 SBCreateRail call subway#create_rail(<f-args>)
command! SBChangeRail call subway#change_rail_from_list()

command! SBShowAllStation call subway#show_all_station_in_buffer()
" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
