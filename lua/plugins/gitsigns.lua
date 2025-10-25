-- See `:help gitsigns` to understand what the configuration keys do
return { -- Adds git releated signs to the gutter, as well as utilities for managing changes
	"lewis6991/gitsigns.nvim",
	opts = {
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
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
	},
}
