local M = {}

-- Default configuration
M.config = {
  claude_path = "/opt/homebrew/bin/claude",
  keymaps = {
    execute = "<leader>CC",
    execute_float = "<leader>CF",
    execute_right = "<leader>CR",
    send_selection = "<leader>CS",
    execute_with_line = "<leader>CL",
    send_buffer = "<leader>CB",   -- New: send entire buffer
    send_git_diff = "<leader>CG", -- Changed from CD to CG for git diff
    copy_response = "<leader>CY", -- New: copy response
    debug = "<leader>CT",         -- Debug mode
  },
  float = {
    width = 0.8,  -- Percentage of screen width
    height = 0.8, -- Percentage of screen height
    border = "rounded",
    title = " Claude AI ",
    winblend = 0,
    title_pos = "center",
  },
  history = {
    enabled = true,
    save_path = vim.fn.stdpath("data") .. "/claude_history",
    max_entries = 100,
    per_project = true, -- New: save history per project
  },
  ui = {
    syntax_highlight = true, -- New: syntax highlighting in responses
    markdown_render = true,  -- New: markdown rendering
    status_line = true,      -- New: status line integration
    theme = {                -- New: theme configuration
      inherit = true,        -- Inherit from Neovim colorscheme
      response_bg = nil,     -- Custom response background
      code_bg = nil,         -- Custom code block background
    },
  },
  context = {                -- New: context configuration
    include_buffer = false,  -- Include current buffer
    include_git = false,     -- Include git context
    include_lsp = false,     -- Include LSP diagnostics
    max_context_lines = 100, -- Max lines of context
  },
  templates = {              -- New: prompt templates
    code_review = "Please review this code:\n",
    explain = "Please explain this code:\n",
    refactor = "Please suggest refactoring for:\n",
    document = "Please document this code:\n",
  },
}

local config = M.config

-- Execute Claude in a floating window
local function execute_claude_float()
  -- Calculate window size
  local width = math.floor(vim.o.columns * config.float.width)
  local height = math.floor(vim.o.lines * config.float.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set up window options
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.float.border,
    title = config.float.title,
    title_pos = config.float.title_pos,
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, "winblend", config.float.winblend)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- Start terminal
  vim.fn.termopen(config.claude_path, {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  })

  -- Enter terminal mode
  vim.cmd('startinsert')
end

-- Execute Claude in right split
local function execute_claude_right()
  -- Create right split
  vim.cmd('botright vsplit')

  -- Set width to 80 columns
  vim.cmd('vertical resize 80')

  -- Create terminal buffer
  vim.cmd('terminal ' .. config.claude_path)

  -- Set buffer options
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, "buftype", "terminal")

  -- Enter terminal mode
  vim.cmd('startinsert')
end

-- Execute Claude in horizontal split (original function)
local function execute_claude_split()
  -- Create a new split
  vim.cmd('split')

  -- Create terminal buffer
  vim.cmd('terminal ' .. config.claude_path)

  -- Set buffer options
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, "buftype", "terminal")

  -- Enter terminal mode
  vim.cmd('startinsert')
end

-- Create commands
local function create_commands()
  vim.api.nvim_create_user_command('Claude', execute_claude_split, {})
  vim.api.nvim_create_user_command('ClaudeFloat', execute_claude_float, {})
  vim.api.nvim_create_user_command('ClaudeRight', execute_claude_right, {})
  vim.api.nvim_create_user_command('ClaudeDebug', function()
    require('claude.utils.debug').run_debug(config)
  end, {})
end

-- Initialize the plugin
function M.setup(user_config)
  -- Print debug info
  vim.notify("Setting up Claude plugin...")

  -- Update config
  config = vim.tbl_deep_extend("force", M.config, user_config or {})

  -- Set up keymaps
  vim.keymap.set("n", config.keymaps.execute, execute_claude_split, {
    noremap = true,
    silent = true,
    desc = "Execute Claude in split"
  })

  vim.keymap.set("n", config.keymaps.execute_float, execute_claude_float, {
    noremap = true,
    silent = true,
    desc = "Execute Claude in floating window"
  })

  vim.keymap.set("n", config.keymaps.execute_right, execute_claude_right, {
    noremap = true,
    silent = true,
    desc = "Execute Claude in right split"
  })

  vim.keymap.set("n", config.keymaps.debug, function()
    require('claude.utils.debug').run_debug(config)
  end, {
    noremap = true,
    silent = true,
    desc = "Run Claude debug mode"
  })

  -- Create commands
  create_commands()

  -- Print completion
  vim.notify("Claude plugin setup complete!")
end

return M
