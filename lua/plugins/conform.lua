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
			local ignored_filetypes = { "c", "cpp", "templ", "go" }
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
		local conform = require("conform")
		conform.setup(opts)

		conform.formatters.prettierd_templ = {
			format = function(_, ctx, _, _)
				local errors = vim.diagnostic.get(ctx.buf, { severity = vim.diagnostic.severity.ERROR })
				if #errors > 0 then
					vim.notify("Conform: prettier_templ formatting skipped due to LSP errors", vim.log.levels.WARN)
				else
					local prettierd_templ = require("utils.conform.prettier_templ")
					local formatted = prettierd_templ.format_start_tags(ctx)
					local formatted_lines = vim.split(formatted, "\n")
					vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, formatted_lines)
				end

				conform.format({
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
				conform.format({
					bufnr = args.buf,
					formatters = { "prettierd_templ" },
					lsp_format = "fallback",
					async = true,
				})
			end,
		})

		conform.formatters.prettierd_speckles = {
			format = function(_, ctx, _, _)
				local errors = vim.diagnostic.get(ctx.buf, { severity = vim.diagnostic.severity.ERROR })
				if #errors > 0 then
					vim.notify("Conform: prettier_speckles formatting skipped due to LSP errors", vim.log.levels.WARN)
				else
					local prettied_gostar = require("utils.conform.prettierd_speckles")
					local formatted = prettied_gostar.format_classes(ctx)
					local formatted_lines = vim.split(formatted, "\n")
					vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, formatted_lines)
				end

				conform.format({
					bufnr = ctx.buf,
					formatters = { "gofumpt", "goimports" },
					lsp_format = "fallback",
					async = false,
				})
			end,
		}

		vim.api.nvim_create_autocmd("BufWritePre", {
			group = vim.api.nvim_create_augroup("ConformPrettierGostar", { clear = true }),
			pattern = "*.go",
			callback = function(args)
				conform.format({
					bufnr = args.buf,
					formatters = { "prettierd_speckles" },
					lsp_format = "fallback",
					async = true,
				})
			end,
		})
	end,
}
