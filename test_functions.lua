-- Test script for Claude plugin functions
vim.opt.runtimepath:append('/Users/h4ckm1n/Documents/Repositorie/Perso/claude-nvim')

local claude = require('claude')
local logger = require('claude.utils.logger')
local context = require('claude.utils.context')
local session = require('claude.utils.session')
local actions = require('claude.utils.actions')

print("=== Testing Claude Plugin Functions ===")

-- Test 1: Basic setup
print("\n1. Testing basic setup...")
local success, err = pcall(function()
  claude.setup()
  print("✓ Plugin setup successful")
end)

if not success then
  print("✗ Plugin setup failed:", err)
  return
end

-- Test 2: Context functions
print("\n2. Testing context functions...")

-- Create a test file
vim.cmd('enew')
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "-- Test Lua file",
  "local M = {}",
  "",
  "function M.test()",
  "  print('Hello, World!')",
  "end",
  "",
  "return M"
})
vim.bo.filetype = 'lua'

local file_context = context.get_current_file_context()
if file_context then
  print("✓ File context retrieved:", file_context.filename)
  print("  - Lines:", file_context.total_lines)
  print("  - Filetype:", file_context.filetype)
else
  print("✗ Failed to get file context")
end

local buffer_context = context.get_buffer_context()
if buffer_context then
  print("✓ Buffer context retrieved")
  print("  - Content length:", #buffer_context.content)
else
  print("✗ Failed to get buffer context")
end

-- Test 3: Session management
print("\n3. Testing session management...")
local project_name = session.get_project_name()
print("✓ Project name:", project_name)

local session_info = session.get_session_info()
print("✓ Session info:", session_info)

-- Test 4: Actions (code extraction)
print("\n4. Testing actions...")
local test_text = [[
Here's some code:

```lua
function hello()
  print("Hello!")
end
```

And some more:

```javascript
console.log("Test");
```
]]

-- Create a buffer with test text
vim.cmd('enew')
vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(test_text, '\n'))
local current_buf = vim.api.nvim_get_current_buf()

-- Test code extraction by calling the internal function
local success, code_stats = pcall(function()
  return actions.get_code_stats(current_buf)
end)

if success then
  print("✓ Code extraction successful")
  print("  - Stats:", code_stats)
else
  print("✗ Code extraction failed:", code_stats)
end

-- Test 5: Logger functions
print("\n5. Testing logger functions...")
logger.info("Test log message", {test = true})
logger.debug("Debug message", {debug_data = "test"})
logger.warn("Warning message")
logger.error("Error message", {error_context = "test"})

local log_stats = logger.get_log_stats()
if log_stats.exists then
  print("✓ Log file created:", log_stats.size_human)
else
  print("✗ Log file not created")
end

print("\n=== Function Testing Complete ===")
print("Check the log file for detailed information:")
print("  " .. logger.config.file_path)