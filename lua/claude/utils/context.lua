local M = {}
local logger = require('claude.utils.logger')

-- Get current buffer context with error handling
function M.get_buffer_context()
  logger.log_function_entry("get_buffer_context")
  
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, 0, 0, -1, false)
  if not ok then 
    logger.error("Failed to get buffer lines", lines)
    return nil
  end
  
  local filetype = vim.bo.filetype or ""
  local filename = vim.fn.expand("%:p") or ""

  local result = {
    content = table.concat(lines, "\n"),
    filetype = filetype,
    filename = filename,
  }
  
  logger.debug("Buffer context retrieved", {
    lines_count = #lines,
    filetype = filetype,
    filename = filename,
    content_length = #result.content
  })

  return result
end

-- Get current file context with smart formatting
function M.get_current_file_context()
  logger.log_function_entry("get_current_file_context")
  
  local filename = vim.fn.expand("%:t")
  local filepath = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  -- Skip if no file or certain file types
  if filename == "" or filetype == "terminal" or filetype == "help" then
    logger.debug("Skipping file context", { filename = filename, filetype = filetype })
    return nil
  end

  local ok, lines = pcall(vim.api.nvim_buf_get_lines, 0, 0, -1, false)
  if not ok then
    logger.error("Failed to get buffer lines for file context", lines)
    return nil
  end
  
  local total_lines = #lines
  logger.debug("File context info", {
    filename = filename,
    filepath = filepath,
    filetype = filetype,
    total_lines = total_lines
  })

  -- Limit context size
  local max_lines = 50
  local content = ""

  if total_lines <= max_lines then
    content = table.concat(lines, "\n")
    logger.debug("Using full file content", { lines_used = total_lines })
  else
    -- Get current cursor position and surrounding context
    local cursor_line = vim.fn.line('.')
    local start_line = math.max(1, cursor_line - math.floor(max_lines / 2))
    local end_line = math.min(total_lines, start_line + max_lines - 1)

    logger.debug("Using partial file content", {
      cursor_line = cursor_line,
      start_line = start_line,
      end_line = end_line,
      lines_used = end_line - start_line + 1
    })

    local context_lines = {}
    for i = start_line, end_line do
      table.insert(context_lines, string.format("%4d: %s", i, lines[i] or ""))
    end
    content = table.concat(context_lines, "\n")
  end

  local formatted = string.format(
    "Current file: %s (line %d/%d, %s)\n```%s\n%s\n```",
    filename,
    vim.fn.line('.'),
    total_lines,
    filetype,
    filetype,
    content
  )

  local result = {
    filename = filename,
    filepath = filepath,
    filetype = filetype,
    content = content,
    formatted = formatted,
    total_lines = total_lines,
    cursor_line = vim.fn.line('.')
  }
  
  logger.debug("File context built", {
    content_length = #content,
    formatted_length = #formatted
  })

  return result
end

-- Get git context (diff) with timeout
function M.get_git_context()
  logger.log_function_entry("get_git_context")
  
  -- Check if we're in a git repository
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    logger.debug("Not in a git repository")
    return nil
  end
  
  -- Try different git diff commands
  local git_commands = {
    "git diff HEAD", -- staged and unstaged changes
    "git diff --cached", -- staged changes only
    "git diff", -- unstaged changes only
    "git diff HEAD~1", -- changes from last commit
  }
  
  for _, cmd in ipairs(git_commands) do
    local git_diff = vim.fn.system(cmd .. " 2>/dev/null")
    if vim.v.shell_error == 0 and git_diff ~= "" then
      logger.debug("Git diff found", { command = cmd, diff_length = #git_diff })
      return git_diff
    end
  end
  
  logger.debug("No git diff found")
  return nil
end

-- Get git status with timeout
function M.get_git_status()
  logger.log_function_entry("get_git_status")
  
  -- Check if we're in a git repository
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    logger.debug("Not in a git repository")
    return nil
  end
  
  local git_status = vim.fn.system("git status --porcelain 2>/dev/null")
  if vim.v.shell_error == 0 and git_status ~= "" then
    logger.debug("Git status found", { status_length = #git_status })
    return git_status
  end
  
  logger.debug("No git status changes found")
  return nil
end

-- Get current git branch with timeout
function M.get_git_branch()
  logger.log_function_entry("get_git_branch")
  
  -- Check if we're in a git repository
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    logger.debug("Not in a git repository")
    return nil
  end
  
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
  if vim.v.shell_error == 0 and branch ~= "" then
    logger.debug("Git branch found", { branch = branch })
    return branch
  end
  
  logger.debug("No git branch found")
  return nil
end

-- Get LSP diagnostics
function M.get_lsp_context()
  local diagnostics = vim.diagnostic.get(0)
  local result = {}

  for _, diagnostic in ipairs(diagnostics) do
    table.insert(result, {
      message = diagnostic.message,
      severity = diagnostic.severity,
      line = diagnostic.lnum + 1,
      source = diagnostic.source,
    })
  end

  return result
end

-- Get LSP errors as formatted strings
function M.get_lsp_errors()
  local diagnostics = vim.diagnostic.get(0)
  local errors = {}

  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      local line_text = vim.api.nvim_buf_get_lines(0, diagnostic.lnum, diagnostic.lnum + 1, false)[1] or ""
      table.insert(errors, string.format(
        "Line %d: %s\n  Code: %s\n  Source: %s",
        diagnostic.lnum + 1,
        diagnostic.message,
        line_text:gsub("^%s+", ""), -- trim leading whitespace
        diagnostic.source or "unknown"
      ))
    end
  end

  return errors
end

-- Get project information
function M.get_project_info()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")

  -- Check for common project files
  local project_files = {
    "package.json",
    "Cargo.toml",
    "go.mod",
    "requirements.txt",
    "Gemfile",
    "pom.xml",
    ".git"
  }

  local detected_type = "unknown"
  for _, file in ipairs(project_files) do
    if vim.fn.filereadable(file) == 1 or vim.fn.isdirectory(file) == 1 then
      detected_type = file
      break
    end
  end

  return {
    name = project_name,
    path = cwd,
    type = detected_type,
    git_branch = M.get_git_branch()
  }
end

-- Get visual selection
function M.get_visual_selection()
  logger.log_function_entry("get_visual_selection")
  
  -- Check if we're in visual mode
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'v' or mode == 'V' or mode == '\22' then
    logger.debug("Currently in visual mode", { mode = mode })
    -- Get current visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    
    if start_pos[2] == 0 or end_pos[2] == 0 then
      logger.debug("Invalid visual selection positions")
      return nil
    end
    
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
    if #lines == 0 then
      logger.debug("No lines in visual selection")
      return nil
    end
    
    -- Handle partial line selection
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    else
      lines[1] = string.sub(lines[1], start_pos[3])
      lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
    
    local result = {
      content = table.concat(lines, "\n"),
      start_line = start_pos[2],
      end_line = end_pos[2],
      filetype = vim.bo.filetype
    }
    
    logger.debug("Visual selection retrieved", {
      start_line = result.start_line,
      end_line = result.end_line,
      content_length = #result.content
    })
    
    return result
  end
  
  -- Try to get last visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    logger.debug("No previous visual selection found")
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  if #lines == 0 then
    logger.debug("No lines in previous visual selection")
    return nil
  end

  -- Handle partial line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
  else
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  end

  local result = {
    content = table.concat(lines, "\n"),
    start_line = start_pos[2],
    end_line = end_pos[2],
    filetype = vim.bo.filetype
  }
  
  logger.debug("Previous visual selection retrieved", {
    start_line = result.start_line,
    end_line = result.end_line,
    content_length = #result.content
  })

  return result
end

-- Build smart context based on configuration
function M.build_context(config)
  local context = {}

  if config.context and config.context.include_buffer then
    context.buffer = M.get_buffer_context()
  end

  if config.context and config.context.include_git then
    context.git = M.get_git_context()
  end

  if config.context and config.context.include_lsp then
    context.lsp = M.get_lsp_context()
  end

  return context
end

-- Get formatted context for current situation
function M.get_smart_context(options)
  options = options or {}
  local context_parts = {}

  -- Project context
  local project = M.get_project_info()
  if project.name ~= "" then
    table.insert(context_parts, string.format("Project: %s (%s)", project.name, project.type))
    if project.git_branch then
      table.insert(context_parts, string.format("Git branch: %s", project.git_branch))
    end
  end

  -- File context
  if options.include_file ~= false then
    local file_context = M.get_current_file_context()
    if file_context then
      table.insert(context_parts, file_context.formatted)
    end
  end

  -- Error context
  if options.include_errors ~= false then
    local errors = M.get_lsp_errors()
    if #errors > 0 then
      table.insert(context_parts, "Current errors:\n" .. table.concat(errors, "\n\n"))
    end
  end

  -- Git context
  if options.include_git then
    local git_status = M.get_git_status()
    if git_status then
      table.insert(context_parts, "Git status:\n" .. git_status)
    end
  end

  return table.concat(context_parts, "\n\n")
end

return M
