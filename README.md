# nnn.vim

### Install

```vim
" using vim-plug
Plug 'mcchrish/nnn.vim'
```
### Usage

Copy this file to the vim/neovim plugin directory.
To open nnn as a file picker in vim/neovim, use the command `:NnnPicker` or
`:Np` or the key-binding `<leader>n`. Once you select one or more files and
quit nnn, vim/neovim will open the first selected file and add the remaining
files to the arg list/buffer list.  If no file is explicitly selected, the
last selected entry is picked.

#### Notes

1. To discard selection and exit, press `^G`.
2. Pressing `Enter` on a file in `nnn` will open the file instead if picking.

### Credits

Main nnn program: https://github.com/jarun/nnn

