local M = {}
local api = vim.api
local fn = vim.fn
local config = require("claude").get_config()

-- Store window and buffer information
local state = {
  buf = nil,
  win = nil,
  prompt_win = nil,
  prompt_buf = nil,
  response_win = nil,
  response_buf = nil,
  is_open = false
}

-- Create a new buffer
local function create_buffer(name, filetype)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "buftype", "nofile")
  api.nvim_buf_set_option(buf, "bufhidden", "hide")
  api.nvim_buf_set_option(buf, "swapfile", false)
  api.nvim_buf_set_option(buf, "filetype", filetype or "claude")
  api.nvim_buf_set_option(buf, "modifiable", true)
  -- Allow normal mode mappings
  api.nvim_buf_set_option(buf, "modifiable", true)
  api.nvim_buf_set_name(buf, name)
  return buf
end

-- Set up buffer keymaps
local function setup_buffer_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Submit with <C-Enter> or <leader>s
  vim.keymap.set({ 'i', 'n' }, '<C-CR>', function()
    local lines = api.nvim_buf_get_lines(state.prompt_buf, 0, -1, false)
    local prompt = table.concat(lines, '\n')
    M.submit_prompt(prompt)
  end, opts)

  -- Also map <C-s> as an alternative for terminals that don't handle <C-CR> well
  vim.keymap.set({ 'i', 'n' }, '<C-s>', function()
    local lines = api.nvim_buf_get_lines(state.prompt_buf, 0, -1, false)
    local prompt = table.concat(lines, '\n')
    M.submit_prompt(prompt)
  end, opts)

  -- Clear prompt with <C-l>
  vim.keymap.set({ 'i', 'n' }, '<C-l>', function()
    api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, { "" })
    vim.cmd('startinsert')
  end, opts)

  -- Exit with q or <Esc> in normal mode
  vim.keymap.set('n', 'q', function()
    M.close()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, opts)

  -- Make sure Enter in insert mode creates a new line
  vim.keymap.set('i', '<CR>', '<CR>', opts)
end

-- Create the floating windows
local function create_windows()
  local total_width = math.floor(vim.o.columns * config.window.width)
  local total_height = math.floor(vim.o.lines * config.window.height)
  local row = math.floor((vim.o.lines - total_height) / 2)
  local col = math.floor((vim.o.columns - total_width) / 2)

  -- Create prompt window (smaller height for input)
  local prompt_height = math.floor(total_height * 0.2)
  local prompt_opts = {
    relative = "editor",
    row = row + total_height - prompt_height,
    col = col,
    width = total_width,
    height = prompt_height,
    style = "minimal",
    border = config.window.border,
    title = " Prompt (Press <C-s> to submit) ",
    title_pos = "center"
  }

  -- Create response window (larger height for responses)
  local response_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = total_width,
    height = total_height - prompt_height - 1,
    style = "minimal",
    border = config.window.border,
    title = " Claude AI ",
    title_pos = "center"
  }

  -- Create buffers if they don't exist
  if not state.prompt_buf or not api.nvim_buf_is_valid(state.prompt_buf) then
    state.prompt_buf = create_buffer("claude-prompt", "claude-prompt")
    -- Initialize with empty line
    api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, { "" })
  end

  if not state.response_buf or not api.nvim_buf_is_valid(state.response_buf) then
    state.response_buf = create_buffer("claude-response", "claude-response")
    -- Initialize with welcome message
    api.nvim_buf_set_lines(state.response_buf, 0, -1, false, {
      "Welcome to Claude!",
      "",
      "Type your question in the prompt window below.",
      "Use <C-s> to submit your question.",
      "Press 'q' or <Esc> in normal mode to close the windows."
    })
  end

  -- Create windows
  state.response_win = api.nvim_open_win(state.response_buf, false, response_opts)
  state.prompt_win = api.nvim_open_win(state.prompt_buf, true, prompt_opts)

  -- Set window-local options
  for _, win in ipairs({ state.prompt_win, state.response_win }) do
    api.nvim_win_set_option(win, "wrap", true)
    api.nvim_win_set_option(win, "cursorline", true)
    api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")
  end

  -- Make prompt buffer modifiable
  api.nvim_buf_set_option(state.prompt_buf, "modifiable", true)

  -- Set up buffer keymaps
  setup_buffer_keymaps(state.prompt_buf)

  -- Enter insert mode in prompt window
  vim.cmd('startinsert')

  state.is_open = true

  -- Set up autocommands
  local group = api.nvim_create_augroup("ClaudeWindow", { clear = true })

  -- Close both windows when either is closed
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(state.prompt_win) .. "," .. tostring(state.response_win),
    callback = function()
      M.close()
    end
  })

  -- Ensure prompt buffer stays modifiable
  api.nvim_create_autocmd("BufEnter", {
    group = group,
    buffer = state.prompt_buf,
    callback = function()
      api.nvim_buf_set_option(state.prompt_buf, "modifiable", true)
      vim.cmd('startinsert')
    end
  })
end

-- Close windows
function M.close()
  if state.prompt_win and api.nvim_win_is_valid(state.prompt_win) then
    api.nvim_win_close(state.prompt_win, true)
  end
  if state.response_win and api.nvim_win_is_valid(state.response_win) then
    api.nvim_win_close(state.response_win, true)
  end
  state.is_open = false
  state.prompt_win = nil
  state.response_win = nil
end

-- Toggle window
function M.toggle()
  if state.is_open then
    M.close()
  else
    create_windows()
  end
end

-- Submit prompt
function M.submit_prompt(prompt)
  if not prompt or prompt == "" then return end

  -- Show loading message
  api.nvim_buf_set_lines(state.response_buf, -1, -1, false, { "", "Claude is thinking..." })

  -- Call Claude CLI
  require("claude.commands").process_prompt(prompt, state.response_buf)

  -- Clear prompt after submission
  api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, { "" })
  vim.cmd('startinsert')
end

-- Submit visual selection
function M.submit_visual()
  local start_pos = fn.getpos("'<")
  local end_pos = fn.getpos("'>")
  local lines = api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

  if #lines > 0 then
    local last_line = lines[#lines]
    lines[#lines] = string.sub(last_line, 1, end_pos[3])
    lines[1] = string.sub(lines[1], start_pos[3])
  end

  local content = table.concat(lines, "\n")

  if not state.is_open then
    create_windows()
  end

  -- Set the content in the prompt buffer
  api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, {
    "Selected code:",
    content,
    "",
    "What would you like to know about this code?"
  })
end

-- Set content in windows
function M.set_content(prompt, response)
  if not state.is_open then
    create_windows()
  end

  if prompt then
    api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, vim.split(prompt, "\n"))
  end
  if response then
    api.nvim_buf_set_lines(state.response_buf, 0, -1, false, vim.split(response, "\n"))
  end
end

return M
