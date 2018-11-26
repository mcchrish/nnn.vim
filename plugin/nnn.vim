" vim/neovim plugin to use nnn as a file picker
" Closely follows and inspired by the vim_file_chooser plugin for ranger.
"
" Author: Arun Prakash Jana
" Email: engineerarun@gmail.com
" Homepage: https://github.com/jarun/nnn
" Copyright © 2018 Arun Prakash Jana

let s:temp = ""

if !(exists("g:nnn#set_default_mappings"))
    let g:nnn#set_default_mappings = 1
endif

fun! s:Create_on_exit_callback(opts)
    let s:On_exit = {}
    let s:eval_opts = a:opts
    fun! s:On_exit.Callback(job_id, code, event) dict
        if a:code != 0
            echoerr 'nnn exited with non-zero.'
            return
        endif

        bd!
        call s:evaluate_temp(s:eval_opts)
    endfun
    return s:On_exit
endfun

fun! s:evaluate_temp(opts)
    if !filereadable(s:temp)
        " When exiting without any selection
        redraw!
        " Nothing to read.
        return
    endif
    let names = readfile(s:temp)
    if empty(names)
        redraw!
        " Nothing to open.
        return
    endif
    " Edit the first item.
    exec a:opts.edit . ' ' . fnameescape(names[0])
    " Add any remaining items to the arg list/buffer list.
    for name in names[1:]
        exec 'argadd ' . fnameescape(name)
    endfor
    redraw!
endfun

function! NnnPicker(...)
    let l:directory = expand(get(a:, 1, ""))
    let l:opts = get(a:, 2, { 'edit': 'edit' })
    let s:temp = tempname()
    let l:cmd = 'nnn -p ' . shellescape(s:temp) . ' ' . l:directory

    if exists("g:nnn#layout")
        exec g:nnn#layout
    endif

    if has("nvim")
        let l:on_exit = s:Create_on_exit_callback(l:opts)
        enew
        call termopen(l:cmd, {'on_exit': function(l:on_exit.Callback) })
        startinsert
    elseif has("gui_running")
        exec 'silent !xterm -e ' . l:cmd
        call s:evaluate_temp(l:opts)
    else
        exec 'silent !' . l:cmd
        call s:evaluate_temp(l:opts)
    endif
endfunction

command! -bar -nargs=? -complete=dir NnnPicker call NnnPicker(<f-args>)
command! -bar -nargs=? -complete=dir Np call NnnPicker(<f-args>)

if g:nnn#set_default_mappings
    nnoremap <leader>n :NnnPicker<CR>
endif
