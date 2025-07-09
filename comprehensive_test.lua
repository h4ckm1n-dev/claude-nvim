-- Comprehensive test script for Claude plugin
vim.opt.runtimepath:append('/Users/h4ckm1n/Documents/Repositorie/Perso/claude-nvim')

local claude = require('claude')
local logger = require('claude.utils.logger')
local context = require('claude.utils.context')
local session = require('claude.utils.session')
local actions = require('claude.utils.actions')

-- print("=== Comprehensive Claude Plugin Test ===")

-- Clear previous logs
logger.clear_log()

-- Test 1: Setup with correct Claude path
-- print("\n1. Testing setup with correct Claude path...")
local config = {
  claude_path = "/Users/h4ckm1n/.claude/local/claude",
  float = {
    width = 0.35,
    height = 0.8,
  },
  logger = {
    level = "DEBUG",
    enabled = true,
  }
}

local success, err = pcall(function()
  claude.setup(config)
  -- print("✓ Plugin setup with custom config successful")
end)

if not success then
  -- print("✗ Plugin setup failed:", err)
  return
end

-- Test 2: File context with actual file
-- print("\n2. Testing file context with actual file...")
vim.cmd('edit /Users/h4ckm1n/Documents/Repositorie/Perso/claude-nvim/lua/claude/init.lua')
local file_context = context.get_current_file_context()
if file_context then
  -- print("✓ File context retrieved:")
  -- print("  - Filename:", file_context.filename)
  -- print("  - Lines:", file_context.total_lines)
  -- print("  - Filetype:", file_context.filetype)
  -- print("  - Cursor line:", file_context.cursor_line)
else
  -- print("✗ Failed to get file context")
end

-- Test 3: Smart context building
-- print("\n3. Testing smart context building...")
local smart_context = context.get_smart_context({
  include_file = true,
  include_errors = true,
  include_git = false
})
if smart_context and #smart_context > 0 then
  -- print("✓ Smart context built")
  -- print("  - Context length:", #smart_context)
  -- print("  - First 100 chars:", smart_context:sub(1, 100) .. "...")
else
  -- print("✗ Failed to build smart context")
end

-- Test 4: Git context
-- print("\n4. Testing git context...")
local git_context = context.get_git_context()
if git_context then
  -- print("✓ Git context retrieved")
  -- print("  - Diff length:", #git_context)
else
  -- print("✗ No git context available")
end

local git_branch = context.get_git_branch()
if git_branch then
  -- print("✓ Git branch:", git_branch)
else
  -- print("✗ No git branch found")
end

-- Test 5: LSP context
-- print("\n5. Testing LSP context...")
local lsp_context = context.get_lsp_context()
-- print("✓ LSP context retrieved")
-- print("  - Diagnostics count:", #lsp_context)

local lsp_errors = context.get_lsp_errors()
-- print("✓ LSP errors retrieved")
-- print("  - Error count:", #lsp_errors)

-- Test 6: Session management
-- print("\n6. Testing session management...")
local project_name = session.get_project_name()
-- print("✓ Project name:", project_name)

local session_info = session.get_session_info()
-- print("✓ Session info:", session_info)

-- Test session save/load
local test_buf = vim.api.nvim_create_buf(false, true)
session.save_session(test_buf)
local loaded_session = session.load_session()
-- print("✓ Session save/load test")
-- print("  - Loaded session:", vim.inspect(loaded_session))

-- Test 7: Actions with real Claude response
-- print("\n7. Testing actions with simulated Claude response...")
local claude_response = [[
Here's the solution:

```lua
local function hello_world()
  -- print("Hello, World!")
  return "success"
end
```

You could also do it in JavaScript:

```javascript
function helloWorld() {
  console.log("Hello, World!");
  return "success";
}
```

Or in Python:

```python
def hello_world():
    -- print("Hello, World!")
    return "success"
```
]]

vim.cmd('enew')
vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(claude_response, '\n'))
local current_buf = vim.api.nvim_get_current_buf()

local code_stats = actions.get_code_stats(current_buf)
-- print("✓ Code stats:", code_stats)

-- Test 8: Error handling
-- print("\n8. Testing error handling...")
local success, err = pcall(function()
  context.get_buffer_context()
end)
-- print("✓ Error handling test:", success and "passed" or "failed")

-- Test 9: Logger edge cases
-- print("\n9. Testing logger edge cases...")
logger.error("Test error with context", {
  test_data = "complex_data",
  nested = {
    value = 123,
    array = {1, 2, 3}
  }
})

logger.log_error_with_context("Test error with full context", 
  "simulated error", 
  { context = "comprehensive test" })

-- Test 10: Project info
-- print("\n10. Testing project info...")
local project_info = context.get_project_info()
-- print("✓ Project info:")
-- print("  - Name:", project_info.name)
-- print("  - Path:", project_info.path)
-- print("  - Type:", project_info.type)
-- print("  - Git branch:", project_info.git_branch)

-- Test 11: Visual selection simulation
-- print("\n11. Testing visual selection...")
vim.cmd('normal! gg')
vim.cmd('normal! V')
vim.cmd('normal! 3j')
local visual_selection = context.get_visual_selection()
if visual_selection then
  -- print("✓ Visual selection retrieved")
  -- print("  - Start line:", visual_selection.start_line)
  -- print("  - End line:", visual_selection.end_line)
  -- print("  - Content length:", #visual_selection.content)
else
  -- print("✗ Failed to get visual selection")
end

-- print("\n=== Test Complete ===")
local log_stats = logger.get_log_stats()
-- print("Log file:", logger.config.file_path)
-- print("Log size:", log_stats.exists and log_stats.size_human or "N/A")
-- print("\nCheck the log file for detailed debugging information!")