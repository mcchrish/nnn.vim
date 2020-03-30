let s:temp_file = ""
let s:action = ""
let s:tbuf = 0
let s:temp_popup_tbuf = -1
let s:temp_popup_frame_buf = -1
let s:win_id = -1
let s:win_frame_id = -1

function! nnn#select_action(action)
    let s:action = a:action
    " quit nnn
    if has("nvim")
        call feedkeys("i\<cr>")
    else
        call term_sendkeys(s:tbuf, "\<cr>")
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

if has('nvim')
    function s:create_popup(hl, opts) abort
        let buf = nvim_create_buf(v:false, v:true)
        let opts = extend({'relative': 'editor', 'style': 'minimal'}, a:opts)
        let border = has_key(opts, 'border') ? remove(opts, 'border') : []
        let win = nvim_open_win(buf, v:true, opts)
        call setwinvar(win, '&winhighlight', 'NormalFloat:'..a:hl)
        call setwinvar(win, '&colorcolumn', '')
        if !empty(border)
            call nvim_buf_set_lines(buf, 0, -1, v:true, border)
        endif
        return buf
    endfunction
else
    function! s:create_popup(hl, opts) abort
        let is_frame = has_key(a:opts, 'border')
        let buf = is_frame ? '' : term_start([&shell, &shellcmdflag], #{hidden: 1, term_finish: 'close'})
        let id = popup_create(buf, #{
                    \ line: a:opts.row,
                    \ col: a:opts.col,
                    \ minwidth: a:opts.width,
                    \ minheight: a:opts.height,
                    \ zindex: 50 - is_frame,
                    \ })

        if is_frame
            call setwinvar(id, '&wincolor', a:hl)
            call setbufline(winbufnr(id), 1, a:opts.border)
            let s:win_id = id
            let s:temp_popup_tbuf = buf
        else
            let s:win_frame_id = id
            let s:temp_popup_frame_buf = buf
        endif
        return winbufnr(id)
    endfunction
endif

function! s:popup(opts) abort
    " Support ambiwidth == 'double'
    let ambidouble = &ambiwidth == 'double' ? 2 : 1

    " Size and position
    let width = min([max([0, float2nr(&columns * a:opts.width)]), &columns])
    let width += width % ambidouble
    let height = min([max([0, float2nr(&lines * a:opts.height)]), &lines - has('nvim')])
    let row = float2nr(get(a:opts, 'yoffset', 0.5) * (&lines - height))
    let col = float2nr(get(a:opts, 'xoffset', 0.5) * (&columns - width))

    " Managing the differences
    let row = min([max([0, row]), &lines - has('nvim') - height])
    let col = min([max([0, col]), &columns - width])
    let row += !has('nvim')
    let col += !has('nvim')

    " Border style
    let style = tolower(get(a:opts, 'border', 'rounded'))
    if !has_key(a:opts, 'border') && !get(a:opts, 'rounded', 1)
        let style = 'sharp'
    endif

    if style =~ 'vertical\|left\|right'
        let mid = style == 'vertical' ? '│' .. repeat(' ', width - 2 * ambidouble) .. '│' :
                    \ style == 'left'     ? '│' .. repeat(' ', width - 1 * ambidouble)
                    \                     :        repeat(' ', width - 1 * ambidouble) .. '│'
        let border = repeat([mid], height)
        let shift = { 'row': 0, 'col': style == 'right' ? 0 : 2, 'width': style == 'vertical' ? -4 : -2, 'height': 0 }
    elseif style =~ 'horizontal\|top\|bottom'
        let hor = repeat('─', width / ambidouble)
        let mid = repeat(' ', width)
        let border = style == 'horizontal' ? [hor] + repeat([mid], height - 2) + [hor] :
                    \ style == 'top'        ? [hor] + repeat([mid], height - 1)
                    \                       :         repeat([mid], height - 1) + [hor]
        let shift = { 'row': style == 'bottom' ? 0 : 1, 'col': 0, 'width': 0, 'height': style == 'horizontal' ? -2 : -1 }
    else
        let edges = style == 'sharp' ? ['┌', '┐', '└', '┘'] : ['╭', '╮', '╰', '╯']
        let bar = repeat('─', width / ambidouble - 2)
        let top = edges[0] .. bar .. edges[1]
        let mid = '│' .. repeat(' ', width - 2 * ambidouble) .. '│'
        let bot = edges[2] .. bar .. edges[3]
        let border = [top] + repeat([mid], height - 2) + [bot]
        let shift = { 'row': 1, 'col': 2, 'width': -4, 'height': -2 }
    endif

    let highlight = get(a:opts, 'highlight', 'Comment')
    let frame = s:create_popup(highlight, {
                \ 'row': row, 'col': col, 'width': width, 'height': height, 'border': border
                \ })
    call s:create_popup('Normal', {
                \ 'row': row + shift.row, 'col': col + shift.col, 'width': width + shift.width, 'height': height + shift.height
                \ })
    if has('nvim')
        execute 'autocmd BufWipeout <buffer> bwipeout '..frame
    endif
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

    if s:present(a:layout, 'window')
        if type(a:layout.window) == type({})
            if !has('nvim') && !has('patch-8.2.191')
                throw 'Neovim is required for floating window or Vim with patch-8.2.191'
            end
            call s:popup(a:layout.window)
            " Since we already created the floating window, we don't need to run any
            " command
            return
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

    if type(l:layout) == type({}) && type(l:layout.window) == type({}) && !has('nvim')
        call popup_close(s:win_id)
        call popup_close(s:win_frame_id)
        if bufexists(l:tbuf)
            execute 'bdelete!' l:tbuf
        endif
        if bufexists(s:temp_popup_tbuf)
            execute 'bdelete!' s:temp_popup_tbuf
        endif
        if bufexists(s:temp_popup_frame_buf)
            execute 'bdelete!' s:temp_popup_frame_buf
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
        silent! execute 'tabnext' a:opts.ppos.tab
        silent! execute a:opts.ppos.win.'wincmd w'
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
        let s:tbuf = term_start([&shell, &shellcmdflag, l:cmd], {'curwin': 1, 'exit_cb': function(l:On_exit)})
        let l:opts.tbuf = s:tbuf
        if !has('patch-8.0.1261') && !has('nvim')
            call term_wait(s:tbuf, 20)
        endif
    endif
    setf nnn
    if g:nnn#statusline
        call s:statusline()
    endif
endfunction

" vim: set sts=4 sw=4 ts=4 et :
