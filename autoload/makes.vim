"########################################################################
" Filename:      makes.vim
" Copyright: Copyright (C) 2020 Rudra Banerjee
"
"    This program is free software: you can redistribute it and/or modify
"    it under the terms of the GNU General Public License as published by
"    the Free Software Foundation, either version 3 of the License, or
"    (at your option) any later version.
"
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" Date:          03/07/2015
" Description:   Make utility for fortran.
"########################################################################

" Variables {{{1
let b:Compiler = get(g:, "fortran_compiler", "gfortran")
let b:ObjExt    =   '.o'
let b:ModExt    =   '.mod'
let b:ExeExt    =   get(g:,'fortran_exeExt','')
let b:VimComp   =   'gfortran'
let b:FCFlags   =  get(g:, "fortran_fcflags",   '-Wall  -O0 -c')
let b:FLFlags   =   get(g:, "fortran_flflags",  '-Wall -O0')
let b:OutputGvim=   'vim'
"}}}1

" Compile current buffer {{{1
function! makes#Fcompile()
  let sou = expand("%:p")
  let obj = expand("%:p:r").b:ObjExt
  let s:fortran_comp_success = 0
    "
  echo "Creating object file"
  setlocal efm=%E%f:%l:%c:,%E%f:%l:,%C,%C%p%*[0123456789^],%ZError:\ %m,%C%.%#
  " Don't process any further if the compilation is up to date
  if filereadable(obj) && (getftime(obj)>getftime(sou))
    echom "'" . obj . "':is up to date"
    let s:fortran_comp_success=1
    return
  endif

  let makeprg_saved = '"' . &makeprg . '"'
  execute "setlocal makeprg=" . b:Compiler
  " let v:statusmsg = ''
  execute "silent make " . b:FCFlags . " " . sou . " -o " . obj

  " Don'r process any further if the compilation was sucessful
  if empty(v:statusmsg)
    echom "'" . obj . "':Compiled successfully"
    let s:fortran_comp_success=1
    return
  endif

  if v:shell_error !=0
    " let &statusline = v:shell_error
    return
  endif
  botright copen
endfunction
"}}}1

" Run executable {{{1
function! makes#Fexe()
  let sou = expand("%:p")
  let obj = expand("%:p:r").b:ObjExt
  " call makes#Fcompile()
  echo "Creating the executable"
    let makeprg_saved = '"' . &makeprg . '"'
    execute "setlocal makeprg=" . b:Compiler
    let s:exe = expand("%:p:r")
    exe "make " .b:FLFlags."  " .sou. " -o ".s:exe
    let s:fortran_link_success = 1
    if v:shell_error !=0
      let &statusline = v:shell_error
      let s:fortran_link_success = 0
      return
    endif
endfunction
"}}}1

function! makes#Frun()
  call makes#Fexe()
  echo "Running the code"
  if s:fortran_link_success==1
    let l:args = exists("b:Clargs") ? b:Clargs : ""
    exe "!".s:exe. " " . l:args
  endif
endfunction

" CLArgs : Command Line Argument {{{1
function! makes#Cla()
  let Exe = expand("%:p:t").b:ExeExt
  let sou = expand("%:p")
  if empty(Exe)
    redraw
    echohl WarningMsg | echo "no file name " | echohl None
    return
  endif
  let	prompt	= 'command line arguments for "'.Exe.'" : '
  if exists("b:Clargs")
    let b:Clargs=input(prompt, b:Clargs,"file")
  else
    let b:Clargs=input(prompt,"","file")
  endif
endfunction
"}}}1

" Debugger :  call debugger, currently supports gdb only {{{1
function! makes#Fdbg()
  let Exe = expand("%:p:r").b:ExeExt
  let sou = expand("%:p")
  let b:F_Debugger = get(g:, "F_Debugger", 'gdb')
  silent exe 'update'
  " if !exists("Exe")
  " call makes#FRun()
  " endif
  let s:FLFlags = "-Wall -g"
  call makes#Fexe()
  echo "Running Debugger"
  let l:arguments = exists("b:ClArgs") ? " ".b:ClArgs : ""

  "   if  s:MSWIN
  "     let l:arguments = substitute( l:arguments, '^\s\+', ' ', '' )
  "     let l:arguments = substitute( l:arguments, '\s\+', "\" \"", 'g')
  "   endif
  "
  " debugger is 'gdb'
  "
  if b:F_Debugger == "gdb"
    exe '!gdb ' . Exe.l:arguments
  endif
  "
  "   if v:windowid != 0
  "     "
  "     " grapical debugger is 'kdbg', uses a PerlTk interface
  "     "
  "     if g:C_Debugger == "kdbg"
  "       if  s:MSWIN
  "         exe '!kdbg "'.s:C_ExecutableToRun.l:arguments.'"'
  "       else
  "         silent exe '!kdbg  '.s:C_ExecutableToRun.l:arguments.' &'
  "       endif
  "     endif
  "     "
  "     " debugger is 'ddd'  (not available for MS Windows); graphical front-end for GDB
  "     "
  "     if g:C_Debugger == "ddd" && !s:MSWIN
  "       if !executable("ddd")
  "         echohl WarningMsg
  "         echo 'ddd does not exist or is not executable!'
  "         echohl None
  "         return
  "       else
  "         silent exe '!ddd '.s:C_ExecutableToRun.l:arguments.' &'
  "       endif
  "     endif
  "     "
  "   endif
  "
  redraw!
endfunction
"}}}1

" run Makefile {{{1
function! makes#MakeRun ()
  let s:Makefile    = ''
  " let s:CmdLineArgs = ''
  let s:Enabled=1
  if s:Enabled == 0
    return s:ErrorMsg ( 'Make : "make" is not executable.' )
  endif

  silent exe 'update'   | " write source file if necessary
  cclose
  "
  " arguments
  " if a:args == '' | let cmdlinearg = s:CmdLineArgs
  " else            | let cmdlinearg = a:args
  " endif
  " :TODO:18.08.2013 21:45:WM: 'cmdlinearg' is not correctly escaped for use under Windows
  "
  " run make
  let l:Margs = exists("b:MakeArgs") ? b:MakeArgs : ""
  exe 'make ' .l:Margs
  botright cwindow
endfunction
" ----------  end of function s:MakesRun  ----------
"}}}1

" Make properties {{{1
function! makes#MakeCla()
  let prompt = 'Make property:'
  if exists("b:MakeArgs")
    let b:MakeArgs = input(prompt, b:MakeArgs, "file")
  else
    let b:MakeArgs = input(prompt,"","file")
  endif
endfunction
"}}}1

" Make Project {{{1
function! makes#MakeProj()
  " Create a gnu style project structure
  let s:Prdir = input("Create new project: ", getcwd(), "file")
  exe ":!mkdir -p ".s:Prdir
  " exe ":lchdir ".s:Prdir
  exe ":!mkdir " .s:Prdir."{/help,/src}"
  exe ":!touch " .s:Prdir."{/ChangeLog,/README,/LICENSE}"
  " exe ":lchdir -"
  let cbf = expand('%:t')
  silent! exe ":!mv *.f90 *.F90 "  .s:Prdir."/src"
  exe ":wa"
  exe ":lchdir ".s:Prdir
  exe "bd|e "  ."src/".cbf

endfunction
" }}}1
