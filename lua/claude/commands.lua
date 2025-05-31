local M = {}
local Job = require("plenary.job")

-- Execute Claude CLI command and handle the response
local function execute_claude_command(prompt, callback)
  local config = require("claude").get_config()

  Job:new({
    command = config.claude_path,
    args = { "--print", prompt },
    on_exit = function(j, return_val)
      if return_val == 0 then
        local result = table.concat(j:result(), "\n")
        callback(result)
      else
        local error_msg = table.concat(j:stderr_result(), "\n")
        vim.schedule(function()
          vim.notify(
            "Claude CLI error: " .. error_msg,
            vim.log.levels.ERROR,
            { title = "Claude.nvim" }
          )
        end)
      end
    end,
  }):start()
end

-- Handle the :Claude command
function M.handle_command(opts)
  local args = opts.args
  if #args == 0 then
    require("claude.window").toggle()
    return
  end

  local prompt = table.concat(args, " ")
  execute_claude_command(prompt, function(response)
    -- Create a new buffer with the response
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(response, "\n"))
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

    -- Open the buffer in a new window
    vim.cmd("vsplit")
    vim.api.nvim_win_set_buf(0, buf)
  end)
end

-- Process a prompt and update the buffer with the response
function M.process_prompt(prompt, buf)
  execute_claude_command(prompt, function(response)
    vim.schedule(function()
      local lines = vim.split(response, "\n")
      table.insert(lines, 1, "")
      table.insert(lines, 1, "Claude's response:")
      table.insert(lines, 1, "")
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    end)
  end)
end

return M
