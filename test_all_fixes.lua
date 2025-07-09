-- Test all fixes for Claude plugin
vim.opt.runtimepath:append('/Users/h4ckm1n/Documents/Repositorie/Perso/claude-nvim')

local claude = require('claude')
local logger = require('claude.utils.logger')
local context = require('claude.utils.context')
local session = require('claude.utils.session')
local actions = require('claude.utils.actions')

-- print("=== Testing All Claude Plugin Fixes ===")

-- Clear log
logger.clear_log()

-- Test 1: Plugin setup with correct path
-- print("\n1. Testing plugin setup with correct Claude path...")
local success, err = pcall(function()
  claude.setup({
    claude_path = "/Users/h4ckm1n/.claude/local/claude",
    logger = { level = "DEBUG" }
  })
  -- print("✓ Plugin setup successful with correct path")
end)

if not success then
  -- print("✗ Plugin setup failed:", err)
  return
end

-- Test 2: Test all keymap functions exist
-- print("\n2. Testing that all keymap functions are implemented...")
local config = claude.config or {}
local missing_functions = {}
local keymap_functions = {
  execute = "execute_claude_split",
  execute_float = "execute_claude_float", 
  execute_right = "execute_claude_right",
  send_selection = "send_selection",
  send_buffer = "send_buffer",
  send_git_diff = "send_git_diff",
  execute_with_line = "execute_with_line",
  copy_response = "copy_response",
  quick_review = "template function",
  explain_code = "template function"
}

for action, func_name in pairs(keymap_functions) do
  if config.keymaps and config.keymaps[action] then
    -- print("✓ Keymap function implemented:", action, "->", func_name)
  else
    table.insert(missing_functions, action)
  end
end

if #missing_functions > 0 then
  -- print("✗ Missing keymap functions:", table.concat(missing_functions, ", "))
else
  -- print("✓ All keymap functions implemented")
end

-- Test 3: Test git integration improvements
-- print("\n3. Testing improved git integration...")
local git_branch = context.get_git_branch()
if git_branch then
  -- print("✓ Git branch detected:", git_branch)
else
  -- print("△ No git branch (expected if not in git repo)")
end

local git_status = context.get_git_status()
if git_status then
  -- print("✓ Git status found:", #git_status, "characters")
else
  -- print("△ No git status changes (expected if clean repo)")
end

local git_diff = context.get_git_context()
if git_diff then
  -- print("✓ Git diff found:", #git_diff, "characters")
else
  -- print("△ No git diff (expected if clean repo)")
end

-- Test 4: Test visual selection improvements
-- print("\n4. Testing visual selection improvements...")
vim.cmd('edit /Users/h4ckm1n/Documents/Repositorie/Perso/claude-nvim/lua/claude/init.lua')

-- Simulate a visual selection by setting marks
vim.cmd('normal! gg')
vim.cmd('normal! V')
vim.cmd('normal! 3j')
vim.cmd('normal! <Esc>')

local visual_selection = context.get_visual_selection()
if visual_selection then
  -- print("✓ Visual selection retrieved")
  -- print("  - Start line:", visual_selection.start_line)
  -- print("  - End line:", visual_selection.end_line)
  -- print("  - Content length:", #visual_selection.content)
else
  -- print("△ No visual selection (expected in headless mode)")
end

-- Test 5: Test context building
-- print("\n5. Testing context building...")
local file_context = context.get_current_file_context()
if file_context then
  -- print("✓ File context built")
  -- print("  - Filename:", file_context.filename)
  -- print("  - Lines:", file_context.total_lines)
else
  -- print("✗ File context failed")
end

local buffer_context = context.get_buffer_context()
if buffer_context then
  -- print("✓ Buffer context built")
  -- print("  - Content length:", #buffer_context.content)
else
  -- print("✗ Buffer context failed")
end

-- Test 6: Test session management
-- print("\n6. Testing session management...")
local project_name = session.get_project_name()
-- print("✓ Project name:", project_name)

local session_info = session.get_session_info()
-- print("✓ Session info:", session_info)

-- Test 7: Test actions
-- print("\n7. Testing actions...")
local claude_response = [[
Here's the solution:

```lua
function hello()
  -- print("Hello, World!")
end
```

```python
def hello():
    -- print("Hello, World!")
```
]]

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(claude_response, '\n'))

local code_stats = actions.get_code_stats(buf)
-- print("✓ Code stats:", code_stats)

-- Clean up
vim.api.nvim_buf_delete(buf, { force = true })

-- Test 8: Test new user commands
-- print("\n8. Testing new user commands...")
local new_commands = {
  'ClaudeSendSelection',
  'ClaudeSendBuffer', 
  'ClaudeSendDiff',
  'ClaudeWithLine',
  'ClaudeCopyResponse'
}

for _, cmd in ipairs(new_commands) do
  if vim.fn.exists(':' .. cmd) == 2 then
    -- print("✓ Command exists:", cmd)
  else
    -- print("✗ Command missing:", cmd)
  end
end

-- Test 9: Test logging
-- print("\n9. Testing logging...")
logger.info("Test message after fixes")
logger.debug("Debug message with data", { test = "all_fixes" })
logger.warn("Warning message")
logger.error("Error message", { context = "fix_testing" })

local log_stats = logger.get_log_stats()
-- print("✓ Log file:", log_stats.exists and log_stats.size_human or "N/A")

-- Test 10: Test Claude CLI path
-- print("\n10. Testing Claude CLI path...")
local claude_path = "/Users/h4ckm1n/.claude/local/claude"
local result = vim.fn.system("test -f " .. claude_path)
if vim.v.shell_error == 0 then
  -- print("✓ Claude CLI exists at configured path")
else
  -- print("✗ Claude CLI not found at:", claude_path)
end

-- Test if it's executable
local result2 = vim.fn.system("test -x " .. claude_path)
if vim.v.shell_error == 0 then
  -- print("✓ Claude CLI is executable")
else
  -- print("✗ Claude CLI is not executable")
end

-- print("\n=== All Fixes Test Complete ===")
-- print("Log file location:", logger.config.file_path)
-- print("Check the log file for detailed debugging information!")

-- Summary
-- print("\n=== FIX SUMMARY ===")
-- print("✓ Claude CLI path: Fixed to /Users/h4ckm1n/.claude/local/claude")
-- print("✓ Missing keymap functions: All implemented")
-- print("✓ Git integration: Improved with better error handling")
-- print("✓ Visual selection: Enhanced with mode detection")
-- print("✓ User commands: Added for all new functions")
-- print("✓ Logging: Comprehensive debug logging added")
-- print("✓ Error handling: Improved throughout plugin")