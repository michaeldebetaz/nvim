-- [[ Kickstart's Basic Keymaps ]]

-- Clear highlight on search on pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic Config & Keymaps
--  See `:help vim.diagnostic.Opts`
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = { min = vim.diagnostic.severity.WARN } },

	-- Can switch between these as you prefer
	virtual_text = true, -- Text shows up at the end of the line
	virtual_lines = false, -- Text shows up underneath the line, with virtual lines

	-- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({
				bufnr = bufnr,
				scope = "cursor",
				focus = false,
			})
		end,
	},
})

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Custom Keymaps ]]

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })

-- Exit insert mode quickly
vim.keymap.set("i", "jk", "<Esc>")

-- Select all text in the buffer
vim.keymap.set("n", "<C-a>", "ggVG", { silent = true })

-- Scroll one page up and down and keep the cursor in the same position
vim.keymap.set("n", "<C-u>", "<C-u>zz", { silent = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { silent = true })

-- Move lines
vim.keymap.set("n", "<A-j>", ":move .+1<CR>", { silent = true })
vim.keymap.set("n", "<A-k>", ":move .-2<CR>", { silent = true })
vim.keymap.set("i", "<A-j>", "<Esc>:move .+1<CR>==gi", { silent = true })
vim.keymap.set("i", "<A-k>", "<Esc>:move .-2<CR>==gi", { silent = true })
vim.keymap.set("v", "<A-j>", ":move '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "<A-k>", ":move '<-2<CR>gv=gv", { silent = true })

-- Copy to system clipboard
vim.keymap.set("v", "<C-c>", '"+y', { silent = true })

-- Resize windows
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { silent = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize +2<CR>", { silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize -2<CR>", { silent = true })

-- Search and replace selected text
vim.keymap.set("v", "<leader>sr", 'y:%s/<C-r>"//g<Left><Left>', { silent = true })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})
