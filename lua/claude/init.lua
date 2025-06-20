local M = {}

-- Default configuration
M.config = {
  claude_path = "/opt/homebrew/bin/claude",
  keymaps = {
    execute = "<leader>CC",           -- Execute in split
    execute_float = "<leader>CF",     -- Execute in float
    execute_right = "<leader>CR",     -- Execute in right split
    send_selection = "<leader>CS",    -- Send selection
    execute_with_line = "<leader>CL", -- Execute with line
    send_buffer = "<leader>CB",       -- Send buffer
    send_git_diff = "<leader>CG",     -- Send git diff
    copy_response = "<leader>CY",     -- Copy response
    debug = "<leader>CT",             -- Debug mode
  },
  float = {
    width = 0.35, -- 35% of screen width
    height = 0.8, -- 80% of screen height
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

-- Handle terminal exit
local function handle_terminal_exit(win, buf, mode)
  return function()
    -- Save window position and size for restoration if needed
    local win_config = win and vim.api.nvim_win_get_config(win) or nil

    -- Clean up the buffer
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    -- Clean up the window
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    -- Show exit message
    vim.schedule(function()
      vim.notify(
        string.format("Claude AI (%s) session ended", mode),
        vim.log.levels.INFO,
        {
          title = "Claude.nvim",
          icon = "🤖",
          timeout = 3000
        }
      )
    end)
  end
end

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

  -- Start terminal with exit handler
  vim.fn.termopen(config.claude_path, {
    on_exit = handle_terminal_exit(win, buf, "float")
  })

  -- Enter terminal mode
  vim.cmd('startinsert')
end

-- Execute Claude in right split
local function execute_claude_right()
  -- Create right split
  vim.cmd('botright vsplit')

  -- Set width to 35% of screen width
  local width = math.floor(vim.o.columns * 0.35)
  vim.cmd('vertical resize ' .. width)

  -- Create terminal buffer
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "buftype", "terminal")

  -- Start terminal with exit handler
  vim.fn.termopen(config.claude_path, {
    on_exit = handle_terminal_exit(win, buf, "right split")
  })

  -- Enter terminal mode
  vim.cmd('startinsert')
end

-- Execute Claude in horizontal split (original function)
local function execute_claude_split()
  -- Create a new split
  vim.cmd('split')

  -- Create terminal buffer
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "buftype", "terminal")

  -- Start terminal with exit handler
  vim.fn.termopen(config.claude_path, {
    on_exit = handle_terminal_exit(win, buf, "horizontal split")
  })

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

  -- Update config with user settings
  config = vim.tbl_deep_extend("force", M.config, user_config or {})

  -- Validate keymaps for conflicts
  local used_keys = {}
  for action, key in pairs(config.keymaps) do
    if used_keys[key] then
      vim.notify(string.format(
        "Claude.nvim: Keymap conflict detected! %s and %s both use %s",
        used_keys[key], action, key
      ), vim.log.levels.WARN)
    end
    used_keys[key] = action
  end

  -- Set up keymaps
  for action, key in pairs(config.keymaps) do
    local cmd
    if action == "execute" then
      cmd = execute_claude_split
    elseif action == "execute_float" then
      cmd = execute_claude_float
    elseif action == "execute_right" then
      cmd = execute_claude_right
    elseif action == "debug" then
      cmd = function() require('claude.utils.debug').run_debug(config) end
      -- Add other actions as needed
    end

    if cmd then
      vim.keymap.set("n", key, cmd, {
        noremap = true,
        silent = true,
        desc = "Claude: " .. action
      })
    end
  end

  -- Create commands
  create_commands()

  -- Print completion
  vim.notify("Claude plugin setup complete!")
end

return M
