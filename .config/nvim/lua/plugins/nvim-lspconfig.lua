local M = {
 "neovim/nvim-lspconfig",
 event = "BufReadPre",
 keys = {
  -- map('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<cr>', {noremap = true})
  --map('n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<cr>', {noremap = true})
  { 'K', '<Cmd>lua vim.lsp.buf.hover()<cr>', {noremap = true} },
  { 'gh', '<Cmd>lua vim.lsp.buf.signature_help()<cr>', {noremap = true} },
  { 'gr', '<Cmd>lua vim.lsp.buf.rename()<cr>', {noremap = true} },
  { '<leader>e', '<Cmd>lua vim.diagnostic.open_float()<cr>', {noremap = true} },
  { 'af', '<Cmd>lua vim.lsp.buf.format { async = true }<cr>', {noremap = true} },
  { 'ai', '<Cmd>lua vim.lsp.buf.code_action()<cr>', {noremap = true} },
 },
 dependencies = {
   "hrsh7th/cmp-nvim-lsp",
 }
}

function M.config()
  local status_ok, lsp = pcall(require, "lspconfig")
  if not status_ok then
    vim.notify("lspconfig not found")
    return
  end

  local map = vim.api.nvim_set_keymap
  -- local coq = require "coq"
  local util = require 'lspconfig.util'

  require'lspconfig.configs'.regols = {
    default_config = {
      cmd = {'regols'};
      filetypes = { 'rego' };
      root_dir = util.root_pattern(".git");
    }
  }

  local capabilities = vim.lsp.protocol.make_client_capabilities()

  local status_ok, cmpnvimlsp = pcall(require, "cmp_nvim_lsp")
  if status_ok then
    capabilities = cmpnvimlsp.default_capabilities(capabilities)
  end

  local servers = {
    sorbet = {},
    gopls = {},
    -- eslint = {},
    ts_ls = {},
    terraformls = {},
    regols = {},
    basedpyright = {},
    angularls = {
      filetypes = { 'typescript', 'html', 'typescriptreact', 'typescript.tsx' },
      -- Check for angular.json since that is the root of the project.
      -- Don't check for tsconfig.json or package.json since there are multiple of these
      -- in an angular monorepo setup.
      root_dir = function(fname)
        local root_dir = util.root_pattern "tsconfig.json"(fname)
          or util.root_pattern("package.json", "jsconfig.json", ".git")(fname)

        -- INFO: this is needed to make sure we don't pick up root_dir inside node_modules
        local node_modules_index = root_dir and root_dir:find("node_modules", 1, true)
        if node_modules_index and node_modules_index > 0 then
          root_dir = root_dir:sub(1, node_modules_index - 2)
        end

        return root_dir
      end,
      on_new_config = function(new_config, new_root_dir)
        -- We need to check our probe directories because they may have changed.
        new_config.cmd = {
          'ngserver',
          '--stdio',
          '--tsProbeLocations',
          new_root_dir,
          '--ngProbeLocations',
          new_root_dir,
        }
      end,

    },
    ccls = {},
    -- solargraph = {
    --   capabilities = capabilities,
    --   cmd = { 'bundle', 'exec', 'solargraph', 'stdio' },
    -- }
  }

  local function on_attach(client, bufnr)
    -- Find the clients capabilities
    if client.supports_method('textDocument/documentHighlight') then
      vim.cmd [[
        augroup LspHighlight
        autocmd!
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
      ]]
    end
  end


  local options = {
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {
      debounce_text_changes = 150,
    },
  }

  for server, opts in pairs(servers) do
    opts = vim.tbl_deep_extend("force", {}, options, opts or {})
    require("lspconfig")[server].setup(opts)
  end

  vim.cmd [[
    " Set completeopt to have a better completion experience
    set completeopt=menuone,noinsert,noselect

    " Avoid showing message extra message when using completion
    set shortmess+=c

    autocmd BufWritePre *.tsx EslintFixAll

    autocmd BufWritePre *.tf lua vim.lsp.buf.format()
  ]]

end

return M
