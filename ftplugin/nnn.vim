if exists('b:nnn_ftplugin')
    finish
endif
let b:nnn_ftplugin = 1

for key in keys(g:nnn#action)
    execute 'tnoremap <nowait><buffer><silent>' key '<c-\><c-n>:<c-u>call nnn#select_action("'.substitute(key, '<', '<lt>', 'g').'")<cr>'
endfor

if g:nnn#set_default_mappings
    tnoremap <buffer><silent> <C-w>l <C-\><C-n><C-w>l
    tnoremap <buffer><silent> <C-w>h <C-\><C-n><C-w>h
    tnoremap <buffer><silent> <C-w>j <C-\><C-n><C-w>j
    tnoremap <buffer><silent> <C-w>k <C-\><C-n><C-w>k
endif

if has('nvim') && stridx(&winhighlight, 'NnnNormalFloat') == -1
    setl winhighlight=Normal:NnnNormal,NormalNC:NnnNormalNC,VertSplit:NnnVertSplit
elseif !has('nvim') && &wincolor !=# 'NnnNormalFloat'
    setl wincolor=NnnNormal
    augroup NnnSetWincolor
        autocmd!
        autocmd BufEnter <buffer> setl wincolor=NnnNormal
        autocmd BufLeave <buffer> setl wincolor=NnnNormalNC
    augroup END
endif

if !exists('g:nnn#statusline') || g:nnn#statusline
    setl statusline=%<%y
endif


setl nospell bufhidden=wipe nobuflisted nonumber norelativenumber noshowmode wrap nocursorline nocursorcolumn
" vim: set sts=4 sw=4 ts=4 et :
