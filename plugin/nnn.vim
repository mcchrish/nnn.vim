if exists('g:nnn#loaded')
  finish
endif
let g:nnn#loaded = 1

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

if !(exists("g:nnn#replace_netrw"))
    let g:nnn#replace_netrw = 0
endif

if !(exists("g:nnn#statusline"))
    let g:nnn#statusline = 1
endif

command! -bar -nargs=? -complete=dir NnnPicker call nnn#pick(<f-args>)
command! -bar -nargs=? -complete=dir Np call nnn#pick(<f-args>)

if g:nnn#set_default_mappings
    nnoremap <silent> <leader>n :NnnPicker<CR>
endif

" To open nnn when vim load a directory
if g:nnn#replace_netrw
    function! s:nnn_pick_on_load_dir(argv_path)
        let l:path = expand(a:argv_path)
        bdelete!
        call nnn#pick(l:path)
    endfunction

    augroup ReplaceNetrwByNnnVim
        autocmd VimEnter * silent! autocmd! FileExplorer
        autocmd BufEnter * if isdirectory(expand("%")) | call <SID>nnn_pick_on_load_dir("%") | endif
    augroup END
endif

" vim: set sts=4 sw=4 ts=4 et :
