return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		require("nvim-tree").setup({})
	end,

	on_attach = function(bufnr)
		local api = require("nvim-tree.api")
		local opts = function(desc)
			return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true,
				nowait = true }
		end

		-- default mappings
		api.config.mappings.default_on_attach(bufnr)

		-- custom mappings
		vim.keymap.set("n", "<C-t>", api.tree.change_root_to_parent, opts("Up"))
		vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
	end,
}
