local M = {}

M.valid_options = {
    'session',
    'set_default_mappings',
    'layout',
    'action',
    'session',
    'command',
}

function M.setup(config)
    for k, v in pairs(config) do
        if not vim.tbl_contains(M.valid_options, k) then
            error("Invalid option to nnn setup(): " .. vim.inspect(k))
        end
        vim.g['nnn#' .. k] = v
    end
end

return M
