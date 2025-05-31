local M = {}

-- Import required modules
local context = require('claude.utils.context')
local render = require('claude.utils.render')

-- Create a log buffer and window
local function create_log_window()
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'log')
  vim.api.nvim_buf_set_name(buf, 'Claude Debug Log')

  -- Calculate window size
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Claude Debug Log ',
    title_pos = 'center',
  })

  return buf, win
end

-- Log function
local function log(buf, message, level)
  level = level or 'INFO'
  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  local log_line = string.format('[%s] [%s] %s', timestamp, level, message)

  local lines = vim.split(log_line, '\n')
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

-- Test context functions
local function test_context(buf, config)
  log(buf, '=== Testing Context Functions ===')

  -- Test buffer context
  local buffer_context = context.get_buffer_context()
  log(buf, 'Buffer Context Test:')
  log(buf, string.format('  Filetype: %s', buffer_context.filetype))
  log(buf, string.format('  Filename: %s', buffer_context.filename))
  log(buf, string.format('  Content length: %d', #buffer_context.content))

  -- Test git context
  local git_context = context.get_git_context()
  log(buf, 'Git Context Test:')
  if git_context then
    log(buf, '  Git diff available')
    log(buf, string.format('  Diff length: %d', #git_context))
  else
    log(buf, '  No git diff available', 'WARN')
  end

  -- Test LSP context
  local lsp_context = context.get_lsp_context()
  log(buf, 'LSP Context Test:')
  log(buf, string.format('  Number of diagnostics: %d', #lsp_context))

  -- Test full context build
  local full_context = context.build_context(config)
  log(buf, 'Full Context Build Test:')
  for key, _ in pairs(full_context) do
    log(buf, string.format('  Context type available: %s', key))
  end
end

-- Test rendering functions
local function test_render(buf)
  log(buf, '=== Testing Render Functions ===')

  -- Create a test buffer
  local test_buf = vim.api.nvim_create_buf(false, true)

  -- Test code highlighting
  local test_code = [[
```lua
local function test()
  return "hello"
end
```
]]
  log(buf, 'Testing Code Highlighting:')
  local success, err = pcall(function()
    render.highlight_code(test_buf, test_code)
    log(buf, '  Code highlighting successful')
  end)
  if not success then
    log(buf, string.format('  Code highlighting failed: %s', err), 'ERROR')
  end

  -- Test markdown rendering
  local test_markdown = [[
# Title
## Subtitle
**Bold text**
_Italic text_
`code`
- List item
]]
  log(buf, 'Testing Markdown Rendering:')
  success, err = pcall(function()
    render.render_markdown(test_buf, test_markdown)
    log(buf, '  Markdown rendering successful')
  end)
  if not success then
    log(buf, string.format('  Markdown rendering failed: %s', err), 'ERROR')
  end

  -- Clean up test buffer
  vim.api.nvim_buf_delete(test_buf, { force = true })
end

-- Test configuration
local function test_config(buf, config)
  log(buf, '=== Testing Configuration ===')

  -- Check required fields
  local required_fields = {
    'keymaps', 'float', 'history', 'ui', 'context', 'templates'
  }

  for _, field in ipairs(required_fields) do
    if config[field] then
      log(buf, string.format('  Config section present: %s', field))
    else
      log(buf, string.format('  Missing config section: %s', field), 'ERROR')
    end
  end

  -- Check keymaps
  for key, mapping in pairs(config.keymaps) do
    log(buf, string.format('  Keymap %s -> %s', key, mapping))
  end
end

-- Main debug function
function M.run_debug(config)
  -- Create log window
  local buf, win = create_log_window()

  -- Log start
  log(buf, 'Starting Claude.nvim debug session')
  log(buf, string.format('Neovim version: %s', vim.version()))
  log(buf, string.format('OS: %s', vim.loop.os_uname().sysname))

  -- Run tests
  test_config(buf, config)
  test_context(buf, config)
  test_render(buf)

  -- Log completion
  log(buf, '=== Debug session completed ===')

  -- Return to normal mode
  vim.cmd('normal! G')
  vim.cmd('setlocal nomodifiable')
end

return M
