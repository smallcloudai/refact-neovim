local refact_lsp = require("refact-neovim.lsp")
local config = require("refact-neovim.config")
local completion = require("refact-neovim.completion")
local status_line = require("refact-neovim.status_line")
local api = vim.api

local function setup(user_config)
  config.setup(user_config)

  -- todo: figure out why the lsp is not able to startup correctly without this timer
  vim.fn.timer_start(0, function()
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

    vim.keymap.set("i", config.get().accept_keymap, completion.accept_suggestion, { expr = true })

    local pause_keymap = config.get().pause_keymap
    if pause_keymap ~= nil then
      vim.keymap.set("i", pause_keymap, completion.toggle_pause, { expr = true })
    end
  end)
end

return {
  setup = setup,
  status_line = status_line,
}
