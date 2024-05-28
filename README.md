# refact-neovim

Refact for Neovim is a free, open-source AI code assistant.

## Installation

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'smallcloudai/refact-neovim',
  config = function()
    require('refact-neovim').setup({
      address_url = "Refact",
      api_key = <API_KEY>,
      lsp_bin = <PATH_TO_LSP_BIN>,
    })
  end
}
```

### Lualine

Refact-neovim is compatible with [lualine](https://github.com/nvim-lualine/lualine.nvim).
Example configuration:

```lua
require('lualine').setup({
  sections = {
    lualine_x = {
      require("refact-neovim").status_line,
    },
  },
})
