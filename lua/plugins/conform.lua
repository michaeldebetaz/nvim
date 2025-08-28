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
			local ignored_filetypes = { "c", "cpp", "templ" }
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
			templ = { "templ" },
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
		local function get_root(bufnr)
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

		---@alias ByteRange { id: integer, start_byte: integer, end_byte: integer, text: string }

		---@param id integer
		---@return string
		local function generate_unique_key(id)
			local random_number = math.random(1000, 9999)
			return '"__TEMPL_EXPR_' .. id .. "_" .. random_number .. '__"'
		end

		---@param bufnr integer
		---@param root TSNode
		---@return string masked_text, table<string, string> replacements
		local function mask_templ_expressions(bufnr, root)
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			local text = table.concat(lines, "\n")

			local attribte_expression_query = vim.treesitter.query.parse(
				"templ",
				[[
            (attribute (expression) @attribute.expression)
          ]]
			)

			---@type ByteRange[]
			local ranges = {}
			for id, node in attribte_expression_query:iter_captures(root, bufnr) do
				local _, _, start_byte, _, _, end_byte = node:range(true)
				local node_text = vim.treesitter.get_node_text(node, bufnr)
				---@type ByteRange
				local range = { id = id, start_byte = start_byte, end_byte = end_byte, text = node_text }
				table.insert(ranges, range)
			end

			---@type table<string, string>
			local replacements = {}

			-- Apply replacements in reverse order to avoid messing up byte positions
			for i = #ranges, 1, -1 do
				local range = ranges[i]
				-- Ensure the generated key does not already exist in the text
				---@string
				local key
				repeat
					key = generate_unique_key(range.id)
				until text:find(key, 1, true) == nil

				replacements[key] = range.text

				text = text:sub(1, range.start_byte) .. key .. text:sub(range.end_byte + 1)
			end

			return text, replacements
		end

		---@param filename string
		---@param text string
		---@param byte_ranges ByteRange[]
		---@return string|nil formatted_masked_text
		local function run_prettierd(filename, text, byte_ranges)
			-- Make sure prettierd is executed inside the templ project directory
			local project_root = vim.fs.root(filename, { "package.json", "node_modules" })

			local stdin_filepath = filename:gsub("%.templ$", ".html")

			-- Run in reverse order to avoid messing up line numbers
			for i = #byte_ranges, 1, -1 do
				local byte_range = byte_ranges[i]

				local prev = text:sub(1, byte_range.start_byte)
				local input_text = text:sub(byte_range.start_byte + 1, byte_range.end_byte)
				local next = text:sub(byte_range.end_byte + 1)

				local out = vim.system(
					{ "prettierd", "--stdin-filepath", stdin_filepath },
					{ stdin = input_text, text = true, cwd = project_root }
				):wait()

				if out.code ~= 0 then
					vim.notify("Failed to run prettierd: " .. vim.inspect(out), vim.log.levels.ERROR)
					return nil
				end

				if out.stdout then
					text = prev .. out.stdout .. next
				end
			end

			return text
		end

		---@param bufnr integer
		---@return  integer[] cursor_pos
		local function save_cursor_position(bufnr)
			local cursor_pos = vim.api.nvim_win_get_cursor(0)
			local line_count = vim.api.nvim_buf_line_count(bufnr)
			cursor_pos[1] = math.min(cursor_pos[1], line_count)
			return cursor_pos
		end

		require("conform").formatters.prettierd_templ = {
			format = function(_, ctx, _, _)
				local ctx_buf_root = get_root(ctx.buf)
				if ctx_buf_root == nil then
					return
				end

				local masked_text, replacements = mask_templ_expressions(ctx.buf, ctx_buf_root)
				local masked_lines = vim.split(masked_text, "\n")

				local scratch_bufnr = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, masked_lines)

				local component_block_query = vim.treesitter.query.parse(
					"templ",
					[[ 
            (component_declaration 
              (component_block) @component.block)
          ]]
				)

				local scratch_buf_root = get_root(scratch_bufnr)
				if scratch_buf_root == nil then
					vim.api.nvim_buf_delete(scratch_bufnr, { force = true })
					return
				end

				---@type ByteRange[]
				local component_block_ranges = {}

				for id, node in component_block_query:iter_captures(scratch_buf_root, scratch_bufnr) do
					local _, _, start_byte, _, _, end_byte = node:range(true)

					-- Only format non-empty component blocks
					if node:child_count() > 0 then
						local node_text = vim.treesitter.get_node_text(node, scratch_bufnr)
						---@type ByteRange
						local range = { id = id, start_byte = start_byte, end_byte = end_byte, text = node_text }

						table.insert(component_block_ranges, range)
					end
				end

				vim.api.nvim_buf_delete(scratch_bufnr, { force = true })

				if #component_block_ranges > 0 then
					local formatted_text = run_prettierd(ctx.filename, masked_text, component_block_ranges)

					if formatted_text ~= nil then
						-- Restore the masked templ expressions
						for key, value in pairs(replacements) do
							formatted_text = formatted_text:gsub(key, value)
						end

						local formatted_lines = vim.split(formatted_text, "\n")

						-- Preserve cursor position after setting lines
						local cursor_pos = save_cursor_position(ctx.buf)

						vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, formatted_lines)

						vim.api.nvim_win_set_cursor(0, cursor_pos)
					end
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
