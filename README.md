# Claude.nvim 🤖

A minimalist yet powerful Neovim plugin for seamless integration with Anthropic's Claude CLI.

## Features

- 🚀 Multiple ways to open Claude:
  - Horizontal split (`<leader>CC` or `:Claude`)
  - Floating window (`<leader>CF` or `:ClaudeFloat`)
  - Right split (`<leader>CR` or `:ClaudeRight`)
- 💡 Rich Context Support:
  - Send text selections directly to Claude (`<leader>CS`)
  - Send entire buffer context (`<leader>CB`)
  - Include git diff information (`<leader>CD`)
  - LSP diagnostics integration
- 📝 Enhanced Response Handling:
  - Syntax highlighting for code blocks
  - Markdown rendering
  - Easy code snippet copying (`<leader>CY`)
- 🎨 Customizable UI:
  - Theme integration with Neovim colorscheme
  - Status line integration
  - Floating window customization
- 📚 Smart Features:
  - Command history with per-project support
  - Common development task templates
  - Context-aware responses
- 🔧 Debug Tools:
  - Built-in debug mode (`<leader>CD` or `:ClaudeDebug`)
  - Function testing and validation
  - Detailed logging window
  - Configuration verification

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
        send_buffer = "<leader>CB",
        send_git_diff = "<leader>CD",
        copy_response = "<leader>CY",
        debug = "<leader>CD",
      },
      -- Enable features as needed
      context = {
        include_buffer = false,
        include_git = false,
        include_lsp = false,
      },
      ui = {
        syntax_highlight = true,
        markdown_render = true,
        status_line = true,
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
    send_buffer = "<leader>CB",    -- Send buffer context
    send_git_diff = "<leader>CD",  -- Send git diff
    copy_response = "<leader>CY",  -- Copy response
    debug = "<leader>CD",          -- Run debug mode
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
    per_project = true,  -- Save history per project
  },
  ui = {
    syntax_highlight = true,     -- Syntax highlighting in responses
    markdown_render = true,      -- Markdown rendering
    status_line = true,         -- Status line integration
    theme = {
      inherit = true,           -- Inherit from Neovim colorscheme
      response_bg = nil,        -- Custom response background
      code_bg = nil,           -- Custom code block background
    },
  },
  context = {
    include_buffer = false,     -- Include current buffer
    include_git = false,        -- Include git context
    include_lsp = false,        -- Include LSP diagnostics
    max_context_lines = 100,    -- Max lines of context
  },
  templates = {
    code_review = "Please review this code:\n",
    explain = "Please explain this code:\n",
    refactor = "Please suggest refactoring for:\n",
    document = "Please document this code:\n",
  },
}
```

## Debug Mode

The plugin includes a comprehensive debug mode that can be activated using `<leader>CD` or `:ClaudeDebug`. This opens a log window that tests and validates:

- Configuration settings
- Context gathering functions
- Rendering capabilities
- Syntax highlighting
- Markdown rendering
- Git integration
- LSP integration

The debug log provides detailed information about:
- System environment
- Neovim version
- Available features
- Test results
- Any potential issues

This is particularly useful for:
- Troubleshooting issues
- Verifying configuration
- Checking feature availability
- Testing new installations

## License

MIT

---
Made with ❤️ by [h4ckm1n](https://github.com/h4ckm1n-dev)
