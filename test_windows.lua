-- Test window functions
vim.opt.runtimepath:append('/Users/h4ckm1n/Documents/Repositorie/Perso/claude-nvim')

local claude = require('claude')
local logger = require('claude.utils.logger')

-- print("=== Testing Window Functions ===")

-- Setup with correct path
claude.setup({
  claude_path = "/Users/h4ckm1n/.claude/local/claude",
  logger = { level = "DEBUG" }
})

-- Test 1: Float window (non-blocking test)
-- print("\n1. Testing float window creation...")
local success, err = pcall(function()
  -- We'll test the internal functions instead of the full window
  local M = require('claude')
  
  -- Test window calculation
  local width = math.floor(vim.o.columns * 0.35)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- print("✓ Window dimensions calculated:")
  -- print("  - Width:", width)
  -- print("  - Height:", height)
  -- print("  - Row:", row)
  -- print("  - Col:", col)
  
  -- Test buffer creation
  local buf = vim.api.nvim_create_buf(false, true)
  -- print("✓ Buffer created:", buf)
  
  -- Test window options
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Claude AI Test ",
    title_pos = "center",
  }
  
  -- Test if we can create window
  local win = vim.api.nvim_open_win(buf, false, opts)
  -- print("✓ Window created:", win)
  
  -- Clean up
  vim.api.nvim_win_close(win, true)
  vim.api.nvim_buf_delete(buf, { force = true })
  -- print("✓ Window and buffer cleaned up")
end)

if success then
  -- print("✓ Float window test passed")
else
  -- print("✗ Float window test failed:", err)
end

-- Test 2: Test context building
-- print("\n2. Testing context building...")
vim.cmd('edit /Users/h4ckm1n/Documents/Repositorie/Perso/claude-nvim/lua/claude/init.lua')

local context = require('claude.utils.context')
local success, err = pcall(function()
  local file_context = context.get_current_file_context()
  local project_info = context.get_project_info()
  
  -- print("✓ File context:")
  -- print("  - Filename:", file_context.filename)
  -- print("  - Total lines:", file_context.total_lines)
  
  -- print("✓ Project info:")
  -- print("  - Name:", project_info.name)
  -- print("  - Type:", project_info.type)
end)

if success then
  -- print("✓ Context building test passed")
else
  -- print("✗ Context building test failed:", err)
end

-- Test 3: Test terminal command preparation
-- print("\n3. Testing terminal command preparation...")
local success, err = pcall(function()
  -- Check if claude command exists
  local claude_path = "/Users/h4ckm1n/.claude/local/claude"
  local cmd = claude_path .. ' 2>/dev/null'
  
  -- print("✓ Command prepared:", cmd)
  
  -- Test if claude exists
  local result = vim.fn.system("which " .. claude_path)
  if vim.v.shell_error == 0 then
    -- print("✓ Claude CLI found at:", claude_path)
  else
    -- print("✗ Claude CLI not found, trying alternative...")
    local alt_result = vim.fn.system("which claude")
    if vim.v.shell_error == 0 then
      -- print("✓ Claude found via PATH:", alt_result:gsub("\n", ""))
    else
      -- print("✗ Claude CLI not available")
    end
  end
end)

if success then
  -- print("✓ Terminal command test passed")
else
  -- print("✗ Terminal command test failed:", err)
end

-- Test 4: Test actions
-- print("\n4. Testing actions...")
local actions = require('claude.utils.actions')
local success, err = pcall(function()
  -- Create a buffer with test Claude response
  local claude_response = [[
Here's a solution:

```lua
function test()
  -- print("test")
end
```
]]
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(claude_response, '\n'))
  
  local stats = actions.get_code_stats(buf)
  -- print("✓ Code stats:", stats)
  
  -- Clean up
  vim.api.nvim_buf_delete(buf, { force = true })
end)

if success then
  -- print("✓ Actions test passed")
else
  -- print("✗ Actions test failed:", err)
end

-- Test 5: Test session management
-- print("\n5. Testing session management...")
local session = require('claude.utils.session')
local success, err = pcall(function()
  local project_name = session.get_project_name()
  -- print("✓ Project name:", project_name)
  
  local session_info = session.get_session_info()
  -- print("✓ Session info:", session_info)
  
  -- Test session directory
  local session_dir = vim.fn.stdpath("data") .. "/claude_sessions"
  -- print("✓ Session directory:", session_dir)
  -- print("✓ Directory exists:", vim.fn.isdirectory(session_dir) == 1)
end)

if success then
  -- print("✓ Session management test passed")
else
  -- print("✗ Session management test failed:", err)
end

-- print("\n=== Window Function Tests Complete ===")
local log_stats = logger.get_log_stats()
-- print("Check log for details:", logger.config.file_path)
-- print("Log size:", log_stats.exists and log_stats.size_human or "N/A")