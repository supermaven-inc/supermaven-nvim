local api = require("supermaven-nvim.api")
local log = require("supermaven-nvim.logger")

local M = {}

M.setup = function()
  vim.api.nvim_create_user_command("SupermavenStart", function()
    api.start()
  end, {})

  vim.api.nvim_create_user_command("SupermavenStop", function()
    api.stop()
  end, {})

  vim.api.nvim_create_user_command("SupermavenRestart", function()
    api.restart()
  end, {})

  vim.api.nvim_create_user_command("SupermavenToggle", function()
    api.toggle()
  end, {})

  vim.api.nvim_create_user_command("SupermavenStatus", function()
    log:trace(string.format("Supermaven is %s", api.is_running() and "running" or "not running"))
  end, {})

  vim.api.nvim_create_user_command("SupermavenUseFree", function()
    api.logout()
    api.use_free_version()
  end, {})

  vim.api.nvim_create_user_command("SupermavenUsePro", function()
    api.logout()
    api.use_pro()
  end, {})

  vim.api.nvim_create_user_command("SupermavenLogout", function()
    api.logout()
  end, {})

  vim.api.nvim_create_user_command("SupermavenShowLog", function()
    api.show_log()
  end, {})

  vim.api.nvim_create_user_command("SupermavenClearLog", function()
    api.clear_log()
  end, {})
end

return M
