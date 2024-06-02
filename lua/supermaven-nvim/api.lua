local binary = require("supermaven-nvim.binary.binary_handler")
local listener = require("supermaven-nvim.document_listener")

local M = {}

M.start = function()
  if M.is_running() then
    vim.notify("Supermaven is already running.", vim.log.levels.WARN)
  end
  binary:start_binary()
  listener.setup()
end

M.use_free_version = function()
  binary:use_free_version()
end

M.logout = function()
  binary:logout()
end

M.use_pro = function()
  binary:use_pro()
end

return M
