return {
	-- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		-- [[ Configure Treesitter ]]
		-- See `:help nvim-treesitter`

		-- Prefer git instead of curl in order to improve connectivity in some environments
		require("nvim-treesitter.install").prefer_git = true

		---@diagnostic disable-next-line: missing-fields
		require("nvim-treesitter.configs").setup({
			--- Add languages to be installed here that you want installed for treesitter
			ensure_installed = {
				"bash",
				"go",
				"html",
				"javascript",
				"lua",
				"markdown",
				"markdown_inline",
				"regex",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
			},

			-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true, disable = { "ruby" } },
			playground = { enable = true },
			incremental_selection = {
				enable = true,
				disable = { "ruby" },
				keymaps = {
					init_selection = "<C-Space>",
					node_incremental = "<C-Space>",
					scope_incremental = "<C-s>",
					node_decremental = "<M-space>",
				},
			},
			textobjects = {
				select = {
					enable = true,
					lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
					keymaps = {
						-- You can use the capture groups defined in textobjects.scm
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						-- You can optionally set descriptions to the mappings (used in the desc parameter of nvim_buf_set_keymap) which plugins like which-key display
						["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
						-- You can also use captures from other query groups like `locals.scm`
						["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
					},
				},
				move = {
					enable = true,
					set_jumps = true, -- whether to set jumps in the jumplist
					goto_next_start = {
						["]m"] = "@function.outer",
						["]]"] = "@class.outer",
					},
					goto_next_end = {
						["]M"] = "@function.outer",
						["]["] = "@class.outer",
					},
					goto_previous_start = {
						["[m"] = "@function.outer",
						["[["] = "@class.outer",
					},
					goto_previous_end = {
						["[M"] = "@function.outer",
						["[]"] = "@class.outer",
					},
				},
			},
		})
	end,
}
