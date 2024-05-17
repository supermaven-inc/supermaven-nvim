# Supermaven Neovim Plugin (BETA)

This plugin, supermaven-nvim, lets you use [Supermaven](https://supermaven.com/) in Neovim. Please note that supermaven-nvim is still in beta and may have bugs and glitches. If you encounter any issues while using supermaven-nvim, consider opening an issue or reaching out to us on [Discord](https://discord.com/invite/QQpqBmQH3w).

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
  debug = false, -- set to true to enable debug logging
  silence_info = false, -- set to true to silence info messages
})
```

## Usage

Upon starting supermaven-nvim, you will be prompted to either use the Free Tier with the command `:SupermavenUseFree` or to activate a Supermaven Pro subscription by following a link, which will connect your Supermaven account.

If Supermaven is set up, you can use `:SupermavenLogout` to switch versions.

You can also use `:SupermavenShowLog` to view the logged messages in `path/to/stdpath-cache/supermaven-nvim.log` if you encounter any issues. Or `:SupermavenClearLog` to clear the log file.
