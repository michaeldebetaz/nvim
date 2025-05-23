return {
	-- Github Copilot
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
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
