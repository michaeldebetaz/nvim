vim.keymap.set("n", "<leader><Enter>", function()
	local filename = vim.fn.expand("%:p")

	local out = vim.system({ "nvim", "-l", filename }):wait()

	-- nvim always write to stderr, even if there is no error

	if out.code ~= 0 then
		vim.notify("Error running Neovim Lua interpretLr: " .. out.stderr, vim.log.levels.ERROR)
		return
	end

	if out.stdout and out.stdout ~= "" then
		vim.notify(out.stdout, vim.log.levels.INFO)
	end
end, { buffer = true, desc = "Run Neovim Lua interpreter on current file" })
