local refact_lsp = require("refact-neovim.lsp")
local util = require("refact-neovim.util")
local config = require("refact-neovim.config")
local api = vim.api
local fn = vim.fn

local M = {
  suggestion = nil,
  timer = nil,
  ns_id = api.nvim_create_namespace("refact.suggestion"),
}


local function stop_timer()
  if M.timer then
    fn.timer_stop(M.timer)
    M.timer = nil
  end
end

local function clear_preview()
  api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
end

local function show_suggestion()
  clear_preview()
  refact_lsp.get_completions(function(err, result)
    if err ~= nil then
      vim.notify("[REFACT] " .. err.message, vim.log.levels.ERROR)
      return
    end

    local generated_text = refact_lsp.extract_generation(result.choices)
    local lines = util.split_str(generated_text, "\n")

    local line, col = util.get_cursor_pos()
    local extmark = {
      virt_text = { { lines[1], "Comment" } }
    }
    if refact_lsp.should_do_multiline() then
      extmark.virt_lines = {}
      extmark.virt_text_win_col = 0
      for i = 2, #lines do
        extmark.virt_lines[i - 1] = { { lines[i], "Comment" } }
      end
    else
      extmark.virt_text_win_col = col
    end

    M.suggestion = lines
    api.nvim_buf_set_extmark(0, M.ns_id, line - 1, col, extmark)
  end)
end

function M.cancel()
  clear_preview()
  stop_timer()
end

function M.schedule()
  M.cancel()

  if not refact_lsp.should_do_suggestion() then
    return
  end

  M.timer = fn.timer_start(config.get().debounce_ms, function()
    if fn.mode() == "i" then
      show_suggestion()
    end
  end)
end

local function complete()
  if M.suggestion == nil then
    return
  end

  if refact_lsp.should_do_multiline() or #M.suggestion > 1 then
    local line, _ = util.get_cursor_pos()
    api.nvim_buf_set_lines(0, line - 1, line, false, M.suggestion)

    local new_line = line + #M.suggestion - 1
    local new_col = string.len(M.suggestion[#M.suggestion]) + 1
    api.nvim_win_set_cursor(0, { new_line, new_col })
  else
    local line, col = util.get_cursor_pos()
    local current_line = util.get_current_line()
    current_line = current_line:sub(1, col)
    api.nvim_buf_set_lines(0, line - 1, line, false, { current_line .. M.suggestion[1] })
    api.nvim_win_set_cursor(0, { line, col + string.len(M.suggestion[1]) })
  end
  M.suggestion = nil
end

function M.accept_suggestion()
  clear_preview()
  vim.schedule(complete)
end

return M
