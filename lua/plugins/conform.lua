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

		---@param bufnr integer
		---@param lang "templ" | "html"
		---@return TSNode|nil
		local function get_root(bufnr, lang)
			-- Parse with treesitter
			local parser = vim.treesitter.get_parser(bufnr, lang)
			if parser == nil then
				vim.notify("Error: no parser found for " .. lang, vim.log.levels.ERROR)
				return nil
			end

			local trees = parser:parse()
			if trees == nil then
				vim.notify("Error: no trees found for " .. lang .. "parser", vim.log.levels.ERROR)
				return nil
			end

			return trees[1]:root()
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

		---@param html string
		---@return string[]|nil tag_starts
		local function extract_start_tags(html)
			local bufnr = vim.api.nvim_create_buf(false, true)

			local lines = vim.split(html, "\n")
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

			local root = get_root(bufnr, "html")
			if root == nil then
				vim.notify("Error: extract_tag_starts function: no root found", vim.log.levels.ERROR)
				return nil
			end

			local query = vim.treesitter.query.parse(
				"html",
				[[ 
          (start_tag) @start.tag
          (self_closing_tag) @self.closing.tag
        ]]
			)

			---@type string[]
			local formatted_tag_starts = {}

			for _, node in query:iter_captures(root, bufnr) do
				local node_text = vim.treesitter.get_node_text(node, bufnr)
				table.insert(formatted_tag_starts, node_text)
			end

			vim.api.nvim_buf_delete(bufnr, { force = true })

			return formatted_tag_starts
		end

		---@alias Capture.AttrExpr { rel_start_byte: integer, rel_end_byte: integer, key: string, expr_text: string }

		---@class Capture
		---@field start_byte integer
		---@field end_byte integer
		---@field tag_end string
		---@field text string
		---@field formatted_start_tag string
		---@field attr_expr Capture.AttrExpr[]

		---@param ctx conform.Context
		---@return string formatted_text
		local function format_start_tags(ctx)
			local lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)
			local text = table.concat(lines, "\n")

			local root = get_root(ctx.buf, "templ")
			if root == nil then
				vim.notify("Error: mask_elements function: no root found", vim.log.levels.ERROR)
				return text
			end

			local query = vim.treesitter.query.parse(
				"templ",
				[[
          (element (tag_start) @tag.start)
          (self_closing_tag) @self.closing.tag
        ]]
			)

			---@type Capture[]
			local captures = {}

			for _, node in query:iter_captures(root, ctx.buf) do
				local _, _, start_byte, _, _, end_byte = node:range(true)
				local node_text = vim.treesitter.get_node_text(node, ctx.buf)

				---@type Capture
				local capture = {
					start_byte = start_byte,
					end_byte = end_byte,
					tag_end = "",
					text = node_text,
					formatted_start_tag = "",
					attr_expr = {},
				}

				for child, _ in node:iter_children() do
					if node:type() == "tag_start" and child:type() == "element_identifier" then
						local element_identifier = vim.treesitter.get_node_text(child, ctx.buf)
						capture.tag_end = "</" .. element_identifier .. ">"
					end

					if child:type() == "attribute" then
						for attr_child, _ in child:iter_children() do
							if attr_child:type() == "expression" then
								local _, _, attr_child_start_byte, _, _, attr_child_end_byte = attr_child:range(true)
								local rel_start_byte = attr_child_start_byte - start_byte
								local rel_end_byte = attr_child_end_byte - start_byte

								---@type Capture.AttrExpr
								local attr_expr = {
									rel_start_byte = rel_start_byte,
									rel_end_byte = rel_end_byte,
								}

								table.insert(capture.attr_expr, attr_expr)
							end
						end
					end
				end

				-- Replace attribute expressions with unique keys in reverse order
				for i = #capture.attr_expr, 1, -1 do
					local attr_expr = capture.attr_expr[i]

					local before = capture.text:sub(1, attr_expr.rel_start_byte)
					local after = capture.text:sub(attr_expr.rel_end_byte + 1, -1)

					local abs_start_byte = capture.start_byte + attr_expr.rel_start_byte

					local key = '"__TEMPL_ATTR_EXPR_' .. abs_start_byte .. '__"'
					local expr_text = capture.text:sub(attr_expr.rel_start_byte + 1, attr_expr.rel_end_byte)
					attr_expr.key = key
					attr_expr.expr_text = expr_text

					capture.text = before .. key .. after
				end

				table.insert(captures, capture)
			end

			-- Create the HTML to be formatted by concatenating all the captured elements

			---@type string[]
			local elements = {}

			for _, capture in ipairs(captures) do
				local element = capture.text .. capture.tag_end
				table.insert(elements, element)
			end

			local html = table.concat(elements, "\n")

			local formatted_html = run_prettierd(ctx.filename, html)

			local formatted_start_tags = extract_start_tags(formatted_html)
			if formatted_start_tags == nil then
				vim.notify("Error: failed to extract start tags", vim.log.levels.ERROR)
				return text
			end

			if #formatted_start_tags ~= #captures then
				vim.notify(
					"Error: number of formatted start tags does not match number of templ captures",
					vim.log.levels.ERROR
				)
				return text
			end

			for i, formatted_start_tag in ipairs(formatted_start_tags) do
				captures[i].formatted_start_tag = formatted_start_tag
			end

			-- Replace the original start tags in reverse order to avoid messing up byte positions
			for i = #captures, 1, -1 do
				local capture = captures[i]

				local formatted_start_tag = capture.formatted_start_tag

				-- Re-insert the original attribute expressions
				for _, attr_expr in ipairs(capture.attr_expr) do
					formatted_start_tag = formatted_start_tag:gsub(attr_expr.key, attr_expr.expr_text)
				end

				local before = text:sub(1, capture.start_byte)
				local after = text:sub(capture.end_byte + 1, -1)
				text = before .. formatted_start_tag .. after
			end

			return text
		end

		require("conform").formatters.prettierd_templ = {
			format = function(_, ctx, _, _)
				-- Don't format if there are any ctxerrors in the buffer
				local errors = vim.diagnostic.get(ctx.buf, { severity = vim.diagnostic.severity.ERROR })
				if errors[1] then
					vim.notify("Conform: prettier_templ formatting skipped due to LSP errors", vim.log.levels.WARN)
					return
				end

				local formatted = format_start_tags(ctx)
				local formatted_lines = vim.split(formatted, "\n")

				vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, formatted_lines)

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
