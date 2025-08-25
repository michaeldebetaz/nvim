return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	---@type conform.setupOpts
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			---@type string[]
			local ignored_filetypes = { "c", "cpp" }
			if vim.tbl_contains(ignored_filetypes, vim.bo[bufnr].filetype) then
				return nil
			else
				---@type conform.FormatOpts
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end
		end,
		formatters_by_ft = {
			astro = { "prettierd", "prettier", stop_after_first = true },
			css = { "prettierd", "prettier", stop_after_first = true },
			go = { "gofumpt", "goimports" },
			html = { "prettierd", "prettier", stop_after_first = true },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			lua = { "stylua" },
			python = { "isort", "black" },
			sh = { "shfmt" },
			sql = { "sleek" },
			-- NOTE: formatting on save is done in the autocmd below
			-- templ = {},
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
		},
	},
	---@param opts conform.setupOpts
	config = function(_, opts)
		require("conform").setup(opts)

		---@param bufnr integer
		---@return TSNode|nil
		local get_root = function(bufnr)
			-- Parse with treesitter
			local parser = vim.treesitter.get_parser(bufnr, "templ")
			if parser == nil then
				vim.notify("Error: no parser found for templ", vim.log.levels.ERROR)
				return nil
			end

			local trees = parser:parse()
			if trees == nil then
				vim.notify("Error: no trees found for templ parser", vim.log.levels.ERROR)
				return nil
			end

			return trees[1]:root()
		end

		---@alias RowRange { start_row: integer, end_row: integer  }

		---@param ctx conform.Context
		---@param ranges RowRange[]
		local function run_prettierd(ctx, ranges)
			-- Make sure prettierd is executed inside the templ project directory
			-- so that it can find the
			--
			local project_root = vim.fs.root(ctx.filename, { "package.json", "node_modules" })

			local stdin_filepath = ctx.filename:gsub("%.templ$", ".html")

			-- Run in reverse order to avoid messing up line numbers
			for i = #ranges, 1, -1 do
				local range = ranges[i]

				local input_lines = vim.api.nvim_buf_get_lines(ctx.buf, range.start_row, range.end_row, false)

				local input_text = table.concat(input_lines, "\n")

				-- -- local output_lines = vim.fn.systemlist({ "prettierd", "--stdin-filepath", stdin_filepath }, input_text)

				local out = vim.system(
					{ "prettierd", "--stdin-filepath", stdin_filepath },
					{ stdin = input_text, text = true, cwd = project_root }
				):wait()

				if out.code ~= 0 then
					vim.notify("Failed to run prettierd: " .. vim.inspect(out), vim.log.levels.ERROR)
					return
				end

				---@type string[]
				local output_lines = {}
				if out.stdout and out.stdout ~= "" then
					output_lines = vim.split(out.stdout, "\n")
				end

				if #output_lines > 0 then
					vim.api.nvim_buf_set_lines(ctx.buf, range.start_row, range.end_row, false, output_lines)
				end
			end
		end

		require("conform").formatters.prettierd_templ = {
			format = function(_, ctx, _, _)
				local root = get_root(ctx.buf)
				if root == nil then
					return
				end

				local query = vim.treesitter.query.parse("templ", "(component_block) @component.block")

				---@type RowRange[]
				local component_block_inner_ranges = {}

				for _, node in query:iter_captures(root, ctx.buf) do
					local start_row, _, end_row, _ = node:range()
					-- We only want to format if there is content inside the component block
					local inner_start_row = start_row + 1
					if end_row > inner_start_row then
						---@type RowRange
						local range = { start_row = inner_start_row, end_row = end_row }
						table.insert(component_block_inner_ranges, range)
					end
				end

				if #component_block_inner_ranges > 0 then
					run_prettierd(ctx, component_block_inner_ranges)
				end

				require("conform").format({
					buf = ctx.buf,
					formatters = { "templ" },
					async = false,
					timeout_ms = 500,
				})
			end,
		}

		local group = vim.api.nvim_create_augroup("ConformPrettierTempl", { clear = true })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = group,
			pattern = "*.templ",
			callback = function(args)
				require("conform").format({
					bufnr = args.buf,
					formatters = { "prettierd_templ" },
					lsp_format = "fallback",
					async = true,
				})
			end,
		})
	end,
}
