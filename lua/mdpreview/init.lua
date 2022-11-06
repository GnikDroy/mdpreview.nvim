local M = {}
local open_previews = {}

local function get_python()
    local opts = {
        { python = "python3", pip = "pip3" },
        { python = "python", pip = "pip" },
    }
    for _, p in ipairs(opts) do
        if vim.fn.executable(p.python) == 1 and vim.fn.executable(p.pip) == 1 then
            return p
        end
    end
    return nil
end

M.install_markdown_live_preview = function()
    local py = get_python()
    if py == nil then
        vim.api.nvim_err_writeln("mdpreview: Python installation not found")
        return
    end

    vim.fn.jobstart(
        { py.pip, 'install', '-U', 'markdown_live_preview' },
        {
            on_exit = function(_, ret, _)
                if ret == 0 then
                    print("mdpreview: Installation successful")
                else
                    print("mdpreview: Installation failed")
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
    for _, preview in ipairs(open_previews) do
        if bufnr == preview.bufnr then
            print(string.format("mdpreview: Server active at localhost:%d", preview.port))
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
    print(string.format("mdpreview: Server started at localhost:%d", port))

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
            table.remove(open_previews, i)
            print("mdpreview: Preview server stopped")
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
