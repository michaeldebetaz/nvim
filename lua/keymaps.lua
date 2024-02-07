-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Custom keymaps ]]

vim.keymap.set("i", "jk", "<Esc>")

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
