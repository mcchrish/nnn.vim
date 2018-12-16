if !(exists("g:nnn#set_default_mappings"))
    let g:nnn#set_default_mappings = 1
endif

if !(exists("g:nnn#layout"))
    let g:nnn#layout = 'enew'
endif

if !(exists("g:nnn#action"))
    let g:nnn#action = {}
endif

if !(exists("g:nnn#command"))
    let g:nnn#command = 'nnn'
endif

command! -bar -nargs=? -complete=dir NnnPicker call nnn#pick(<f-args>)
command! -bar -nargs=? -complete=dir Np call nnn#pick(<f-args>)

if g:nnn#set_default_mappings
    nnoremap <silent> <leader>n :NnnPicker<CR>
endif

" vim: set sts=4 sw=4 ts=4 et :
