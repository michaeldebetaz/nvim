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
					accept = "<Tab>",
					accept_word = false,
					accept_line = false,
					next = "<C-]>",
					prev = "<C-[>",
					dismiss = "<A-0>",
				},
			},
			copilot_node_command = vim.fn.expand("$HOME") .. "/.nvm/versions/node/v20.10.0/bin/node", -- Node.js version must be > 18.x
		})
	end,
}
