describe("setup", function()
	it("should set up the plugin's user commands", function()
		require("supermaven-nvim").setup()
		local user_commands = vim.api.nvim_get_commands({})
		-- User commands = SupermmaveUserFree
		assert.are.not_same(user_commands["SupermavenUseFree"], nil, "SupermavenUseFree command should be set up")
		assert.are.not_same(user_commands["SupermavenUsePro"], nil, "SupermavenUsePro command should be set up")
		assert.are.not_same(user_commands["SupermavenLogout"], nil, "SupermavenLogout command should be set up")
	end)

	it("should set up the plugin with the default config", function()
		require("supermaven-nvim").setup()
		assert.are.same(require("supermaven-nvim").config, {
			keymaps = {
				accept_suggestion = "<Tab>",
				clear_suggestion = "<C-]>",
				accept_word = "<C-j>",
			},
			ignore_filetypes = {},
		}, "default config should be set")
	end)

	it("should set up the plugin with a custom config", function()
		require("supermaven-nvim").setup({
			keymaps = {
				accept_suggestion = "<C-j>",
				clear_suggestion = "<C-k>",
				accept_word = "<C-l>",
			},
			ignore_filetypes = { cpp = true },
			color = {
				suggestion_color = "#ffffff",
				cterm = 244,
			},
		})
		assert.are.same(require("supermaven-nvim").config, {
			keymaps = {
				accept_suggestion = "<C-j>",
				clear_suggestion = "<C-k>",
				accept_word = "<C-l>",
			},
			ignore_filetypes = { cpp = true },
			color = {
				suggestion_color = "#ffffff",
				cterm = 244,
			},
		}, "custom config should be set")
	end)
end)
