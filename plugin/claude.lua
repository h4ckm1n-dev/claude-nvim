if vim.g.loaded_claude then
  return
end
vim.g.loaded_claude = true

-- Commands
vim.api.nvim_create_user_command("Claude", function(opts)
  require("claude.commands").handle_command(opts)
end, {
  nargs = "*",
  desc = "Interact with Claude AI",
})

-- Set up highlight groups
vim.api.nvim_set_hl(0, "ClaudePrompt", { link = "Comment" })
vim.api.nvim_set_hl(0, "ClaudeResponse", { link = "Normal" })
vim.api.nvim_set_hl(0, "ClaudeError", { link = "ErrorMsg" })
