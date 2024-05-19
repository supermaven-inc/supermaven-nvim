---@class SupermavenKeymap
---@field accept_suggestion string: The keymap to accept the suggestion.
---@field clear_suggestion string: The keymap to clear the suggestion.
---@field accept_word string: The keymap to accept the word under the cursor.

---@class SupermavenColor
---@field suggestion_color string|nil: The color of the suggestion.
---@field cterm string|nil: The color of the suggestion in the terminal.

---@class SupermavenConfig
---@field keymaps table<string, string>: The keymaps to use for the plugin.
---@field ignore_filetypes table<string, string>: The filetypes to ignore.
---@field color SupermavenColor|nil: The color of the suggestion.

local default_config = {
  keymaps = {
    accept_suggestion = "<Tab>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = {},
  disable_inline_completion = false,
  disable_keymaps = false
}

M = {}

---@class SupermavenConfig
---@field default_config SupermavenConfig: The default configuration.
M.default_config = default_config

---@class SupermavenConfig
---@field setup_config function: Sets up the configuration.
--- Sets up the configuration with the default values and the given custom values.
---@param args SupermavenConfig|nil
---@return SupermavenConfig
M.setup_config = function(args)
	local config = vim.tbl_deep_extend("force", {}, default_config, args or {})
	return config
end

return M