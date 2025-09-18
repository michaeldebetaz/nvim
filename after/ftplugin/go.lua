vim.keymap.set("n", "<leader>lr", function()
	vim.cmd.write()
	vim.cmd("LspRestart")
end, { buffer = true, desc = "Restart the LSP client" })
