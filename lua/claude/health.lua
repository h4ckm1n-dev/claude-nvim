local M = {}

local health = vim.health or require("health")

function M.check()
  health.report_start("Claude.nvim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.8.0") == 1 then
    health.report_ok("Neovim version >= 0.8.0")
  else
    health.report_error("Neovim version must be >= 0.8.0")
  end

  -- Check for plenary.nvim
  local has_plenary, _ = pcall(require, "plenary")
  if has_plenary then
    health.report_ok("plenary.nvim is installed")
  else
    health.report_error("plenary.nvim is required")
  end

  -- Check for Claude CLI
  local config = require("claude").get_config()
  local claude_path = config.claude_path
  local claude_exists = vim.fn.executable(claude_path) == 1

  if claude_exists then
    health.report_ok("Claude CLI is installed")
  else
    health.report_error(string.format(
      "Claude CLI not found at '%s'. Please install it first",
      claude_path
    ))
  end
end

return M
