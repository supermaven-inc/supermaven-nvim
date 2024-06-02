local api = require("supermaven-nvim.api")

local M = {}

M.setup = function()
  vim.api.nvim_create_user_command("SupermavenUseFree", function()
    api.use_free_version()
  end, {})

  vim.api.nvim_create_user_command("SupermavenUsePro", function()
    api.use_pro()
  end, {})

  vim.api.nvim_create_user_command("SupermavenLogout", function()
    api.logout()
  end, {})
end

return M
