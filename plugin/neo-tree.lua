-- Plugin to browse the file system and other tree like structures in whatever style suits you, including sidebars, floating windows, netrw split style, or all of them at once!
vim.pack.add({
	{
		src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
		version = vim.version.range("3"),
	},
	-- dependencies
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	-- optional, but recommended
	"https://github.com/nvim-tree/nvim-web-devicons",
})
require("neo-tree").setup({
	filesystem = { filtered_items = { visible = true } },
})

---@param type string
local find_buffer_by_type = function(type)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
		if ft == type then
			return buf
		end
	end
	return -1
end
---@param toggle_command function
local toggle = function(toggle_command)
	if find_buffer_by_type("neo-tree") > 0 then
		require("neo-tree.command").execute({ action = "close" })
	else
		toggle_command()
	end
end
vim.keymap.set({ "n" }, "<leader>b", function()
	toggle(function()
		require("neo-tree.command").execute({ action = "focus", reveal = true, dir = vim.uv.cwd() })
	end)
end, { desc = "Toggle Explorer (root)" })
