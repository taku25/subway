if exists('g:loaded_subway')
  finish
elseif !has("signs")
 echoerr "***sorry*** [".expand("%")."] your vim doesn't support signs"
 finish
endif
let g:loaded_subway = 1

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}


" local variable.  " {{{
let s:default_rail_name = "default"
let s:current_rail = s:default_rail_name
let s:station_id = 0
let s:station_dict = {
                     \ "all":[],      
                     \ "default":[]
                     \ }
"}}}

function! s:create_station_info()
    
    let stationInfo = {
                    \ "filepath":expand('%:@'),
                    \ "position":getpos('.'),
                    \ "string":getline("."),
                    \ "number":s:station_id
                    }

    let s:station_id = s:station_id + 1

    return stationInfo
endfunction

function! s:subway_make_user_select_list(targetlist)
    let displaylist = []
    let l:i = 0
    for l:target in a:targetlist
        :call add(displaylist, (l:i + 1) . '.' . l:target)
        let l:i+=1
    endfor
    return displaylist
endfunction


function! subway#change_rail_from_name(...)

    let l:railName = s:default_rail_name
    if a:0 != 0
        let l:railName = a:1
    endif

    if has_kay(targetRail, l:railName) == 0
        echo "not found " . l:railName 
        return
    endif

    let s:current_rail = l:railName
endfunction

function! subway#change_rail_from_ui()

    let l:railList = keys(s:station_dict)
    let l:displayList = s:subway_make_user_select_list(l:railList)

    let l:inputnumber = inputlist(l:displayList) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displayList)
        return 
    endif

    let s:current_rail = l:railList[l:inputnumber]
endfunction


function! subway#make_rail(railName)
    if has_key(s:staion_list, railName) == 0
    endif
endfunction

function! subway#make_station(...)

    let ln = line(".")
    exe 'sign define rail text=* texthl=SignColor'
    exe 'sign place ' . '1' . ' line=' . ln . ' name=rail buffer=' . winbufnr(0)

endfunction



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
