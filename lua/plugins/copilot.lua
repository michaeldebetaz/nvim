return {
	-- Github Copilot
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	keys = {
		{
			"<leader>cp",
			function()
				if require("copilot.client").is_disabled() then
					require("copilot.command").enable()
					vim.notify("Copilot enabled", vim.log.levels.INFO)
				else
					require("copilot.command").disable()
					vim.notify("Copilot disabled", vim.log.levels.INFO)
				end
			end,
			desc = "Toggle (Copilot)",
		},
	},
	config = function()
		require("copilot").setup({
			suggestion = {
				auto_trigger = true,
				keymap = {
					accept_word = "<C-y>",
					accept_line = "<C-l>",
					accept = "<M-l>",
				},
			},
		})
	end,
}
