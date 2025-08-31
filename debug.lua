---@param key string
---@param data any
---@param log_level? vim.log.levels
local function print(key, data, log_level)
	log_level = log_level or vim.log.levels.INFO
	vim.notify(vim.inspect({ [key] = data }), log_level)
end

---@return conform.Context
local function get_ctx()
	local filename = "/home/dem/projects/playground/prettierd_templ/template.templ"
	local file = io.open(filename, "r")

	local lines = {}
	if file then
		for line in file:lines() do
			table.insert(lines, line)
		end
		file:close()
	end

	local scratch_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, lines)

	return {
		buf = scratch_bufnr,
		filename = filename,
	}
end

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

---@param bufnr integer
---@return string output_text, table<string, string> replacements
local function mask_inner(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local text = table.concat(lines, "\n")

	---@type table<string, string>
	local replacements = {}

	local scratch_buf_root = get_root(bufnr)
	if scratch_buf_root == nil then
		vim.notify("Error: mask_inner function: no root found", vim.log.levels.ERROR)
		return text, replacements
	end

	local query = vim.treesitter.query.parse(
		"templ",
		[[
      (attribute (expression) @attr.expr)
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

	if #captures < 1 then
		return text, replacements
	end

	-- TODO: not mask inside other constructs (e.g. if inside for, if, else, etc.)
	-- if it has elements inside
	for i = #captures, 1, -1 do
		local capture = captures[i]

		-- if it's an attribute expression, the mask should be quoted
		if capture.name == "attr.expr" then
			local key = '"__TEMPL_ATTR_EXPR_' .. i .. '__"'
			replacements[key] = vim.treesitter.get_node_text(capture.node, bufnr)
			local _, _, start_byte, _, _, end_byte = capture.node:range(true)
			text = text:sub(1, start_byte) .. key .. text:sub(end_byte + 1)
		end

		-- If it's a switch We'll only add a newline before the first "case" when restoring
		if capture.name == "switch" then
			for child_node, _ in capture.node:iter_children() do
				local first_found = false
				if not first_found and child_node:type() == "component_switch_expression_case" then
					local _, _, start_byte = child_node:start()
					local end_byte = start_byte + #"case"
					local key = "__TEMPL_CASE_" .. i .. "__"
					replacements[key] = "\n" .. text:sub(start_byte + 1, end_byte)
					text = text:sub(1, start_byte) .. key .. text:sub(end_byte + 1)
					first_found = true
				end
			end
		end
	end

	return text, replacements
end

-- ---@param bufnr integer
-- ---@return string masked_text, table<string, string> replacements
-- local function mask_outer(bufnr)
-- 	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
-- 	local text = table.concat(lines, "\n")
--
-- 	---@type table<string, string>
-- 	local replacements = {}
--
-- 	local scratch_buf_root = get_root(bufnr)
-- 	if scratch_buf_root == nil then
-- 		vim.notify("Error: mask_outer function: no root found", vim.log.levels.ERROR)
-- 		return text, replacements
-- 	end
--
-- 	local query = vim.treesitter.query.parse(
-- 		"templ",
-- 		[[
-- 			(component_declaration
--         (component_block) @component.block)
-- 		]]
-- 	)
-- 	---@type TSQueryCapture[]
-- 	local captures = {}
-- 	for id, node in query:iter_captures(scratch_buf_root, bufnr) do
-- 		---@type TSQueryCapture
-- 		local capture = { name = query.captures[id], node = node }
-- 		table.insert(captures, capture)
-- 	end
--
-- 	if #captures < 1 then
-- 		return text, replacements
-- 	end
--
-- 	---@type { start_byte: integer, end_byte: integer }[]
-- 	local mask = { start_byte = 1, end_byte = -1 }
--
-- 	for i = #captures, 1, -1 do
-- 		local capture = captures[i]
--
-- 		local _, _, node_start_byte, _, _, node_end_byte = capture.node:range(true)
-- 		-- Mask from the end of the node ("}" included)
-- 		mask.start_byte = node_end_byte + 1 - 1
--
-- 		local key = "__TEMPL_AFTER_BLOCK_" .. i .. "__"
-- 		replacements[key] = text:sub(mask.start_byte, mask.end_byte)
--
-- 		local prev = text:sub(1, mask.start_byte - 1)
-- 		local next = ""
--
-- 		if i < #captures then
-- 			next = text:sub(mask.end_byte + 1, -1)
-- 		end
--
-- 		text = prev .. key .. next
--
-- 		mask.end_byte = node_start_byte + 2
--
-- 		-- Mask from the bottom to the start of the first node ("{" included)
-- 		if i == 1 then
-- 			key = "__TEMPL_BEFORE_BLOCK_" .. i .. "__"
-- 			replacements[key] = text:sub(1, mask.end_byte - 1)
-- 			text = key .. text:sub(mask.end_byte + 1)
-- 		end
-- 	end
--
-- 	return text, replacements
-- end

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
	)
		:wait()

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
local function unmask(text, replacements)
	for key, value in pairs(replacements) do
		text = text:gsub(key, value)
	end
	return text
end

local function debug()
	local ctx = get_ctx()

	local scratch_bufnr = vim.api.nvim_create_buf(false, true)
	local input_lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)
	vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, input_lines)

	local masked_text_inner, replacements_inner = mask_inner(scratch_bufnr)
	local masked_lines_inner = vim.split(masked_text_inner, "\n")

	vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, masked_lines_inner)

	-- local masked_text_outer, replacements_outer = mask_outer(scratch_bufnr)
	-- vim.notify("After mask_outer: " .. masked_text_outer, vim.log.levels.INFO)

	-- local replacements = vim.tbl_extend("error", replacements_inner, replacements_outer)
	vim.api.nvim_buf_delete(scratch_bufnr, { force = true })

	local formatted = run_prettierd(ctx.filename, masked_text_inner)
	vim.notify("After prettierd: " .. formatted, vim.log.levels.INFO)

	local unmasked_formatted = unmask(formatted, replacements_inner)
	vim.notify("After unmask: " .. unmasked_formatted, vim.log.levels.INFO)

	vim.api.nvim_buf_delete(ctx.buf, { force = true })
end

debug()
