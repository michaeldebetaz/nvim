return {
	-- Theme Catppuccin
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
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
		vim.cmd.hi("Comment gui=none")
	end,
}
