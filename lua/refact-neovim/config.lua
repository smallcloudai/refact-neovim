local default_config = {
  max_tokens = 50,
  accept_keymap = "<Tab>",
  debounce_ms = 200,
  completion_expression = "^[%s%]:(){},.\"';>]*$",
  --- @type string | nil
  lsp_bin = nil,
  address_url = "Refact",
  api_key = "",
}

local M = {
  config = nil,
}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})
end

function M.get()
  if M.config == nil then
    vim.notify("[REFACT] config is not initialized", vim.log.levels.ERROR)
    return nil
  end

  return M.config
end

return M
