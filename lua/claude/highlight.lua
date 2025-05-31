local M = {}
local api = vim.api
local config = require("claude").get_config()

-- Store namespace for highlights
local ns = api.nvim_create_namespace("claude_highlight")

-- Language detection patterns
local lang_patterns = {
  lua = "^```lua",
  python = "^```python",
  javascript = "^```javascript",
  typescript = "^```typescript",
  rust = "^```rust",
  go = "^```go",
  -- Add more languages as needed
}

-- Detect language from code block
local function detect_language(line)
  for lang, pattern in pairs(lang_patterns) do
    if line:match(pattern) then
      return lang
    end
  end
  return nil
end

-- Extract code blocks from buffer
local function find_code_blocks(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local blocks = {}
  local current_block = nil

  for i, line in ipairs(lines) do
    if line:match("^```") then
      if current_block then
        current_block.end_line = i - 1
        table.insert(blocks, current_block)
        current_block = nil
      else
        current_block = {
          start_line = i + 1,
          language = detect_language(line)
        }
      end
    end
  end

  return blocks
end

-- Highlight code block
local function highlight_block(bufnr, block)
  if not block.language then return end

  -- Get treesitter parser
  local parser = vim.treesitter.get_string_parser(
    table.concat(
      api.nvim_buf_get_lines(bufnr, block.start_line, block.end_line, false),
      "\n"
    ),
    block.language
  )

  if not parser then return end

  -- Parse and get syntax tree
  local tree = parser:parse()[1]
  local root = tree:root()

  -- Apply highlights
  local highlight_query = vim.treesitter.get_query(block.language, "highlights")
  if not highlight_query then return end

  for id, node, metadata in highlight_query:iter_captures(root, block.language) do
    local start_row, start_col, end_row, end_col = node:range()
    local capture_name = highlight_query.captures[id]

    -- Adjust for block offset
    start_row = start_row + block.start_line
    end_row = end_row + block.start_line

    api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col, {
      end_line = end_row,
      end_col = end_col,
      hl_group = string.format("@%s", capture_name)
    })
  end
end

-- Refresh highlights
function M.refresh()
  local bufnr = api.nvim_get_current_buf()

  -- Clear existing highlights
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  -- Find and highlight code blocks
  local blocks = find_code_blocks(bufnr)
  for _, block in ipairs(blocks) do
    highlight_block(bufnr, block)
  end
end

-- Initialize highlighting
function M.setup()
  -- Set up autocommands for auto-refresh
  local group = api.nvim_create_augroup("ClaudeHighlight", { clear = true })

  api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function()
      if config.highlight.enabled then
        vim.defer_fn(function()
          M.refresh()
        end, config.highlight.timeout)
      end
    end,
  })
end

return M
