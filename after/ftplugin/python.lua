vim.keymap.set("n", "<leader><CR>", function()
	vim.cmd.write()
	vim.cmd("!echo && python3.12 %")
end, { buffer = true, desc = "Run Python on current file" })
