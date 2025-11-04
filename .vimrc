set spell spelllang=en_us
set spellfile=spell.add
set nosmartindent
set wrap

map <F1> lbi<strong><ESC>ea</strong><ESC>
vmap <F1> :<HOME><DEL><DEL><DEL><DEL><DEL>s/\%V\(.*\)\%V./<strong>\0<\/strong>/g<CR>
map <F2> lbi<em><ESC>ea</em><ESC>
vmap <F2> :<HOME><DEL><DEL><DEL><DEL><DEL>s/\%V\(.*\)\%V./<em>\0<\/em>/g<CR>
map <F3> lbi<span class='red'><ESC>ea</span><ESC>
vmap <F3> :<HOME><DEL><DEL><DEL><DEL><DEL>s/\%V\(.*\)\%V./<span class='red'>\0<\/span>/g<CR>
map <F5> i<CR>\begin{itemize}<CR><CR><CR>\end{itemize}<ESC><UP><UP>o  \item
map <F6> o\item
