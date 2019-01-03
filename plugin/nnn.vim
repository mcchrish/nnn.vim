fun! s:init_config_var(var, value)
    if !exists(a:var)
        exec 'let ' . a:var . ' = ' . "'" . substitute(a:value, "'", "''", "g") . "'"
        return 1
    endif
    return 0
endfun

call s:init_config_var("g:nnn#layout", "enew")
call s:init_config_var("g:nnn#action", {})
call s:init_config_var("g:nnn#command", "nnn")
call s:init_config_var("g:nnn#set_default_mappings", 1)
call s:init_config_var("g:nnn#replace_netrw", 0)

command! -bar -nargs=? -complete=dir NnnPicker call nnn#pick(<f-args>)
command! -bar -nargs=? -complete=dir Np call nnn#pick(<f-args>)

if g:nnn#set_default_mappings
    nnoremap <silent> <leader>n :NnnPicker<CR>
endif

" To open nnn when vim load a directory
if g:nnn#replace_netrw
    fun! s:nnn_pick_on_load_dir(argv_path)
        let l:path = expand(a:argv_path)
        bdelete!
        call nnn#pick(l:path)
    endfun

    augroup ReplaceNetrwByNnnVim
        autocmd VimEnter * silent! autocmd! FileExplorer
        autocmd BufEnter * if isdirectory(expand("%")) | call <SID>nnn_pick_on_load_dir("%") | endif
    augroup END
endif

" vim: set sts=4 sw=4 ts=4 et :
