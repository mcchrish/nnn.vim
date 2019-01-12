let s:temp = ""
let s:action = ""
let s:term_buff = 0

function! nnn#select_action(action)
    let s:action = a:action
    " quit nnn
    if has("nvim")
        call feedkeys("i\<cr>")
    else
        call term_sendkeys(s:term_buff, "\<cr>")
    endif
endfunction

function! s:create_on_exit_callback(opts)
    let l:opts = a:opts
    function! s:callback(id, code, ...) closure
        if a:code != 0
            echohl ErrorMsg | echo 'nnn exited with '.a:code | echohl None
            return
        endif

        call s:eval_temp(l:opts)
    endfunction
    return function('s:callback')
endfunction

function! s:present(dict, ...)
    for key in a:000
        if !empty(get(a:dict, key, ''))
            return 1
        endif
    endfor
    return 0
endfunction

function! s:calc_size(val, max)
    let l:val = substitute(a:val, '^\~', '', '')
    if val =~ '%$'
        return a:max * str2nr(val[:-2]) / 100
    else
        return min([a:max, str2nr(val)])
    endif
endfunction

function! s:eval_layout(layout)
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
endfunction

function! s:switch_back(opts)
    let l:buf = a:opts.ppos.buf
    let l:layout = a:opts.layout
    let l:tbuf = bufnr('')
    if type(l:layout) != 1 || (type(l:layout) == 1 && l:layout != 'enew')
        execute 'tabnext' a:opts.ppos.tab
        execute a:opts.ppos.win.'wincmd w'
    elseif l:layout == 'enew' && bufexists(l:buf)
        execute 'keepalt b' l:buf
    endif
    if bufexists(l:tbuf)
        execute 'bdelete! '.l:tbuf
    endif
endfunction

function! s:eval_temp(opts) abort
    let l:buf = a:opts.ppos.buf
    let l:layout = a:opts.layout
    " When exiting without any selection
    if !filereadable(s:temp)
        call s:switch_back(a:opts)
        return
    endif

    let l:file = readfile(s:temp)
    if empty(l:file)
        call s:switch_back(a:opts)
        return
    endif

    let l:names = filter(split(l:file[0], "\\n"), '!isdirectory(v:val)')
    if empty(l:names) || strlen(l:names[0]) <= 0
        call s:switch_back(a:opts)
        return
    endif

    let l:tbuf = bufnr('')
    if type(l:layout) != 1 || (type(l:layout) == 1 && l:layout != 'enew')
        " Close the term window first before moving to the prev window
        execute 'bdelete! '.l:tbuf
    endif
    execute 'tabnext' a:opts.ppos.tab
    execute a:opts.ppos.win.'wincmd w'

    " Edit the first item.
    let l:cmd = strlen(s:action) > 0 ? s:action : a:opts.edit
    execute l:cmd . ' ' . fnameescape(l:names[0])
    " Add any remaining items to the arg list/buffer list.
    for l:name in l:names[1:]
        execute 'argadd ' . fnameescape(l:name)
    endfor
    let s:action = "" " reset action

    if bufexists(l:tbuf)
        execute 'bdelete! '.l:tbuf
    endif
    redraw!
endfunction

function! s:statusline()
    setlocal statusline=%#StatusLineTerm#\ nnn\ %#StatusLineTermNC#
endfunction

function! nnn#pick(...) abort
    let l:directory = expand(get(a:, 1, ""))
    let l:default_opts = { 'edit': 'edit' }
    let l:opts = extend(l:default_opts, get(a:, 2, {}))
    let s:temp = tempname()
    let l:cmd = g:nnn#command.' -p '.shellescape(s:temp).' '.expand(l:directory)
    let l:layout = exists('l:opts.layout') ? l:opts.layout : g:nnn#layout

    let l:opts.layout = l:layout
    let l:opts.ppos = { 'buf': bufnr(''), 'win': winnr(), 'tab': tabpagenr() }
    execute s:eval_layout(l:layout)

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
    if g:nnn#statusline
        call s:statusline()
    endif
endfunction

" vim: set sts=4 sw=4 ts=4 et :
