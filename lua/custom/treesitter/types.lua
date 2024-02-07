---@meta custom.treesitter

---@class TSNodeUtils
---@field __index TSNodeUtils
---@field find_function_declaration_below_cursor fun():TSNode|nil
---@field find_parent_function_declaration fun(node:TSNode):TSNode|nil
---@field find_formal_parameters fun(node:TSNode):TSNode|nil
---@field find_identifiers fun(node:TSNode): TSNode[]
---@field get_nearest_parent_function_identifiers fun(): TSNode[]|nil
