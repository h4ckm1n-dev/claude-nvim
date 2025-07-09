local M = {}
local logger = require('claude.utils.logger')

local config = {}

-- Initialize session management
function M.setup(plugin_config)
  logger.log_function_entry("session.setup", { plugin_config = plugin_config })
  
  config = plugin_config

  -- Create session directory if it doesn't exist
  local session_dir = vim.fn.stdpath("data") .. "/claude_sessions"
  if vim.fn.isdirectory(session_dir) == 0 then
    logger.debug("Creating session directory", { session_dir = session_dir })
    vim.fn.mkdir(session_dir, "p")
  end
  
  logger.debug("Session setup completed", { session_dir = session_dir })
end

-- Get current project name
function M.get_project_name()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")

  -- Check if we're in a git repo
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if vim.v.shell_error == 0 and git_root ~= "" then
    project_name = vim.fn.fnamemodify(git_root, ":t")
  end

  return project_name
end

-- Get session file path for current project
local function get_session_file()
  local project_name = M.get_project_name()
  local session_dir = vim.fn.stdpath("data") .. "/claude_sessions"
  return string.format("%s/%s.json", session_dir, project_name:gsub("[^%w%-_]", "_"))
end

-- Save current session
function M.save_session(buf)
  if not config.smart_context or not config.smart_context.remember_per_project then
    return
  end

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local session_file = get_session_file()
  local session_data = {
    project = M.get_project_name(),
    timestamp = os.time(),
    cwd = vim.fn.getcwd(),
    last_file = vim.fn.expand("%:p"),
    conversation_count = (M.load_session().conversation_count or 0) + 1
  }

  -- Save to file
  local ok, encoded = pcall(vim.json.encode, session_data)
  if ok then
    local file = io.open(session_file, "w")
    if file then
      file:write(encoded)
      file:close()
    end
  end
end

-- Load session for current project
function M.load_session()
  if not config.smart_context or not config.smart_context.remember_per_project then
    return {}
  end

  local session_file = get_session_file()
  if vim.fn.filereadable(session_file) == 0 then
    return {}
  end

  local file = io.open(session_file, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local ok, session_data = pcall(vim.json.decode, content)
  if ok and session_data then
    return session_data
  end

  return {}
end

-- Get session info for display
function M.get_session_info()
  local session = M.load_session()
  if not session.timestamp then
    return "New session"
  end

  local time_diff = os.time() - session.timestamp
  local time_str = ""

  if time_diff < 60 then
    time_str = "just now"
  elseif time_diff < 3600 then
    time_str = string.format("%d minutes ago", math.floor(time_diff / 60))
  elseif time_diff < 86400 then
    time_str = string.format("%d hours ago", math.floor(time_diff / 3600))
  else
    time_str = string.format("%d days ago", math.floor(time_diff / 86400))
  end

  return string.format("Session #%d (%s)", session.conversation_count or 1, time_str)
end

-- Export conversation to markdown
function M.export_conversation(buf, filename)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- Generate filename if not provided
  if not filename then
    local project = M.get_project_name()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    filename = string.format("claude_%s_%s.md", project, timestamp)
  end

  -- Add markdown header
  local markdown_content = string.format([[
# Claude Conversation - %s

**Project:** %s
**Date:** %s
**Working Directory:** %s

---

%s
]], M.get_project_name(), M.get_project_name(), os.date("%Y-%m-%d %H:%M:%S"), vim.fn.getcwd(), content)

  -- Write to file
  local file = io.open(filename, "w")
  if file then
    file:write(markdown_content)
    file:close()
  else
  end
end

-- Clean old sessions (keep last 10 per project)
function M.cleanup_sessions()
  local session_dir = vim.fn.stdpath("data") .. "/claude_sessions"
  if vim.fn.isdirectory(session_dir) == 0 then
    return
  end

  -- Simple cleanup - remove files older than 30 days
  local cutoff_time = os.time() - (30 * 24 * 60 * 60)

  local files = vim.fn.glob(session_dir .. "/*.json", false, true)
  for _, file in ipairs(files) do
    local stat = vim.loop.fs_stat(file)
    if stat and stat.mtime.sec < cutoff_time then
      vim.fn.delete(file)
    end
  end
end

-- Get all project sessions
function M.list_sessions()
  local session_dir = vim.fn.stdpath("data") .. "/claude_sessions"
  if vim.fn.isdirectory(session_dir) == 0 then
    return {}
  end

  local sessions = {}
  local files = vim.fn.glob(session_dir .. "/*.json", false, true)

  for _, file in ipairs(files) do
    local session = {}
    local content_file = io.open(file, "r")
    if content_file then
      local content = content_file:read("*all")
      content_file:close()

      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        session = data
        session.file = file
        table.insert(sessions, session)
      end
    end
  end

  -- Sort by timestamp (newest first)
  table.sort(sessions, function(a, b)
    return (a.timestamp or 0) > (b.timestamp or 0)
  end)

  return sessions
end

-- Switch to a different project session
function M.switch_session(project_name)
  if not project_name then
    -- Show available sessions
    local sessions = M.list_sessions()
    if #sessions == 0 then
      return
    end

    local choices = {}
    for i, session in ipairs(sessions) do
      local time_str = os.date("%Y-%m-%d %H:%M", session.timestamp or 0)
      table.insert(choices, string.format("%d. %s (%s)", i, session.project or "Unknown", time_str))
    end

    vim.ui.select(choices, {
      prompt = "Select session:",
    }, function(choice, idx)
      if idx then
        local session = sessions[idx]
        if session.cwd and vim.fn.isdirectory(session.cwd) == 1 then
          vim.cmd("cd " .. session.cwd)
        end
      end
    end)
  end
end

return M
