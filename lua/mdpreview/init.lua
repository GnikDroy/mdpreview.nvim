local M = {}
local open_previews = {}

local function get_python()
    local opts = { "python3", "python" }
    for _, p in ipairs(opts) do
        if vim.fn.executable(p) == 1 then
            return p
        end
    end
    return nil
end

M.install_mlp = function()
    local python = get_python()
    if python == nil then
        vim.notify("mdpreview: Python installation not found", vim.log.levels.ERROR)
        return
    end

    vim.notify("mdpreview: Downloading & Installing markdown_live_preview", vim.log.levels.INFO)
    vim.fn.jobstart(
        { python, '-m', 'pip', 'install', '-U', 'markdown_live_preview' },
        {
            on_exit = function(_, ret, _)
                if ret == 0 then
                    vim.notify("mdpreview: Installation successful", vim.log.levels.INFO)
                else
                    vim.notify("mdpreview: Installation failed (pip)", vim.log.levels.ERROR)
                end
            end,
        })
end

local function find_suitable_port()
    local port = nil
    for _, preview in ipairs(open_previews) do
        if port == nil or preview.port > port then
            port = preview.port
        end
    end
    return port == nil and M.config.port or port + 1
end

M.preview_open = function(bufnr)
    if vim.fn.executable("mlp") <= 0 then
        vim.notify("mdpreview: mlp not installed. Try ':lua require('mdpreview').install_mlp()'", vim.log.levels.WARN)
        return
    end

    for _, preview in ipairs(open_previews) do
        if bufnr == preview.bufnr then
            vim.notify(string.format("mdpreview: Server active at localhost:%d", preview.port), vim.log.levels.INFO)
            return
        end
    end

    local opts = { "mlp" }
    if not M.config.follow then table.insert(opts, "--no-follow") end
    if not M.config.browser then table.insert(opts, "--no-browser") end
    if not M.config.localhost_only then opts:append(opts, "--open") end

    table.insert(opts, "--port")
    local port = find_suitable_port()
    table.insert(opts, string.format("%d", find_suitable_port()))
    table.insert(opts, vim.fn.expand("%:p"))

    local job = vim.fn.jobstart(opts)
    if job <= 0 then return end
    vim.notify(string.format("mdpreview: Server started at localhost:%d", port), vim.log.levels.INFO)

    table.insert(open_previews, {
        bufnr = bufnr,
        job = job,
        port = port,
    })
end

M.preview_close = function(bufnr)
    for i = #open_previews, 1, -1 do
        if open_previews[i].bufnr == bufnr then
            vim.fn.jobstop(open_previews[i].job)
            vim.notify(string.format("mdpreview: Preview server at localhost:%d stopped", open_previews[i].port), vim.log.levels.INFO)
            table.remove(open_previews, i)
        end
    end
end

M.setup = function(config)
    M.config = {
        port = 8080,
        localhost_only = true,
        follow = true,
        browser = true,
    }
    M.config = vim.tbl_deep_extend("force", M.config, config)
    return M
end

return M
