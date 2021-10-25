if exists('b:nnn_ftplugin')
    finish
endif
let b:nnn_ftplugin = 1

for key in keys(g:nnn#action)
    execute 'tnoremap <nowait><buffer><silent>' key '<c-\><c-n>:<c-u>call nnn#select_action("'.substitute(key, '<', '<lt>', 'g').'")<cr>'
endfor

if g:nnn#set_default_mappings
    tnoremap <nowait><buffer><silent> <C-w>l <C-\><C-n><C-w>l
    tnoremap <nowait><buffer><silent> <C-w>h <C-\><C-n><C-w>h
    tnoremap <nowait><buffer><silent> <C-w>j <C-\><C-n><C-w>j
    tnoremap <nowait><buffer><silent> <C-w>k <C-\><C-n><C-w>k
endif

setlocal winhighlight=VertSplit:NnnVertSplit,NormalNC:NnnNormalNC,Normal:NnnNormal

function! s:statusline_bufenter()
    setlocal statusline=%#StatusLine#\ nnn\ %#StatusLineNC#
endfunction

function! s:statusline_bufleave()
    setlocal statusline=%#NnnNormalNC#
endfunction

if exists('g:nnn#statusline') && g:nnn#statusline
    call s:statusline_bufenter()
endif

if exists('g:nnn#hide_inactive_statusline') && g:nnn#hide_inactive_statusline
    augroup nnn_statusline
        autocmd!
        autocmd BufLeave <buffer> call <SID>statusline_bufleave()
        autocmd BufEnter <buffer> call <SID>statusline_bufenter()
    augroup end
endif

setlocal nospell bufhidden=wipe nobuflisted nonumber norelativenumber noshowmode wrap nocursorline nocursorcolumn
" vim: set sts=4 sw=4 ts=4 et :
