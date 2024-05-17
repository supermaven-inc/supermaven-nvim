local default_config = {
	keymaps = {
		accept_suggestion = "<Tab>",
		clear_suggestion = "<C-]>",
		accept_word = "<C-j>",
	},
	ignore_filetypes = {},
	debug = false,
	silence_info = false,
	log_level = "warn",
	__setup = false,
}

local M = {}

local config = vim.deepcopy(default_config)

local wanted_type = function(key)
	if vim.startswith(key, "__") then
		return "nil", true
	end
	return type(default_config[key]), true
end

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

M.get_config = function()
	return config
end

M.__set = function(new_config)
	config = vim.tbl_deep_extend("force", {}, config, new_config or {})
end

M.reset_config = function()
	config = vim.deepcopy(default_config)
end

M.setup_config = function(args)
	if config.__setup then
		return
	end
	local validated_config = validate_config(args)

	config = vim.tbl_extend("force", config, validated_config)

	config.__setup = true
end

return M
