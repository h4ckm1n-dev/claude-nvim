local M = {}

-- Detect code blocks and their language
local function detect_code_blocks(text)
  local blocks = {}
  local current_pos = 1

  -- Ensure text is a string
  if type(text) ~= "string" then
    return blocks
  end

  -- Match code blocks with proper error handling
  local pattern = "```(%w*)\n(.-)\n```"
  local start_pos, end_pos, lang, code = text:find(pattern)

  while start_pos do
    table.insert(blocks, {
      start = start_pos,
      lang = (lang and lang ~= "") and lang or "text",
      code = code or "",
      finish = end_pos
    })
    start_pos, end_pos, lang, code = text:find(pattern, end_pos + 1)
  end

  return blocks
end

-- Apply syntax highlighting to code blocks
function M.highlight_code(bufnr, text)
  -- Validate input
  if type(bufnr) ~= "number" or type(text) ~= "string" then
    return
  end

  -- Create namespace
  local ns_id = vim.api.nvim_create_namespace('claude_highlight')

  local blocks = detect_code_blocks(text)
  for _, block in ipairs(blocks) do
    -- Skip empty blocks
    if not block.code or block.code == "" then
      goto continue
    end

    -- Create a temporary buffer for highlighting
    local ok, temp_bufnr = pcall(vim.api.nvim_create_buf, false, true)
    if not ok then
      goto continue
    end

    -- Set buffer options safely
    pcall(vim.api.nvim_buf_set_option, temp_bufnr, 'buftype', 'nofile')
    pcall(vim.api.nvim_buf_set_option, temp_bufnr, 'bufhidden', 'wipe')

    -- Split code into lines and clean them
    local code_lines = vim.split(block.code, "\n")
    local clean_lines = {}
    for _, line in ipairs(code_lines) do
      if line and not line:match("^%s*$") then
        table.insert(clean_lines, line)
      end
    end

    -- Skip if no valid lines
    if #clean_lines == 0 then
      pcall(vim.api.nvim_buf_delete, temp_bufnr, { force = true })
      goto continue
    end

    -- Set lines and syntax
    ok = pcall(vim.api.nvim_buf_set_lines, temp_bufnr, 0, -1, false, clean_lines)
    if not ok then
      pcall(vim.api.nvim_buf_delete, temp_bufnr, { force = true })
      goto continue
    end

    -- Set syntax if language is specified
    if block.lang and block.lang ~= "text" then
      pcall(vim.api.nvim_buf_set_option, temp_bufnr, 'syntax', block.lang)
      vim.cmd('redraw')
    end

    -- Copy highlighting safely
    for i, line in ipairs(clean_lines) do
      local ok, highlights = pcall(vim.api.nvim_buf_get_extmarks, temp_bufnr, -1, i - 1, i, { details = true })
      if ok then
        for _, hl in ipairs(highlights) do
          if hl[4] and hl[4].hl_group then
            pcall(vim.api.nvim_buf_add_highlight, bufnr, ns_id, hl[4].hl_group, i - 1, 0, #line)
          end
        end
      end
    end

    -- Clean up
    pcall(vim.api.nvim_buf_delete, temp_bufnr, { force = true })

    ::continue::
  end
end

-- Simple markdown rendering
function M.render_markdown(bufnr, text)
  -- Validate input
  if type(bufnr) ~= "number" or type(text) ~= "string" then
    return
  end

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
    if type(line) == "string" then
      for _, syntax in ipairs(markdown_syntax) do
        for match in line:gmatch(syntax.pattern) do
          pcall(vim.api.nvim_buf_add_highlight, bufnr, -1, syntax.hl_group, i - 1, 0, #line)
        end
      end
    end
  end
end

-- Apply all rendering based on configuration
function M.render_response(bufnr, text, config)
  -- Validate input
  if type(bufnr) ~= "number" or type(text) ~= "string" or type(config) ~= "table" then
    return
  end

  if config.ui.syntax_highlight then
    M.highlight_code(bufnr, text)
  end

  if config.ui.markdown_render then
    M.render_markdown(bufnr, text)
  end
end

return M
