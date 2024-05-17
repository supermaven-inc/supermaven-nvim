---@class SupermavenConfig
---@field log_level LogLevel
---@field ignore_filetypes string[]
local default_config = {
	keymaps = {
		accept_suggestion = "<Tab>",
		clear_suggestion = "<C-]>",
		accept_word = "<C-j>",
	},
  color = {
    suggestion_color = "#ffffff",
    cterm_color = 244,
  },
	ignore_filetypes = {},
	debug = false,
	silence_info = false,
	log_level = "warn",
	__setup = false,
}

local M = {}

local config = default_config

--- Get the type of the value
---@param key string: key in the config table
---@return string: type of the value
---@return boolean: whether the value is optional
local wanted_type = function(key)
	if vim.startswith(key, "__") then
		return "nil", true
	end
	return type(default_config[key]), true
end

--- Validate the config table
---@param args table: config table
---@return table: validated config table
local validate_config = function(args)
	local to_check, validated = {}, {}

	---@diagnostic disable-next-line: unused-function
	local function get_wanted_type(config_table)
		for key in pairs(config_table) do
			local wanted, optional = wanted_type(key)
			to_check[key] = { args[key], wanted, optional }
			validated[key] = args[key]
		end
	end

	get_wanted_type(config)
	vim.validate(to_check)
	return validated
end

---@class SupermavenConfig
---@field get_config function: SupermavenConfig -> table
--- Get the config table
---@return SupermavenConfig: config table
M.get_config = function()
	return config
end

--- Set the config table
---@param new_config SupermavenConfig: config table
M.__set = function(new_config)
	config = vim.tbl_deep_extend("force", {}, config, new_config or {})
end

--- Reset the config table
--- This is useful when you want to change the config table
--- without having to restart Neovim.
M.reset_config = function()
	config = default_config
end

--- Set the config table
---@param args SupermavenConfig: config table
M.setup_config = function(args)
	if config.__setup then
		return
	end
	local validated_config = validate_config(args)

	config = vim.tbl_extend("force", config, validated_config)

	config.__setup = true
end

return M
