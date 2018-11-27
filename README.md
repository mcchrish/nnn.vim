# nnn.vim

nnn and vim/neovim integration.

<p align="center"> 
  <img src="https://user-images.githubusercontent.com/7200153/49083382-5ed00d00-f287-11e8-9f94-77fa548deb72.png">
</p>

### Install

You must install nnn itself. Instructions
[here](https://github.com/jarun/nnn#installation).

Then install using your favorite plugin manager:

```vim
" using vim-plug
Plug 'mcchrish/nnn.vim'
```

### Usage

To open nnn as a file picker in vim/neovim, use the command `:NnnPicker` or
`:Np` or the key-binding `<leader>n`. You can pass a directory to `:NnnPicker`
command and opens nnn from there e.g. `:NnnPicker path/to/somewhere`.

Once you [select](https://github.com/jarun/nnn#selection) one or more files and
quit nnn, vim/neovim will open the first selected file and add the remaining
files to the arg list/buffer list. If no file is explicitly selected, the last
highlighted (in reverse-video) entry is picked.

To discard selection and exit, press <kbd>^G</kbd>.

The default behaviour of nnn as a file manager is retained. Pressing
<kbd>Enter</kbd> on a file in nnn will open the file instead if picking.

#### Custom mappings

```vim
" Disable default mappings
let g:nnn#set_default_mappings = 0

" Then set your own
nnoremap <silent> <leader>nn :NnnPicker<CR>


" Or override
" Start nnn in the current file's directory
nnoremap <leader>n :NnnPicker '%:p:h'<CR>
```

#### Layout

```vim
" Opens the nnn window in a split
let g:nnn#layout = 'split' " or vertical split, tabedit etc.
```

#### Advanced configuration

The `NnnPicker()` function can be called with custom directory and additional
options such as opening file in splits or tabs. Basically a more configurable
version of `:NnnPicker` command.

```vim
call NnnPicker('~/some-files', { 'edit': 'vertical split' })
" Then you can do all kinds of mappings if you want
```

### Credits

Main nnn program: https://github.com/jarun/nnn
