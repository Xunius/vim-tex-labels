
"let g:vim_tex_label_context_lines = 3
"let g:vim_tex_label_win_width = 80
"let g:vim_tex_label_max_search_range = 20

let g:vim_tex_label_winname = '__VimTexLabelSplit__'

function! GetVar(name, default)
  " Return a value for the given variable, looking first into buffer, then
  " globals and defaulting to default
  if (exists ("b:" . a:name))
    return b:{a:name}
  elseif (exists ("g:" . a:name))
    return g:{a:name}
  else
    return a:default
  end
endfunction

function! s:RepeatString(text, n)
	let l:result = ''
	for i in range(1,a:n)
		let l:result = l:result . a:text
	endfor
	return l:result
endfunction

"----------------Test split window---------------- {{{
function! s:CreateSidePane()

	let l:win_width = GetVar('vim_tex_label_win_width', 50)
	let l:split_cmd = l:win_width . "vsplit " . g:vim_tex_label_winname
	silent execute l:split_cmd
	let l:win_number = bufwinnr(g:vim_tex_label_winname)
	silent execute l:win_number . "wincmd w"

	" defined keybindings
	nnoremap <buffer> <silent> <CR> :call <SID>MyJumpToLabel("winch")<CR>
	nnoremap <buffer> <silent> h :call <SID>MyJumpToLabel("nowinch")<CR>

endfunction

function! s:AddToSidePane(texts)

	let l:win_number = bufwinnr(g:vim_tex_label_winname)
	if winnr() != l:win_number
		silent execute l:win_number . "wincmd w"
	endif

	setlocal modifiable
	normal! ggdG
	setlocal buftype=nofile
	setlocal filetype=vim_tex_labels

	" fill contents
	if len(a:texts) > 0
		for lii in a:texts
			let @a = lii
			silent execute "normal! " . '"apo'
		endfor
	endif

	silent normal! gg
	setlocal nomodifiable

endfunction


function! s:MyJumpToLabel(action)
	let l:line = line('.')
	let l:cursor_line = substitute(getline('.'), '\v^\s*(.*)$', '\1', "")

	" loop through dict
	let l:found = 0
	let l:target_line = 0
	match none
	for [key, value] in items(s:string_dict)
		if index(value, l:line) >= 0
			let l:found = 1
			let l:target_line = key
			break
		endif
	endfor

	if l:found != '0' && l:target_line != '0'

		execute "1wincmd w"
		" Add the current cursor position to the jump list, so that user can
		" jump back using the ' and ` marks.
		mark '

		call setpos('.', [0, l:target_line, 0])

		" find the label
		for [key, value] in items(s:label_dict)
			for i in range(len(value))
				let l:lii = value[i]
				if string(l:lii[0]) == l:target_line
					let l:target_label = l:lii[2]
					break
				endif
			endfor
		endfor

		" If the line is inside a fold, open the fold
		if foldclosed('.') != -1
			.foldopen!
		endif

		" Bring the line to the middle of the window
		normal! z.

		" highlight line
		execute 'match Search ' . '/\v\\label\{(.*)=' . l:target_label . '\}/'

		if a:action ==# "nowinch"
			let l:win_number = bufwinnr(g:vim_tex_label_winname)
			execute l:win_number . "wincmd w"
		endif
	endif


endfunction

"----------------Test split window---------------- }}}


function! s:FindEquationContext(line, begin_eq_pattern)
	let l:end_eq_pattern = '\v\\end\{equation\}'

	" search for \begin{equation}
	call setpos('.', [0, a:line, 0])
	let l:target_b = search(a:begin_eq_pattern, "bW")
	" search for \end{equation}
	call setpos('.', [0, a:line, 0])
	let l:target_e = search(l:end_eq_pattern, "W")

	let l:result = []
	for i in range(l:target_b+1, l:target_e-1)
		call add(l:result, getline(i))
	endfor

	let l:result = l:result[:GetVar('vim_tex_label_max_search_range', 20)]
	"return join(l:result, "\n")
	return l:result

endfunction


function! s:GetTargetPattern(label_type, label)
	let l:type = tolower(a:label_type)
	let l:lab = tolower(a:label)

	if len(l:type) > 0
		if index(["fig", "figure", "f"], l:type) >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif index(["tab", "table", "t"], l:type) >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif index(["eq", "equation", "e"], l:type) >= 0
			let l:result = '\v\\begin\{equation\}'
		elseif index(["sub", "subsection", "sec", "section", "s"], l:type) >= 0
			let l:result = '\v^\\(sub)=section'
		elseif index(["alg", "algorithm"], l:type) >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif index(["lst", "listing"], l:type) >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif index(["ch", "chapter"], l:type) >= 0
			let l:result = '\v\\chapter\{(.*)\}='
		else
			let l:result = ''
		endif
	else
		if match(l:lab, 'fig') >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif match(l:lab, 'tab') >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif match(l:lab, 'eq') >= 0
			let l:result = '\v\\begin\{equation\}'
		elseif match(l:lab, 'sec') >= 0
			let l:result = '\v^\\(sub)=section'
		elseif match(l:lab, 'sub') >= 0
			let l:result = '\v^\\(sub)=section'
		elseif match(l:lab, 'alg') >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif match(l:lab, 'l(i)=st') >= 0
			let l:result = '\v\\caption\{(.*)\}='
		elseif match(l:lab, 'ch(apter)=') >= 0
			let l:result = '\v\\chapter\{(.*)\}='
		else
			let l:result = ''
		endif
	endif

	return l:result
endfunction

function! s:FindContextAroundLine(line)
	let l:result = []
	let l:context_lines = GetVar('vim_tex_label_context_lines', 3)
	let l:backward_lines = l:context_lines/2
	let l:forward_lines = l:context_lines - l:backward_lines

	" search backward
	let l:i = 1
	let l:found = 0
	while l:found < l:backward_lines
		let l:cur = a:line - l:i
		if l:cur <= 0
			break
		endif
		let l:curline = getline(l:cur)
		if len(l:curline) > 0 && match(l:curline, '\v^\s*$') == -1
			call add(l:result, l:curline)
			let l:found += 1
		endif
		let l:i += 1
	endwhile

	call add(l:result, a:line)

	" search forward
	let l:i = 1
	let l:found = 0
	while l:found < l:forward_lines
		let l:cur = a:line + l:i
		if l:cur > line('$')
			break
		endif
		let l:curline = getline(l:cur)
		if len(l:curline) > 0 && match(l:curline, '\v^\s*$') == -1
			call add(l:result, l:curline)
			let l:found += 1
		endif
		let l:i += 1
	endwhile

	"return join(l:result, "\n")
	return l:result

endfunction

function! s:FindLabelContext(label_type, label_list)

	let l:line = a:label_list[0]
	let l:col = a:label_list[1]
	let l:label = a:label_list[2]
	let l:max_range = GetVar('vim_tex_label_max_search_range', 20)
	let l:search_start = max([1, l:line - l:max_range])
	let l:search_end = min([line('$'), l:line + l:max_range])

	let l:type_pattern = <SID>GetTargetPattern(a:label_type, l:label)

	" if no pattern returned, default to fetch a few lines as context
	if l:type_pattern == ''
		return <SID>FindContextAroundLine(l:line)
	" if equation, fetch lines in \begin{equation} and \end{equation}
    elseif l:type_pattern == '\v\\begin\{equation\}'
		return <SID>FindEquationContext(l:line, l:type_pattern)
	else
		call setpos('.', [0, l:line, l:col])

		" search backward
		let l:target_b = search(l:type_pattern, "bW", l:search_start)
		if l:target_b > 0
			return [getline(l:target_b)]
		" search forward
		else
			call setpos('.', [0, l:line+1, l:col])
			let l:target_f = search(l:type_pattern, "W", l:search_end)
			if l:target_f > 0
				return [getline(l:target_f)]
			endif
		endif
		return ['']
	endif
endfunction


function! s:AppendToDict(dict, key, value)

	if has_key(a:dict, a:key)
		call add(a:dict[a:key], a:value)
	else
		let a:dict[a:key] = [a:value]
	endif
	return a:dict
endfunction


function! s:FindLabels()

	"let l:labels = []
	let l:nlines = line('$')
	let l:pattern = '\v\\label\{(.*)\}'
	let l:sub_pattern = '\v\\label\{(.*):(.*)\}'
	"let l:uncat_labels = []
	let s:label_dict = {} " key: label type, value: list of labels [row, col, label_str]

	" scan through lines and fetch \labels
	" couldn't find an easiler way
	for i in range(1, l:nlines)
		let l:mstrii = matchstr(getline(i), l:pattern)
		" column necessary?
		let l:mcolii = match(getline(i), l:pattern)

		if len(l:mstrii) > 0
			" try find submatches of the form \label{fig:fig1}
			let l:sub_match1 = substitute(l:mstrii, l:sub_pattern, '\1', "")
			if l:sub_match1 ==# l:mstrii
				" if sub_match1 is the same as mstrii, label has no submatches
				let l:sub_match1 = ''
				let l:sub_match2 = substitute(l:mstrii, l:pattern, '\1', "")
			else
				let l:sub_match2 = substitute(l:mstrii, l:sub_pattern, '\2', "")
			endif
			let s:label_dict=<SID>AppendToDict(s:label_dict, l:sub_match1, [i, l:mcolii, l:sub_match2])
		endif
	endfor

	return s:label_dict

endfunction


function! s:AddStringLine(string_list, string_dict, text, key)
	call add(a:string_list, a:text)
	call <SID>AppendToDict(a:string_dict, a:key, len(a:string_list))
endfunction


function! s:ComposeLabelList(label_dict)

	let l:result_strs = []
	let s:string_dict = {}

	if len(s:label_dict) == 0
		return ''
	endif

	" write labels with a type
	let l:keys = keys(s:label_dict)
	call filter(l:keys, 'len(v:val)')

	if len(l:keys) > 0
		call sort(l:keys)
		for key in l:keys
			let l:str = "  " . key . "  "
			call <SID>AddStringLine(l:result_strs, s:string_dict, <SID>RepeatString("=", len(l:str)), 0)
			call <SID>AddStringLine(l:result_strs, s:string_dict, l:str, 0)
			call <SID>AddStringLine(l:result_strs, s:string_dict, <SID>RepeatString("=", len(l:str)), 0)
			for v in s:label_dict[key]
				call <SID>AddStringLine(l:result_strs, s:string_dict, "* " . v[0] . ":" . v[2], v[0])
				let l:context = <SID>FindLabelContext(key, v)
				for ll in l:context
					call <SID>AddStringLine(l:result_strs, s:string_dict, "   " .
								\ ll, v[0])
				endfor
			endfor
		endfor
	endif

	" write labels with no type
	if has_key(s:label_dict, '')
		let l:uncat_labels = s:label_dict['']
		if len(l:uncat_labels) > 0
			call sort(l:uncat_labels)
			call <SID>AddStringLine(l:result_strs, s:string_dict, "=====================", 0)
			call <SID>AddStringLine(l:result_strs, s:string_dict, "Uncategorized labels:", 0)
			call <SID>AddStringLine(l:result_strs, s:string_dict, "=====================", 0)
			for v in l:uncat_labels
				call <SID>AddStringLine(l:result_strs, s:string_dict, "* " . v[0] . ":" . v[2], v[0])
				let l:context = <SID>FindLabelContext('', v)
				for ll in l:context
					call <SID>AddStringLine(l:result_strs, s:string_dict, "   " .
								\ ll, v[0])
				endfor
			endfor
		endif
	endif

	return l:result_strs

endfunction


function! s:ToggleLabelList()

	let l:win_number = bufwinnr(g:vim_tex_label_winname)

	if l:win_number == -1
		echom 'Finding labels and create new pane'
		let s:label_dict = <SID>FindLabels()
		let l:tag_strings = <SID>ComposeLabelList(s:label_dict)
		call <SID>CreateSidePane()
		call <SID>AddToSidePane(l:tag_strings)
	else
		echom 'Closing pane'

		if winnr() == l:win_number
			" Already in the taglist window. Close it and return
			if winbufnr(2) != -1
				" If a window other than the taglist window is open,
				" then only close the taglist window.
				close
			endif
		else
			" Goto the taglist window, close it and then come back to the
			" original window
			let curbufnr = bufnr('%')
			exe l:win_number . 'wincmd w'
			close
			" Need to jump back to the original window only if we are not
			" already in that window
			let l:win_number = bufwinnr(curbufnr)
			if winnr() != l:win_number
				exe l:win_number . 'wincmd w'
			endif
		endif
		return
	endif


endfunction

nnoremap <buffer> <leader>z :call <SID>ToggleLabelList()<cr>
command! -nargs=0 -bar TexLabelToggle call s:ToggleLabelList()
command! -nargs=0 -bar TexLabelJumpToLabel call s:MyJumpToLabel('winch')
command! -nargs=0 -bar TexLabelScrollToLabel call s:MyJumpToLabel('nowinch')

"au BufReadPost quickfix setlocal modifiable
"au BufReadPost quickfix execute "%y a"
"au BufReadPost quickfix setlocal nomodifiable
