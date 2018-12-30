let s:temp = ""
let s:action = ""
let s:term_buff = 0

fun! nnn#select_action(action)
    let s:action = a:action
    " quit nnn
    if has("nvim")
        call feedkeys("i\<cr>")
    else
        call term_sendkeys(s:term_buff, "\<cr>")
    endif
endfun

fun! s:create_on_exit_callback(opts)
    let l:opts = a:opts
    fun! s:callback(id, code, ...) closure
        if a:code != 0
            echohl ErrorMsg | echo 'nnn exited with '.a:code | echohl None
            return
        endif

        bdelete!
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

fun! s:eval_temp(opts) abort
    if !filereadable(s:temp)
        " When exiting without any selection
        redraw!
        " Nothing to read.
        return
    endif

    let l:file = readfile(s:temp)
    if empty(l:file)
        redraw!
        " Nothing to open.
        return
    endif

    let l:names = filter(split(l:file[0], "\\n"), '!isdirectory(v:val)')
    if empty(l:names)
        redraw!
        " Nothing to open.
        return
    endif

    " Edit the first item.
    let l:cmd = strlen(s:action) > 0 ? s:action : a:opts.edit
    exec l:cmd . ' ' . fnameescape(l:names[0])
    " Add any remaining items to the arg list/buffer list.
    for l:name in l:names[1:]
        exec 'argadd ' . fnameescape(l:name)
    endfor
    let s:action = "" " reset action
    redraw!
endfun

fun! nnn#pick(...) abort
    let l:directory = expand(get(a:, 1, ""))
    let l:default_opts = { 'edit': 'edit' }
    let l:opts = extend(l:default_opts, get(a:, 2, {}))
    let s:temp = tempname()
    let l:cmd = g:nnn#command.' -p '.shellescape(s:temp).' '.expand(l:directory)
    let l:layout = exists('l:opts.layout') ? l:opts.layout : g:nnn#layout

    exec s:eval_layout(l:layout)

    let l:On_exit = s:create_on_exit_callback(l:opts)

    if has("nvim")
        call termopen(l:cmd, {'on_exit': function(l:On_exit) })
        startinsert
    else
        let s:term_buff = term_start([&shell, &shellcmdflag, l:cmd], {'curwin': 1, 'exit_cb': function(l:On_exit)})
        if !has('patch-8.0.1261') && !has('nvim')
            call term_wait(s:term_buff, 20)
        endif
    endif
    setf nnn
endfun

" vim: set sts=4 sw=4 ts=4 et :
