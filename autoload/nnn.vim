let s:temp_file = ""
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

        call s:eval_temp_file(l:opts)
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
    if type(a:layout) == v:t_string
        return 'keepalt ' . a:layout
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

function! s:switch_back(opts, Cmd)
    let l:buf = a:opts.ppos.buf
    let l:layout = a:opts.layout
    let l:tbuf = a:opts.tbuf

    " when split explorer
    if type(l:layout) == v:t_string && l:layout == 'enew' && bufexists(l:buf)
        execute 'keepalt b' l:buf
        if bufexists(l:tbuf)
            execute 'bdelete!' l:tbuf
        endif
    endif

    " don't switch when action = 'edit' and just retain the window
    " don't switch when layout = 'enew' for split explorer feature
    if (type(a:Cmd) == v:t_string && a:Cmd != 'edit')
                \ || (type(l:layout) != v:t_string
                \ || (type(l:layout) == v:t_string && l:layout != 'enew'))
        if bufexists(l:tbuf)
            execute 'bdelete!' l:tbuf
        endif
        execute 'tabnext' a:opts.ppos.tab
        execute a:opts.ppos.win.'wincmd w'
    endif
endfunction

function! s:extract_filenames()
    if !filereadable(s:temp_file)
        return []
    endif

    let l:file = readfile(s:temp_file)
    if empty(l:file)
        return []
    endif

    let l:names = uniq(filter(split(l:file[0], "\\n"), '!isdirectory(v:val) && filereadable(v:val)'))
    if empty(l:names) || strlen(l:names[0]) <= 0
        return []
    endif

    return l:names
endfunction

function! s:eval_temp_file(opts) abort
    let l:tbuf = a:opts.tbuf
    let l:Cmd = type(s:action) == v:t_func || strlen(s:action) > 0 ? s:action : a:opts.edit

    call s:switch_back(a:opts, l:Cmd)

    let l:names = s:extract_filenames()
    " When exiting without any selection
    if empty(l:names)
        return
    endif

    " Action passed is function
    if (type(l:Cmd) == 2)
        call l:Cmd(l:names)
    else
        " Edit the first item.
        execute 'silent' l:Cmd fnameescape(l:names[0])
        " Add any remaining items to the arg list/buffer list.
        for l:name in l:names[1:]
            execute 'silent argadd' fnameescape(l:name)
        endfor
    endif

    let s:action = "" " reset action

    if bufexists(l:tbuf)
        execute 'bdelete!' l:tbuf
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
    let s:temp_file = tempname()
    let l:cmd = g:nnn#command.' -p '.shellescape(s:temp_file).' '.expand(l:directory)
    let l:layout = exists('l:opts.layout') ? l:opts.layout : g:nnn#layout

    let l:opts.layout = l:layout
    let l:opts.ppos = { 'buf': bufnr(''), 'win': winnr(), 'tab': tabpagenr() }
    execute s:eval_layout(l:layout)

    let l:On_exit = s:create_on_exit_callback(l:opts)

    if has("nvim")
        call termopen(l:cmd, {'on_exit': function(l:On_exit) })
        let l:opts.tbuf = bufnr('')
        startinsert
    else
        let s:term_buff = term_start([&shell, &shellcmdflag, l:cmd], {'curwin': 1, 'exit_cb': function(l:On_exit)})
        let l:opts.tbuf = s:term_buff
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
