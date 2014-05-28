" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}


" global variable {{{

let g:subway_enable_highlight =
      \ get(g:, 'subway_enable_highlight', '0')

let g:subway_line_highlight =
      \ get(g:, 'subway_line_highlight', 'Title')

let g:subway_text_highlight =
      \ get(g:, 'subway_text_highlight', 'CursorLine')


"}}}

command! SBMakeCentralStation call subway#make_central_station()
command! SBDestroyCentralStation call subway#destroy_central_station()

command! -nargs=? SBMakeStation call subway#make_station(<f-args>)
command! -nargs=? SBDestroyStation call subway#destroy_station(<f-args>)
command! -nargs=? SBToggleStation call subway#toggle_station(<f-args>)
command! SBMovePreviousStation call subway#move_staion(1)
command! SBMoveNextStation call subway#move_staion(0)

command! -nargs=1 SBCreateRail call subway#create_rail(<f-args>)
command! SBChangeRail call subway#change_rail_from_list()

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
