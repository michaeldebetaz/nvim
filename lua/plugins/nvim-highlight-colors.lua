return {
	"brenoprata10/nvim-highlight-colors",
	opts = {
		exclude_buffer = function(bufnr)
			if vim.bo[bufnr].filetype ~= "css" then
				return true
			end

			local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
			if size > 100000 then
				return true
			end

			return false
		end,
	},
}
