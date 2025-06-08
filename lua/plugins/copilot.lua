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
				else
					require("copilot.command").disable()
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
					accept = "<C-l>",
					accept_line = "<M-l>",
				},
			},
		})
	end,
}
