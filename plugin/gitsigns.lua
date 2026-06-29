-- See `:help gitsigns` to understand what the configuration keys do
-- Adds git releated signs to the gutter, as well as utilities for managing changes
vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup({
  signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },

	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")
		-- Navigation
		vim.keymap.set("n", "<leader>hf", function()
			---@diagnostic disable-next-line: param-type-mismatch
			gitsigns.nav_hunk("first")
		end, { buffer = bufnr, desc = "Jump to first hunk" })
		vim.keymap.set("n", "<leader>hl", function()
			---@diagnostic disable-next-line: param-type-mismatch
			gitsigns.nav_hunk("last")
		end, { buffer = bufnr, desc = "Jump to last hunk" })
		vim.keymap.set("n", "<leader>hn", function()
			---@diagnostic disable-next-line: param-type-mismatch
			gitsigns.nav_hunk("next")
		end, { buffer = bufnr, desc = "Jump to next hunk" })
		vim.keymap.set("n", "<leader>hN", function()
			---@diagnostic disable-next-line: param-type-mismatch
			gitsigns.nav_hunk("prev")
		end, { buffer = bufnr, desc = "Jump to previous hunk" })

		-- Actions
		vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
		vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
		vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
	end,
})
