if exists("b:current_syntax")
	finish
endif

let b:current_syntax = "vim_tex_labels"

syntax match vim_tex_label_Label '\v^\* (.*):(.*)$' contains=vim_tex_label_Label_C
highlight link vim_tex_label_Label Question

syntax match vim_tex_label_Label_C '\v^\* (.*):' contained containedin=vim_tex_label_Label
highlight link vim_tex_label_Label_C Directory

syntax match vim_tex_label_Context '\v^\   (.*)$'
highlight link vim_tex_label_Context Folded

syntax region vim_tex_label_Type start=/\v^\=+$/ end=/\v^\=+$/
highlight link vim_tex_label_Type IncSearch

" type: Search, IncSearch, Directory
" label: Question, Title, Underlined
" context: Folded, Normal, Comment,
" line number: Todo, LineNr, Folded
