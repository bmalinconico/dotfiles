--[[
smart_format.nvim

This module provides a smart formatting command for Neovim that formats either the entire buffer or a visually selected range,
depending on user context. The formatting behavior is:

1. NORMAL MODE (entire buffer formatting):
   - If the active LSP client supports document formatting, it will be used.
   - If no LSP supports formatting, fall back to an external formatter command based on filetype.
   - If filetype is blank or unrecognized, present a `vim.ui.select()` menu to the user to choose a known content type,
     then use the corresponding formatter command.

2. VISUAL MODE (selected range formatting):
   - Present a `vim.ui.select()` menu to choose the content type (e.g., json, sql, xml, etc.).
   - Users can select the format type by either choosing the numeric option or typing the file type directly.
   - Pipe the selected lines through the matching external formatter command.

Design Goals:
- Avoid deprecated Neovim APIs (e.g., use `vim.lsp.get_clients()` instead of `get_active_clients()`).
- Use `vim.ui.select()` for clean, extensible UI prompts. Compatible with built-in UI or plugins like dressing.nvim.
- Easy extensibility:
    - `filetype_formatters`: maps filetypes (or chosen types) to shell commands for full buffer formatting.
    - `visual_formatters`: same as above, used during visual selection (can be the same table).
- External formatters are shell commands that read from stdin and write to stdout.
- Formatter commands must not require file paths; they operate on piped content.

Exposed Commands:
- `:SmartFormat` — the main entry point. Can be called in normal or visual mode.

Key Considerations:
- This plugin does not auto-install or verify formatters — users are responsible for installing them (e.g., jq, shfmt).
- No async shell formatting — formatting commands are synchronous.
- Designed to be compatible with lazy.nvim or manual loading in init.lua.
]]

local M = {}

-- External formatters fallback by filetype
local filetype_formatters = {
  json = "jq .",
  sql = "pg_format",
}

-- Visual selection formatters (prompt-based)
local visual_formatters = {
  json = "jq .",
  sql = "pg_format",
}
-- Check if LSP supports formatting
local function has_lsp_formatter()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    if client.server_capabilities.documentFormattingProvider then
      return true
    end
  end
  return false
end

-- Format buffer using external command
local function format_buffer_with_cmd(cmd)
  vim.cmd("silent %!" .. cmd)
end

-- Format visual range using external command
local function format_visual_with_cmd(cmd)
  local srow = vim.fn.line("'<")
  local erow = vim.fn.line("'>")
  vim.cmd(string.format("silent %d,%d!%s", srow, erow, cmd))
end

-- Prompt user using vim.ui.select for visual format type
local function prompt_format_type(callback)
  local options = vim.tbl_keys(visual_formatters)
  table.sort(options)
  vim.ui.select(options, { prompt = "Select format type:" }, function(choice)
    if not choice then
      callback(nil)
      return
    end

    local selected_index = tonumber(choice:match("^(%d+)%."))
    if selected_index then
      callback(options[selected_index])
      return
    end

    local input_type = choice:match("%s*(%S+)%s*")
    if vim.tbl_contains(options, input_type) then
      callback(input_type)
    else
      print("Invalid format type: " .. choice)
      callback(nil)
    end
  end)
end

-- Format visual selection
local function format_visual()
  prompt_format_type(function(format_type)
    if not format_type then
      print("No format selected.")
      return
    end

    local cmd = visual_formatters[format_type]
    if not cmd then
      print("No formatter defined for: " .. format_type)
      return
    end

    format_visual_with_cmd(cmd)
  end)
end

-- Format entire buffer
local function format_buffer()
  if has_lsp_formatter() then
    vim.lsp.buf.format({ async = true })
    return
  end

  local ft = vim.bo.filetype
  local cmd = filetype_formatters[ft]

  if ft == "" or not cmd then
    prompt_format_type(function(format_type)
      local fallback_cmd = filetype_formatters[format_type]
      if fallback_cmd then
        format_buffer_with_cmd(fallback_cmd)
      else
        print("No formatter for selected type.")
      end
    end)
    return
  end

  format_buffer_with_cmd(cmd)
end

-- Main smart format dispatcher
function M.smart_format()
  local mode = vim.fn.mode()
  if mode:match("[vV]") then
    format_visual()
  else
    format_buffer()
  end
end

-- Register the command
vim.api.nvim_create_user_command("SmartFormat", M.smart_format, { range = true })

return M
