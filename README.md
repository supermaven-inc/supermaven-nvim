# Supermaven Neovim Plugin

This plugin, supermaven-nvim, lets you use [Supermaven](https://supermaven.com/) in Neovim. If you encounter any issues while using supermaven-nvim, consider opening an issue or reaching out to us on [Discord](https://discord.com/invite/QQpqBmQH3w).

## Installation

Using a plugin manager, run the .setup({}) function in your Neovim configuration file.

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require("lazy").setup({
    {
      "supermaven-inc/supermaven-nvim",
      config = function()
        require("supermaven-nvim").setup({})
      end,
    },
}, {})
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "supermaven-inc/supermaven-nvim",
  config = function()
    require("supermaven-nvim").setup({})
  end,
}
```

### Optional configuration

By default, supermaven-nvim will use the `<Tab>` and `<C-]>` keymaps to accept and clear suggestions. You can change these keymaps by passing a `keymaps` table to the .setup({}) function. Also in this table is `accept_word`, which allows partially accepting a completion, up to the end of the next word. By default this keymap is set to `<C-j>`.

The `ignore_filetypes` table is used to ignore filetypes when using supermaven-nvim. If a filetype is present as a key, and its value is `true`, supermaven-nvim will not display suggestions for that filetype.

`suggestion_color` and `cterm` options can be used to set the color of the suggestion text.

```lua
require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<Tab>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = { cpp = true },
  color = {
    suggestion_color = "#ffffff",
    cterm = 244,
  },
  disable_inline_completion = false, -- disables inline completion for use with cmp
  disable_keymaps = false -- disables built in keymaps for more manual control
})
```

### Using with nvim-cmp

If you are using nvim-cmp, you can use the `supermaven` source (which is registered by default) by adding the following to your `cmp.setup()` function:

```lua
-- cmp.lua
cmp.setup {
  ...
  sources = {
    { name = "supermaven" },
  }
  ...
}
```

It also has a builtin highlight group CmpItemKindSupermaven. To add an icon to Supermaven for lspkind, simply add Supermaven to your lspkind symbol map.

```lua
-- lspkind.lua
local lspkind = require("lspkind")
lspkind.init({
  symbol_map = {
    Supermaven = "",
  },
})

vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", {fg ="#6CC644"})
```

Alternatively, you can add Supermaven to the lspkind symbol_map within the cmp format function.

```lua
-- cmp.lua
cmp.setup {
  ...
  formatting = {
    format = lspkind.cmp_format({
      mode = "symbol",
      max_width = 50,
      symbol_map = { Supermaven = "" }
    })
  }
  ...
}
```

### Programatically checking and accepting suggestions

Alternatively, you can also check if there is an active suggestion and accept it programatically.

For example:

```lua
require("supermaven-nvim").setup({
  disable_keymaps = true
})

...

M.expand = function(fallback)
  local luasnip = require('luasnip')
  local suggestion = require('supermaven-nvim.completion_preview')

  if luasnip.expandable() then
    luasnip.expand()
  elseif suggestion.has_suggestion() then
    suggestion.on_accept_suggestion()
  else
    fallback()
  end
end
```

## Usage

Upon starting supermaven-nvim, you will be prompted to either use the Free Tier with the command `:SupermavenUseFree` or to activate a Supermaven Pro subscription by following a link, which will connect your Supermaven account.

If Supermaven is set up, you can use `:SupermavenLogout` to switch versions.

### Commands

Supermaven-nvim provides the following commands:

```
:SupermavenStart   start supermaven-nvim
:SupermavenStop    stop supermaven-nvim
:SupermavenRestart restart supermaven-nvim
:SupermavenStatus  show status of supermaven-nvim
:SupermavenUseFree switch to the free version
:SupermavenUsePro  switch to the pro version
:SupermavenLogout  log out of supermaven
```

### Lua API

The `supermaven-nvim.api` module provides the following functions for interacting with supermaven-nvim from Lua:

```lua
local api = require("supermaven-nvim.api")

api.start() -- starts supermaven-nvim
api.stop() -- stops supermaven-nvim
api.restart() -- restarts supermaven-nvim if it is running, otherwise starts it
api.is_running() -- returns true if supermaven-nvim is running
api.use_free_version() -- switch to the free version
api.use_pro() -- switch to the pro version
api.logout() -- log out of supermaven
```
