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
	config = config.get_config()
	if config.keymaps.accept_suggestion ~= nil then
		local accept_suggestion_key = config.keymaps.accept_suggestion
		vim.keymap.set(
			"i",
			accept_suggestion_key,
			completion_preview.on_accept_suggestion,
			{ noremap = true, silent = true }
		)
	end

	if config.keymaps.accept_word ~= nil then
		local accept_word_key = config.keymaps.accept_word
		vim.keymap.set(
			"i",
			accept_word_key,
			completion_preview.on_accept_suggestion_word,
			{ noremap = true, silent = true }
		)
	end

	if config.keymaps.clear_suggestion ~= nil then
		local clear_suggestion_key = config.keymaps.clear_suggestion
		vim.keymap.set(
			"i",
			clear_suggestion_key,
			completion_preview.on_dispose_inlay,
			{ noremap = true, silent = true }
		)
	end
	binary:start_binary(config.ignore_filetypes or {})

	if config.color and config.color.suggestion_color and config.color.cterm then
		vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
			pattern = "*",
			callback = function(event)
				vim.api.nvim_set_hl(0, "SupermavenSuggestion", {
					fg = config.color.suggestion_color,
					ctermfg = config.color.cterm,
				})
				completion_preview.suggestion_group = "SupermavenSuggestion"
			end,
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
end

return M
