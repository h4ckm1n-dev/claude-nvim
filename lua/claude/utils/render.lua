local M = {}

-- Detect code blocks and their language
local function detect_code_blocks(text)
  local blocks = {}
  local current_pos = 1

  for start_pos, lang, code, end_pos in text:gmatch("```(%w*)\n(.-)\n```") do
    table.insert(blocks, {
      start = start_pos,
      lang = lang ~= "" and lang or "text",
      code = code,
      finish = end_pos
    })
  end

  return blocks
end

-- Apply syntax highlighting to code blocks
function M.highlight_code(bufnr, text)
  local blocks = detect_code_blocks(text)

  for _, block in ipairs(blocks) do
    -- Create a temporary buffer for highlighting
    local temp_bufnr = vim.api.nvim_create_buf(false, true)

    -- Set buffer options safely
    pcall(vim.api.nvim_buf_set_option, temp_bufnr, 'buftype', 'nofile')
    pcall(vim.api.nvim_buf_set_option, temp_bufnr, 'bufhidden', 'wipe')

    -- Set filetype if language is specified
    if block.lang and block.lang ~= "text" then
      pcall(vim.api.nvim_buf_set_option, temp_bufnr, 'filetype', block.lang)
    end

    -- Split code into lines and remove empty lines at start/end
    local code_lines = vim.split(block.code, "\n")
    while code_lines[1] and code_lines[1]:match("^%s*$") do
      table.remove(code_lines, 1)
    end
    while code_lines[#code_lines] and code_lines[#code_lines]:match("^%s*$") do
      table.remove(code_lines)
    end

    -- Set lines safely
    if #code_lines > 0 then
      pcall(vim.api.nvim_buf_set_lines, temp_bufnr, 0, -1, false, code_lines)

      -- Get highlighting
      local ns_id = vim.api.nvim_create_namespace('claude_highlight')
      vim.api.nvim_buf_set_option(temp_bufnr, 'syntax', block.lang)

      -- Wait for syntax to be applied
      vim.cmd('redraw')

      -- Copy highlighting safely
      for i, line in ipairs(code_lines) do
        local highlights = vim.api.nvim_buf_get_extmarks(temp_bufnr, -1, i - 1, i, { details = true })
        for _, hl in ipairs(highlights) do
          pcall(vim.api.nvim_buf_add_highlight, bufnr, ns_id, hl[4].hl_group, i - 1, hl[3], hl[3] + hl[4].end_col)
        end
      end
    end

    -- Clean up
    pcall(vim.api.nvim_buf_delete, temp_bufnr, { force = true })
  end
end

-- Simple markdown rendering
function M.render_markdown(bufnr, text)
  -- Basic markdown syntax
  local markdown_syntax = {
    { pattern = "^#%s+(.-)$",   hl_group = "Title" },
    { pattern = "^##%s+(.-)$",  hl_group = "Title" },
    { pattern = "^###%s+(.-)$", hl_group = "Title" },
    { pattern = "%*%*(.-)%*%*", hl_group = "Bold" },
    { pattern = "_%_(.-)%_%_",  hl_group = "Italic" },
    { pattern = "`([^`]+)`",    hl_group = "Special" },
    { pattern = "^%-%s+(.-)$",  hl_group = "Statement" },
  }

  local lines = vim.split(text, "\n")
  for i, line in ipairs(lines) do
    for _, syntax in ipairs(markdown_syntax) do
      for match in line:gmatch(syntax.pattern) do
        vim.api.nvim_buf_add_highlight(bufnr, -1, syntax.hl_group, i - 1, 0, -1)
      end
    end
  end
end

-- Apply all rendering based on configuration
function M.render_response(bufnr, text, config)
  if config.ui.syntax_highlight then
    M.highlight_code(bufnr, text)
  end

  if config.ui.markdown_render then
    M.render_markdown(bufnr, text)
  end
end

return M
