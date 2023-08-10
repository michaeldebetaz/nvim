return {
	-- Theme Catppuccin
	"catppuccin/nvim",
	priority = 999,
	config = function()
		vim.cmd.colorscheme("catppuccin")
	end,
}
