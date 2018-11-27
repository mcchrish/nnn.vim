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

fun! s:create_on_exit_callback(opts)
    let l:opts = a:opts
    fun! s:callback(id, code, ...) closure
        if a:code != 0
            echoerr 'nnn exited with non-zero.'
            return
        endif

        bd!
        call s:evaluate_temp(l:opts)
    endfun
    return function('s:callback')
endfun

fun! s:evaluate_temp(opts)
    if !filereadable(s:temp)
        " When exiting without any selection
        redraw!
        " Nothing to read.
        return
    endif
    let l:names = filter(readfile(s:temp), '!isdirectory(v:val)')
    if empty(l:names)
        redraw!
        " Nothing to open.
        return
    endif
    " Edit the first item.
    exec a:opts.edit . ' ' . fnameescape(l:names[0])
    " Add any remaining items to the arg list/buffer list.
    for l:name in l:names[1:]
        exec 'argadd ' . fnameescape(l:name)
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

    let l:On_exit = s:create_on_exit_callback(l:opts)

    if has("nvim")
        enew
        call termopen(l:cmd, {'on_exit': function(l:On_exit) })
        startinsert
    else
        let l:term_buff = term_start([&shell, &shellcmdflag, l:cmd], {'curwin': 1, 'exit_cb': function(l:On_exit)})
        if !has('patch-8.0.1261') && !has('nvim')
            call term_wait(l:term_buff, 20)
        endif
    endif

    setlocal nospell bufhidden=wipe nobuflisted nonumber
    setf nnn
endfunction

command! -bar -nargs=? -complete=dir NnnPicker call NnnPicker(<f-args>)
command! -bar -nargs=? -complete=dir Np call NnnPicker(<f-args>)

if g:nnn#set_default_mappings
    nnoremap <silent> <leader>n :NnnPicker<CR>
endif
