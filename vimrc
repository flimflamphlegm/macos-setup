" Show line numbers
set number

" Enable syntax highlighting
syntax on

" Use 24-bit (true) color — kitty and most modern terminals support this.
" COLORTERM is set to "truecolor"/"24bit" when the terminal supports it.
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
  set termguicolors
endif

" Colorscheme
colorscheme unokai

if &term=="xterm"
  set t_Co=8
  set t_Sb=[4%dm
  set t_Sf=[3%dm
endif

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
" Revert with: ":delcommand DiffOrig".
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
                  \ | wincmd p | diffthis
endif

if has('langmap') && exists('+langremap')
  " Prevent that the langmap option applies to characters that result from a
  " mapping.  If set (default), this may break plugins (but it's backward
  " compatible).
  set nolangremap
endif

" Don't wake up system with blinking cursor:
let &guicursor = &guicursor . ",a:blinkon0"

" Source a global configuration file if available
if filereadable("/etc/vimrc.local")
  source /etc/vimrc.local
endif
