local binary = require("supermaven-nvim.binary.binary_handler")
local completion_preview = require("supermaven-nvim.completion_preview")
local u = require("supermaven-nvim.util")
local listener = require("supermaven-nvim.document_listener")
local config = require("supermaven-nvim.config")

M = {}

M.setup = function(args)
  local config_settings = config.setup_config(args)
  if config_settings.keymaps.accept_suggestion ~= nil then
    local accept_suggestion_key = config_settings.keymaps.accept_suggestion
    vim.keymap.set('i', accept_suggestion_key, completion_preview.on_accept_suggestion, { noremap = true, silent = true })
  end

  if config_settings.keymaps.accept_word ~= nil then
    local accept_word_key = config_settings.keymaps.accept_word
    vim.keymap.set('i', accept_word_key, completion_preview.on_accept_suggestion_word, { noremap = true, silent = true })
  end

  if config_settings.keymaps.clear_suggestion ~= nil then
    local clear_suggestion_key = config_settings.keymaps.clear_suggestion
    vim.keymap.set('i', clear_suggestion_key, completion_preview.on_dispose_inlay, { noremap = true, silent = true })
  end
  binary:start_binary(config_settings.ignore_filetypes or {})

  if config_settings.color and config_settings.color.suggestion_color and config_settings.color.cterm then
    vim.api.nvim_create_autocmd({"VimEnter", "ColorScheme"}, {
      pattern = "*",
      callback = function(event)
        vim.api.nvim_set_hl(0, "SupermavenSuggestion", { 
          fg = config_settings.color.suggestion_color,
          ctermfg = config_settings.color.cterm,
        })
        completion_preview.suggestion_group = "SupermavenSuggestion"
      end
    })
  end
end

return M
