local M = {}
local config = require("claude").get_config()
local state = require("claude").get_state()

-- Initialize history
function M.init(save_path)
  -- Create directory if it doesn't exist
  vim.fn.mkdir(vim.fn.fnamemodify(save_path, ":h"), "p")

  -- Load history if file exists
  if vim.fn.filereadable(save_path) == 1 then
    local content = vim.fn.readfile(save_path)
    state.history = vim.fn.json_decode(table.concat(content, "\n"))
    state.history_index = #state.history
  end
end

-- Save history
function M.save()
  if not config.history.save_path then return end

  -- Trim history to max entries
  while #state.history > config.history.max_entries do
    table.remove(state.history, 1)
  end

  -- Save to file
  local content = vim.fn.json_encode(state.history)
  vim.fn.writefile({ content }, config.history.save_path)
end

-- Add entry to history
function M.add_entry(prompt, response)
  table.insert(state.history, {
    prompt = prompt,
    response = response,
    timestamp = os.time(),
  })
  state.history_index = #state.history

  -- Auto-save if enabled
  if config.history.enabled then
    M.save()
  end
end

-- Navigate history
function M.next()
  if state.history_index < #state.history then
    state.history_index = state.history_index + 1
    M.show_entry(state.history_index)
  end
end

function M.prev()
  if state.history_index > 1 then
    state.history_index = state.history_index - 1
    M.show_entry(state.history_index)
  end
end

-- Show history entry in window
function M.show_entry(index)
  local entry = state.history[index]
  if not entry then return end

  local window = require("claude.window")
  window.set_content(entry.prompt, entry.response)
end

-- Show history in a new buffer
function M.show()
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}

  for i, entry in ipairs(state.history) do
    local time = os.date("%Y-%m-%d %H:%M:%S", entry.timestamp)
    table.insert(lines, string.format("Entry %d - %s", i, time))
    table.insert(lines, "Prompt: " .. entry.prompt)
    table.insert(lines, "Response:")
    for _, line in ipairs(vim.split(entry.response, "\n")) do
      table.insert(lines, "  " .. line)
    end
    table.insert(lines, string.rep("-", 80))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "claude-history")

  -- Open in a new window
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, buf)
end

return M
