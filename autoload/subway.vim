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
                    \ 'line'     : line("."),
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
        "
        call subway#create_rail(targetRailName)
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

function! s:subway_get_native_sing_list(railName)
    let l:nativesingResult = s:subway_execute_command('sign place buffer='.bufnr('%'))

    "return s:vital_data_string.lines(l:nativesingResult)
    let l:nativesingList = s:vital_data_string.lines(l:nativesingResult)
   
    let l:resultList = []
    for singstring in l:nativesingList
        
        "check name
        if match(singstring, "name=".a:railName, 0) < 0
            continue
        endif
        call add(l:resultList, singstring)
    endfor

    return l:resultList
endfunction

function! s:subway_get_id_from_line_number_in_buffer(railName, lineNumber)
    let l:nativesingList = s:subway_get_native_sing_list(a:railName)

    let l:result = -1
    for singstring in l:nativesingList
        
        "check line number
        if match(singstring, "line=" . a:lineNumber, 0) < 0
            continue
        endif

        "check name
        if match(singstring, "name=".a:railName, 0) < 0
            continue
        endif

        let l:result = substitute(singstring,'.*id=\([0-9A-Za-z]\+\).*','\1',"")
        break
    endfor

    return l:result
endfunction

function! s:subway_get_line_number_from_station_id_in_buffer(railName, stationId)
    let l:nativesingList = s:subway_get_native_sing_list(a:railName)

    let l:lineNumber = -1
    for singstring in l:nativesingList
        "check name
        if match(singstring, "name=".a:railName, 0) < 0
            continue
        endif
            
        let l:tempId = substitute(singstring,'.*id=\([0-9A-Za-z]\+\).*','\1',"")
        if l:tempId != a:stationId
            continue
        endif

        let l:lineNumber = substitute(singstring,'.*line=\([0-9]\+\).*','\1',"")
        break
    endfor

    return l:lineNumber
endfunction

function! s:subway_get_both_ends_station_in_buffer(railName, starting)
    let l:nativesingList = s:subway_get_native_sing_list(a:railName)

    let l:lineNumber = 0 
    let l:stationId = -1
    for singString in l:nativesingList
        "check name
        if match(singString, "name=".a:railName, 0) < 0
            continue
        endif
            
        let l:tempLineNumber = substitute(singString,'.*line=\([0-9]\+\).*','\1',"")
        let l:tempStationId = substitute(singString,'.*id=\([0-9A-Za-z]\+\).*','\1',"")

        if l:lineNumber == 0
            "check line number
            let l:lineNumber = l:tempLineNumber
            let l:stationId = l:tempStationId
        else
            let l:base = l:lineNumber
            let l:target = l:tempLineNumber

            if a:starting == 0
                let l:base = l:tempLineNumber
                let l:target = l:lineNumber
            endif

            if  l:target < l:base 
                let l:lineNumber = l:tempLineNumber
                let l:stationId = l:tempStationId
            endif
        endif
    endfor
    return l:stationId
endfunction

function! s:subway_get_near_station_in_buffer(railName, previous)
    let l:currentLine = line(".")
    let l:singList = s:subway_get_native_sing_list(a:railName)

    let l:stationId = -1 
    let l:diffValue = 0
    for singString in l:singList
        
        let l:tempLineNumber = substitute(singString,'.*line=\([0-9]\+\).*','\1',"")
        if l:currentLine == l:tempLineNumber
            continue
        endif

        let l:tempDiffValue = 10000000000
        if a:previous == 1
            if l:tempLineNumber > l:currentLine 
                continue
            endif

            let l:tempDiffValue = l:currentLine - l:tempLineNumber
         
        else
            if l:tempLineNumber < l:currentLine 
                continue
            endif
            let l:tempDiffValue = l:tempLineNumber - l:currentLine 
        endif
        
        let l:tempStationId = substitute(singString,'.*id=\([0-9A-Za-z]\+\).*','\1',"")

        if l:stationId == -1
            let l:diffValue = l:tempDiffValue
            let l:stationId = l:tempStationId
        else
            if l:tempDiffValue < l:diffValue 
                let l:diffValue = l:tempDiffValue
                let l:stationId = l:tempStationId
            endif
        endif
    endfor

    return l:stationId

endfunction

function! s:subway_cleaer_station_in_buffer()

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
    let railName = a:0 == 0 ? s:current_rail_name : a:1

    let stationId = s:subway_get_id_from_line_number_in_buffer(railName, line("."))
    if stationId != -1
        return
    endif

    let stationList = s:subway_get_station_list(railName)
    let stationInfo = s:create_station_info()


    let textLabel = railName == s:central_rail_name ? '*' : (railName != s:current_rail_name ? 'x' : '+')

    exe 'sign define '.railName.' text='.textLabel
    exe 'sign place '.stationInfo["id"].' line='.stationInfo["line"].' name='.railName.' buffer='.stationInfo["bufferid"]

    call add(stationList,stationInfo)
endfunction

function! subway#destroy_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1

    let stationId = s:subway_get_id_from_line_number_in_buffer(railName, line("."))
    if stationId == -1
        return
    endif
    

    call s:subway_remove_station_from_id(railName, stationId)

    exe 'sign unplace '.stationId
endfunction


function! subway#toggle_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1
    if s:subway_get_id_from_line_number_in_buffer(railName, line(".")) == -1
        call subway#make_station(railName)
    else
        call subway#destroy_station(railName)
    endif
endfunction

function! subway#move_staion(previous, ...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1

    let l:stationId = s:subway_get_near_station_in_buffer(railName, a:previous)
    if l:stationId == -1
        let l:stationId = s:subway_get_both_ends_station_in_buffer(railName, 1 - a:previous)
    endif

    if l:stationId == -1
        return
    endif

    "let l:station = s:subway_get_station_from_id(railName, l:stationId)
    let l:lineNumber = s:subway_get_line_number_from_station_id_in_buffer(railName, l:stationId)

    exe ':'.l:lineNumber
    
endfunction

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
