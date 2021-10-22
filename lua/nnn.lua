local M = {}

M.valid_options = {
	"set_default_mappings",
	"layout",
	"explorer_layout",
	"action",
	"session",
	"command",
	"replace_netrw",
	"statusline",
	"shell",
}

function M.setup(config)
	for k, v in pairs(config) do
		if not vim.tbl_contains(M.valid_options, k) then
			error("Invalid option to nnn setup(): " .. vim.inspect(k))
		end
		vim.g["nnn#" .. k] = v
	end
end

return M
