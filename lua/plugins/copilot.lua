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
					vim.notify("Copilot is enabled", vim.log.levels.WARN)
				else
					require("copilot.command").disable()
					vim.notify("Copilot is disabled", vim.log.levels.WARN)
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
					accept_word = "<C-e>",
					accept_line = "<C-l>",
					accept = "<M-l>",
				},
			},
		})
	end,
}
