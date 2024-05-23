local util = require("refact-neovim.util")
local config = require("refact-neovim.config").get()
local lsp = vim.lsp
local api = vim.api

local M = {
  setup_done = false,
  client_id = nil
}

function M.extract_generation(response)
  if #response == 0 then
    return ""
  end
  return response[1].code_completion
end

function M.should_do_suggestion()
  local remaining_text = util.get_till_end_of_current_line()
  return remaining_text:match(config.completion_expression) ~= nil
end

function M.should_do_multiline()
  return util.is_only_white_space(util.get_current_line())
end

function M.get_completions(callback)
  if M.client_id == nil then
    vim.notify("client_id is nil", vim.log.levels.WARN)
    return
  end
  if not lsp.buf_is_attached(0, M.client_id) then
    vim.notify("buffer is not attached", vim.log.levels.WARN)
    return
  end

  local params = lsp.util.make_position_params()
  params.parameters = {
    temperature = 0.1,
    max_new_tokens = config.max_tokens,
  }
  params.multiline = M.should_do_multiline()

  if params.multiline then
    params.position.character = 0
  end

  local client = lsp.get_client_by_id(M.client_id)
  if client ~= nil then
    local status, request_id = client.request("refact/getCompletions", params, callback, 0)

    if not status then
      vim.notify("[REFACT] request 'refact/getCompletions' failed", vim.log.levels.WARN)
    end

    return request_id
  else
    return nil
  end
end

function M.setup()
  if M.setup_done then
    return
  end

  local cmd = lsp.rpc.connect("127.0.0.1", 8002)

  local client_id = lsp.start({
    name = "refact",
    cmd = cmd,
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
  })

  if client_id == nil then
    vim.notify("[REFACT] Error starting refact-lsp", vim.log.levels.ERROR)
    return
  end

  local augroup = "refact.language_server"

  api.nvim_create_augroup(augroup, { clear = true })

  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = "*",
    callback = function(ev)
      if not lsp.buf_is_attached(ev.buf, client_id) then
        lsp.buf_attach_client(ev.buf, client_id)
      end
    end,
  })
  M.client_id = client_id

  api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      lsp.stop_client(client_id)
    end,
  })

  M.setup_done = true
end

return M
