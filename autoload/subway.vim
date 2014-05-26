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

" vital {{{
let s:vital = vital#of('subway')
let s:vital_data_string = s:vital.import('Data.String')
" }}}



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
                    \ 'id'       : s:station_id,
                    \ 'filepath' : expand('%:p'),
                    \ 'position' : getpos('.'),
                    \ 'string'   : getline("."),
                    \ 'bufferid' : bufnr('%'),
                    \}

    let s:station_id = s:station_id + 1

    return stationInfo
endfunction

function! s:subway_execute_command(command)
    let oldLang = v:lang
    exec ":lan mes en_US"
    let l:result = ""
    redir => l:result
    silent exe a:command
    redir END
    exec ":lan mes " . oldLang
    return l:result
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


function! s:subway_remove_station_from_id(railName, stationId)
    let staionList = s:subway_get_station_list(a:railName)

    let result = 0
    let index = 0
    for station in staionList
        if station['id'] == a:stationId
            let result = 1
            break
        endif
        let index = index + 1
    endfor

    if result == 1
        call remove(staionList, index)
    endif

    return result
endfunction

function! s:subway_get_station_from_id(railName, stationId)
    let l:stationList = s:subway_get_station_list(a:railName)

    let l:resultStation = {}
    for station in l:stationList
        if station['id'] == a:stationId
            l:resultStation = station
            break
        endif
    endfor

    return l:resultStation 
endfunction

function! s:subway_get_id_from_line_number_in_buffer(lineNumber)
    let l:nativeSignalResult = s:subway_execute_command('sign place buffer='.bufnr('%'))
    let l:nativeSignalList = s:vital_data_string.lines(l:nativeSignalResult)

    let l:result = -1
    for signalstring in l:nativeSignalList
        
        "check line number
        if match(signalstring, "line=" . a:lineNumber, 0) < 0
            continue
        endif

        "check name
        if match(signalstring, "name=".s:current_rail_name, 0) < 0
            continue
        endif

        let l:result = substitute(signalstring,'.*id=\([0-9A-Za-z]\+\).*','\1',"")
        break
    endfor

    return l:result
endfunction

function! subway#change_rail_from_name(...)

    let railName = a:0 == 0 ? s:current_rail_name : a:1

    if has_kay(targetRail, l:railName) == 0
        echo "not found " . l:railName 
        return
    endif


    let s:current_rail_name = l:railName
endfunction


function! subway#change_rail_from_list()

    let l:railList = keys(s:station_dict)
    let l:displayList = s:subway_make_user_select_list(l:railList)

    let l:inputnumber = inputlist(l:displayList) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displayList)
        return 
    endif

    call subway#change_rail_from_name(l:railList[l:inputnumber])
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

function! subway#make_station(...)
    let stationId = s:subway_get_id_from_line_number_in_buffer(line("."))
    if stationId != -1
        return
    endif

    let railName = a:0 == 0 ? s:current_rail_name : a:1
    let stationList = s:subway_get_station_list(railName)
    let stationInfo = s:create_station_info()

    let textLabel = railName == s:central_rail_name ? '*' : '+'
    exe 'sign define '.railName.' text='.textLabel
    exe 'sign place '.stationInfo["id"].' line='.stationInfo["position"][1].' name='.railName.' buffer='.stationInfo["bufferid"]

    call add(stationList,stationInfo)
endfunction

function! subway#destroy_station(...)
    let stationId = s:subway_get_id_from_line_number_in_buffer(line("."))
    if stationId == -1
        return
    endif
    
    let railName = a:0 == 0 ? s:current_rail_name : a:1

    call s:subway_remove_station_from_id(railName, stationId)

    exe 'sign unplace '.stationId
endfunction


function! subway#toggle_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1
    if s:subway_get_id_from_line_number_in_buffer(line(".")) == -1
        call subway#make_station(railName)
    else
        call subway#destroy_station(railName)
    endif
endfunction

function! 

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
