local binary = require("supermaven-nvim.binary.binary_handler")
local completion_preview = require("supermaven-nvim.completion_preview")
local listener = require("supermaven-nvim.document_listener")
local config = require("supermaven-nvim.config")

local M = {}

M.setup = function(args)
  config.setup(args)

  if config.disable_inline_completion then
    completion_preview.disable_inline_completion = true
  elseif not config.disable_keymaps then
    if config.keymaps.accept_suggestion ~= nil then
      local accept_suggestion_key = config.keymaps.accept_suggestion
      vim.keymap.set('i', accept_suggestion_key, completion_preview.on_accept_suggestion,
        { noremap = true, silent = true })
    end

    if config.keymaps.accept_word ~= nil then
      local accept_word_key = config.keymaps.accept_word
      vim.keymap.set('i', accept_word_key, completion_preview.on_accept_suggestion_word,
        { noremap = true, silent = true })
    end

    if config.keymaps.clear_suggestion ~= nil then
      local clear_suggestion_key = config.keymaps.clear_suggestion
      vim.keymap.set('i', clear_suggestion_key, completion_preview.on_dispose_inlay, { noremap = true, silent = true })
    end
  end

  binary:start_binary()

  if config.color and config.color.suggestion_color and config.color.cterm then
    vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
      pattern = "*",
      callback = function(event)
        vim.api.nvim_set_hl(0, "SupermavenSuggestion", {
          fg = config.color.suggestion_color,
          ctermfg = config.color.cterm,
        })
        completion_preview.suggestion_group = "SupermavenSuggestion"
      end
    })
  end

  local cmp_ok, cmp = pcall(require, "cmp")
  if cmp_ok then
    local cmp_source = require("supermaven-nvim.cmp")
    cmp.register_source("supermaven", cmp_source.new())
  else
    if config.disable_inline_completion then
      vim.notify(
        "nvim-cmp is not available, but inline completion is disabled. Supermaven nvim-cmp source will not be registered.",
        vim.log.levels.WARN)
    end
  end
end

return M
