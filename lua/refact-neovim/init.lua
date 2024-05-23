local refact_lsp = require("refact-neovim.lsp")
local util = require("refact-neovim.util")
local completion = require("refact-neovim.completion")

local api = vim.api
local accept_keymap = "<Tab>"

local function setup()
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

  vim.keymap.set("i", accept_keymap, completion.accept_suggestion, { expr = true })
end

return {
  setup = setup
}
