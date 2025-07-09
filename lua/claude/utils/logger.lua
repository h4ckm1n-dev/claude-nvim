local M = {}

local uv = vim.uv or vim.loop

M.config = {
  enabled = true,
  level = "DEBUG", -- DEBUG, INFO, WARN, ERROR
  file_path = vim.fn.stdpath("data") .. "/claude_debug.log",
  max_file_size = 10 * 1024 * 1024, -- 10MB
  backup_count = 3,
  include_timestamp = true,
  include_location = true,
  include_stack_trace = false,
  async = true,
}

local levels = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

local level_colors = {
  DEBUG = "Comment",
  INFO = "Normal",
  WARN = "WarningMsg",
  ERROR = "ErrorMsg",
}

local log_queue = {}
local log_timer = nil

local function get_caller_info()
  if not M.config.include_location then
    return ""
  end
  
  local info = debug.getinfo(4, "Sl")
  if info then
    local source = info.source:match("@(.+)") or info.source
    source = source:gsub(vim.fn.expand("~"), "~")
    return string.format("[%s:%d] ", vim.fn.fnamemodify(source, ":t"), info.currentline)
  end
  return ""
end

local function get_stack_trace()
  if not M.config.include_stack_trace then
    return ""
  end
  
  local stack = {}
  for i = 4, 10 do
    local info = debug.getinfo(i, "Sl")
    if not info then break end
    
    local source = info.source:match("@(.+)") or info.source
    source = source:gsub(vim.fn.expand("~"), "~")
    table.insert(stack, string.format("  %s:%d", vim.fn.fnamemodify(source, ":t"), info.currentline))
  end
  
  if #stack > 0 then
    return "\nStack trace:\n" .. table.concat(stack, "\n") .. "\n"
  end
  return ""
end

local function format_message(level, message, data)
  local parts = {}
  
  if M.config.include_timestamp then
    table.insert(parts, os.date("%Y-%m-%d %H:%M:%S"))
  end
  
  table.insert(parts, string.format("[%s]", level))
  
  local caller_info = get_caller_info()
  if caller_info ~= "" then
    table.insert(parts, caller_info)
  end
  
  table.insert(parts, message)
  
  if data then
    table.insert(parts, vim.inspect(data))
  end
  
  local formatted = table.concat(parts, " ")
  
  local stack_trace = get_stack_trace()
  if stack_trace ~= "" then
    formatted = formatted .. stack_trace
  end
  
  return formatted .. "\n"
end

local function rotate_log_file()
  local file_path = M.config.file_path
  local stat = uv.fs_stat(file_path)
  
  if not stat or stat.size < M.config.max_file_size then
    return
  end
  
  for i = M.config.backup_count, 1, -1 do
    local old_file = file_path .. "." .. i
    local new_file = file_path .. "." .. (i + 1)
    
    if uv.fs_stat(old_file) then
      if i == M.config.backup_count then
        uv.fs_unlink(new_file)
      else
        uv.fs_rename(old_file, new_file)
      end
    end
  end
  
  if uv.fs_stat(file_path) then
    uv.fs_rename(file_path, file_path .. ".1")
  end
end

local function write_to_file(content)
  rotate_log_file()
  
  local file = io.open(M.config.file_path, "a")
  if file then
    file:write(content)
    file:close()
  else
    vim.notify("Failed to write to log file: " .. M.config.file_path, vim.log.levels.ERROR)
  end
end

local function process_log_queue()
  if #log_queue == 0 then
    return
  end
  
  local content = table.concat(log_queue, "")
  log_queue = {}
  
  if M.config.async then
    vim.schedule(function()
      write_to_file(content)
    end)
  else
    write_to_file(content)
  end
end

local function log(level, message, data)
  if not M.config.enabled then
    return
  end
  
  if levels[level] < levels[M.config.level] then
    return
  end
  
  local formatted = format_message(level, message, data)
  
  if M.config.async then
    table.insert(log_queue, formatted)
    
    if not log_timer then
      log_timer = vim.defer_fn(function()
        process_log_queue()
        log_timer = nil
      end, 100)
    end
  else
    write_to_file(formatted)
  end
  
  vim.notify(string.format("[Claude] %s: %s", level, message), vim.log.levels[level])
end

function M.debug(message, data)
  log("DEBUG", message, data)
end

function M.info(message, data)
  log("INFO", message, data)
end

function M.warn(message, data)
  log("WARN", message, data)
end

function M.error(message, data)
  log("ERROR", message, data)
end

function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})
  
  local dir = vim.fn.fnamemodify(M.config.file_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  
  M.info("Logger initialized", {
    file_path = M.config.file_path,
    level = M.config.level,
    async = M.config.async,
  })
end

function M.clear_log()
  local file = io.open(M.config.file_path, "w")
  if file then
    file:close()
    M.info("Log file cleared")
  else
    M.error("Failed to clear log file")
  end
end

function M.open_log()
  if vim.fn.filereadable(M.config.file_path) == 1 then
    vim.cmd("edit " .. M.config.file_path)
  else
    M.warn("Log file does not exist: " .. M.config.file_path)
  end
end

function M.tail_log()
  if vim.fn.filereadable(M.config.file_path) == 1 then
    vim.cmd("split")
    vim.cmd("edit " .. M.config.file_path)
    vim.cmd("normal! G")
    vim.cmd("setlocal autoread")
    vim.cmd("au CursorHold,CursorHoldI <buffer> checktime")
  else
    M.warn("Log file does not exist: " .. M.config.file_path)
  end
end

function M.get_log_stats()
  local stat = uv.fs_stat(M.config.file_path)
  if stat then
    return {
      size = stat.size,
      size_human = string.format("%.2f MB", stat.size / 1024 / 1024),
      modified = os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec),
      exists = true,
    }
  else
    return {
      exists = false,
    }
  end
end

function M.log_plugin_startup()
  M.info("=== Claude Plugin Starting ===")
  M.debug("Neovim version", vim.version())
  M.debug("Plugin config", M.config)
  M.debug("Environment", {
    stdpath_data = vim.fn.stdpath("data"),
    stdpath_config = vim.fn.stdpath("config"),
    os = vim.loop.os_uname(),
  })
end

function M.log_function_entry(func_name, args)
  M.debug("-> " .. func_name, args)
end

function M.log_function_exit(func_name, result)
  M.debug("<- " .. func_name, result)
end

function M.log_error_with_context(message, error_obj, context)
  M.error(message, {
    error = error_obj,
    context = context,
    buffer = vim.api.nvim_get_current_buf(),
    window = vim.api.nvim_get_current_win(),
    mode = vim.api.nvim_get_mode(),
  })
end

return M