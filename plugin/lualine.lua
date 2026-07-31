vim.pack.add({
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/nvim-lualine/lualine.nvim",
})
require("lualine").setup({
	options = {
		icons_enabled = false,
		component_separators = { left = "|", right = "|" },
		section_separators = { left = "", right = "" },
		theme = "auto",
	},
})
