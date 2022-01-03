if exists('b:nnn_ftplugin')
    finish
endif
let b:nnn_ftplugin = 1

for key in keys(g:nnn#action)
    execute 'tnoremap <nowait><buffer><silent>' key '<c-\><c-n>:<c-u>call nnn#select_action("'.substitute(key, '<', '<lt>', 'g').'")<cr>'
endfor

if g:nnn#set_default_mappings
    tnoremap <buffer><silent> <C-w> <C-\><C-n><C-w>
endif

if !exists('w:is_nnn_float')
    if has('nvim')
        setl winhighlight=Normal:NnnNormal,NormalNC:NnnNormalNC,VertSplit:NnnVertSplit
    else
        setl wincolor=NnnNormal
        augroup NnnSetWincolor
            autocmd!
            autocmd BufEnter <buffer> setl wincolor=NnnNormal
            autocmd BufLeave <buffer> setl wincolor=NnnNormalNC
        augroup END
    endif
endif

if has('nvim')
    autocmd BufEnter <buffer> startinsert
else
    autocmd BufEnter <buffer> if term_getstatus(bufnr()) =~# 'normal' | call feedkeys('i', 't') | endif
endif

if !exists('g:nnn#statusline') || g:nnn#statusline
    if exists('b:is_nnn_picker')
        setl statusline=\ nnn%=[picker]
    else
        setl statusline=\ nnn%=[explorer]
    endif
endif


setl nospell bufhidden=wipe nobuflisted nonumber norelativenumber wrap nocursorline nocursorcolumn
" vim: set sts=4 sw=4 ts=4 et :
