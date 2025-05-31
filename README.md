# Claude.nvim

A Neovim plugin for seamless integration with Claude CLI.

<img width="1800" alt="Capture d’écran 2025-05-31 à 21 45 00" src="https://github.com/user-attachments/assets/ce5566a5-37ad-4639-918c-567dcae5d740" />

## Prerequisites
- Neovim >= 0.5.0
- Claude CLI installed (`brew install anthropic/tools/claude`)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "h4ckm1n/claude-nvim",
    config = function()
        require("claude").setup({
            claude_path = "/opt/homebrew/bin/claude", -- Path to Claude CLI
            keymaps = {
                execute = "<leader>CC",      -- Open in horizontal split
                execute_float = "<leader>CF", -- Open in floating window
                execute_right = "<leader>CR", -- Open in right split
            },
            float = {
                width = 0.8,    -- 80% of screen width
                height = 0.8,   -- 80% of screen height
                border = "rounded",
            },
        })
    end,
}
```

## Usage

The plugin provides three ways to interact with Claude:

1. Horizontal Split (default):
   - Use `<leader>CC` or `:Claude`
   - Opens Claude in a horizontal split below current window

2. Floating Window:
   - Use `<leader>CF` or `:ClaudeFloat`
   - Opens Claude in a centered floating window
   - Window size and border style are customizable

3. Right Split:
   - Use `<leader>CR` or `:ClaudeRight`
   - Opens Claude in a vertical split on the right
   - Fixed width of 80 columns

## Configuration

You can customize the plugin behavior through the setup function:

```lua
require("claude").setup({
    -- Path to Claude CLI executable
    claude_path = "/opt/homebrew/bin/claude",

    -- Keymaps
    keymaps = {
        execute = "<leader>CC",      -- Horizontal split
        execute_float = "<leader>CF", -- Floating window
        execute_right = "<leader>CR", -- Right split
    },

    -- Floating window settings
    float = {
        width = 0.8,    -- Percentage of screen width
        height = 0.8,   -- Percentage of screen height
        border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    },
})
```

## License

MIT
