vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
})
require("catppuccin").setup({
	flavour = "mocha",
	highlight_overrides = {
		mocha = function()
			return {
				["@tag.attribute.tsx"] = { fg = "#94e2d5" },
			}
		end,
	},
})
vim.cmd.colorscheme("catppuccin")
