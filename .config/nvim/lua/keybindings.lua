vim.g.mapleader = ' ' 
vim.g.maplocalleader = ' ' 
local map = vim.api.nvim_set_keymap

map('i', 'jk', '<esc>', {noremap = true})
map('n', '<leader>evc', ':edit $MYVIMRC<CR>', {noremap = true})
map('n', '<leader>rvc', ':luafile $MYVIMRC<CR>', {noremap = true})
map('i', '<esc>', '<nop>', {noremap = true})

-- Copy to clipboard
map('v', '<leader>y', '"+y', {noremap = true})
map('n', '<leader>Y', '"+yg_', {noremap = true})
map('n', '<leader>y', '"+y', {noremap = true})
map('n', '<leader>yy', '"+yy', {noremap = true})

map('n', '<leader>r', ':set opfunc=ChangePaste<CR>g@', {silent=true})


vim.cmd [[
let test#strategy = "neovim"

function! ChangePaste(type, ...)
    silent exe "normal! `[v`]\"_c"
    silent exe "normal! \"0p"
endfunction

augroup autoDebugger
  autocmd!
  " Ruby
  autocmd FileType ruby noremap <leader>d Obinding.pry<esc>==
  "autocmd FileType ruby inoremap <leader>d <esc>Obinding.pry<esc>==i
  "autocmd FileType ruby iabbrev <buffer> binding TRYAGAIN

  autocmd FileType ruby nnoremap <leader>pd yiwOputs <esc>p
  "autocmd FileType ruby inoremap <leader>pd <esc>yiwOputs <esc>p

  "python
  autocmd FileType python noremap <leader>d Obreakpoint();<esc>

  "typescript
  autocmd FileType typescript noremap <leader>d Odebugger;<esc>==
"  autocmd FileType typescript inoremap <leader>d <esc>Odebugger;<esc>==i
  autocmd FileType typescript iabbrev <buffer> debugger TRYAGAIN

  autocmd FileType typescript nnoremap <leader>pd yiwOconsole.log(<esc>pA)
"  autocmd FileType typescript inoremap <leader>pd <esc>yiwOconsole.log(<esc>pA)
augroup END
]]

