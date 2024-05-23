local refact_lsp = require("refact-neovim.lsp")
local config_module = require("refact-neovim.config")
local completion = require("refact-neovim.completion")
local api = vim.api

local function setup(user_config)
  config_module.setup(user_config)
  local config = config_module.get()

  refact_lsp.setup()

  api.nvim_create_autocmd("InsertLeave", {
    callback = completion.cancel
  })

  api.nvim_create_autocmd("InsertEnter", {
    callback = completion.schedule
  })

  api.nvim_create_autocmd("CursorMovedI", {
    callback = completion.schedule
  })

  vim.keymap.set("i", config.accept_keymap, completion.accept_suggestion, { expr = true })
end

return {
  setup = setup
}
