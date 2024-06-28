return {
	-- Plugin to browse the file system and other tree like structures in whatever style suits you, including sidebars, floating windows, netrw split style, or all of them at once!
	"nvim-neo-tree/neo-tree.nvim",
	version = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
	},
	keys = function()
		local find_buffer_by_type = function(type)
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				local ft = vim.api.nvim_buf_get_option(buf, "filetype")
				if ft == type then
					return buf
				end
			end
			return -1
		end

		local toggle = function(toggle_command)
			if find_buffer_by_type("neo-tree") > 0 then
				require("neo-tree.command").execute({ action = "close" })
			else
				toggle_command()
			end
		end

		return {
			{
				"<leader>b",
				function()
					toggle(function()
						require("neo-tree.command").execute({ action = "focus", reveal = true, dir = vim.uv.cwd() })
					end)
				end,
				desc = "Toggle Explorer (cwd)",
			},
			{
				"<leader>B",
				function()
					toggle(function()
						require("neo-tree.command").execute({ action = "focus", reveal = true })
					end)
				end,
				desc = "Toggle Explorer (root)",
			},
		}
	end,
	config = function()
		require("neo-tree").setup({
			filesystem = { filtered_items = { visible = true } },
		})
	end,
}
