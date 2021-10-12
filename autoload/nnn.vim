let s:temp_file = ''
let s:action = ''
let s:nnn_conf_dir = (!empty($XDG_CONFIG_HOME) ? $XDG_CONFIG_HOME : $HOME.'/.config') . '/nnn'

let s:local_ses = 'nnn_vim_'
" Add timestamp for convenience
" :h strftime() -- strftime is not portable
if exists('*strftime')
    let s:local_ses .= strftime('%Y_%m_%dT%H_%M_%SZ')
else
    " HACK: cannot use / in a session name
    let s:local_ses .= substitute(tempname(), '/', '_', 'g')
endif

" nnn highlight groups
if hlexists('FloatBorder')
    highlight default link NnnBorder FloatBorder
else
    highlight default link NnnBorder Comment
endif
highlight default link NnnNormal Normal

function! s:statusline()
    setlocal statusline=%#StatusLineTerm#\ nnn\ %#StatusLineTermNC#
endfunction

function! nnn#select_action(key) abort
    let s:action = g:nnn#action[a:key]
    " quit nnn
    if has('nvim')
        call feedkeys("i\<cr>")
    else
        call term_sendkeys(b:tbuf, "\<cr>")
    endif
endfunction

function! s:present(dict, ...)
    if type(a:dict) != v:t_dict
        return 0
    endif
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

function! s:extra_selections()
    if !filereadable(s:temp_file)
        return []
    endif

    let l:files = readfile(s:temp_file)
    if empty(l:files)
        return []
    endif

    call uniq(l:files)

    if empty(l:files) || strlen(l:files[0]) <= 0
        return []
    endif

    return l:files
endfunction

function! s:eval_temp_file(opts)
    let l:Cmd = type(s:action) == v:t_func || strlen(s:action) > 0 ? s:action : a:opts.edit

    call s:switch_back(a:opts, l:Cmd)

    let l:names = s:extra_selections()
    " When exiting without any selection
    if empty(l:names)
        return
    endif

    " Action passed is function
    if (type(l:Cmd) == v:t_func)
        call l:Cmd(l:names)
    else
        " Remove directories and missing files
        call filter(l:names, {_, val -> !isdirectory(val) && filereadable(val) })
        " Consider trimming out current working directory from filename
        let l:cwd = getcwd()
        call map(l:names, { _, val -> strcharpart(val, 0, strlen(l:cwd)) ==# l:cwd  ? strcharpart(val, strlen(l:cwd) + 1) : val }) " + 1 is to also remove the trailing slash
        call reverse(l:names)
        " Edit the first item.
        execute 'silent' l:Cmd fnameescape(l:names[0])
        " Add any remaining items to the arg list/buffer list.
        for l:name in l:names[1:]
            execute 'silent argadd' fnameescape(l:name)
        endfor
    endif

    let s:action = '' " reset action
    redraw!
endfunction

function! s:popup(opts, term_opts)
    " Size and position
    let width = min([max([0, float2nr(&columns * a:opts.width)]), &columns])
    let height = min([max([0, float2nr(&lines * a:opts.height)]), &lines - has('nvim')])
    let yoffset = get(a:opts, 'yoffset', 0.5)
    let xoffset = get(a:opts, 'xoffset', 0.5)
    let row = float2nr(yoffset * (&lines - height))
    let col = float2nr(xoffset * (&columns - width))

    " Managing the differences
    let row = min([max([0, row]), &lines - has('nvim') - height])
    let col = min([max([0, col]), &columns - width])
    let row += !has('nvim')
    let col += !has('nvim')

    let l:border = get(a:opts, 'border', 'rounded')
    let l:highlight = get(a:opts, 'highlight', 'NnnBorder')

    if has('nvim')
        let l:borderchars = l:border ==# 'none' ? 'none' : map(l:border ==# 'rounded'
                    \ ? ['╭', '─' ,'╮', '│', '╯', '─', '╰', '│' ]
                    \ : ['┌', '─' ,'┐', '│', '┘', '─', '└', '│' ], 
                    \ {_, val -> [v:val, l:highlight]})

        let l:win = nvim_open_win(nvim_create_buf(v:false, v:true), v:true, {
                    \ 'row': row,
                    \ 'col': col,
                    \ 'width': width,
                    \ 'height': height,
                    \ 'border': l:borderchars,
                    \ 'relative': 'editor',
                    \ 'style': 'minimal'
                    \ })
        call setwinvar(l:win, '&winhighlight', 'NormalFloat:NnnNormal')
        return { 'buf': s:create_term_buf(a:term_opts), 'winhandle': l:win }
    else
        let l:buf = s:create_term_buf(extend(a:term_opts, #{ curwin: 0, hidden: 1 }))
        let l:borderchars = l:border ==# 'rounded'
                    \ ? ['─', '│', '─', '│', '╭', '╮','╯' , '╰']
                    \ : ['─', '│', '─', '│', '┌', '┐', '┘', '└']
        let l:win = popup_create(l:buf, #{
                    \ line: row,
                    \ col: col,
                    \ minwidth: width,
                    \ minheight: height,
                    \ highlight: 'NnnNormal',
                    \ border: l:border ==# 'none' ? [0, 0, 0, 0] : [],
                    \ borderhighlight: [l:highlight],
                    \ borderchars: l:borderchars,
                    \ })
        return #{ buf: l:buf, winhandle: l:win }
    endif
endfunction

function! s:switch_back(opts, cmd)
    let l:buf = a:opts.ppos.buf
    let l:layout = a:opts.layout
    let l:term = a:opts.term

    " when split explorer
    if type(l:layout) == v:t_string && l:layout ==# 'enew' && bufexists(l:buf)
        execute 'keepalt b' l:buf
    elseif s:present(l:layout, 'window')
        if type(l:layout.window) != v:t_dict
            throw 'Invalid layout'
        endif
        " Making sure we close the windows when sometimes they linger
        if has('nvim') && nvim_win_is_valid(l:term.winhandle)
            call nvim_win_close(l:term.winhandle, v:false)
        else
            call popup_close(l:term.winhandle)
        endif
    endif

    " don't switch when action = 'edit' and just retain the window
    " don't switch when layout = 'enew' for split explorer feature
    if (type(a:cmd) == v:t_string && a:cmd !=# 'edit')
                \ || (type(l:layout) != v:t_string || (type(l:layout) == v:t_string && l:layout !=# 'enew'))
        call win_gotoid(a:opts.ppos.winid)
    endif

    if bufexists(l:term.buf)
        execute 'bwipeout!' l:term.buf
    endif
endfunction

function! s:create_term_buf(opts)
    let l:shell = get(g:, 'nnn#shell', &shell)
    if has('nvim')
        call termopen([l:shell, &shellcmdflag, a:opts.cmd], {
                    \ 'env': { 'NNN_SEL': s:temp_file },
                    \ 'on_exit': a:opts.on_exit
                    \ })
        startinsert
        return bufnr('')
    else
        return term_start([l:shell, &shellcmdflag, a:opts.cmd], {
                    \ 'curwin': get(a:opts, 'curwin', 1),
                    \ 'hidden': get(a:opts, 'hidden', 0),
                    \ 'env': { 'NNN_SEL': s:temp_file },
                    \ 'exit_cb': a:opts.on_exit
                    \ })
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

        let fname = s:nnn_conf_dir.'/.lastd'
        if !empty(glob(fname))
            let firstline = readfile(fname)[0]
            let lastd = split(firstline, '"')[1]
            execute 'cd' fnameescape(lastd)
            call delete(fnameescape(fname))
        endif
    endfunction
    return function('s:callback')
endfunction

function! s:build_window(layout, term_opts)
    if s:present(a:layout, 'window')
        if type(a:layout.window) == v:t_dict
            if !g:nnn#has_floating_window_support
                throw 'Your vim/neovim version does not support popup/floating window.'
            endif
            return s:popup(a:layout.window, a:term_opts)
        else
            throw 'Invalid layout'
        endif
    endif

    if type(a:layout) == v:t_string
        execute 'keepalt' a:layout
        return { 'buf': s:create_term_buf(a:term_opts), 'winhandle': win_getid() }
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
            execute l:cmd . s:calc_size(l:size, l:max) . 'new'
            return { 'buf': s:create_term_buf(a:term_opts), 'winhandle': win_getid() }
        endif
    endfor

    throw 'Invalid layout'
endfunction

function! nnn#pick(...) abort
    let l:directory = get(a:, 1, '')
    let l:default_opts = { 'edit': 'edit' }
    let l:opts = extend(l:default_opts, get(a:, 2, {}))
    let s:temp_file = tempname()

    if g:nnn#session ==# 'none' || get(l:opts, 'session', 0)
        let l:sess_cfg = ' '
    elseif g:nnn#session ==# 'global'
        let l:sess_cfg = ' -S '
    elseif g:nnn#session ==# 'local'
        let l:sess_cfg = ' -S -s '.s:local_ses.' '
        let session_file = s:nnn_conf_dir.'/sessions/'.s:local_ses
        execute 'augroup NnnSession | autocmd! VimLeavePre * call delete(fnameescape("'.session_file.'")) | augroup End'
    else
        let l:sess_cfg = ' '
    endif

    let l:cmd = g:nnn#command.l:sess_cfg.' -p '.shellescape(s:temp_file).' '.(l:directory != '' ? shellescape(l:directory): '')
    let l:layout = exists('l:opts.layout') ? l:opts.layout : g:nnn#layout

    let l:opts.layout = l:layout
    let l:opts.ppos = { 'buf': bufnr(''), 'winid': win_getid() }

    let l:opts.term = s:build_window(l:layout, { 'cmd': l:cmd, 'on_exit': s:create_on_exit_callback(l:opts) })
    let b:tbuf = l:opts.term.buf
    setfiletype nnn
    if g:nnn#statusline && !s:present(l:layout, 'window')
        call s:statusline()
    endif
endfunction

" vim: set sts=4 sw=4 ts=4 et :
