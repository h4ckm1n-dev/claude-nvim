# Claude.nvim 🤖

A minimalist Neovim plugin for seamless integration with Anthropic's Claude CLI.

## Features

- 🚀 Three ways to open Claude:
  - Horizontal split (`<leader>CC` or `:Claude`)
  - Floating window (`<leader>CF` or `:ClaudeFloat`)
  - Right split (`<leader>CR` or `:ClaudeRight`)
- 💡 Send text selections directly to Claude
- 📝 Command history support
- 🎨 Customizable UI with floating window options

## Prerequisites

- Neovim >= 0.8.0
- [Claude CLI](https://github.com/anthropics/claude-cli) installed and configured

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add to your plugin specifications in `lua/plugins/claude.lua`:

```lua
return {
  "h4ckm1n-dev/claude-nvim",
  event = "VeryLazy",
  config = function()
    require("claude").setup({
      -- Optional: override default configuration
      keymaps = {
        execute = "<leader>CC",
        execute_float = "<leader>CF",
        execute_right = "<leader>CR",
        send_selection = "<leader>CS",
        execute_with_line = "<leader>CL",
      },
    })
  end,
}
```

## Default Configuration

```lua
{
  keymaps = {
    execute = "<leader>CC",        -- Open in horizontal split
    execute_float = "<leader>CF",  -- Open in floating window
    execute_right = "<leader>CR",  -- Open in right split
    send_selection = "<leader>CS", -- Send selection to Claude
    execute_with_line = "<leader>CL", -- Execute with current line
  },
  float = {
    width = 0.8,      -- 80% of screen width
    height = 0.8,     -- 80% of screen height
    border = "rounded",
    title = " Claude AI ",
    winblend = 0,
    title_pos = "center",
  },
  history = {
    enabled = true,
    save_path = vim.fn.stdpath("data") .. "/claude_history",
    max_entries = 100,
  },
}
```

## License

MIT

---
Made with ❤️ by [h4ckm1n](https://github.com/h4ckm1n-dev)
