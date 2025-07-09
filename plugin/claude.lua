if vim.g.loaded_claude then
  return
end
vim.g.loaded_claude = true

-- Initialize the plugin with error handling
local function safe_setup()
  local success, err = pcall(function()
    require("claude").setup()
  end)
  
  if not success then
    vim.notify("Claude plugin failed to load: " .. tostring(err), vim.log.levels.ERROR)
    -- Try to write to log file directly
    local log_file = vim.fn.stdpath("data") .. "/claude_debug.log"
    local file = io.open(log_file, "a")
    if file then
      file:write(string.format("[%s] [ERROR] Plugin load failed: %s\n", 
        os.date("%Y-%m-%d %H:%M:%S"), tostring(err)))
      file:close()
    end
  end
end

safe_setup()

-- Set up highlight groups
vim.api.nvim_set_hl(0, "ClaudePrompt", { link = "Comment" })
vim.api.nvim_set_hl(0, "ClaudeResponse", { link = "Normal" })
vim.api.nvim_set_hl(0, "ClaudeError", { link = "ErrorMsg" })
