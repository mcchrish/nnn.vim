if exists("g:nnn_ftplugin")
    finish
endif
let b:nnn_ftplugin = 1

let s:nowait = (v:version > 703 ? '<nowait>' : '')

for key in keys(g:nnn#action)
    if type(g:nnn#action[key]) == 2
        exec 'tnoremap '.s:nowait.'<buffer><silent> '.key.' <c-\><c-n>:<c-u>call nnn#select_action('.string(g:nnn#action[key]).')<cr>'
    else
        exec 'tnoremap '.s:nowait.'<buffer><silent> '.key.' <c-\><c-n>:<c-u>call nnn#select_action("'.g:nnn#action[key].'")<cr>'
    endif
endfor

setlocal nospell bufhidden=wipe nobuflisted nonumber noruler
" vim: set sts=4 sw=4 ts=4 et :
