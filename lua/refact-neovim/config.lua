local default_config = {
  max_tokens = 50,
  accept_keymap = "<Tab>",
  debounce_ms = 200,
}

local M = {
  config = vim.deepcopy(default_config),
}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})
end

function M.get()
  return M.config
end

return M
