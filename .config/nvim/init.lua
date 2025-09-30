require 'settings.options'
require 'settings.spelling'
require 'keybindings'


local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup('plugins')
-- require("lazy").setup({
--   {
--     "pmizio/typescript-tools.nvim",
--     dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
--     opts = {},
--   }
-- })


require 'golang'
require 'js_ts'
require 'formatter'
