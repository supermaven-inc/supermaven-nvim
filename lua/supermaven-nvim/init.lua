local binary = require("supermaven-nvim.binary.binary_handler")
local completion_preview = require("supermaven-nvim.completion_preview")
local u = require("supermaven-nvim.util")
local listener = require("supermaven-nvim.document_listener")
local supermave_config = require("supermaven-nvim.config")

---@class Supermaven
M = {}

---@class Supermaven
---@field config SupermavenConfig
M.config = {}

---@class Supermaven
---@field setup function
--- Sets up the plugin with the given a custom configuration (args)
--- or the default configuration.
---
--- The default configuration is:
---
--- ```lua
--- require("supermaven-nvim").setup({
---   keymaps = {
---     accept_suggestion = "<Tab>",
---     clear_suggestion = "<C-]>",
---     accept_word = "<C-j>",
---   },
---   ignore_filetypes = {},
--- })
--- ```
---
---Or you can pass a custom configuration:
---
---[link to the configuration section](https://github.com/supermaven-nvim/supermaven-nvim/blob/main/lua/supermaven-nvim/config.lua)
---
---@see SupermavenConfig
---@param args SupermavenConfig
M.setup = function(args)
  M.config = supermave_config.setup_config(args)
  if M.config.keymaps.accept_suggestion ~= nil then
    local accept_suggestion_key = M.config.keymaps.accept_suggestion
    vim.keymap.set('i', accept_suggestion_key, completion_preview.on_accept_suggestion, { noremap = true, silent = true })
  end

  if M.config.keymaps.accept_word ~= nil then
    local accept_word_key = M.config.keymaps.accept_word
    vim.keymap.set('i', accept_word_key, completion_preview.on_accept_suggestion_word, { noremap = true, silent = true })
  end

  if M.config.keymaps.clear_suggestion ~= nil then
    local clear_suggestion_key = M.config.keymaps.clear_suggestion
    vim.keymap.set('i', clear_suggestion_key, completion_preview.on_dispose_inlay, { noremap = true, silent = true })
  end
  binary:start_binary(M.config.ignore_filetypes or {})

  if M.config.color and M.config.color.suggestion_color and M.config.color.cterm then
    vim.api.nvim_create_autocmd({"VimEnter", "ColorScheme"}, {
      pattern = "*",
      callback = function(_)
        vim.api.nvim_set_hl(0, "SupermavenSuggestion", {
          fg = M.config.color.suggestion_color,
          ctermfg = M.config.color.cterm,
        })
        completion_preview.suggestion_group = "SupermavenSuggestion"
      end
    })
  end
end

return M
