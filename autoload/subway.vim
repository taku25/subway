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
let s:default_line_name = "default"
let s:central_line_name = "CENTRAL"

let s:current_line_name = s:default_line_name
let s:station_id = 1

"...
let s:default_station_list = []
let s:central_station_list = []


let s:station_dict = {
                    \  s:default_line_name : s:default_station_list,
                    \  s:central_line_name : s:central_station_list,
                    \ }

"}}}

function! s:create_station_info(lineName)
    
    let subStationList = []

    "id       : uniq station id
    "line     : station linenumber
    "bufferid : buffernumber
    "parent   : parent lineName
    "subline  : sub lineName
    let stationInfo = {
                    \ 'id'         : s:station_id,
                    \ 'line'       : str2nr(line(".")),
                    \ 'bufferid'   : bufnr('%'),
                    \ 'parent'     : a:lineName,
                    \ 'subline'    : subStationList,
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


function! s:subway_get_station_list(lineName)

    let targetLineName = a:lineName == "" ? s:current_line_name : a:lineName
    
    if has_key(s:station_dict, targetLineName) == 0
        "
        call subway#create_line(targetLineName)
    endif

    return s:station_dict[targetLineName]

endfunction

function! s:subway_get_sub_station_list(lineName)

    let resultList = []
    for lineKey in keys(s:station_dict)
        if lineKey == a:lineName || lineKey == s:central_line_name
            continue
        endif

        let stationList = s:station_dict[lineKey]
        for stationInfo in stationList
            for subLineName in stationInfo['subline']
                if subLineName == a:lineName
                    call add(resultList, stationInfo)
                endif
            endfor 
        endfor
    endfor

    return resultList

endfunction

function! s:subway_remove_sub_station(stationInfo, subLineName)

    let result = 0
    let index = 0
    for subline in a:stationInfo['subline']
        if subline == a:subLineName
            let result = 1
            break
        endif
        let index = index + 1
    endfor

    if result == 1
        call remove(a:stationInfo['subline'], index)
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

function! s:subway_get_station_from_id(lineName, stationId)
    let l:stationList = s:subway_get_station_list(a:lineName)

    let l:resultStation = {}
    for station in l:stationList
        if station['id'] == a:stationId
            let l:resultStation = station
            break
        endif
    endfor

    return l:resultStation 
endfunction


function! s:subway_get_line_name_from_native_sign(signString)
    let lineName = substitute(a:signString,'.*name=subway_\([0-9a-zA-Z]\+\)_.*','\1',"")
    return lineName
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
"param lineName string argument
"   Get station sign from the line name. 
"   if line name is empty Get all station sign 
"return dictionary list { name:lineName, line:lineNumber, id:id} ...
function! s:subway_get_native_station_sign_list(lineName, buffernumber)
    "let l:nativesignResult = s:subway_execute_command('sign place buffer='.bufnr('%'))
    let l:nativesignResult = s:subway_execute_command('sign place buffer='.a:buffernumber)

    "return s:vital_data_string.lines(l:nativesignResult)
    let l:nativesignList = s:vital_data_string.lines(l:nativesignResult)
   
    let resultList = []
    for signString in l:nativesignList

        if s:subway_is_station_sign_from_native_sign(signString) == 0
            continue
        endif
        
        let dict = {
                  \ 'name' : s:subway_get_line_name_from_native_sign(signString),
                  \ 'line' : s:subway_get_line_number_from_native_sign(signString),
                  \ 'id'   : s:subway_get_id_from_native_sign(signString),
                  \}

        call add(resultList, dict)
    endfor
        
    return resultList
endfunction

function! s:subway_get_native_station_sign_list_for_all_buffer()
    let l:bufNumber = bufnr("$")

    let l:allsignList = []
    for i in range(l:bufNumber)
        let bufnumber = i + 1
        if bufexists(bufnumber) == 0
            continue
        endif
    
        let l:nativeSignInfoList = s:subway_get_native_station_sign_list("", bufnumber)
        call extend(l:allsignList, l:nativeSignInfoList)
    endfor

    return l:allsignList
endfunction

function! s:subway_get_id_from_line_number_in_buffer(lineNumber, lineName)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:lineName, bufnr('%'))

    let l:result = -1
    for nativeSignInfo in l:nativeSignInfoList
        
        "check line number
        if nativeSignInfo['line'] != a:lineNumber
           continue 
        endif

        "check name
        if a:lineName != ""
            if nativeSignInfo['name'] != a:lineName
               continue 
            endif
        endif

        let l:result = nativeSignInfo['id']
        break
    endfor

    return l:result
endfunction


"brief get id and line name from native sign in buffer
"return list [id, name]
function! s:subway_get_id_and_line_name_from_line_number_in_buffer(lineNumber)
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

function! s:subway_get_line_number_from_station_id_in_buffer(lineName, stationId)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:lineName, bufnr('%'))

    let l:lineNumber = -1
    for nativeSignInfo in l:nativeSignInfoList
        "check name
        if a:lineName != ""
            if nativeSignInfo['name'] != a:lineName
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

function! s:subway_get_both_ends_station_in_buffer(lineName, starting)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:lineName, bufnr('%'))

    let l:lineNumber = 0 
    let l:stationId = -1
    for nativeSignInfo in l:nativeSignInfoList
        "check name
        if a:lineName != ""
            if nativeSignInfo['name'] != a:lineName
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

function! s:subway_get_near_station_in_buffer(lineName, previous)
    let l:nativeSignInfoList = s:subway_get_native_station_sign_list(a:lineName, bufnr('%'))

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

    let l:nativeSignInfoList = s:subway_get_native_station_sign_list_for_all_buffer()
   
    "unplace
    for nativeSignInfo in l:nativeSignInfoList
        exe 'sign unplace '.nativeSignInfo['id']
    endfor

endfunction

function! s:subway_set_station(stationInfo)
    let textLabel = a:stationInfo['parent'] == s:central_line_name ? '*' :
                                 \ (len(a:stationInfo['subline']) == 0 ? '+' : 'x')

    let highlightValue = g:subway_enable_highlight == 0 ? "" :
                            \ ' linehl='.g:subway_line_highlight. 
                            \ ' texthl='.g:subway_text_highlight

    exe 'sign define subway_'.a:stationInfo['parent'].'_ text='.textLabel.highlightValue
    exe 'sign place '.a:stationInfo["id"].
                    \' line='.a:stationInfo["line"].
                    \' name=subway_'.a:stationInfo['parent'].
                    \'_ buffer='.a:stationInfo["bufferid"]

endfunction

function! subway#change_line_from_name(...)

    let lineName = a:0 == 0 ? s:default_line_name : a:1

    if has_key(s:station_dict, lineName) == 0
        echo "not found " . lineName 
        return
    endif


    "don't change the order
    "1.update
    call s:subway_update_station_info_list()
    "2.clear
    call s:subway_clear_station_in_all_buffer()
    "3.
    let s:current_line_name = lineName


    "base station
    let stationInfoList = s:station_dict[lineName]
    for station in stationInfoList
        call s:subway_set_station(station)
    endfor

    "central station
    let stationInfoList = s:station_dict[s:central_line_name]
    for station in stationInfoList
        call s:subway_set_station(station)
    endfor 

    "substation
    let stationInfoList = s:subway_get_sub_station_list(lineName)
    for station in stationInfoList
        call s:subway_set_station(station)
    endfor
endfunction


function! subway#change_line_from_list()

    let l:lineList = []
    for stationKey in keys(s:station_dict)
        if stationKey == s:central_line_name
            continue
        endif
        call add(l:lineList, stationKey)
    endfor

    let l:displayList = s:subway_make_user_select_list(l:lineList)
    let l:inputnumber = inputlist(l:displayList) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displayList)
        return 
    endif

    call subway#change_line_from_name(l:lineList[l:inputnumber])
endfunction

function! subway#create_line(lineName)

    if a:lineName == ""
        echo "line name is Empty" 
        return 0
    elseif has_key(s:station_dict, a:lineName)
        echo a:lineName . " already exists" 
        return 0
    endif

    let s:station_dict[a:lineName] = []

    return 1
endfunction


function! subway#make_central_station()
    call subway#make_station(s:central_line_name)
endfunction

function! subway#destroy_central_station(...)
    call subway#destroy_station(s:central_line_name)
endfunction

function! subway#make_station(...)
    let lineName = a:0 == 0 ? s:current_line_name : a:1

    let staionIdAndLineName = s:subway_get_id_and_line_name_from_line_number_in_buffer(line("."))
    if len(staionIdAndLineName) != 0
        "not exists station"
        return
    endif

    let stationList = s:subway_get_station_list(lineName)
    let stationInfo = s:create_station_info(lineName)

    
    if lineName != s:central_line_name && lineName != s:current_line_name
        call add(stationInfo['subline'], s:current_line_name)
    endif

    call add(stationList,stationInfo)

    call s:subway_set_station(stationInfo)

endfunction

function! subway#destroy_station(...)
    let lineName = a:0 == 0 ? s:current_line_name : a:1

    let stationIdAndLineName = s:subway_get_id_and_line_name_from_line_number_in_buffer(line("."))
     
    if len(stationIdAndLineName) == 0
        "not exists station"
        return
    endif
   
    let stationInfo = s:subway_get_station_from_id(stationIdAndLineName[1], stationIdAndLineName[0])

    if lineName == s:central_line_name || lineName == s:current_line_name
        call s:subway_remove_station(stationInfo)
    else
        call s:subway_remove_sub_station(stationInfo, s:current_line_name)
    endif

    exe 'sign unplace '.stationIdAndLineName[0]
endfunction


function! subway#toggle_station(...)
    let lineName = a:0 == 0 ? s:current_line_name : a:1
    let staionIdAndLineName = s:subway_get_id_and_line_name_from_line_number_in_buffer(line("."))
    if len(staionIdAndLineName) == 0
        call subway#make_station(lineName)
    else
        call subway#destroy_station(lineName)
    endif
endfunction

function! subway#move_staion(previous, ...)
    let lineName = a:0 == 0 ? "" : a:1

    let l:stationId = s:subway_get_near_station_in_buffer(lineName, a:previous)
    if l:stationId == -1
        let l:stationId = s:subway_get_both_ends_station_in_buffer(lineName, 1 - a:previous)
    endif

    if l:stationId == -1
        return
    endif

    let l:lineNumber = s:subway_get_line_number_from_station_id_in_buffer(lineName, l:stationId)

    exe ':'.l:lineNumber
    
endfunction

function! subway#clear_line(...)
    let lineName = a:0 == 0 ? s:current_line_name : a:1
    
    if !has_key(s:station_dict, lineName)
        return
    endif
    
    call s:subway_clear_station_in_all_buffer()

    "clear station
    let s:station_dict[lineName] = [] 

endfunction

function! subway#destroy_line(...)
    let lineName = a:0 == 0 ? s:current_line_name : a:1
    
    if !has_key(s:station_dict, lineName)
        return
    endif
    
    call s:subway_clear_station_in_all_buffer()

    "can't delete centline and default line
    if lineName == s:central_line_name || lineName == s:default_line_name
        echo "can't delete centline and default line. clear station"
        return
    endif

    "remove line
    call remove(s:station_dict, lineName)

endfunction



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
