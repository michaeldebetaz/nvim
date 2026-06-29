vim.pack.add({ "https://github.com/dmmulroy/tsc.nvim" })
require("tsc").setup({ use_trouble_qflist = true })
vim.keymap.set("n", "<leader>to", "<cmd>TSCOpen<cr>")
vim.keymap.set("n", "<leader>tc", "<cmd>TSCClose<cr>")
