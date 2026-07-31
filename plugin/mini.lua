vim.pack.add({ "https://github.com/echasnovski/mini.nvim" })
require("mini.ai").setup({ n_lines = 500 })
require("mini.surround").setup()
if vim.g.have_nerd_font then
	require("mini.icons").setup()
	MiniIcons.mock_nvim_web_devicons()
end
