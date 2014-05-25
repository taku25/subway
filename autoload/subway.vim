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
let s:central_rail_name = "central"

let s:current_rail_name = s:default_rail_name
let s:station_id = 1


let s:station_dict = {}
let s:station_dict[s:default_rail_name] = []
let s:station_dict[s:central_rail_name] = []

"}}}

function! s:create_station_info()
    
    "bufferidで十分？ filepathいらないかも
    let stationInfo = {
                    \ 'filepath' : expand('%:p'),
                    \ 'position' : getpos('.'),
                    \ 'string'   : getline("."),
                    \ 'bufferid' : bufnr('%'),
                    \ 'id'   : s:station_id,
                    \}

    echo stationInfo

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


function! s:subway_get_station_list(railName)

    let targetRailName = a:railName == "" ? s:current_rail_name : a:railName
    
    if has_key(s:station_dict, targetRailName) == 0
        let targetRailName = s:current_rail_name
    endif

    return s:station_dict[targetRailName]

endfunction


function! subway#change_rail_from_name(...)

    let railName = a:0 == 0 ? s:current_rail_name : a:1

    if has_kay(targetRail, l:railName) == 0
        echo "not found " . l:railName 
        return
    endif

    let s:current_rail_name = l:railName
endfunction

function! subway#change_rail_from_ui()

    let l:railList = keys(s:station_dict)
    let l:displayList = s:subway_make_user_select_list(l:railList)

    let l:inputnumber = inputlist(l:displayList) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displayList)
        return 
    endif

    let s:current_rail_name = l:railList[l:inputnumber]
endfunction

function! subway#create_rail(railName)

    if a:railName == ""
        echo "rail name is Empty" 
        return 0
    elseif has_key(s:staion_list, a:railName)
        echo a:railName . " already exists" 
        return 0
    endif

    let s:station_dict[a:railName] = []

    return 1
endfunction

function! subway#make_rail(railName)
    if has_key(s:staion_list, railName) == 0
    endif
endfunction

function! subway#make_station(...)

    let railName = a:0 == 0 ? s:current_rail_name : a:1
    let stationList = s:subway_get_station_list(railName)
    let stationInfo = s:create_station_info()

    exe 'sign define '.railName.' text=*'
    exe 'sign place '.stationInfo["id"].' line='.stationInfo["position"][1].' name='.railName.' buffer='.stationInfo["bufferid"]

    call add(stationList,stationInfo)
endfunction



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
