let s:temp_file = ''
let s:action = ''
let s:tbuf = 0

let s:local_ses = 'nnn_vim_'
" Add timestamp for convenience
" :h strftime() -- strftime is not portable
if exists('*strftime')
    let s:local_ses .= strftime('%Y_%m_%dT%H_%M_%SZ')
else
    " HACK: cannot use / in a session name
    let s:local_ses .= substitute(tempname(), '/', '_', 'g')
endif

function! s:statusline()
    setlocal statusline=%#StatusLineTerm#\ nnn\ %#StatusLineTermNC#
endfunction

function! nnn#select_action(action) abort
    let s:action = a:action
    " quit nnn
    if has("nvim")
        call feedkeys("i\<cr>")
    else
        call term_sendkeys(s:tbuf, "\<cr>")
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

function! s:eval_temp_file(opts)
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
    redraw!
endfunction

function! s:popup(opts, term_opts)
    " Size and position
    let width = min([max([0, float2nr(&columns * a:opts.width)]), &columns])
    let height = min([max([0, float2nr(&lines * a:opts.height)]), &lines - has('nvim')])
    let row = float2nr(get(a:opts, 'yoffset', 0.5) * (&lines - height))
    let col = float2nr(get(a:opts, 'xoffset', 0.5) * (&columns - width))

    " Managing the differences
    let row = min([max([0, row]), &lines - has('nvim') - height])
    let col = min([max([0, col]), &columns - width])
    let row += !has('nvim')
    let col += !has('nvim')

    let l:border = get(a:opts, 'border', 'rounded')
    let l:highlight = get(a:opts, 'highlight', 'Comment')

    if has('nvim')
        let l:win = nvim_open_win(nvim_create_buf(v:false, v:true), v:true, {
                    \ 'row': row,
                    \ 'col': col,
                    \ 'width': width,
                    \ 'height': height,
                    \ 'border': l:border == 'rounded' ? 'rounded' : 'single',
                    \ 'relative': 'editor',
                    \ 'style': 'minimal'
                    \ })
        call setwinvar(l:win, '&winhighlight', 'NormalFloat:Normal')
        call setwinvar(l:win, '&colorcolumn', '')
        return { 'term': { 'buf': s:create_term_buf(a:term_opts), 'winhandle': l:win } }
    else
        let l:buf = s:create_term_buf(extend(a:term_opts, #{ curwin: 0, hidden: 1 }))
        let l:borderchars = l:.border == 'rounded' ? ['─', '│', '─', '│', '╭', '╮','╯' , '╰'] : ['─', '│', '─', '│', '┌', '┐', '┘', '└']
        let l:win = popup_create(l:buf, #{
                    \ line: row,
                    \ col: col,
                    \ minwidth: width,
                    \ minheight: height,
                    \ border: [],
                    \ borderhighlight: [l:highlight],
                    \ borderchars: l:borderchars,
                    \ })
        return #{ term: { buf: l:buf, winhandle: l:win } }
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

    let l:names = uniq(filter(l:file, '!isdirectory(v:val) && filereadable(v:val)'))
    if empty(l:names) || strlen(l:names[0]) <= 0
        return []
    endif

    return l:names
endfunction

function! s:switch_back(opts, Cmd)
    let l:buf = a:opts.ppos.buf
    let l:layout = a:opts.layout
    let l:term_wins = a:opts.term_wins

    " when split explorer
    if type(l:layout) == v:t_string && l:layout == 'enew' && bufexists(l:buf)
        try
            execute 'keepalt b' l:buf
        " in case nnn was used to delete file in open buffer
        catch /E211: File/
            let junk = input(matchstr(string(v:exception), 'E211: .*$') . "\nPress ENTER to continue")
        endtry
        if bufexists(l:term_wins.term.buf)
            execute 'bwipeout!' l:term_wins.term.buf
        endif
    endif

    if s:present(l:layout, 'window')
        if type(l:layout.window) != v:t_dict
            throw 'Invalid layout'
        endif
        if has('nvim')
            " Making sure we close the windows when sometimes they linger
            if nvim_win_is_valid(l:term_wins.term.winhandle)
                call nvim_win_close(l:term_wins.term.winhandle, v:false)
            endif

            if bufexists(l:term_wins.term.buf)
                execute 'bwipeout!' l:term_wins.term.buf
            endif
        else
            call popup_close(l:term_wins.term.winhandle)

            if bufexists(l:term_wins.term.buf)
                execute 'bwipeout!' l:term_wins.term.buf
            endif
        endif
    endif

    " don't switch when action = 'edit' and just retain the window
    " don't switch when layout = 'enew' for split explorer feature
    if (type(a:Cmd) == v:t_string && a:Cmd != 'edit')
                \ || (type(l:layout) != v:t_string
                \ || (type(l:layout) == v:t_string && l:layout != 'enew'))
        " delete the nnn window and buffer
        try
            if has('nvim')
                if nvim_win_is_valid(l:term_wins.term.winhandle)
                    call nvim_win_close(l:term_wins.term.winhandle, v:false)
                endif
            else
                execute win_id2win(l:term_wins.term.winhandle) . 'close'
            endif
        catch /E444: Cannot close last window/
            " In case Vim complains it is the last window, fail silently.
        endtry
        if bufexists(l:term_wins.term.buf)
            execute 'bwipeout!' l:term_wins.term.buf
        endif
        silent! execute 'tabnext' a:opts.ppos.tab
        silent! execute a:opts.ppos.win.'wincmd w'
    endif
endfunction

function! s:create_term_buf(opts)
    if has("nvim")
        call termopen([g:nnn#shell, &shellcmdflag, a:opts.cmd], {
                    \ 'env': { 'NNN_SEL': s:temp_file },
                    \ 'on_exit': a:opts.on_exit
                    \ })
        startinsert
        return bufnr('')
    else
        let l:curwin = get(a:opts, 'curwin', 1)
        let l:hidden = get(a:opts, 'hidden', 0)
        let l:Exit_cb = get(a:opts, 'on_exit')
        let l:tbuf = term_start([g:nnn#shell, &shellcmdflag, a:opts.cmd], {
                    \ 'env': { 'NNN_SEL': s:temp_file },
                    \ 'curwin': l:curwin,
                    \ 'hidden': l:hidden,
                    \ 'exit_cb': l:Exit_cb
                    \ })
        if !has('patch-8.0.1261') && !has('nvim')
            call term_wait(l:tbuf, 20)
        endif
        return l:tbuf
    endif
endfunction

let s:nnn_conf_dir = (!empty($XDG_CONFIG_HOME) ? $XDG_CONFIG_HOME : $HOME.'/.config') . '/nnn'

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
    if type(a:layout) == v:t_string
        execute 'keepalt ' . a:layout
        return { 'term': { 
                    \ 'buf': s:create_term_buf(a:term_opts),
                    \ 'winhandle': win_getid()
                    \ } }
    endif

    if s:present(a:layout, 'window')
        if type(a:layout.window) == v:t_dict
            if !has('nvim') && !has('patch-8.2.191')
                throw 'Neovim 0.5+ or Vim with patch-8.2.191+ is required for floating window'
            end
            return s:popup(a:layout.window, a:term_opts)
        else
            throw 'Invalid layout'
        endif
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
            return { 'term': { 
                        \ 'buf': s:create_term_buf(a:term_opts),
                        \ 'winhandle': win_getid()
                        \ } }
        endif
    endfor

    throw 'Invalid layout'
endfunction


function! nnn#pick(...) abort
    let l:directory = get(a:, 1, '')
    let l:default_opts = { 'edit': 'edit' }
    let l:opts = extend(l:default_opts, get(a:, 2, {}))
    let s:temp_file = tempname()

    if g:nnn#session ==# 'none' || !get(l:opts, 'session', 1)
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
    let l:opts.ppos = { 'buf': bufnr(''), 'win': winnr(), 'tab': tabpagenr() }
    let l:On_exit = s:create_on_exit_callback(l:opts)

    let l:opts.term_wins = s:build_window(l:layout, { 'cmd': l:cmd, 'on_exit': l:On_exit })
    let s:tbuf = l:opts.term_wins.term.buf
    setfiletype nnn
    if g:nnn#statusline && type(l:layout) == v:t_string
        call s:statusline()
    endif
endfunction

" vim: set sts=4 sw=4 ts=4 et :
