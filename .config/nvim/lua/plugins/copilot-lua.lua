
local M = {
  enabled = true,
  "zbirenbaum/copilot.lua",
  event = "InsertEnter",
  keys = {
    { "<C-k>", function() require("copilot.suggestion").accept_word() end, mode = "i" },
    { "<C-l>", function() require("copilot.suggestion").accept_line() end, mode = "i" },
    { "<C-j>", function() require("copilot.suggestion").accept() end, mode = "i" },
  },
}

function M.config()
  vim.defer_fn(function()

    local status_ok, copilot = pcall(require, "copilot")
    if not status_ok then
      vim.notify("copilot not found")
    else
      copilot.setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
        }
      })
    end

  end, 100)
end

return M
