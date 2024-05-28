local util = require("refact-neovim.util")
local config = require("refact-neovim.config")
local lsp = vim.lsp
local api = vim.api
local fn = vim.fn

local M = {
  setup_done = false,
  client_id = nil
}

local function get_bin_url()
  local os_uname = vim.uv.os_uname()
  local arch = os_uname.machine
  local os = os_uname.sysname

  -- todo: put urls to download binary, instead of source code
  local dist_map = {
    x86_64_Linux = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
    armv7l_Linux = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
    arm64_Linux = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
    x86_64_Windows = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
    i686_Windows = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
    arm64_Windows = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
    x86_64_Darwin = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
    arm64_Darwin = "https://github.com/smallcloudai/refact-lsp/archive/refs/tags/v0.8.2.zip",
  }

  return dist_map[arch .. "_" .. os]
end

local function download_and_unzip(url, path)
  fn.system("curl -L -o " .. path .. ".zip " .. url)
  fn.system("unzip " .. path .. ".zip -d " .. path .. "-src")
  fn.system("rm " .. path .. ".zip")
  fn.system("cargo build --release --manifest-path=" .. path .. "-src/refact-lsp-0.8.2/Cargo.toml")
  fn.system("mv " .. path .. "-src/refact-lsp-0.8.0/target/release/refact-lsp " .. path)
  fn.system("rm -r " .. path .. "-src")
end

local function download_lsp()
  local url = get_bin_url()
  if url == nil then
    return
  end

  local lsp_bin = config.get().lsp_bin
  if lsp_bin ~= nil then
    if fn.filereadable(lsp_bin) == 0 then
      vim.notify("[REFACT] couldn't find lsp binary: " .. lsp_bin, vim.log.levels.ERROR)
      return nil
    end

    return lsp_bin
  end

  local bin_dir = api.nvim_call_function("stdpath", { "data" }) .. "/refact-neovim/bin"
  fn.system("mkdir -p " .. bin_dir)
  local bin_path = bin_dir .. "/refact-lsp"

  if fn.filereadable(bin_path) == 0 then
    download_and_unzip(url, bin_path)
    vim.notify("[REFACT] successfully downloaded refact-lsp", vim.log.levels.INFO)
  end

  return bin_path
end

function M.extract_generation(response)
  if #response == 0 then
    return ""
  end
  return response[1].code_completion
end

function M.should_do_suggestion()
  local remaining_text = util.get_till_end_of_current_line()
  return remaining_text:match(config.get().completion_expression) ~= nil
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
    max_new_tokens = config.get().max_tokens,
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

local function create_command(path)
  local cmd = {
    path,
    "--address-url", config.get().address_url,
    "--api-key", config.get().api_key,
    "--lsp-stdin-stdout", "1"
  }

  if config.get().insecure_ssl then
    table.insert(cmd, "--insecure")
  end

  if config.get().telemetry_code_snippets then
    table.insert(cmd, "--snippet-telemetry")
  end

  if config.get().vecdb then
    table.insert(cmd, "--vecdb")
  end

  if config.get().ast then
    table.insert(cmd, "--ast")
    local file_limit = config.get().ast_file_limit
    if file_limit ~= 15000 then
      table.insert(cmd, "--ast-index-max-files")
      table.insert(cmd, tostring(file_limit))
    end
  end

  return cmd
end

function M.setup()
  if M.setup_done then
    return
  end

  if config.get().api_key == "" then
    vim.notify("[REFACT] api_key is not set", vim.log.levels.ERROR)
    return
  end

  local path = download_lsp()

  if path == nil then
    vim.notify("[REFACT] failed to download refact-lsp", vim.log.levels.ERROR)
    return
  end

  local cmd = create_command(path)

  local client_id = lsp.start({
    name = "refact",
    cmd = cmd,
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
  })

  if client_id == nil then
    vim.notify("[REFACT] Error starting refact-lsp ", vim.log.levels.ERROR)
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
