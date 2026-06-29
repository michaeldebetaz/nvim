-- [[ LSP Configuration ]]

-- Useful status updates for LSP.
vim.pack.add({ "https://github.com/j-hui/fidget.nvim" })
require("fidget").setup({})

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	callback = function(event)
		-- Rename the variable under your cursor.
		--  Most Language Servers support renaming across files, etc.
		vim.keymap.set("n", "grn", vim.lsp.buf.rename, { buffer = event.buf, desc = "LSP: [R]e[n]ame" })

		-- Execute a code action, usually your cursor needs to be on top of an error
		-- or a suggestion from your LSP for this to activate.
		vim.keymap.set(
			{ "n", "x" },
			"gra",
			vim.lsp.buf.code_action,
			{ buffer = event.buf, desc = "LSP: [G]oto Code [A]ction" }
		)
		-- WARN: This is not Goto Definition, this is Goto Declaration.
		--  For example, in C this would take you to the header.
		vim.keymap.set("n", "grD", vim.lsp.buf.declaration, { buffer = event.buf, desc = "LSP: [G]oto [D]eclaration" })
		vim.keymap.set(
			"n",
			"grd",
			require("telescope.builtin").lsp_definitions,
			{ buffer = event.buf, desc = "LSP: [G]oto [D]efinition" }
		)
		vim.keymap.set(
			"n",
			"grr",
			require("telescope.builtin").lsp_references,
			{ buffer = event.buf, desc = "LSP: [G]oto [R]eferences" }
		)
		vim.keymap.set(
			"n",
			"gri",
			require("telescope.builtin").lsp_implementations,
			{ buffer = event.buf, desc = "LSP: [G]oto [I]mplementation" }
		)
		vim.keymap.set(
			"n",
			"gO",
			require("telescope.builtin").lsp_document_symbols,
			{ buffer = event.buf, desc = "LSP: Open Document Symbols" }
		)
		vim.keymap.set(
			"n",
			"gW",
			require("telescope.builtin").lsp_dynamic_workspace_symbols,
			{ buffer = event.buf, desc = "LSP: Open Workspace Symbols" }
		)
		vim.keymap.set(
			"n",
			"grt",
			require("telescope.builtin").lsp_type_definitions,
			{ buffer = event.buf, desc = "LSP: [G]oto [T]ype Definition" }
		)
		-- The following two autocommands are used to highlight references of the
		-- word under your cursor when your cursor rests there for a little while.
		--    See `:help CursorHold` for information about when this is executed
		--
		-- When you move your cursor, the highlights will be cleared (the second autocommand).
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client:supports_method("textDocument/documentHighlight", event.buf) then
			local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})
			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
				end,
			})
		end

		-- The following code creates a keymap to toggle inlay hints in your
		-- code, if the language server you are using supports them
		--
		-- This may be unwanted, since they displace some of your code
		if client and client:supports_method("textDocument/inlayHint", event.buf) then
			vim.keymap.set("n", "<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
			end, { desc = "[T]oggle Inlay [H]ints" })
		end
	end,
})

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
	bashls = {},
	cssls = {},
	css_variables = {
		settings = {
			cssVariables = {
				blacklistFolders = {
					"**/.cache",
					"**/.DS_Store",
					"**/.git",
					"**/.hg",
					"**/.next",
					"**/.svn",
					"**/bower_components",
					"**/CVS",
					"**/dist",
					"**/node_modules",
					"**/tests",
					"**/tmp",
				},
				lookupFiles = { "**/*.css" },
			},
		},
	},
	gopls = {},
	html = {},
	lua_ls = {
		on_init = function(client)
			client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

			if client.workspace_folders then
				local path = client.workspace_folders[1].name
				if
					path ~= vim.fn.stdpath("config")
					and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
				then
					return
				end
			end

			client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
				runtime = {
					version = "LuaJIT",
					path = { "lua/?.lua", "lua/?/init.lua" },
				},
				workspace = {
					checkThirdParty = false,
					-- NOTE: this is a lot slower and will cause issues when working on your own configuration.
					--  See https://github.com/neovim/nvim-lspconfig/issues/3189
					library = vim.tbl_extend("force", vim.api.nvim_get_runtime_file("", true), {
						"${3rd}/luv/library",
						"${3rd}/busted/library",
					}),
				},
			})
		end,
		---@type lspconfig.settings.lua_ls
		settings = {
			Lua = {
				format = { enable = false }, -- Disable formatting (formatting is done by stylua)
			},
		},
		pyright = { settings = { python = { analysis = { autoSearchPaths = true } } } },
		tailwindcss = {},
		templ = {},
		ts_ls = {},

		stylua = {}, -- Used to format Lua code
	},
}

vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
})

-- Automatically install LSPs and related tools to stdpath for Neovim
require("mason").setup({})

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
	"gofumpt",
	"goimports",
	"prettier",
	"prettierd",
	"stylua",
})
vim.list_extend(ensure_installed, {
	-- You can add other tools here that you want Mason to install
})

require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

for name, server in pairs(servers) do
	vim.lsp.config(name, server)
	vim.lsp.enable(name)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "go",
	callback = function(args)
		local client_name = "go-tailwindcss"

		-- Check if tailwindcss is already attached
		local clients = vim.lsp.get_clients({ bufnr = args.buf })
		for _, client in ipairs(clients) do
			if client.name == client_name then
				return -- Already attached
			end
		end

		local root_dir = vim.fs.root(args.buf, { "package.json", ".git", "go.mod" })

		if root_dir then
			vim.lsp.start({
				name = client_name,
				cmd = { "tailwindcss-language-server", "--stdio" },
				root_dir = root_dir,
				settings = {
					tailwindCSS = {
						experimental = {
							classRegex = {
								-- Match Speckles Class() method
								[[Class\("([^"]*)"\)]],
								[[Class\('([^']*)'\)]],
								-- Match Speckles IfClass() method (second parameter)
								[[IfClass\([^,]+,\s*"([^"]*)"\)]],
								[[IfClass\([^,]+,\s*'([^"]*)'\)]],
							},
						},
						includeLanguages = {
							go = "html",
						},
					},
				},
			})
		end
	end,
})
