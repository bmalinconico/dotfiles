local M = {
  "nvim-telescope/telescope.nvim",
  keys = {
    { '<leader>ff', ':Telescope find_files<cr>', {} },
    { '<leader>fg', ':Telescope live_grep<cr>', {} },
    { '<leader>fb', "<cmd>lua require('telescope.builtin').buffers{ sort_lastused=true }<cr>", {} },
    { '<leader>fw', ':Telescope grep_string<cr>', {} },
    { '<leader>fr', ':Telescope resume<cr>', {} },
    { 'gd', '<Cmd>Telescope lsp_definitions<cr>', {noremap = true} },
    { 'gw', '<Cmd>Telescope lsp_references<cr>', {noremap = true} },
    { 'gi', '<Cmd>lua require("telescope.builtin").lsp_implementations{ sort_lastused=true }<cr>', {noremap = true} },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build='make'
    },
  }
}

function M.config()
  local status_ok, telescope = pcall(require, "telescope")
  if not status_ok then
    vim.notify("telescope not found")
    return
  end

  local actions = require('telescope.actions')
  -- Global remapping
  ------------------------------
  telescope.setup{
    defaults = {
      file_ignore_patterns = {
        "vendor/.*",
        "projects/research/.*",
        "sorbet/.*.rbi",
        -- In LUA % is the escape character
        "^documentation/lake%-front",
        "grpc_gateway/generated/.*",
        "fake_[^/]+.go$",
        "^proto_gen/"
      },
      mappings = {
        n = {
          ["q"] = actions.close,
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,                    -- false will only do exact matching
          override_generic_sorter = true,  -- override the generic sorter
          override_file_sorter = true,     -- override the file sorter
          case_mode = "smart_case",        -- "smart_case" or "ignore_case" or "respect_case"
        }
      }
    }
  }

  require('telescope').load_extension('fzf')
end

return M;
