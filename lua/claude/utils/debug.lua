local M = {}

-- Import required modules
local context = require('claude.utils.context')
local render = require('claude.utils.render')

-- Debug results table
local debug_results = {
  config = { status = 'pending', issues = {} },
  context = { status = 'pending', issues = {} },
  render = { status = 'pending', issues = {} },
  system = { status = 'pending', issues = {} }
}

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

-- Log function with result tracking
local function log(buf, message, level, category)
  level = level or 'INFO'
  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  local log_line = string.format('[%s] [%s] %s', timestamp, level, message)

  -- Track issues
  if category and level == 'ERROR' then
    table.insert(debug_results[category].issues, message)
    debug_results[category].status = 'failed'
  elseif category and level == 'WARN' then
    table.insert(debug_results[category].issues, message)
    if debug_results[category].status == 'pending' then
      debug_results[category].status = 'warning'
    end
  end

  local lines = vim.split(log_line, '\n')
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

-- Test system requirements
local function test_system(buf)
  log(buf, '=== Testing System Requirements ===', 'INFO', 'system')

  local all_passed = true

  -- Check Neovim version
  local nvim_version = vim.version()
  if nvim_version.major >= 0 and nvim_version.minor >= 8 then
    log(buf, string.format('  Neovim version OK: %d.%d', nvim_version.major, nvim_version.minor), 'INFO', 'system')
  else
    all_passed = false
    log(buf, string.format('  Neovim version below recommended (0.8.0): %d.%d', nvim_version.major, nvim_version.minor),
      'WARN', 'system')
  end

  -- Check Claude CLI
  local claude_exists = vim.fn.executable('claude')
  if claude_exists == 1 then
    log(buf, '  Claude CLI found', 'INFO', 'system')
  else
    all_passed = false
    log(buf, '  Claude CLI not found in PATH', 'ERROR', 'system')
  end

  -- Check for required Neovim features
  local required_features = { 'nvim_create_buf', 'nvim_open_win', 'nvim_buf_set_lines' }
  for _, feature in ipairs(required_features) do
    if vim.fn.exists('*' .. feature) == 1 then
      log(buf, string.format('  Required feature available: %s', feature), 'INFO', 'system')
    else
      all_passed = false
      log(buf, string.format('  Missing required feature: %s', feature), 'ERROR', 'system')
    end
  end

  -- Set final status
  if all_passed then
    debug_results.system.status = 'success'
  end
end

-- Test context functions
local function test_context(buf, config)
  log(buf, '=== Testing Context Functions ===', 'INFO', 'context')

  -- Test buffer context
  local success, buffer_context = pcall(context.get_buffer_context)
  if success then
    log(buf, 'Buffer Context Test:', 'INFO', 'context')
    log(buf, string.format('  Filetype: %s', buffer_context.filetype), 'INFO', 'context')
    log(buf, string.format('  Filename: %s', buffer_context.filename), 'INFO', 'context')
    log(buf, string.format('  Content length: %d', #buffer_context.content), 'INFO', 'context')
  else
    log(buf, 'Buffer context test failed: ' .. buffer_context, 'ERROR', 'context')
  end

  -- Test git context
  success, git_context = pcall(context.get_git_context)
  if success then
    log(buf, 'Git Context Test:', 'INFO', 'context')
    if git_context then
      log(buf, '  Git diff available', 'INFO', 'context')
      log(buf, string.format('  Diff length: %d', #git_context), 'INFO', 'context')
    else
      log(buf, '  No git diff available', 'WARN', 'context')
    end
  else
    log(buf, 'Git context test failed: ' .. git_context, 'ERROR', 'context')
  end

  -- Test LSP context
  success, lsp_context = pcall(context.get_lsp_context)
  if success then
    log(buf, 'LSP Context Test:', 'INFO', 'context')
    log(buf, string.format('  Number of diagnostics: %d', #lsp_context), 'INFO', 'context')
  else
    log(buf, 'LSP context test failed: ' .. lsp_context, 'ERROR', 'context')
  end

  if debug_results.context.status == 'pending' then
    debug_results.context.status = 'success'
  end
end

-- Test rendering functions
local function test_render(buf)
  log(buf, '=== Testing Render Functions ===', 'INFO', 'render')

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
  log(buf, 'Testing Code Highlighting:', 'INFO', 'render')
  local success, err = pcall(function()
    render.highlight_code(test_buf, test_code)
    log(buf, '  Code highlighting successful', 'INFO', 'render')
  end)
  if not success then
    log(buf, string.format('  Code highlighting failed: %s', err), 'ERROR', 'render')
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
  log(buf, 'Testing Markdown Rendering:', 'INFO', 'render')
  success, err = pcall(function()
    render.render_markdown(test_buf, test_markdown)
    log(buf, '  Markdown rendering successful', 'INFO', 'render')
  end)
  if not success then
    log(buf, string.format('  Markdown rendering failed: %s', err), 'ERROR', 'render')
  end

  -- Clean up test buffer
  vim.api.nvim_buf_delete(test_buf, { force = true })

  if debug_results.render.status == 'pending' then
    debug_results.render.status = 'success'
  end
end

-- Test configuration
local function test_config(buf, config)
  log(buf, '=== Testing Configuration ===', 'INFO', 'config')

  -- Check required fields
  local required_fields = {
    'keymaps', 'float', 'history', 'ui', 'context', 'templates'
  }

  for _, field in ipairs(required_fields) do
    if config[field] then
      log(buf, string.format('  Config section present: %s', field), 'INFO', 'config')
    else
      log(buf, string.format('  Missing config section: %s', field), 'ERROR', 'config')
    end
  end

  -- Check keymaps
  for key, mapping in pairs(config.keymaps) do
    log(buf, string.format('  Keymap %s -> %s', key, mapping), 'INFO', 'config')
  end

  if debug_results.config.status == 'pending' then
    debug_results.config.status = 'success'
  end
end

-- Generate summary report
local function generate_summary(buf)
  log(buf, '\n=== Debug Summary ===')

  -- Count issues
  local total_errors = 0
  local total_warnings = 0
  for category, result in pairs(debug_results) do
    for _, issue in ipairs(result.issues) do
      if result.status == 'failed' then
        total_errors = total_errors + 1
      elseif result.status == 'warning' then
        total_warnings = total_warnings + 1
      end
    end
  end

  -- Overall status
  local overall_status
  if total_errors > 0 then
    overall_status = 'FAILED'
  elseif total_warnings > 0 then
    overall_status = 'PASSED WITH WARNINGS'
  else
    overall_status = 'PASSED'
  end

  -- Print summary
  log(buf, string.format('\nOverall Status: %s', overall_status))
  log(buf, string.format('Total Errors: %d', total_errors))
  log(buf, string.format('Total Warnings: %d', total_warnings))

  -- Category status
  log(buf, '\nCategory Status:')
  for category, result in pairs(debug_results) do
    log(buf, string.format('  %s: %s', category:upper(), result.status:upper()))
    if #result.issues > 0 then
      log(buf, '  Issues:')
      for _, issue in ipairs(result.issues) do
        log(buf, '    - ' .. issue)
      end
    end
  end

  -- Recommendations
  if total_errors > 0 or total_warnings > 0 then
    log(buf, '\nRecommendations:')
    if debug_results.system.status ~= 'success' then
      log(buf, '  - Check system requirements and Claude CLI installation')
    end
    if debug_results.config.status ~= 'success' then
      log(buf, '  - Verify plugin configuration in your init.lua')
    end
    if debug_results.context.status ~= 'success' then
      log(buf, '  - Check LSP and Git integration setup')
    end
    if debug_results.render.status ~= 'success' then
      log(buf, '  - Verify syntax highlighting and markdown plugins')
    end
  end
end

-- Main debug function
function M.run_debug(config)
  -- Reset results
  for category, _ in pairs(debug_results) do
    debug_results[category] = { status = 'pending', issues = {} }
  end

  -- Create log window
  local buf, win = create_log_window()

  -- Log start
  log(buf, 'Starting Claude.nvim debug session')
  log(buf, string.format('Neovim version: %s', vim.version()))
  log(buf, string.format('OS: %s', vim.loop.os_uname().sysname))

  -- Run tests
  test_system(buf)
  test_config(buf, config)
  test_context(buf, config)
  test_render(buf)

  -- Generate summary
  generate_summary(buf)

  -- Log completion
  log(buf, '\n=== Debug session completed ===')

  -- Return to normal mode and make buffer read-only
  vim.cmd('normal! G')
  vim.cmd('setlocal nomodifiable')

  -- Return results for programmatic use
  return debug_results
end

return M
