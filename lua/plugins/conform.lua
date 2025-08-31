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
			templ = { "templ", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
		},
	},
	---@param opts conform.setupOpts
	config = function(_, opts)
		require("conform").setup(opts)

		---@para---@param bufnr integer
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

		---@param bufnr integer
		---@return string output_text, table<string, string> replacements
		local function mask_attr_expr(bufnr)
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			local text = table.concat(lines, "\n")

			---@type table<string, string>
			local replacements = {}

			local root = get_root(bufnr)
			if root == nil then
				vim.notify("Error: mask_inner function: no root found", vim.log.levels.ERROR)
				return text, replacements
			end

			local query = vim.treesitter.query.parse(
				"templ",
				[[
          (attribute (expression) @attr.expr)
        ]]
			)
			---@alias TSQueryCapture { name: string, node: TSNode }

			---@type TSQueryCapture[]
			local captures = {}
			for id, node in query:iter_captures(root, bufnr) do
				---@type TSQueryCapture
				local capture = { name = query.captures[id], node = node }
				table.insert(captures, capture)
			end

			if #captures < 1 then
				return text, replacements
			end

			for i = #captures, 1, -1 do
				local capture = captures[i]

				-- if it's an attribute expression, the mask should be quoted
				local key = '"__TEMPL_ATTR_EXPR_' .. i .. '__"'
				replacements[key] = vim.treesitter.get_node_text(capture.node, bufnr)
				local _, _, start_byte, _, _, end_byte = capture.node:range(true)
				text = text:sub(1, start_byte) .. key .. text:sub(end_byte + 1)
			end

			return text, replacements
		end

		---@param bufnr integer
		---@return string masked_text, table<string, string> replacements
		local function mask_between(bufnr)
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			local text = table.concat(lines, "\n")

			---@type table<string, string>
			local replacements = {}

			local scratch_buf_root = get_root(bufnr)
			if scratch_buf_root == nil then
				vim.notify("Error: mask_outer function: no root found", vim.log.levels.ERROR)
				return text, replacements
			end

			local query = vim.treesitter.query.parse(
				"templ",
				[[
			    (component_declaration
				  (component_block) @component.block)
		    ]]
			)
			---@type TSQueryCapture[]
			local captures = {}
			for id, node in query:iter_captures(scratch_buf_root, bufnr) do
				---@type TSQueryCapture
				local capture = { name = query.captures[id], node = node }
				table.insert(captures, capture)
			end

			if #captures < 1 then
				return text, replacements
			end

			---@type { start_byte: integer, end_byte: integer }[]
			local mask = { start_byte = 1, end_byte = -1 }

			for i = #captures, 1, -1 do
				local capture = captures[i]

				local _, _, node_start_byte, _, _, node_end_byte = capture.node:range(true)
				-- Mask from the end of the node ("}" included)
				mask.start_byte = node_end_byte + 1 - 1

				local key = "__TEMPL_AFTER_BLOCK_" .. i .. "__"
				replacements[key] = text:sub(mask.start_byte, mask.end_byte)

				local prev = text:sub(1, mask.start_byte - 1)
				local next = ""

				if i < #captures then
					next = text:sub(mask.end_byte + 1, -1)
				end

				text = prev .. key .. next

				mask.end_byte = node_start_byte + 2

				-- Mask from the bottom to the start of the first node ("{" included)
				if i == 1 then
					key = "__TEMPL_BEFORE_BLOCK_" .. i .. "__"
					replacements[key] = text:sub(1, mask.end_byte - 1)
					text = key .. text:sub(mask.end_byte + 1)
				end
			end

			return text, replacements
		end

		---@param filename string
		---@param text string
		---@return string formatted_text
		local function run_prettierd(filename, text)
			-- Make sure prettierd is executed inside the templ project directory
			local project_root = vim.fs.root(filename, { "package.json", "node_modules" })

			local stdin_filepath = filename:gsub("%.templ$", ".html")

			local out = vim.system(
				{ "prettierd", "--stdin-filepath", stdin_filepath },
				{ stdin = text, text = true, cwd = project_root }
			):wait()

			if out.code ~= 0 then
				vim.notify("Failed to run prettierd: " .. vim.inspect(out), vim.log.levels.ERROR)
				return text
			end

			local stdout = out.stdout
			if stdout ~= nil then
				text = stdout
			end

			return text
		end

		---@param text string
		---@param replacements table<string, string>
		---@return string unmasked_text
		local function unmask(text, replacements)
			for key, value in pairs(replacements) do
				text = text:gsub(key, value)
			end
			return text
		end

		---@param bufnr integer
		---@return string fixed_text
		local function fix_formatting(bufnr)
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			local text = table.concat(lines, "\n")

			-- Add newline before first "case" in switch statements
			local scratch_buf_root = get_root(bufnr)
			if scratch_buf_root == nil then
				vim.notify("Error: mask_outer function: no root found", vim.log.levels.ERROR)
				return text
			end

			local query = vim.treesitter.query.parse(
				"templ",
				[[
          (component_switch_statement) @switch
		    ]]
			)
			---@type TSQueryCapture[]
			local captures = {}
			for id, node in query:iter_captures(scratch_buf_root, bufnr) do
				---@type TSQueryCapture
				local capture = { name = query.captures[id], node = node }
				table.insert(captures, capture)
			end

			for i = #captures, 1, -1 do
				local capture = captures[i]

				local first_found = false
				for child_node, _ in capture.node:iter_children() do
					if not first_found and child_node:type() == "component_switch_expression_case" then
						local _, _, start_byte = child_node:start()
						local case_statement = "case"
						local end_byte = start_byte + #case_statement

						local new_text = "\n" .. case_statement
						text = text:sub(1, start_byte) .. new_text .. text:sub(end_byte + 1)
						first_found = true
					end
				end
			end

			return text
		end

		require("conform").formatters.prettierd_templ = {
			format = function(_, ctx, _, _)
				-- Don't format if there are any ctxerrors in the buffer
				local errors = vim.diagnostic.get(ctx.buf, { severity = vim.diagnostic.severity.ERROR })
				if errors[1] then
					vim.notify("prettier_templ: not formatting due to LSP errors", vim.log.levels.WARN)
					return
				end

				-- Run the masking in a scratch buffer to avoid messing with the user's buffer
				local input_lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)
				local scratch_bufnr = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, input_lines)

				local masked_attr_expr, replacements_attr_expr = mask_attr_expr(scratch_bufnr)
				local masked_lines_inner = vim.split(masked_attr_expr, "\n")
				vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, masked_lines_inner)

				local masked_between, replacements_between = mask_between(scratch_bufnr)

				local replacements = vim.tbl_extend("error", replacements_attr_expr, replacements_between)

				local masked_formatted = run_prettierd(ctx.filename, masked_between)

				local formatted = unmask(masked_formatted, replacements)
				local formatted_lines = vim.split(formatted, "\n")
				vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, formatted_lines)

				local fixed = fix_formatting(scratch_bufnr)
				local fixed_lines = vim.split(fixed, "\n")
				vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, fixed_lines)

				vim.api.nvim_buf_delete(scratch_bufnr, { force = true })

				require("conform").format({
					bufnr = ctx.buf,
					formatters = { "templ" },
					lsp_format = "fallback",
					async = false,
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
