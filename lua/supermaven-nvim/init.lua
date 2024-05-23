local binary = require("supermaven-nvim.binary.binary_handler")
local completion_preview = require("supermaven-nvim.completion_preview")
local _u = require("supermaven-nvim.util")
local _listener = require("supermaven-nvim.document_listener")
local config = require("supermaven-nvim.config")
local log = require("supermaven-nvim.logger")

local M = {}

M.setup = function(args)
	if config.get_config().__setup then
		return
	end

	args = args or {}
	config.setup_config(args)
  local config_settings = config.get_config()

  if config_settings.disable_inline_completion then
    completion_preview.disable_inline_completion = true
  elseif not config_settings.disable_keymaps then
    if config_settings.keymaps.accept_suggestion ~= nil then
      local accept_suggestion_key = config_settings.keymaps.accept_suggestion
      vim.keymap.set('i', accept_suggestion_key, completion_preview.on_accept_suggestion,
        { noremap = true, silent = true })
    end

    if config_settings.keymaps.accept_word ~= nil then
      local accept_word_key = config_settings.keymaps.accept_word
      vim.keymap.set('i', accept_word_key, completion_preview.on_accept_suggestion_word,
        { noremap = true, silent = true })
    end

    if config_settings.keymaps.clear_suggestion ~= nil then
      local clear_suggestion_key = config_settings.keymaps.clear_suggestion
      vim.keymap.set('i', clear_suggestion_key, completion_preview.on_dispose_inlay, { noremap = true, silent = true })
    end
  end

  binary:start_binary(config_settings.ignore_filetypes or {})

  if config_settings.color and config_settings.color.suggestion_color and config_settings.color.cterm then
    vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
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

	vim.api.nvim_create_user_command("SupermavenShowLog", function()
    local log_path = require("supermaven-nvim.logger"):get_log_path()
    if log_path ~= nil then
      vim.cmd(string.format(":e %s", log_path))
    else
      log:warn("No log file found to show!")
    end
	end, {})

  vim.api.nvim_create_user_command("SupermavenClearLog", function()
    local log_path = require("supermaven-nvim.logger"):get_log_path()
    if log_path ~= nil then
      vim.loop.fs_unlink(log_path)
      else
        log:warn("No log file found to remove!")
    end
  end, {})

  local cmp_ok, cmp = pcall(require, "cmp")
  if cmp_ok then
    local cmp_source = require("supermaven-nvim.cmp")
    cmp.register_source("supermaven", cmp_source.new())
  else
    if config_settings.disable_inline_completion then
      log:warn(
        "nvim-cmp is not available, but inline completion is disabled. Supermaven nvim-cmp source will not be registered."
      )
    end
  end
end

return M
