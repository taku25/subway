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
let s:central_rail_name = "CENTRAL"

let s:current_rail_name = s:default_rail_name
let s:station_id = 1

"...
let s:default_station_list = []
let s:central_station_list = []


let s:station_dict = {
                    \  s:default_rail_name : s:default_station_list,
                    \  s:central_rail_name : s:central_station_list,
                    \ }

"}}}

function! s:create_station_info(railName)
    
    let subStationList = []

    "id       : uniq station id
    "line     : station linenumber
    "bufferid : buffernumber
    "parent   : parent railName
    "subrail  : sub railName
    let stationInfo = {
                    \ 'id'         : s:station_id,
                    \ 'line'       : str2nr(line(".")),
                    \ 'bufferid'   : bufnr('%'),
                    \ 'parent'     : a:railName,
                    \ 'subrail'    : subStationList,
                    \}

    let s:station_id = s:station_id + 1

    return stationInfo
endfunction

function! s:subway_execute_command(command)
    let saveLang = v:lang
    exec ":lan mes en_US"
    let l:result = ""
    redir => l:result
    silent exe a:command
    redir END
    exec ":lan mes " . saveLang
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

function! s:subway_get_sub_station_list(railName)

    let resultList = []
    for railKey in keys(s:station_dict)
        if railKey == a:railName || railKey == s:central_rail_name
            continue
        endif

        let stationList = s:station_dict[railKey]
        for stationInfo in stationList
            for subRailName in stationInfo['subrail']
                if subRailName == a:railName
                    call add(resultList, stationInfo)
                endif
            endfor 
        endfor
    endfor

    return resultList

endfunction

function! s:subway_remove_sub_station(stationInfo, subRailName)

    let result = 0
    let index = 0
    for subrail in a:stationInfo['subrail']
        if subrail == a:subRailName
            let result = 1
            break
        endif
        let index = index + 1
    endfor

    if result == 1
        call remove(a:stationInfo['subrail'], index)
    endif

    return result
endfunction

function! s:subway_remove_station(stationInfo)
    let staionList = s:subway_get_station_list(a:stationInfo['parent'])

    let result = 0
    let index = 0
    for station in staionList
        if station['id'] == a:stationInfo['id']
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
            let l:resultStation = station
            break
        endif
    endfor

    return l:resultStation 
endfunction


function! s:subway_get_rail_name_from_native_sign(signString)
    let railName = substitute(a:signString,'.*name=subway_\([0-9a-zA-Z]\+\)_.*','\1',"")
    return railName
endfunction

function! s:subway_get_line_number_from_native_sign(signString)
    let lineNumber = substitute(a:signString,'.*line=\([0-9]\+\).*','\1',"")
    return lineNumber == "" ?  -1 : str2nr(lineNumber)
endfunction


function! s:subway_get_id_from_native_sign(signString)
    let result = substitute(a:signString,'.*id=\([0-9A-Za-z]\+\).*','\1',"")
    return result == "" ?  0 : str2nr(result)
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
"return list [id, name]
function! s:subway_get_id_and_rail_name_from_line_number_in_buffer(lineNumber)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list("", bufnr('%'))

    let result = []
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
        if a:railName != ""
            if nativeSignInfo['name'] != a:railName
                continue
            endif
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
        if a:railName != ""
            if nativeSignInfo['name'] != a:railName
                continue
            endif
        endif
            
        if l:lineNumber == 0 
            "check line number
            let l:lineNumber = nativeSignInfo['line']
            let l:stationId = nativeSignInfo['id']
        else
            if a:starting == 1
                if nativeSignInfo['line'] < l:lineNumber
                    let l:lineNumber = nativeSignInfo['line']
                    let l:stationId = nativeSignInfo['id']
                endif
            else
                if nativeSignInfo['line'] > l:lineNumber
                    let l:lineNumber = nativeSignInfo['line']
                    let l:stationId = nativeSignInfo['id']
                endif
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


function! s:subway_update_station_info_list()

    let l:nativeSignInfoList = s:subway_get_native_station_sign_list("", bufnr('%'))
   
    let stationInfo = {}
    for nativeSignInfo in l:nativeSignInfoList
        let stationInfo = s:subway_get_station_from_id(nativeSignInfo['name'], nativeSignInfo['id'])
        let stationInfo['line'] = nativeSignInfo['line']
    endfor

endfunction

function! s:subway_clear_station_in_all_buffer()

    let l:nativeSignInfoList = subway_get_native_station_sign_list_for_all_buffer()

    "all clear!!
    for nativeSignInfo in l:nativeSignInfoList
        exe 'sign unplace '.nativeSignInfo['id']
    endfor

endfunction

function! s:subway_set_station(stationInfo)
    let textLabel = a:stationInfo['parent'] == s:central_rail_name ? '*' :
                                 \ (len(a:stationInfo['subrail']) == 0 ? '+' : 'x')

    let highlightValue = g:subway_enable_highlight == 0 ? "" :
                            \ ' linehl='.g:subway_line_highlight. 
                            \ ' texthl='.g:subway_text_highlight

    exe 'sign define subway_'.a:stationInfo['parent'].'_ text='.textLabel.highlightValue
    exe 'sign place '.a:stationInfo["id"].
                    \' line='.a:stationInfo["line"].
                    \' name=subway_'.a:stationInfo['parent'].
                    \'_ buffer='.a:stationInfo["bufferid"]

endfunction

function! subway#change_rail_from_name(...)

    let railName = a:0 == 0 ? s:default_rail_name : a:1

    if has_key(s:station_dict, railName) == 0
        echo "not found " . railName 
        return
    endif


    "don't change the order
    "1.update
    call s:subway_update_station_info_list()
    "2.clear
    call s:subway_clear_station_in_all_buffer()
    "3.
    let s:current_rail_name = l:railName


    "base station
    let stationInfoList = s:station_dict[railName]
    for station in stationInfoList
        call s:subway_set_station(station)
    endfor

    "central station
    let stationInfoList = s:station_dict[s:central_rail_name]
    for station in stationInfoList
        call s:subway_set_station(station)
    endfor 

    "substation
    let stationInfoList = s:subway_get_sub_station_list(railName)
    for station in stationInfoList
        call s:subway_set_station(station)
    endfor
endfunction


function! subway#change_rail_from_list()

    let l:railList = []
    for stationKey in keys(s:station_dict)
        if stationKey == s:central_rail_name
            continue
        endif
        call add(l:railList, stationKey)
    endfor

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
    elseif has_key(s:station_dict, a:railName)
        echo a:railName . " already exists" 
        return 0
    endif

    let s:station_dict[a:railName] = []

    return 1
endfunction


function! subway#make_central_station()
    call subway#make_station(s:central_rail_name)
endfunction

function! subway#destroy_central_station(...)
    call subway#destroy_station(s:central_rail_name)
endfunction

function! subway#make_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1

    let staionIdAndRailName = s:subway_get_id_and_rail_name_from_line_number_in_buffer(line("."))
    if len(staionIdAndRailName) != 0
        "not exists station"
        return
    endif

    let stationList = s:subway_get_station_list(railName)
    let stationInfo = s:create_station_info(railName)

    
    if railName != s:central_rail_name && railName != s:current_rail_name
        call add(stationInfo['subrail'], s:current_rail_name)
    endif

    call add(stationList,stationInfo)

    call s:subway_set_station(stationInfo)

endfunction

function! subway#destroy_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1

    let stationIdAndRailName = s:subway_get_id_and_rail_name_from_line_number_in_buffer(line("."))
     
    if len(stationIdAndRailName) == 0
        "not exists station"
        return
    endif
   
    let stationInfo = s:subway_get_station_from_id(stationIdAndRailName[1], stationIdAndRailName[0])

    if railName == s:central_rail_name || railName == s:current_rail_name
        call s:subway_remove_station(stationInfo)
    else
        call s:subway_remove_sub_station(stationInfo, s:current_rail_name)
    endif

    exe 'sign unplace '.stationIdAndRailName[0]
endfunction


function! subway#toggle_station(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1
    let staionIdAndRailName = s:subway_get_id_and_rail_name_from_line_number_in_buffer(line("."))
    if len(staionIdAndRailName) == 0
        call subway#make_station(railName)
    else
        call subway#destroy_station(railName)
    endif
endfunction

function! subway#move_staion(previous, ...)
    let railName = a:0 == 0 ? "" : a:1

    let l:stationId = s:subway_get_near_station_in_buffer(railName, a:previous)
    if l:stationId == -1
        let l:stationId = s:subway_get_both_ends_station_in_buffer(railName, 1 - a:previous)
    endif

    if l:stationId == -1
        return
    endif

    let l:lineNumber = s:subway_get_line_number_from_station_id_in_buffer(railName, l:stationId)

    exe ':'.l:lineNumber
    
endfunction

function! subway#clear_rail(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1
    
    if !has_key(railName)
        return
    endif
    
    let l:nativeSignInfoList = subway_get_native_station_sign_list_for_all_buffer(railName)
   
    "unplace
    for nativeSignInfo in l:nativeSignInfoList
        exe 'sign unplace '.nativeSignInfo['id']
    endfor

    "cleaer station
    let s:station_dict[railName] = [] 

endfunction

function! subway#destroy_rail(...)
    let railName = a:0 == 0 ? s:current_rail_name : a:1
    
    if !has_key(railName)
        return
    endif
    
    let l:nativeSignInfoList = subway_get_native_station_sign_list_for_all_buffer(railName)
   
    "unplace
    for nativeSignInfo in l:nativeSignInfoList
        exe 'sign unplace '.nativeSignInfo['id']
    endfor

    "can't delete centrail and default rail
    if railName == s:central_rail_name || railName == s:default_rail_name
        echo "can't delete centrail and default rail. clear station"
        return
    endif

    "remove rail
    call remove(s:station_dict, railName)

endfunction



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
