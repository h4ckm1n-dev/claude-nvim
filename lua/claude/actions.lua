local M = {}
local api = vim.api

-- Extract code blocks from text
local function extract_code_blocks(text)
  local blocks = {}
  local current_block = nil
  local lines = vim.split(text, "\n")

  for i, line in ipairs(lines) do
    if line:match("^```") then
      if current_block then
        current_block.code = table.concat(current_block.lines, "\n")
        table.insert(blocks, current_block)
        current_block = nil
      else
        current_block = {
          language = line:match("^```(.+)"),
          lines = {},
          start_line = i
        }
      end
    elseif current_block then
      table.insert(current_block.lines, line)
    end
  end

  return blocks
end

-- Apply code block to buffer with error handling
local function apply_code_block(code, target_buf)
  if not api.nvim_buf_is_valid(target_buf) then
    return false
  end
  
  -- Create temporary buffer for diff
  local temp_buf = api.nvim_create_buf(false, true)
  local ok = pcall(api.nvim_buf_set_lines, temp_buf, 0, -1, false, vim.split(code, "\n"))
  if not ok then
    pcall(api.nvim_buf_delete, temp_buf, { force = true })
    return false
  end

  -- Get diff with error handling
  local diff_ok, diff = pcall(vim.diff,
    table.concat(api.nvim_buf_get_lines(target_buf, 0, -1, false), "\n"),
    table.concat(api.nvim_buf_get_lines(temp_buf, 0, -1, false), "\n"),
    {
      algorithm = "minimal",
      ctxlen = 3
    }
  )
  
  if not diff_ok then
    pcall(api.nvim_buf_delete, temp_buf, { force = true })
    return false
  end

  -- Apply changes
  if diff then
    local changes = vim.diff.parse(diff)
    for _, change in ipairs(changes) do
      if change.type == "delete" then
        api.nvim_buf_set_lines(target_buf, change.start, change.start + change.count, false, {})
      elseif change.type == "add" then
        api.nvim_buf_set_lines(target_buf, change.start, change.start, false, change.lines)
      elseif change.type == "change" then
        api.nvim_buf_set_lines(target_buf, change.start, change.start + change.old_count, false, change.lines)
      end
    end
  end

  -- Clean up
  pcall(api.nvim_buf_delete, temp_buf, { force = true })
  return true
end

-- Apply code suggestion
function M.apply_code()
  local win = api.nvim_get_current_win()
  local buf = api.nvim_win_get_buf(win)
  local cursor = api.nvim_win_get_cursor(win)

  -- Get current line and surrounding context
  local lines = api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1] + 1, false)
  local current_line = lines[1]

  -- Find code blocks in current buffer
  local content = table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  local blocks = extract_code_blocks(content)

  if #blocks == 0 then
    return
  end

  -- Create picker for multiple blocks
  if #blocks > 1 then
    vim.ui.select(blocks, {
      prompt = "Select code block to apply:",
      format_item = function(block)
        return string.format("%s code block at line %d", block.language or "Unknown", block.start_line)
      end
    }, function(block)
      if block then
        apply_code_block(block.code, buf)
      end
    end)
  else
    apply_code_block(blocks[1].code, buf)
  end
end

return M
