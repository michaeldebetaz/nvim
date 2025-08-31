vim.keymap.set("n", "<leader><Enter>", function()
	vim.cmd.write()
	vim.cmd("luafile %")
end, { buffer = true, desc = "Run Neovim Lua interpreter on current file" })
