describe("[supermaven-nvim tests]", function()
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
			local actual = require("supermaven-nvim").setup()
			local expected = require("supermaven-nvim.config").config

			assert.are.same(actual, expected, "default config should be set")
		end)

		it("should set up the plugin with a custom config", function()
			local actual = require("supermaven-nvim").setup({
				keymaps = {
					accept_suggestion = "<C-j>",
					clear_suggestion = "<C-k>",
					accept_word = "<C-l>",
				},
				ignore_filetypes = { cpp = true },
				color = {
					suggestion_color = "#89b4fa",
					cterm = 177,
				},
			})
			local expected = require("supermaven-nvim.config").config

			assert.are.same(actual, expected, "custom config should be set")
		end)
	end)
end)
