# Markdown Preview for Neovim

Preview markdown files on your browser. Uses [markdown-live-preview](https://github.com/ms-jpq/markdown-live-preview).
In fact, this plugin is just a thin wrapper around `markdown-live-preview`.
It automatically sets up `mlp` and provides a convenient way to interface with it.

![MarkdownPreview](https://raw.githubusercontent.com/ms-jpq/markdown-live-preview/md/preview/smol.gif)

## Features

* Cross platform
* Minimal, asynchronous and standalone.
* Auto reload browser page on edit.
* Syntax highlighted code blocks
* Supports Github flavored markdown, including tables.
* Serves local assets

## Install

**Make sure python is installed**

Install with packer

```lua
use({
    "gnikdroy/mdpreview.nvim",
    ft = "markdown",
    config = function()
        require("mdpreview").setup({
            port = 8080,
            localhost_only = true,
            follow = true,
            browser = true,
        })
    end
})
```

## Configuration


### Options

The default options are 
```lua
{
    port = 8080,
    localhost_only = true,
    follow = true,
    browser = true,
}
```
| Option            | Explanation                                                                        |
|-------------------|------------------------------------------------------------------------------------|
| port              | The port the server will listen on. Subsequent servers will increment this value   |
| localhost_only    | Only expose the server on the loopback address. If false, listens on 0.0.0.0       |
| follow            | Autoscroll to edit location in the browser                                         |
| browser           | Opens the preview on a brower                                                      |

**Port** specifies the port the server should listen on. Additional previews will incrementally increase this value.

### Commands

This plugin provides no user-defined commands, or keybindings for you.
Instead it relies on you to set things up. This way you have 100% control over the plugin.

The following example adds two commands `:Preview` and `:PreviewClose`
Additionally, `:PreviewClose` is called automatically when buffer is deleted.

**These commands only exist in markdown file buffers (\*.md)!**

```lua
use({
    "gnikdroy/mdpreview.nvim",
    ft = "markdown",
    run = function() require("mdpreview").install_mlp() end,
    config = function()
        local mdpreview = require("mdpreview").setup({})

        -- Add commands :Preview and :PreviewClose
        vim.api.nvim_create_autocmd('BufEnter', {
            pattern = '*.md',
            callback = function(details)
                vim.api.nvim_buf_create_user_command(details.buf, "Preview",
                    function() mdpreview.preview_open(details.buf) end, {})
                vim.api.nvim_buf_create_user_command(details.buf, "PreviewClose",
                    function() mdpreview.preview_close(details.buf) end, {})
            end,
            desc = "mdpreview: Create preview commands",
        })

        -- Automatically close preview when buffer is deleted
        vim.api.nvim_create_autocmd('BufDelete', {
            pattern = '*.md',
            callback = function(details) mdpreview.preview_close(details.buf) end,
            desc = "mdpreview: Automatically close previews on buffer close",
        })
    end
})
```

## Special thanks

- [markdown-live-preview](https://github.com/ms-jpq/markdown-live-preview)
