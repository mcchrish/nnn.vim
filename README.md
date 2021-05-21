# nnn.vim

File manager for vim/neovim powered by n³.

<p align="center">
  <img width="934" src="https://user-images.githubusercontent.com/7200153/77138110-8dd94600-6aab-11ea-925f-8e159b8f0ad4.png">
  <small>colorscheme <a href="https://github.com/pgdouyon/vim-yin-yang">yin</a></small>
</p>

### Requirements

1. n³
2. Neovim or Vim 8.1 with terminal support

### Install

You must install n³ itself. Instructions
[here](https://github.com/jarun/nnn/wiki/Usage#installation).

Then install using your favorite plugin manager:

```vim
" using vim-plug
Plug 'mcchrish/nnn.vim'
```

### Usage

To open n³ as a file picker in vim/neovim, use the command `:NnnPicker` or
`:Np` or the key-binding `<leader>n`. You can pass a directory to `:NnnPicker`
command and opens n³ from there e.g. `:NnnPicker path/to/somewhere`.

Once you [select](https://github.com/jarun/nnn/wiki/concepts#selection) one or more files and
press <kbd>enter</kbd>, vim quits the n³ window and opens the first selected
file and add the remaining files to the arg list/buffer list.

Pressing <kbd>enter</kbd> on a file in n³ will pick any earlier selection, pick
the file and exit n³.

Note that pressing <kbd>l</kbd> or <kbd>Right</kbd> on a file would open it
instead of picking.

To discard selection and exit, press <kbd>^G</kbd>.

You may have to set `set hidden` to make floating window work.

Please visit the complete documentation by running `:help nnn`.

### Configurations

#### Custom mappings

```vim
" Disable default mappings
let g:nnn#set_default_mappings = 0

" Then set your own
nnoremap <silent> <leader>nn :NnnPicker<CR>


" Or override
" Start nnn in the current file's directory
nnoremap <leader>n :NnnPicker %:p:h<CR>
```

#### Layout

```vim
" Opens the n³ window in a split
let g:nnn#layout = 'new' " or vnew, tabnew etc.

" Or pass a dictionary with window size
let g:nnn#layout = { 'left': '~20%' } " or right, up, down

" Floating window (neovim latest and vim with patch 8.2.191)
let g:nnn#layout = { 'window': { 'width': 0.9, 'height': 0.6, 'highlight': 'Debug' } }
```

#### Action

You can set extra key-bindings for opening files in different ways. Nothing is
set by default to not override n³'s own key-bindings.

```vim
let g:nnn#action = {
      \ '<c-t>': 'tab split',
      \ '<c-x>': 'split',
      \ '<c-v>': 'vsplit' }
```

For example, when inside an n³ window, pressing <kbd>ctrl-t</kbd> will open the
selected file in a tab, instead of the current window. <kbd>ctrl-x</kbd> will
open in a split an so on. Meanwhile for multi selected files will be loaded in
the buffer list.

#### Persistent session

You can configure n³ to use a session to remember your place when you reopen it.

```vim
" use the same nnn session within a vim session
let g:nnn#session = 'local'

" use the same nnn session everywhere (including outside vim)
let g:nnn#session = 'global'
```

#### Command override

When you want to override the default n³ command and add some extra flags.
Example you want to start n³ in detail mode.

```vim
let g:nnn#command = 'nnn -d'

" or pass some env variables
let g:nnn#command = 'NNN_TRASH=1 nnn -d'
```

#### `nnn#pick()`

The `nnn#pick([<dir>][,<opts>])` function can be called with custom directory
and additional options such as opening file in splits or tabs. Basically a more
configurable version of `:NnnPicker` command.

```vim
call nnn#pick('~/some-files', { 'edit': 'vertical split' })
" Then you can do all kinds of mappings if you want
```

`opts` can be:

- `edit` - type of window the select file will be open.
- `layout` - same as `g:nnn#layout` and overrides it if specified.

#### Environment variables

You can define env variables in `vimrc` and n³ will detect it.

```vim
let $NNN_TRASH=1
```

### Credits

Main n³ program: https://github.com/jarun/nnn
