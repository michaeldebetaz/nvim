return {
	-- Set lualine as statusline
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		---@diagnostic disable-next-line: undefined-field
		require("lualine").setup({
			options = {
				icons_enabled = false,
				component_separators = { left = "|", right = "|" },
				section_separators = { left = "", right = "" },
				theme = "auto",
			},
		})
	end,
}
