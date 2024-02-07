local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local d = ls.dynamic_node
local extras = require("luasnip.extras")
local fmt = require("luasnip.extras.fmt")
local rep = extras.rep

local function import_params()
	---@class TSNodeUtils
	local ts_utils = require("custom.treesitter")
	local current_buffer = vim.api.nvim_get_current_buf()

	local identifiers = ts_utils.get_nearest_parent_function_identifiers()
	if identifiers == nil then
		return { "" }
	end

	---@type string[]
	local params = {}
	for _, identifier in ipairs(identifiers) do
		local param = vim.treesitter.get_node_text(identifier, current_buffer)
		print(param)
		vim.list_extend(params, { param })
	end

	return params
end

local function my()
	return f(function()
		local params = import_params()
		print(vim.inspect(params))
		return params[1]
	end, {})
end

local jsdoc_snippet = s("jsd", fmt.format_nodes([[---@param {{{}}} {{{}}}]], { i(1), my() }))

ls.add_snippets("all", { jsdoc_snippet })
