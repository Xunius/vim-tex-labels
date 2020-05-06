# vim-tex-labels

A (very rudimentary) vim plugin to list Latex labels (`\label{}`) in a `.tex` document in a side pane.


## Demo

![Demo](/doc/demo.png)


## Installation

Install with `vundle`:

Add in `.vimrc` the plugin list:

```
Plugin 'xunius/vim-tex-labels'
```

Then do `:PluginInstall`.


## Usage

When editing a `.tex` file, run `:TexLabelToggle` to toggle the side pane.
Or use the default keybinding of `<leader>z`. This will toggle a side pane
on the right showing the `\label{}`s in the `.tex` file.

Move around in the list, and press `Enter` to jump to the label in the `.tex` file,
or press `h` to scroll to the label without leaving the side pane.


## Configs

Set toggle keybinding:

```
nnoremap <leader>z :TexLabelToggle<cr>
```

Set side pane width:

```
let g:vim_tex_label_win_width = 40
```

Set the number of context lines for each label:

```
let g:vim_tex_label_context_lines = 3
```

Set the number of lines to search up-and-down for context lines:

```
"let g:vim_tex_label_max_search_range = 20
```

## Contributions are welcome
