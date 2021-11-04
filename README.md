# nnn.vim

File manager for vim/neovim powered by n³.

https://user-images.githubusercontent.com/7200153/127453278-3e638e33-707a-49c8-b34e-225c225906b1.mov

<p align="center">
  <small>colorscheme <a href="https://github.com/pgdouyon/vim-yin-yang">yin</a></small>
</p>

## Requirements

1. n³
2. `has('nvim') || has('terminal')` i.e. terminal support
3. Optional `has('nvim-0.5') || has('popupwin')` for floating window
4. Optional n³ v4.3(+) needed for file-explorer mode

## Install

Install n³. Instructions
[here](https://github.com/jarun/nnn/wiki/Usage#installation).

Install the plugin using the built-in package manager:

Vim:

```bash
git clone --depth 1 https://github.com/mcchrish/nnn.vim\
 ~/.vim/pack/nnn/start/nnn.vim
```

Neovim:

```bash
git clone --depth 1 https://github.com/mcchrish/nnn.vim\
 "${XDG_DATA_HOME:-~/.local/share}"/nvim/site/pack/nnn/start/nnn.vim
```

Or install the plugin using other plugin manager:

```vim
" using vim-plug
Plug 'mcchrish/nnn.vim'
```

## Usage

### Picker

To open n³ as a file picker in vim/neovim, use the command `:NnnPicker` or the
key-binding `<leader>n`. The command accepts an optional path to open e.g.
`:NnnPicker path/to/somewhere`.

Run the plugin,
[select file(s)](https://github.com/jarun/nnn/wiki/concepts#selection) and press
<kbd>Enter</kbd> to quit the n³ window. Now vim will open the first selected
file and add the remaining files to the arg list/buffer list.

Pressing <kbd>Enter</kbd> on a file in n³ will pick any earlier selection (or
the hovered file if no selection exists) and exit n³.

### Explorer

To open n³ as a file-explorer use the command `:NnnExplorer`. The command
accepts optional path similar to `:NnnPicker`. In explorer mode pressing
<kbd>Enter</kbd> will pick a file but keep the n³ window open. Running
`:NnnExplorer` while an explorer window is active on that tab will toggle/close
it.

**NOTE**: In order to use explorer mode n³ version 4.3 (or above) must be
installed.

---

**NOTE**: Pressing <kbd>l</kbd> or <kbd>Right</kbd> on a file would open it
instead of picking. Use `-o` via [nnn#command](#command-override) to disable
this.

To discard selection and/or exit, press <kbd>q</kbd>.

#### `cd` on quit

Press <kbd>c-g</kbd> to quit n³ and `cd` into the last directory.

`set hidden` may be required for the floating windows to work.

For complete plugin documentation see `:help nnn`.

## Configuration

### Custom mappings

```vim
" Disable default mappings
let g:nnn#set_default_mappings = 0

" Set custom mappings
nnoremap <silent> <leader>nn :NnnPicker<CR>

" Start n³ in the current file's directory
nnoremap <leader>n :NnnPicker %:p:h<CR>
```

### Layout

```vim
" Opens the n³ window in a split
let g:nnn#layout = 'new' " or vnew, tabnew etc.

" Or pass a dictionary with window size
let g:nnn#layout = { 'left': '~20%' } " or right, up, down

" Floating window. This is the default
let g:nnn#layout = { 'window': { 'width': 0.9, 'height': 0.6, 'highlight': 'Comment' } }
```

`g:nnn#explorer_layout` is same as `g:nnn#layout` but for the explorer mode.

### Action

It's possible to set extra key-bindings for opening files in various ways. No
default is set so that n³'s key-bindings are not overridden.

```vim
let g:nnn#action = {
      \ '<c-t>': 'tab split',
      \ '<c-s>': 'split',
      \ '<c-v>': 'vsplit' }
```

With the above example, when inside an n³ window, pressing <kbd>^T</kbd> will
open the selected file in a tab instead of the current window. <kbd>^X</kbd>
will open in a split an so on. Multi-selected files will be loaded in the buffer
list.

An example assigning a function to an action:

```vim
function! CdSelectedFile(lines)
    let dir = a:lines[-1]
    if filereadable(dir)
        let dir = fnamemodify(dir, ':h')
    endif
    execute 'cd' dir
endfunction

let g:nnn#action = { '<c-w>': function('CdSelectedFile') }
```

In this example, pressing <kbd>c-w</kbd> will select the file and `cd` into its
directory.

### Persistent session

n³ sessions can be used to remember the location when it is reopened.

```vim
" use the same n³ session within a vim session
let g:nnn#session = 'local'

" use the same n³ session everywhere (including outside vim)
let g:nnn#session = 'global'
```

**NOTE**: If desired, an n³ session can be disabled temporarily by passing
`session: 0` as an option to `nnn#pick()`.

### Command override

It's possible to override the default n³ command and add some extra program
options.

```vim
" to start n³ in detail mode:
let g:nnn#command = 'nnn -d'

" OR, to pass env variables
let g:nnn#command = 'NNN_TRASH=1 nnn -d'
```

### `nnn#pick()` and `nnn#explorer()`

The `nnn#pick([<dir>][,<opts>])` and `nnn#explorer([<dir>][,<opts>])` functions
can be called with a custom directory and additional options such as opening
file in splits or tabs. They are more configurable versions of the `:NnnPicker`
and `:NnnExplorer` commands.

```vim
call nnn#pick('~/some-directory', { 'edit': 'vertical split' })
" Then add custom mappings
```

`opts` can be:

-   `edit` - type of window the select file will be open.
-   `layout` - same as `g:nnn#layout` and overrides it if specified.

### Environment variables

n³ will detect env variables defined in `vimrc`.

```vim
let $NNN_TRASH=1
```

### Explorer FAQ

-   How to auto start explorer when vim opens?

```vim
" Start NnnExplorer and leave the cursor in it.
autocmd VimEnter * call nnn#explorer()

" Start NnnExplorer and put the cursor back in the other window.
autocmd VimEnter * call nnn#explorer() | wincmd p | stopinsert

" If a file is specified, start NnnExplorer and move the cursor to the file window.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() > 0 || exists("s:std_in") | call nnn#explorer() | wincmd p | stopinsert | endif
```

-   How to auto close vim when explorer is the last window remaining?

```vim
" Exit Vim if NnnExplorer is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && &filetype ==# 'nnn' | quit! | endif

" Close the tab if NnnExplorer is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && &filetype ==# 'nnn' | quit! | endif
```

### Setup for `init.lua`

Use the same option names as you would in Vim script, e.g.:

```lua
local function copy_to_clipboard(lines)
	local joined_lines = table.concat(lines, "\n")
	vim.fn.setreg("+", joined_lines)
end

require("nnn").setup({
	command = "nnn -o -C",
	set_default_mappings = 0,
	replace_netrw = 1,
	action = {
		["<c-t>"] = "tab split",
		["<c-s>"] = "split",
		["<c-v>"] = "vsplit",
		["<c-o>"] = copy_to_clipboard,
	},
})
```

## Troubleshooting

These are some common problems that one might run into. Follow the instruction
and add relevant code snippet into your `vimrc` or `init.vim` to fix them.

-   Files being renamed randomly: This can happen when using `AutoComplPop`
    plugin.

```vim
function! AutoCmpNNN()
    call acp#disable()
    autocmd BufLeave <buffer> call acp#enable()
    autocmd BufEnter <buffer> call acp#disable()
endfunction
autocmd FileType nnn call AutoCmpNNN()
```

-   Explorer buffer gets wiped when opening a file: This can happen when using
    `miniBufExpl` plugin. The workaround is to make sure `miniBufExpl` is open
    before calling `:NnnExplorer`.

```vim
let g:miniBufExplBuffersNeeded = 1
```

-   Can't execute `wqa`: This issue exists in both vim and neovim. When you try
    to quit using the command `wqa` you see the error:
    `E948: Job still running`. Crude workaround:

```vim
command Z w | qa
cabbrev wqa Z
```

## Credits

Main [n³ repository](https://github.com/jarun/nnn).
