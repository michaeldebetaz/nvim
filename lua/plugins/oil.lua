return {
	"stevearc/oil.nvim",
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	config = function()
		---@modules oil
		local oil = require("oil")

		oil.setup({ view_options = { show_hidden = true } })

		vim.keymap.set("n", "-", oil.open, { desc = "Open parent directory" })
	end,
}
