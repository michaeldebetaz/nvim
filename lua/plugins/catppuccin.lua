return {
	-- Theme Catppuccin
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	opts = {
		flavour = "mocha",
		highlight_overrides = {
			mocha = function()
				return {
					["@tag.attribute.tsx"] = { fg = "#94e2d5" },
				}
			end,
		},
	},
}
