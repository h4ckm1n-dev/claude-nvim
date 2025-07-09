locac> M = {}
local context = require('claude.utils.context')
local render = require('claude.utils.render')
local session = require('claude.utils.session')
local actions = require('claude.utils.actions')
local logger = require('claude.utils.logger')

-- Enhanced configuration with smart features
M.config = {
  claude_path = "/Users/h4ckm1n/.claude/local/claude",
  keymaps = {
    execute = "<leader>CC",           -- Execute in split
    execute_float = "<leader>CF",     -- Execute in float
    execute_right = "<leader>CR",     -- Execute in right split
    send_selection = "<leader>CS",    -- Send selection
    execute_with_line = "<leader>CL", -- Execute with line
    send_buffer = "<leader>CB",       -- Send buffer
    send_git_diff = "<leader>CG",     -- Send git diff
    copy_response = "<leader>CY",     -- Copy response
    quick_review = "<leader>CQ",      -- Quick code review
    explain_code = "<leader>CE",      -- Explain current code
  },
  float = {
    width = 0.35,         -- 35% of screen width
    height = 0.8,         -- 80% of screen height
    border = "rounded",
    title_dynamic = true, -- Dynamic title with context
    winblend = 0,
    title_pos = "center",
  },
  history = {
    enabled = true,
    save_path = vim.fn.stdpath("data") .. "/claude_history",
    max_entries = 100,
    per_project = true, -- Save history per project
  },
  ui = {
    syntax_highlight = true,  -- Syntax highlighting in responses
    markdown_render = true,   -- Markdown rendering
    status_line = true,       -- Status line integration
    show_context_info = true, -- Show what context is included
    theme = {
      inherit = true,         -- Inherit from Neovim colorscheme
      response_bg = nil,      -- Custom response background
      code_bg = nil,          -- Custom code block background
    },
  },
  smart_context = {
    auto_include_file = true,    -- Include current file context
    auto_include_errors = true,  -- Include LSP errors if present
    remember_per_project = true, -- Simple session memory
    max_context_lines = 50,      -- Limit context size
    show_line_numbers = true,    -- Include line numbers in context
  },
  quick_actions = {
    enabled = true,          -- y/p/n shortcuts in Claude window
    return_to_source = true, -- Auto-return focus after paste
    auto_copy_code = true,   -- Auto-copy code suggestions
  },
  templates = {
    code_review = "Please review this code for best practices, potential issues, and improvements:\n\n",
    explain = "Please explain this code in detail:\n\n",
    refactor = "Please suggest refactoring improvements for this code:\n\n",
    document = "Please add comprehensive documentation for this code:\n\n",
    debug = "Help me debug this code. What might be wrong?\n\n",
    optimize = "Please suggest optimizations for this code:\n\n",
  },
}

local config = M.config

-- Get dynamic title based on context
local function get_dynamic_title()
  logger.log_function_entry("get_dynamic_title")
  
  local base_title = " Claude AI "

  if not config.float.title_dynamic then
    logger.debug("Dynamic title disabled, using base title")
    return base_title
  end

  local project_name = session.get_project_name()
  local current_file = vim.fn.expand('%:t')

  logger.debug("Title context", {
    project_name = project_name,
    current_file = current_file
  })

  if project_name and current_file ~= "" then
    return string.format(" Claude AI - %s (%s) ", project_name, current_file)
  elseif project_name then
    return string.format(" Claude AI - %s ", project_name)
  elseif current_file ~= "" then
    return string.format(" Claude AI (%s) ", current_file)
  end

  return base_title
end

-- Build smart context
local function build_smart_context()
  logger.log_function_entry("build_smart_context")
  
  local context_parts = {}
  local info_parts = {}

  if config.smart_context.auto_include_file then
    logger.debug("Including file context")
    local file_context = context.get_current_file_context()
    if file_context and file_context.content then
      table.insert(context_parts, file_context.formatted)
      table.insert(info_parts, file_context.filename)
      logger.debug("File context added", {
        filename = file_context.filename,
        content_length = #file_context.content
      })
    else
      logger.debug("No file context available")
    end
  end

  if config.smart_context.auto_include_errors then
    logger.debug("Including LSP errors")
    local error_context = context.get_lsp_errors()
    if error_context and #error_context > 0 then
      table.insert(context_parts, "Current LSP errors:\n" .. table.concat(error_context, "\n"))
      table.insert(info_parts, string.format("%d errors", #error_context))
      logger.debug("LSP errors added", { error_count = #error_context })
    else
      logger.debug("No LSP errors found")
    end
  end

  local context_text = ""
  if #context_parts > 0 then
    context_text = table.concat(context_parts, "\n\n") .. "\n\n"
  end

  local info_text = ""
  if #info_parts > 0 then
    info_text = "Context: " .. table.concat(info_parts, ", ")
  end

  logger.debug("Context built", {
    context_parts = #context_parts,
    info_parts = #info_parts,
    context_length = #context_text,
    info_text = info_text
  })

  return context_text, info_text
end

-- Handle terminal exit
local function handle_terminal_exit(win, buf, mode)
  return function(job_id, exit_code, event_type)
    logger.info("Terminal exit handler called", {
      job_id = job_id,
      exit_code = exit_code,
      event_type = event_type,
      mode = mode,
      win = win,
      buf = buf
    })

    -- Save session before exit
    if config.smart_context.remember_per_project then
      logger.debug("Saving session before exit")
      local success, err = pcall(session.save_session, buf)
      if not success then
        logger.error("Failed to save session", err)
      end
    end

    -- Clean up the buffer
    if buf and vim.api.nvim_buf_is_valid(buf) then
      logger.debug("Cleaning up buffer", { buf = buf })
      local success, err = pcall(vim.api.nvim_buf_delete, buf, { force = true })
      if not success then
        logger.error("Failed to delete buffer", err)
      end
    end

    -- Clean up the window
    if win and vim.api.nvim_win_is_valid(win) then
      logger.debug("Cleaning up window", { win = win })
      local success, err = pcall(vim.api.nvim_win_close, win, true)
      if not success then
        logger.error("Failed to close window", err)
      end
    end

    logger.info("Terminal cleanup completed")
  end
end

-- Filter unwanted output from Claude CLI
local function filter_claude_output(_, data, _)
  if not data then return end
  
  for i, line in ipairs(data) do
    -- Filter out source map references and other debug messages
    if line:match("sourceMappingURL") or
        line:match("middleware%-route%-matcher") or
        line:match("^//# ") then
      data[i] = ""
    end
  end
end

-- Set up quick actions for Claude window
local function setup_claude_keymaps(buf)
  if not config.quick_actions.enabled then
    return
  end

  -- Yank code suggestions
  vim.keymap.set('n', 'y', function()
    actions.yank_code_suggestion(buf)
  end, { buffer = buf, desc = "Yank code suggestion" })

  -- Paste at cursor in source file
  vim.keymap.set('n', 'p', function()
    actions.paste_to_source(buf)
  end, { buffer = buf, desc = "Paste to source file" })

  -- Create new file with code
  vim.keymap.set('n', 'n', function()
    actions.create_new_file(buf)
  end, { buffer = buf, desc = "Create new file" })

end

-- Execute Claude in a floating window
local function execute_claude_float()
  logger.log_function_entry("execute_claude_float")
  
  -- Calculate window size
  local width = math.floor(vim.o.columns * config.float.width)
  local height = math.floor(vim.o.lines * config.float.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  logger.debug("Float window dimensions", {
    width = width,
    height = height,
    row = row,
    col = col,
    columns = vim.o.columns,
    lines = vim.o.lines
  })

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  logger.debug("Created buffer", { buf = buf })

  -- Build smart context
  local context_text, info_text = build_smart_context()

  -- Set up window options with dynamic title
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.float.border,
    title = get_dynamic_title(),
    title_pos = config.float.title_pos,
  }

  logger.debug("Window options", opts)

  -- Create window
  local success, win = pcall(vim.api.nvim_open_win, buf, true, opts)
  if not success then
    logger.error("Failed to create window", win)
    return
  end
  logger.debug("Created window", { win = win })

  -- Set window options
  pcall(vim.api.nvim_set_option_value, "winblend", config.float.winblend, {win = win})
  pcall(vim.api.nvim_set_option_value, "cursorline", true, {win = win})


  -- Load previous session if available
  local session_data = session.load_session()
  logger.debug("Session data loaded", session_data)

  -- Start terminal with filtered output and exit handler
  local cmd = config.claude_path .. ' 2>/dev/null'
  logger.info("Starting terminal", { cmd = cmd })
  
  local job_id = vim.fn.termopen(cmd, {
    on_exit = handle_terminal_exit(win, buf, "float"),
    on_stderr = filter_claude_output,
    stderr_buffered = false,
  })

  if job_id <= 0 then
    logger.error("Failed to start terminal", { job_id = job_id, cmd = cmd })
    return
  end
  logger.debug("Terminal started", { job_id = job_id })

  -- Set up quick actions
  setup_claude_keymaps(buf)

  -- Auto-send context if available
  if context_text ~= "" then
    logger.debug("Scheduling context auto-send", { context_length = #context_text })
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        local lines = vim.split(context_text, '\n')
        for _, line in ipairs(lines) do
          vim.api.nvim_chan_send(vim.bo[buf].channel, line .. '\r')
        end
        logger.debug("Context auto-sent", { lines_sent = #lines })
      else
        logger.warn("Buffer invalid when trying to auto-send context")
      end
    end, 1000) -- Wait 1 second for Claude to start
  end

  -- Enter terminal mode
  vim.cmd('startinsert')
  logger.info("Float window setup completed")
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
  vim.bo[buf].buftype = "terminal"

  -- Build smart context
  local context_text, info_text = build_smart_context()


  -- Start terminal with filtered output and exit handler
  vim.fn.termopen(config.claude_path .. ' 2>/dev/null', {
    on_exit = handle_terminal_exit(win, buf, "right split"),
    on_stderr = filter_claude_output,
    stderr_buffered = false,
  })

  -- Set up quick actions
  setup_claude_keymaps(buf)

  -- Auto-send context if available
  if context_text ~= "" then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].channel then
        local lines = vim.split(context_text, '\n')
        for _, line in ipairs(lines) do
          vim.api.nvim_chan_send(vim.bo[buf].channel, line .. '\r')
        end
      end
    end, 1000)
  end

  -- Enter terminal mode
  vim.cmd('startinsert')
end

-- Execute Claude in horizontal split
local function execute_claude_split()
  -- Create a new split
  vim.cmd('split')

  -- Create terminal buffer
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  -- Set buffer options
  vim.bo[buf].buftype = "terminal"

  -- Build smart context
  local context_text, info_text = build_smart_context()


  -- Start terminal with filtered output and exit handler
  vim.fn.termopen(config.claude_path .. ' 2>/dev/null', {
    on_exit = handle_terminal_exit(win, buf, "horizontal split"),
    on_stderr = filter_claude_output,
    stderr_buffered = false,
  })

  -- Set up quick actions
  setup_claude_keymaps(buf)

  -- Auto-send context if available
  if context_text ~= "" then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].channel then
        local lines = vim.split(context_text, '\n')
        for _, line in ipairs(lines) do
          vim.api.nvim_chan_send(vim.bo[buf].channel, line .. '\r')
        end
      end
    end, 1000)
  end

  -- Enter terminal mode
  vim.cmd('startinsert')
end

-- Send current selection to Claude
local function send_selection()
  logger.log_function_entry("send_selection")
  
  local visual_selection = context.get_visual_selection()
  if not visual_selection then
    vim.notify("No selection found", vim.log.levels.WARN)
    logger.warn("No visual selection found")
    return
  end

  -- Open Claude with selection
  execute_claude_float()

  -- Send selection after a delay
  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].channel then
      local lines = vim.split(visual_selection.content, '\n')
      for _, line in ipairs(lines) do
        vim.api.nvim_chan_send(vim.bo[buf].channel, line .. '\r')
      end
      logger.debug("Selection sent to Claude", { lines_sent = #lines })
    end
  end, 1000)
end

-- Send current buffer to Claude
local function send_buffer()
  logger.log_function_entry("send_buffer")
  
  local buffer_context = context.get_buffer_context()
  if not buffer_context then
    vim.notify("No buffer content found", vim.log.levels.WARN)
    logger.warn("No buffer content found")
    return
  end

  -- Open Claude with buffer content
  execute_claude_float()

  -- Send buffer content after a delay
  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].channel then
      local lines = vim.split(buffer_context.content, '\n')
      for _, line in ipairs(lines) do
        vim.api.nvim_chan_send(vim.bo[buf].channel, line .. '\r')
      end
      logger.debug("Buffer sent to Claude", { lines_sent = #lines })
    end
  end, 1000)
end

-- Send git diff to Claude
local function send_git_diff()
  logger.log_function_entry("send_git_diff")
  
  local git_diff = context.get_git_context()
  if not git_diff then
    vim.notify("No git diff found", vim.log.levels.WARN)
    logger.warn("No git diff found")
    return
  end

  -- Open Claude with git diff
  execute_claude_float()

  -- Send git diff after a delay
  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].channel then
      local prompt = "Please review this git diff:\n\n" .. git_diff .. "\n"
      vim.api.nvim_chan_send(vim.bo[buf].channel, prompt)
      logger.debug("Git diff sent to Claude", { diff_length = #git_diff })
    end
  end, 1000)
end

-- Execute Claude with current line context
local function execute_with_line()
  logger.log_function_entry("execute_with_line")
  
  local current_line = vim.fn.getline('.')
  local line_num = vim.fn.line('.')
  local filename = vim.fn.expand('%:t')
  
  -- Open Claude with line context
  execute_claude_float()

  -- Send line context after a delay
  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].channel then
      local prompt = string.format("Current line %d in %s:\n%s\n\n", line_num, filename, current_line)
      vim.api.nvim_chan_send(vim.bo[buf].channel, prompt)
      logger.debug("Line context sent to Claude", { line_num = line_num, filename = filename })
    end
  end, 1000)
end

-- Copy Claude response to clipboard
local function copy_response()
  logger.log_function_entry("copy_response")
  
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= 'terminal' then
    vim.notify("Not in a Claude terminal buffer", vim.log.levels.WARN)
    logger.warn("Not in Claude terminal buffer")
    return
  end

  -- Get all lines from the buffer
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Copy to clipboard
  vim.fn.setreg('+', content)
  vim.fn.setreg('"', content)
  
  vim.notify("Claude response copied to clipboard", vim.log.levels.INFO)
  logger.info("Claude response copied to clipboard", { content_length = #content })
end

-- Quick templates
local function execute_template(template_key)
  local template = config.templates[template_key]
  if not template then
    return
  end

  -- Get current selection or file context
  local context_text = ""
  local visual_selection = vim.fn.getline("'<", "'>")

  if #visual_selection > 1 or (visual_selection[1] and visual_selection[1] ~= "") then
    context_text = table.concat(visual_selection, "\n")
  else
    local file_context = context.get_current_file_context()
    if file_context then
      context_text = file_context.content
    end
  end

  -- Open Claude with template
  execute_claude_float()

  -- Send template + context after a delay
  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].channel then
      local full_prompt = template .. context_text .. "\n"
      vim.api.nvim_chan_send(vim.bo[buf].channel, full_prompt)
    end
  end, 1500)
end

-- Create commands
local function create_commands()
  vim.api.nvim_create_user_command('Claude', execute_claude_split, {})
  vim.api.nvim_create_user_command('ClaudeFloat', execute_claude_float, {})
  vim.api.nvim_create_user_command('ClaudeRight', execute_claude_right, {})

  -- New function commands
  vim.api.nvim_create_user_command('ClaudeSendSelection', send_selection, { 
    range = true, 
    desc = "Send visual selection to Claude" 
  })
  
  vim.api.nvim_create_user_command('ClaudeSendBuffer', send_buffer, { 
    desc = "Send current buffer to Claude" 
  })
  
  vim.api.nvim_create_user_command('ClaudeSendDiff', send_git_diff, { 
    desc = "Send git diff to Claude" 
  })
  
  vim.api.nvim_create_user_command('ClaudeWithLine', execute_with_line, { 
    desc = "Execute Claude with current line context" 
  })
  
  vim.api.nvim_create_user_command('ClaudeCopyResponse', copy_response, { 
    desc = "Copy Claude response to clipboard" 
  })

  -- Template commands
  vim.api.nvim_create_user_command('ClaudeReview', function()
    execute_template('code_review')
  end, { range = true })

  vim.api.nvim_create_user_command('ClaudeExplain', function()
    execute_template('explain')
  end, { range = true })

  vim.api.nvim_create_user_command('ClaudeRefactor', function()
    execute_template('refactor')
  end, { range = true })

  -- Logging commands
  vim.api.nvim_create_user_command('ClaudeLog', function()
    logger.open_log()
  end, { desc = "Open Claude debug log" })

  vim.api.nvim_create_user_command('ClaudeLogTail', function()
    logger.tail_log()
  end, { desc = "Tail Claude debug log" })

  vim.api.nvim_create_user_command('ClaudeLogClear', function()
    logger.clear_log()
  end, { desc = "Clear Claude debug log" })

  vim.api.nvim_create_user_command('ClaudeLogStats', function()
    local stats = logger.get_log_stats()
    if stats.exists then
      vim.notify(string.format("Log file: %s (%s, modified: %s)", 
        logger.config.file_path, stats.size_human, stats.modified))
    else
      vim.notify("Log file doesn't exist yet")
    end
  end, { desc = "Show Claude log statistics" })
end

-- Initialize the plugin
function M.setup(user_config)
  logger.log_plugin_startup()
  logger.log_function_entry("M.setup", { user_config = user_config })

  -- Initialize logger first
  logger.setup(user_config and user_config.logger or {})

  -- Update config with user settings
  config = vim.tbl_deep_extend("force", M.config, user_config or {})
  logger.debug("Config merged", { config = config })

  -- Validate keymaps for conflicts
  local used_keys = {}
  for action, key in pairs(config.keymaps) do
    if used_keys[key] then
      local warning = string.format("Warning: Keymap %s is used by both %s and %s", key, used_keys[key], action)
      logger.warn(warning)
      vim.notify(warning, vim.log.levels.WARN)
    end
    used_keys[key] = action
  end

  -- Set up keymaps
  logger.debug("Setting up keymaps", { keymaps = config.keymaps })
  for action, key in pairs(config.keymaps) do
    local cmd
    if action == "execute" then
      cmd = execute_claude_split
    elseif action == "execute_float" then
      cmd = execute_claude_float
    elseif action == "execute_right" then
      cmd = execute_claude_right
    elseif action == "send_selection" then
      cmd = send_selection
    elseif action == "send_buffer" then
      cmd = send_buffer
    elseif action == "send_git_diff" then
      cmd = send_git_diff
    elseif action == "execute_with_line" then
      cmd = execute_with_line
    elseif action == "copy_response" then
      cmd = copy_response
    elseif action == "quick_review" then
      cmd = function() execute_template('code_review') end
    elseif action == "explain_code" then
      cmd = function() execute_template('explain') end
    end

    if cmd then
      vim.keymap.set("n", key, cmd, {
        noremap = true,
        silent = true,
        desc = "Claude: " .. action
      })
      logger.debug("Keymap set", { action = action, key = key })
    else
      logger.warn("No command found for action", { action = action })
    end
  end

  -- Create commands
  logger.debug("Creating commands")
  create_commands()

  -- Initialize session management
  logger.debug("Initializing session management")
  session.setup(config)

  logger.info("Plugin setup completed successfully")
end

return M
