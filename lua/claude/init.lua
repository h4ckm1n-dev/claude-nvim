local M = {}

-- Default configuration
local default_config = {
  claude_path = "/opt/homebrew/bin/claude",
  keymaps = {
    execute = "<leader>CC",
    execute_float = "<leader>CF",
    execute_right = "<leader>CR",
  },
  float = {
    width = 0.8,  -- Percentage of screen width
    height = 0.8, -- Percentage of screen height
    border = "rounded",
  },
}

local config = default_config

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
    title = " Claude AI ",
    title_pos = "center",
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, "winblend", 0)
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
end

-- Initialize the plugin
function M.setup(user_config)
  -- Print debug info
  vim.notify("Setting up Claude plugin...")

  -- Update config
  config = vim.tbl_deep_extend("force", default_config, user_config or {})

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

  -- Create commands
  create_commands()

  -- Print completion
  vim.notify("Claude plugin setup complete!")
end

return M
