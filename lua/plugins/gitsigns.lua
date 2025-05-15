return {
	-- Adds git releated signs to the gutter, as well as utilities for managing changes
	"lewis6991/gitsigns.nvim",
	opts = { -- See `:help gitsigns` to understand what the configuration keys do
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},

		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")

			vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
			vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
			vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
			vim.keymap.set("n", "<leader>hf", function()
				gitsigns.nav_hunk("first")
			end, { buffer = bufnr, desc = "Jump to first hunk" })
			vim.keymap.set("n", "<leader>hl", function()
				gitsigns.nav_hunk("last")
			end, { buffer = bufnr, desc = "Jump to last hunk" })
			vim.keymap.set("n", "<leader>hn", function()
				gitsigns.nav_hunk("next")
			end, { buffer = bufnr, desc = "Jump to next hunk" })
			vim.keymap.set("n", "<leader>hN", function()
				gitsigns.nav_hunk("prev")
			end, { buffer = bufnr, desc = "Jump to previous hunk" })
		end,
	},
}
