return {
	"dmmulroy/tsc.nvim",
	config = function()
		require("tsc").setup({
			use_trouble_qflist = true,
		})
		vim.keymap.set("n", "<leader>to", vim.cmd.TSCOpen)
		vim.keymap.set("n", "<leader>tc", vim.cmd.TSCClose)
	end,
}
