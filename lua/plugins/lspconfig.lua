return {
	-- LSP Configuration & Plugins
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for neovim
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		-- Useful status updates for LSP
		-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
		{ "j-hui/fidget.nvim", opt = {} },
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = event.buf, desc = "[G]oto [D]efinition" })
				vim.keymap.set(
					"n",
					"gr",
					require("telescope.builtin").lsp_references,
					{ buffer = event.buf, desc = "[G]oto [R]eferences" }
				)
				vim.keymap.set(
					"n",
					"gI",
					vim.lsp.buf.implementation,
					{ buffer = event.buf, desc = "[G]oto [I]mplementation" }
				)
				vim.keymap.set(
					"n",
					"<leader>D",
					vim.lsp.buf.type_definition,
					{ buffer = event.buf, desc = "Type [D]efinition" }
				)
				vim.keymap.set(
					"n",
					"<leader>ds",
					require("telescope.builtin").lsp_document_symbols,
					{ buffer = event.buf, desc = "[D]ocument [S]ymbols" }
				)
				vim.keymap.set(
					"n",
					"<leader>ws",
					require("telescope.builtin").lsp_dynamic_workspace_symbols,
					{ buffer = event.buf, desc = "[W]orkspace [S]ymbols" }
				)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = event.buf, desc = "[R]e[n]ame" })
				vim.keymap.set(
					"n",
					"<leader>ca",
					vim.lsp.buf.code_action,
					{ buffer = event.buf, desc = "[C]ode [A]ction" }
				)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = event.buf, desc = "Hover Documentation" })
				vim.keymap.set(
					"n",
					"gD",
					vim.lsp.buf.declaration,
					{ buffer = event.buf, desc = "[G]oto [D]eclaration" }
				)

				-- The following two autocommands are used to highlight references of the
				-- word under your cursor when your cursor rests there for a little while.
				--    See `:help CursorHold` for information about when this is executed
				--
				-- When you move your cursor, the highlights will be cleared (the second autocommand).
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.server_capabilities.documentHighlightProvider then
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						callback = vim.lsp.buf.clear_references,
					})
				end
			end,
		})

		-- LSP servers and clients are able to communicate to each other what features they support.
		--  By default, Neovim doesn't support everything that is in the LSP Specification.
		--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
		--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

		local servers = {
			bashls = {},
			eslint = {
				settings = {
					filetypes = {
						"javascript",
						"javascriptreact",
						"javascript.jsx",
						"typescript",
						"typescriptreact",
						"typescript.tsx",
					},
				},
			},
			htmx = {
				settings = {
					filetypes = {
						"html",
						"astro",
						"javascriptreact",
						"javascript.jsx",
						"typescriptreact",
						"typescript.tsx",
					},
				},
			},
			lua_ls = {
				settings = {
					Lua = { completion = { callSnippet = "Replace" } },
				},
			},
			pyright = {},
			tailwindcss = {},
			tsserver = {},
		}

		-- Ensure the servers and tools above are installed
		require("mason").setup()

		-- You can add other tools here that you want Mason to install
		-- for you, so that they are available from within Neovim.
		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"stylua", -- Used to format lua code
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					-- This handles overriding only values explicitly passed
					-- by the server configuration above. Useful when disabling
					-- certain features of an LSP (for example, turning off formatting for tsserver)
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})
	end,
}
