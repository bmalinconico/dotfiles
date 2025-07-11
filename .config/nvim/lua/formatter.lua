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
  - `formatters`: maps filetypes (or chosen types) to shell commands for formatting. This table is used for both full buffer and visual selection formatting.
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
local formatters = {
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

local function format_buffer_with_cmd(cmd)
  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Error formatting buffer: " .. table.concat(result, "\n"), vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, result)
end

-- Prompt user using vim.ui.select for visual format type
local function format_visual_with_cmd(cmd)
  local srow = vim.fn.line("'<") - 1
  local erow = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, srow, erow, false)
  local input = table.concat(lines, "\n")
  local result = vim.fn.systemlist(cmd, input)
  if vim.v.shell_error ~= 0 then
    vim.notify("Error formatting selection: " .. table.concat(result, "\n"), vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_buf_set_lines(0, srow, erow, false, result)
end

--- Prompt user using vim.ui.select for visual format type
local function prompt_format_type(callback)
  local options = vim.tbl_keys(formatters)
  table.sort(options)
  vim.ui.select(options, { prompt = "Select format type:" }, function(choice)
    if not choice then
      callback(nil)
      return
    end

    callback(choice)
  end)
end

-- Format visual selection
local function format_visual()
  prompt_format_type(function(format_type)
    if not format_type then
      print("No format selected.")
      return
    end

    local cmd = formatters[format_type]
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
  local cmd = formatters[ft]

  if ft == "" or not cmd then
    prompt_format_type(function(format_type)
      local cmd = formatters[format_type]
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
