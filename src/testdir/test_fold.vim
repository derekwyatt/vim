" Test for folding

func! Test_address_fold()
  new
  call setline(1, ['int FuncName() {/*{{{*/', 1, 2, 3, 4, 5, '}/*}}}*/',
	      \ 'after fold 1', 'after fold 2', 'after fold 3'])
  setl fen fdm=marker
  " The next ccommands should all copy the same part of the buffer,
  " regardless of the adressing type, since the part to be copied
  " is folded away
  :1y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))
  :.y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))
  :.+y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))
  :.,.y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))
  :sil .1,.y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))
  " use silent to make E493 go away
  :sil .+,.y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))
  :,y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))
  :,+y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/','after fold 1'], getreg(0,1,1))
  " using .+3 as second address should copy the whole folded line + the next 3
  " lines
  :.,+3y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/',
	      \ 'after fold 1', 'after fold 2', 'after fold 3'], getreg(0,1,1))
  :sil .,-2y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3', '4', '5', '}/*}}}*/'], getreg(0,1,1))

  " now test again with folding disabled
  set nofoldenable
  :1y
  call assert_equal(['int FuncName() {/*{{{*/'], getreg(0,1,1))
  :.y
  call assert_equal(['int FuncName() {/*{{{*/'], getreg(0,1,1))
  :.+y
  call assert_equal(['1'], getreg(0,1,1))
  :.,.y
  call assert_equal(['int FuncName() {/*{{{*/'], getreg(0,1,1))
  " use silent to make E493 go away
  :sil .1,.y
  call assert_equal(['int FuncName() {/*{{{*/', '1'], getreg(0,1,1))
  " use silent to make E493 go away
  :sil .+,.y
  call assert_equal(['int FuncName() {/*{{{*/', '1'], getreg(0,1,1))
  :,y
  call assert_equal(['int FuncName() {/*{{{*/'], getreg(0,1,1))
  :,+y
  call assert_equal(['int FuncName() {/*{{{*/', '1'], getreg(0,1,1))
  " using .+3 as second address should copy the whole folded line + the next 3
  " lines
  :.,+3y
  call assert_equal(['int FuncName() {/*{{{*/', '1', '2', '3'], getreg(0,1,1))
  :7
  :sil .,-2y
  call assert_equal(['4', '5', '}/*}}}*/'], getreg(0,1,1))

  quit!
endfunc

func! Test_indent_fold()
    new
    call setline(1, ['', 'a', '    b', '    c'])
    setl fen fdm=indent
    2
    norm! >>
    let a=map(range(1,4), 'foldclosed(v:val)')
    call assert_equal([-1,-1,-1,-1], a)
endfunc

func! Test_indent_fold()
    new
    call setline(1, ['', 'a', '    b', '    c'])
    setl fen fdm=indent
    2
    norm! >>
    let a=map(range(1,4), 'foldclosed(v:val)')
    call assert_equal([-1,-1,-1,-1], a)
    bw!
endfunc

func! Test_indent_fold2()
    new
    call setline(1, ['', '{{{', '}}}', '{{{', '}}}'])
    setl fen fdm=marker
    2
    norm! >>
    let a=map(range(1,5), 'foldclosed(v:val)')
    call assert_equal([-1,-1,-1,4,4], a)
    bw!
endfunc

func Test_manual_fold_with_filter()
  if !executable('cat')
    return
  endif
  for type in ['manual', 'marker']
    exe 'set foldmethod=' . type
    new
    call setline(1, range(1, 20))
    4,$fold
    %foldopen
    10,$fold
    %foldopen
    " This filter command should not have an effect
    1,8! cat
    call feedkeys('5ggzdzMGdd', 'xt')
    call assert_equal(['1', '2', '3', '4', '5', '6', '7', '8', '9'], getline(1, '$'))

    bwipe!
    set foldmethod&
  endfor
endfunc

func! Test_indent_fold_with_read()
  new
  set foldmethod=indent
  call setline(1, repeat(["\<Tab>a"], 4))
  for n in range(1, 4)
    call assert_equal(1, foldlevel(n))
  endfor

  call writefile(["a", "", "\<Tab>a"], 'Xfile')
  foldopen
  2read Xfile
  %foldclose
  call assert_equal(1, foldlevel(1))
  call assert_equal(2, foldclosedend(1))
  call assert_equal(0, foldlevel(3))
  call assert_equal(0, foldlevel(4))
  call assert_equal(1, foldlevel(5))
  call assert_equal(7, foldclosedend(5))

  bwipe!
  set foldmethod&
  call delete('Xfile')
endfunc

func Test_combining_folds_indent()
  new
  let one = "\<Tab>a"
  let zero = 'a'
  call setline(1, [one, one, zero, zero, zero, one, one, one])
  set foldmethod=indent
  3,5d
  %foldclose
  call assert_equal(5, foldclosedend(1))

  set foldmethod&
  bwipe!
endfunc

func Test_combining_folds_marker()
  new
  call setline(1, ['{{{', '}}}', '', '', '', '{{{', '', '}}}'])
  set foldmethod=marker
  3,5d
  %foldclose
  call assert_equal(2, foldclosedend(1))

  set foldmethod&
  bwipe!
endfunc

func s:TestFoldExpr(lnum)
  let thisline = getline(a:lnum)
  if thisline == 'a'
    return 1
  elseif thisline == 'b'
    return 0
  elseif thisline == 'c'
    return '<1'
  elseif thisline == 'd'
    return '>1'
  endif
  return 0
endfunction

func Test_update_folds_expr_read()
  new
  call setline(1, ['a', 'a', 'a', 'a', 'a', 'a'])
  set foldmethod=expr
  set foldexpr=s:TestFoldExpr(v:lnum)
  2
  foldopen
  call writefile(['b', 'b', 'a', 'a', 'd', 'a', 'a', 'c'], 'Xfile')
  read Xfile
  %foldclose
  call assert_equal(2, foldclosedend(1))
  call assert_equal(0, foldlevel(3))
  call assert_equal(0, foldlevel(4))
  call assert_equal(6, foldclosedend(5))
  call assert_equal(10, foldclosedend(7))
  call assert_equal(14, foldclosedend(11))

  call delete('Xfile')
  bwipe!
  set foldmethod& foldexpr&
endfunc
