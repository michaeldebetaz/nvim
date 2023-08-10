return {
	"jose-elias-alvarez/null-ls.nvim",
	requires = "nvim-lua/plenary.nvim",
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
			},
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ async = false })
						end,
					})
				end
			end,
		})
	end,
}
