" vim/neovim plugin to use nnn as a file picker
" Closely follows and inspired by the vim_file_chooser plugin for ranger and
" some from fzf.vim.
"
" Author: Arun Prakash Jana
" Email: engineerarun@gmail.com
" Homepage: https://github.com/jarun/nnn
" Copyright © 2018 Arun Prakash Jana

let s:temp = ""

if !(exists("g:nnn#set_default_mappings"))
    let g:nnn#set_default_mappings = 1
endif

if !(exists("g:nnn#layout"))
    let g:nnn#layout = 'enew'
endif

fun! s:create_on_exit_callback(opts)
    let l:opts = a:opts
    fun! s:callback(id, code, ...) closure
        if a:code != 0
            echoerr 'nnn exited with non-zero.'
            return
        endif

        bd!
        call s:eval_temp(l:opts)
    endfun
    return function('s:callback')
endfun

function! s:present(dict, ...)
    for key in a:000
        if !empty(get(a:dict, key, ''))
            return 1
        endif
    endfor
    return 0
endfunction

fun! s:calc_size(val, max)
    let l:val = substitute(a:val, '^\~', '', '')
    if val =~ '%$'
        return a:max * str2nr(val[:-2]) / 100
    else
        return min([a:max, str2nr(val)])
    endif
endfun

fun! s:eval_layout(layout)
    if type(a:layout) == 1
        return a:layout
    endif

    let l:directions = {
        \ 'up':    ['topleft', 'resize', &lines],
        \ 'down':  ['botright', 'resize', &lines],
        \ 'left':  ['vertical topleft', 'vertical resize', &columns],
        \ 'right': ['vertical botright', 'vertical resize', &columns] }

    for key in ['up', 'down', 'left', 'right']
        if s:present(a:layout, key)
            let l:size = a:layout[key]
            let [l:cmd, l:resz, l:max]= l:directions[key]
            return l:cmd . s:calc_size(l:size, l:max) . 'new'
        endif
    endfor
    throw 'Invalid layout'
endfun

fun! s:eval_temp(opts)
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

fun! NnnPicker(...) abort
    let l:directory = expand(get(a:, 1, ""))
    let l:default_opts = { 'edit': 'edit' }
    let l:opts = extend(l:default_opts, get(a:, 2, {}))
    let s:temp = tempname()
    let l:cmd = 'nnn -p ' . shellescape(s:temp) . ' ' . l:directory
    let l:layout = exists('l:opts.layout') ? l:opts.layout : g:nnn#layout

    exec s:eval_layout(l:layout)

    let l:On_exit = s:create_on_exit_callback(l:opts)

    if has("nvim")
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
endfun

command! -bar -nargs=? -complete=dir NnnPicker call NnnPicker(<f-args>)
command! -bar -nargs=? -complete=dir Np call NnnPicker(<f-args>)

if g:nnn#set_default_mappings
    nnoremap <silent> <leader>n :NnnPicker<CR>
endif

" vim: set sts=4 sw=4 ts=4 et :
