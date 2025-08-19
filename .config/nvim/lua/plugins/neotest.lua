local M = {
  "nvim-neotest/neotest",
  event = {
    'BufReadPre *_spec.rb,*_test.go',
    'BufWritePre *_spec.rb,*_test.go',
  },
  keys = {
    -- We are running a cmd here to identify the type
    { '<leader>t', '<cmd>lua require("plugins.neotest").runNearest()<CR>', {silent = true} },
    { '<leader>ta', "<cmd>lua require('neotest').run.attach()<CR>", {silent = true} },
    { '<leader>tc', "<cmd>lua require('neotest').run.stop()<CR>", {silent = true} },
    { '<leader>ts', "<cmd>lua require('neotest').summary.toggle()<CR>", {silent = true} },
    { '<leader>to', "<cmd>lua require('neotest').output.open({ enter = true })<CR>", {silent = true} },
    { '<leader>T', '<cmd>lua require("plugins.neotest").runFile()<CR>', {silent = true} },
    { '<leader>l', '<cmd>lua require("plugins.neotest").runLast()<CR>', {silent = true} },
  },
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-neotest/neotest-plenary",
    "nvim-neotest/neotest-python",
    "olimorris/neotest-rspec",
    'haydenmeade/neotest-jest',
    { "bmalinconico/vim-test", branch="enable_auto_continue" }
  }
}

-- These functions delegate to vim-test for go files since it handles debugging
function M.runNearest()
  if vim.bo.filetype == "go" then
    vim.cmd("TestNearest")
  else
    require('neotest').run.run()
  end
end

function M.runFile()
  if vim.bo.filetype == "go" then
    vim.cmd("TestFile")
  else
    require('neotest').run.run(vim.fn.expand('%'))
  end
end

function M.runLast()
  if vim.bo.filetype == "go" then
    vim.cmd("TestLast")
  else
    require('neotest').run.run_last()
  end
end

function M.config()
  neotest = require("neotest")

  neotest.setup({
    output = {
      enabled = true,
      open_on_run = "short",
      auto_continue = false,
    },
    running = {
      concurrent = false
    },
    quickfix = {
      enabled = false,
      open = false,
    },
    adapters = {
      require("neotest-python"),
      require("neotest-plenary"),
      require("neotest-rspec"),
      require('neotest-jest')({
        jestCommand = "npm test --",
        jestConfigFile = "custom.jest.config.ts",
        env = { CI = true },
        cwd = function(path)
          return vim.fn.getcwd()
        end,
      }),
    },
  })

  -- The following block of code is from the GoLang testrunner readme
  -- local neotest_ns = vim.api.nvim_create_namespace("neotest")
  -- vim.diagnostic.config({
  --   virtual_text = {
  --     format = function(diagnostic)
  --       local message = diagnostic.message
  --         :gsub("\n", " ")
  --         :gsub("\t", " ")
  --         :gsub("%s+", " ")
  --         :gsub("^%s+", "")
  --       return message
  --     end,
  --   },
  -- }, neotest_ns)


  local map = vim.api.nvim_set_keymap;


  local augroup = vim.api.nvim_create_augroup 
  local autocmd = vim.api.nvim_create_autocmd

  local group = augroup('NeotestAuGroup', { clear = true })

  autocmd('BufReadPost', {
    pattern = '*_spec.rb',
    group = group,
    callback = function()
      require('neotest').run.run(vim.fn.expand('%'))
    end
  })

  -- autocmd('BufWritePost', {
  --   pattern = '*_spec.rb',
  --   group = group,
  --   callback = function()
  --     require('neotest').run.run()
  --   end
  -- })

  autocmd("FileType", {
    pattern = "neotest-output,neotest-attach",
    group = group,
    callback = function(opts)
      -- Allow simple Q to quit the window
      vim.keymap.set("n", "q", function()
        pcall(vim.api.nvim_win_close, 0, true)
      end, {
          buffer = opts.buf,
        })

      -- Use my normal jk to get out of the terminal insert mode
      vim.keymap.set("t", "jk", '<C-\\><C-n>', { buffer = opts.buf})

    end,
  })
end

return M
