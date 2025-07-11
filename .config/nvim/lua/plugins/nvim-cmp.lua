local M = {
  enabled = true,
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  -- This plugin must be loaded before tabnine-nvim
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-vsnip",
    "hrsh7th/vim-vsnip",
  }
}

function M.config()
  local status_ok, cmp = pcall(require, "cmp")
  if not status_ok then
    vim.notify("nvim-cmp not found")
    return
  end

  -- VSnip must be required for cmp to work
  -- require 'plugins.config.nvim-vsnip'

  local icons = require 'settings.icons'

  cmp.setup({
    experimental = {
      native_menu = false,
      ghost_text = true,
    },
    snippet = {
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      end,
    },
    mapping = {
      ['<esc>'] = cmp.mapping.close(),
      ['<CR>'] = cmp.mapping.confirm({ select = false }),
      ['<C-Space>'] = cmp.mapping.confirm({ select = true }),
      ['<Tab>'] = function(fallback)
        local cmp = require('cmp')
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end,
      ['<S-Tab>'] = function(fallback)
        local cmp = require('cmp')
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    formatting = {
      fields = {"abbr", "kind", "menu" },
      format = function(entry, vim_item)

        if entry.source.name == "cmp_tabnine" then
          vim_item.kind = icons.tools.Tabnine
          vim_item.kind_hl_group = "CmpItemKindTabnine"
        end

        if entry.source.name == "copilot" then
          vim_item.kind = icons.tools.Copilot
          vim_item.kind_hl_group = "CmpItemKindCopilot"
        end

        -- NOTE: order matters
        -- vim_item.menu = ({
        --   nvim_lsp = "",
        --   nvim_lua = "",
        --   luasnip = "",
        --   buffer = "",
        --   path = "",
        --   emoji = "",
        -- })[entry.source.name]
        return vim_item
      end,
    },
    sources = {
      { 
        name = 'nvim_lsp',
        max_item_count = 10,
        group_index =2,
        entry_filter = function(entry, ctx)
          local isSorbetUntyped = not (
             string.find(entry:get_word(),  'T.untyped') 
          or string.find(entry:get_word(),  'file is not `# typed: true` or higher') 
          )

          return isSorbetUntyped
        end
      },
      -- { name = 'cmp_tabnine', group_index = 2 },
      { name = "copilot", group_index = 2 },
      { 
        name = 'buffer',
        group_index = 2,
        option = {
          get_bufnrs = function()
            return vim.api.nvim_list_bufs()
          end
        }
      },
      { name = 'vsnip', group_index = 2},
      { name = 'path', group_index = 4},
    }
  })
  
  -- Show/Hide copilot suggestion based when the cmp menu is visible
  --cmp.event:on("menu_opened", function()
  --  vim.b.copilot_suggestion_hidden = true
  --end)

  --cmp.event:on("menu_closed", function()
  --  vim.b.copilot_suggestion_hidden = false
  --end)


  vim.cmd [[
    imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
    smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
    imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
    smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
  ]]
  -- inoremap <C-x> <Cmd>lua require('cmp').complete({ config = { sources = { { name = 'copilot' } } } })<CR>
end

return M
