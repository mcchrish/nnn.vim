# nnn.vim

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

Once you select one or more files and quit nnn, vim/neovim will open the first
selected file and add the remaining files to the arg list/buffer list. If no
file is explicitly selected, the last selected entry is picked.

#### Custom mappings

```vim
" Disable default mappings
let g:nnn#set_default_mappings = 0

" Then set your own
nnoremap <leader>nn :NnnPicker<CR>


" Or override
" Start nnn in the current file's directory
nnoremap <leader>n :NnnPicker '%:p:h'<CR>
```

#### Layout

```vim
" Opens the nnn window in a split
let g:nnn#layout = 'split' " vsplit, etab etc.
```

#### Notes

1. To discard selection and exit, press `^G`.
2. Pressing `Enter` on a file in `nnn` will open the file instead if picking.

### Credits

Main nnn program: https://github.com/jarun/nnn
