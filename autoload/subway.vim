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

function! subway#show_all_station_in_current_buffer()
    echo s:subway_get_native_station_sign_list("", bufnr('%'))
endfunction

function! subway#show_all_station()
    echo s:subway_get_native_station_sign_list_for_all_buffer("")
endfunction

function! s:subway_get_rail_name_from_native_sign(signString)
    let railName = substitute(a:signString,'.*name=subway_\([0-9a-zA-Z]\+\)_.*','\1',"")
    return railName
endfunction

function! s:subway_get_line_number_from_native_sign(signString)
    let lineNumber = substitute(a:signString,'.*line=\([0-9]\+\).*','\1',"")
    return lineNumber == "" ?  -1 : lineNumber
endfunction


function! s:subway_get_id_from_native_sign(signString)
    let result = substitute(a:signString,'.*id=\([0-9A-Za-z]\+\).*','\1',"")
    return result == "" ?  0 : result
endfunction

function! s:subway_is_station_sign_from_native_sign(signString)
    let result = 1
    if match(a:signString, "name=subway_", 0) < 0
        let result = 0
    endif

    return result
endfunction

"brief get native sign list
"param railName string argument
"   Get station sign from the rail name. 
"   if rail name is empty Get all station sign 
"return dictionary list { name:railName, line:lineNumber, id:id} ...
function! s:subway_get_native_station_sign_list(railName, buffernumber)
    "let l:nativesignResult = s:subway_execute_command('sign place buffer='.bufnr('%'))
    let l:nativesignResult = s:subway_execute_command('sign place buffer='.a:buffernumber)

    let l:searchString = "name=subway_" . a:railName

    "return s:vital_data_string.lines(l:nativesignResult)
    let l:nativesignList = s:vital_data_string.lines(l:nativesignResult)
   
    let l:resultList = []
    for signString in l:nativesignList

        if s:subway_is_station_sign_from_native_sign(signString) == 0
            continue
        endif

        let dict = {
                  \ 'name' : s:subway_get_rail_name_from_native_sign(signString),
                  \ 'line' : s:subway_get_line_number_from_native_sign(signString),
                  \ 'id'   : s:subway_get_id_from_native_sign(signString),
                  \}

        call add(l:resultList, dict)
    endfor

    return l:resultList
endfunction

function! s:subway_get_native_station_sign_list_for_all_buffer(railName)
    let l:bufNumber = bufnr("$")

    let l:allsignList = []
    for i in range(l:bufNumber)
        if bufexists(i) == 0
            continue
        endif
    
        let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:railName, i)
        call extend(l:allsignList, l:nativeSignInfoList)
    endfor

    return l:allsignList
endfunction

function! s:subway_get_id_from_line_number_in_buffer(lineNumber, railName)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:railName, bufnr('%'))

    let l:result = -1
    for nativeSignInfo in l:nativeSignInfoList
        
        "check line number
        if nativeSignInfo['line'] != a:lineNumber
           continue 
        endif

        "check name
        if nativeSignInfo['name'] != a:railName
           continue 
        endif

        let l:result = nativeSignInfo['id']
        break
    endfor

    return l:result
endfunction


"brief get id and rail name from native sign in buffer
"return list
"       index 0 
"           id
"       index 1
"           name
function! s:subway_get_id_and_rail_name_from_line_number_in_buffer(lineNumber)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list("", bufnr('%'))

    let result = {}
    for nativeSignInfo in l:nativeSignInfoList
        
        "check line number
        if nativeSignInfo['line'] != a:lineNumber
           continue 
        endif

        call add(result, nativeSignInfo['id'])
        call add(result, nativeSignInfo['name'])
        break
    endfor

    return result
endfunction

function! s:subway_get_line_number_from_station_id_in_buffer(railName, stationId)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:railName, bufnr('%'))

    let l:lineNumber = -1
    for nativeSignInfo in l:nativeSignInfoList
        "check name
        if nativeSignInfo['name'] != a:railName
            continue
        endif
            
        if nativeSignInfo['id'] != a:stationId
            continue
        endif

        let l:lineNumber = nativeSignInfo['line']
        break
    endfor

    return l:lineNumber
endfunction

function! s:subway_get_both_ends_station_in_buffer(railName, starting)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:railName, bufnr('%'))

    let l:lineNumber = 0 
    let l:stationId = -1
    for nativeSignInfo in l:nativeSignInfoList
        "check name
        if nativeSignInfo['name'] != a:railName
            continue
        endif
            
        if l:lineNumber == 0
            "check line number
            let l:lineNumber = nativeSignInfo['line']
            let l:stationId = nativeSignInfo['id']
        else
            let l:base = l:lineNumber
            let l:target = nativeSignInfo['line']

            if a:starting == 0
                let l:base = nativeSignInfo['line']
                let l:target = l:lineNumber
            endif

            if  l:target < l:base 
                let l:lineNumber = nativeSignInfo['line']
                let l:stationId = nativeSignInfo['id']
            endif
        endif
    endfor
    return l:stationId
endfunction

function! s:subway_get_near_station_in_buffer(railName, previous)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:railName, bufnr('%'))

    let l:currentLine = line(".")
    let l:stationId = -1 
    let l:diffValue = 0
    for nativeSignInfo in l:nativeSignInfoList
        
        if l:currentLine == nativeSignInfo['line']
            continue
        endif

        let l:tempDiffValue = 10000000000
        if a:previous == 1
            if nativeSignInfo['line'] > l:currentLine 
                continue
            endif
            let l:tempDiffValue = l:currentLine - nativeSignInfo['line']
        else
            if nativeSignInfo['line'] < l:currentLine 
                continue
            endif
            let l:tempDiffValue = nativeSignInfo['line'] - l:currentLine 
        endif
        
        let l:tempStationId = nativeSignInfo['id']

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


function! s:subway_update_station_list(...)

    let l:nativeSignInfoList = a:0 == 0 ? s:subway_get_native_station_sign_list(a:railName) : a:1

endfunction

function! s:subway_clear_station_in_all_buffer()

    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:railName, bufnr('%'))
    
    for nativeSignInfo in l:nativeSignInfoList
        
    endfor

endfunction

function! s:subway_set_station(railName, stationInfo)
    let textLabel = a:railName == s:central_rail_name ? '*' : (a:railName != s:current_rail_name ? 'x' : '+')

    exe 'sign define subway_'.a:railName.'_ text='.textLabel
    exe 'sign place '.a:stationInfo["id"].' line='.a:stationInfo["line"].' name=subway_'.a:railName.'_ buffer='.a:stationInfo["bufferid"]
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

    let stationId = s:subway_get_id_from_line_number_in_buffer(line("."), railName)
    if stationId != -1
        return
    endif

    let stationList = s:subway_get_station_list(railName)
    let stationInfo = s:create_station_info()

    call add(stationList,stationInfo)

    call s:subway_set_station(railName, stationInfo)

endfunction

function! subway#destroy_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1

    let stationId = s:subway_get_id_from_line_number_in_buffer(line("."), railName)
    if stationId == -1
        return
    endif
    

    call s:subway_remove_station_from_id(railName, stationId)

    exe 'sign unplace '.stationId
endfunction


function! subway#toggle_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1
    if s:subway_get_id_from_line_number_in_buffer(line("."), railName) == -1
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
