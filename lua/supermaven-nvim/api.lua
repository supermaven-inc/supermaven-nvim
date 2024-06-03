local binary = require("supermaven-nvim.binary.binary_handler")
local listener = require("supermaven-nvim.document_listener")

local M = {}

M.is_running = function()
  return binary:is_running()
end

M.start = function()
  if M.is_running() then
    vim.notify("Supermaven is already running.", vim.log.levels.WARN)
  end
  binary:start_binary()
  listener.setup()
end

M.stop = function()
  if not M.is_running() then
    vim.notify("Supermaven is not running.", vim.log.levels.WARN)
    return
  end
  listener.teardown()
  binary:stop_binary()
end

M.restart = function()
  if M.is_running() then
    M.stop()
  end
  M.start()
end

M.toggle = function()
  if M.is_running() then
    M.stop()
  else
    M.start()
  end
end

M.use_free_version = function()
  binary:use_free_version()
end

M.use_pro = function()
  binary:use_pro()
end

M.logout = function()
  binary:logout()
end

return M
