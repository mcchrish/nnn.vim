local M = {}

function M.setup(config)
    for k, v in pairs(config) do
        vim.g['nnn#' .. k] = v
    end
end

return M
