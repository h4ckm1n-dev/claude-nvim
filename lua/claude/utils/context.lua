local M = {}

-- Get current buffer context
function M.get_buffer_context()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")

  return {
    content = table.concat(lines, "\n"),
    filetype = filetype,
    filename = filename,
  }
end

-- Get git context (diff)
function M.get_git_context()
  local git_diff = vim.fn.system("git diff")
  if vim.v.shell_error == 0 and git_diff ~= "" then
    return git_diff
  end
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
    })
  end

  return result
end

-- Build full context based on configuration
function M.build_context(config)
  local context = {}

  if config.context.include_buffer then
    context.buffer = M.get_buffer_context()
  end

  if config.context.include_git then
    context.git = M.get_git_context()
  end

  if config.context.include_lsp then
    context.lsp = M.get_lsp_context()
  end

  return context
end

return M
