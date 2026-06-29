vim.pack.add({ "https://github.com/catppuccin/nvim" })
require("catppuccin").setup({
	flavour = "mocha",
	styles = {
		syntax = { old_colors = true },
	},
	highlight_overrides = {
		mocha = function()
			return {
				["@tag.attribute.tsx"] = { fg = "#94e2d5" },
			}
		end,
	},
})
vim.cmd.colorscheme("catppuccin")
