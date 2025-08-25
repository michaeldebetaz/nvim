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

		---@alias TSNodeRange { start_row: integer, start_col: integer, end_row: integer, end_col: integer }

		---@param ctx conform.Context
		---@param ranges TSNodeRange[]
		local function run_prettierd(ctx, ranges)
			-- Run in reverse order to avoid messing up line numbers
			for i = #ranges, 1, -1 do
				local range = ranges[i]
				-- The first row is the line with the opening tag, so we start from the next line
				local start_row = range.start_row + 1
				-- The last row is the line with the closing tag, but end_row is exclusive, so we can use it as is
				local end_row = range.end_row

				local stdin_filepath = ctx.filename:gsub("%.templ$", ".html")

				local input_lines = vim.api.nvim_buf_get_lines(ctx.buf, start_row, end_row, false)

				local input_text = table.concat(input_lines, "\n")

				local output_lines = vim.fn.systemlist({ "prettierd", "--stdin-filepath", stdin_filepath }, input_text)

				if vim.v.shell_error ~= 0 then
					local error = table.concat(output_lines, "\n")
					vim.notify("Failed to run prettierd: " .. error, vim.log.levels.ERROR)
					return
				end

				if output_lines and #output_lines > 0 then
					vim.api.nvim_buf_set_lines(ctx.buf, start_row, end_row, false, output_lines)
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

				---@type TSNodeRange[]
				local ranges = {}

				for _, node in query:iter_captures(root, ctx.buf) do
					local start_row, start_col, end_row, end_col = node:range()
					-- We only want to format if there is content inside the component block
					if end_row > start_row + 1 then
						table.insert(ranges, {
							start_row = start_row,
							start_col = start_col,
							end_row = end_row,
							end_col = end_col,
						})
					end
				end

				if #ranges > 0 then
					run_prettierd(ctx, ranges)
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
