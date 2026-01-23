return {
	"brenoprata10/nvim-highlight-colors",
	opts = {
		render = "virtual",
		virtual_symbol_position = "eow",
		virtual_symbol_prefix = " ",
		virtual_symbol_suffix = "",
		enable_tailwind = false,
		exclude_buffer = function(bufnr)
			local filename = "stellar.css"
			return vim.api.nvim_buf_get_name(bufnr):sub(-#filename) == filename
		end,
	},
}
