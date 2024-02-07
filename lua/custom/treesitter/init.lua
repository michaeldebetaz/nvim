---@class TSNodeUtils
local M = {}

M.__index = M

M.find_function_declaration_below_cursor = function()
	local current_buffer = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local node = vim.treesitter.get_node({ bufnr = current_buffer, pos = cursor })
	if node == nil or node:type() ~= "function_declaration" then
		return nil
	end
	return node
end

M.find_parent_function_declaration = function(node)
	---@type TSNode|nil
	local n = node
	while n ~= nil and n:type() ~= "function_declaration" do
		n = n:parent()
	end
	return n
end

M.find_formal_parameters = function(node)
	---@type TSNode|nil
	local formal_parameters = nil

	for _, child in ipairs(node:named_children()) do
		local type = child:type()
		if type == "formal_parameters" then
			formal_parameters = child
			break
		end
	end

	return formal_parameters
end

M.find_identifiers = function(node)
	---@type TSNode[]
	local identifiers = {}
	for _, child in ipairs(node:named_children()) do
		if child:type() == "identifier" then
			local identifier = child
			table.insert(identifiers, identifier)
		end
		if child:type() == "rest_pattern" then
			local rest_pattern_identifiers = M.find_identifiers(child)
			if rest_pattern_identifiers ~= nil then
				for _, identifier in ipairs(rest_pattern_identifiers) do
					table.insert(identifiers, identifier)
				end
			end
		end
	end
	return identifiers
end

M.get_nearest_parent_function_identifiers = function()
	local current_buffer = vim.api.nvim_get_current_buf()

	local current_node = vim.treesitter.get_node({ bufnr = current_buffer })
	if current_node == nil then
		return nil
	end

	local function_declaration = M.find_parent_function_declaration(current_node)
	if function_declaration == nil then
		return nil
	end

	local formal_parameters = M.find_formal_parameters(function_declaration)
	if formal_parameters == nil then
		return nil
	end

	local identifiers = M.find_identifiers(formal_parameters)
	for _, identifier in ipairs(identifiers) do
		local s = vim.treesitter.get_node_text(identifier, current_buffer)
		print(s)
	end
	return identifiers
end

return M
