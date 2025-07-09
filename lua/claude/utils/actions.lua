local M = {}
local logger = require('claude.utils.logger')

-- Extract code blocks from Claude's response
local function extract_code_blocks(text)
  logger.log_function_entry("extract_code_blocks", { text_length = #text })
  
  local blocks = {}

  -- Pattern to match code blocks
  for lang, code in text:gmatch("```(%w*)\n(.-)\n```") do
    table.insert(blocks, {
      language = lang ~= "" and lang or "text",
      code = code
    })
  end

  logger.debug("Code blocks extracted", { 
    blocks_count = #blocks,
    languages = vim.tbl_map(function(block) return block.language end, blocks)
  })

  return blocks
end

-- Get the most recent code suggestion from Claude buffer
local function get_recent_code_suggestion(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  local blocks = extract_code_blocks(content)

  -- Return the last code block
  if #blocks > 0 then
    return blocks[#blocks]
  end

  return nil
end

-- Get all code blocks from Claude buffer
local function get_all_code_blocks(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return {}
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  return extract_code_blocks(content)
end

-- Yank code suggestion to clipboard
function M.yank_code_suggestion(buf)
  local code_block = get_recent_code_suggestion(buf)

  if not code_block then
    return
  end

  -- Copy to clipboard
  vim.fn.setreg('+', code_block.code)
  vim.fn.setreg('"', code_block.code)

  local line_count = #vim.split(code_block.code, '\n')
end

-- Get the source window (the window we came from)
local function get_source_window()
  local claude_win = vim.api.nvim_get_current_win()
  local windows = vim.api.nvim_list_wins()

  for _, win in ipairs(windows) do
    if win ~= claude_win then
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_get_option_value('buftype', {buf = buf})
      -- Return first non-terminal, non-special buffer
      if buftype ~= 'terminal' and buftype ~= 'nofile' and buftype ~= 'help' then
        return win, buf
      end
    end
  end

  return nil, nil
end

-- Paste code to source file at cursor position
function M.paste_to_source(buf)
  local code_block = get_recent_code_suggestion(buf)

  if not code_block then
    return
  end

  local source_win, source_buf = get_source_window()
  if not source_win then
    return
  end

  -- Switch to source window
  vim.api.nvim_set_current_win(source_win)

  -- Get cursor position
  local cursor = vim.api.nvim_win_get_cursor(source_win)
  local line_num = cursor[1]
  local col_num = cursor[2]

  -- Split code into lines
  local code_lines = vim.split(code_block.code, '\n')

  -- Insert the code
  vim.api.nvim_buf_set_lines(source_buf, line_num, line_num, false, code_lines)

  -- Move cursor to end of inserted code
  local new_line = line_num + #code_lines
  vim.api.nvim_win_set_cursor(source_win, { new_line, 0 })


  -- Return focus to Claude window if configured
  local claude_buf_id = buf
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == claude_buf_id then
      vim.api.nvim_set_current_win(win)
      break
    end
  end
end

-- Create new file with code suggestion
function M.create_new_file(buf)
  local blocks = get_all_code_blocks(buf)

  if #blocks == 0 then
    return
  end

  local choices = {}
  for i, block in ipairs(blocks) do
    local preview = block.code:sub(1, 50):gsub('\n', ' ')
    if #block.code > 50 then
      preview = preview .. "..."
    end
    table.insert(choices, string.format("%d. %s: %s", i, block.language, preview))
  end

  if #choices == 1 then
    -- Only one block, create file directly
    M.create_file_with_code(blocks[1])
  else
    -- Multiple blocks, let user choose
    vim.ui.select(choices, {
      prompt = "Select code block to create file:",
    }, function(choice, idx)
      if idx then
        M.create_file_with_code(blocks[idx])
      end
    end)
  end
end

-- Create file with specific code block
function M.create_file_with_code(code_block)
  -- Suggest filename based on language
  local extensions = {
    javascript = "js",
    typescript = "ts",
    python = "py",
    lua = "lua",
    rust = "rs",
    go = "go",
    java = "java",
    cpp = "cpp",
    c = "c",
    html = "html",
    css = "css",
    json = "json",
    yaml = "yml",
    xml = "xml",
    shell = "sh",
    bash = "sh",
    markdown = "md"
  }

  local ext = extensions[code_block.language] or "txt"
  local suggested_name = string.format("claude_suggestion.%s", ext)

  vim.ui.input({
    prompt = "Filename: ",
    default = suggested_name,
  }, function(filename)
    if not filename or filename == "" then
      return
    end

    -- Create new buffer
    local new_buf = vim.api.nvim_create_buf(true, false)

    -- Set the content
    local code_lines = vim.split(code_block.code, '\n')
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, code_lines)

    -- Set filename
    vim.api.nvim_buf_set_name(new_buf, filename)

    -- Set filetype based on extension
    local filetype = code_block.language
    if filetype == "text" or filetype == "" then
      -- Try to detect from extension
      local file_ext = filename:match("%.([^%.]+)$")
      local ft_map = {
        js = "javascript",
        ts = "typescript",
        py = "python",
        rs = "rust",
        go = "go",
        java = "java",
        cpp = "cpp",
        c = "c",
        html = "html",
        css = "css",
        md = "markdown",
        sh = "bash"
      }
      filetype = ft_map[file_ext] or file_ext or "text"
    end

    vim.api.nvim_set_option_value('filetype', filetype, {buf = new_buf})

    -- Open in new window
    vim.cmd('vsplit')
    vim.api.nvim_win_set_buf(0, new_buf)

  end)
end

-- Apply code suggestion as diff/patch
function M.apply_code_diff(buf)
  local code_block = get_recent_code_suggestion(buf)

  if not code_block then
    return
  end

  local source_win, source_buf = get_source_window()
  if not source_win then
    return
  end

end

-- Show available actions
function M.show_actions()
  local actions = {
    "y - Yank code to clipboard",
    "p - Paste code to source file",
    "n - Create new file with code",
    "? - Show this help"
  }

end

-- Get code statistics from Claude buffer
function M.get_code_stats(buf)
  local blocks = get_all_code_blocks(buf)

  if #blocks == 0 then
    return "No code blocks found"
  end

  local stats = {}
  local total_lines = 0

  for _, block in ipairs(blocks) do
    local lines = #vim.split(block.code, '\n')
    total_lines = total_lines + lines

    if stats[block.language] then
      stats[block.language] = stats[block.language] + lines
    else
      stats[block.language] = lines
    end
  end

  local result = { string.format("Found %d code blocks (%d total lines):", #blocks, total_lines) }

  for lang, lines in pairs(stats) do
    table.insert(result, string.format("  %s: %d lines", lang, lines))
  end

  return table.concat(result, "\n")
end

return M
