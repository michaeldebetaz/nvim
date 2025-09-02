---@param key string
---@param data any
---@param log_level? vim.log.levels
local function print(key, data, log_level)
	log_level = log_level or vim.log.levels.INFO
	vim.notify(vim.inspect({ [key] = data }), log_level)
end

---@return { buf: integer, filename: string }
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

local function debug()
	local ctx = get_ctx()

	local scratch_bufnr = vim.api.nvim_create_buf(false, true)
	local input_lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)
	vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, input_lines)

	format_start_tags(scratch_bufnr, ctx.filename)

	vim.api.nvim_buf_delete(ctx.buf, { force = true })
end

debug()
