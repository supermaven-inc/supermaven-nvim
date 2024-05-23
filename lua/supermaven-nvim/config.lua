local default_config = {
  keymaps = {
    accept_suggestion = "<Tab>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = {},
  disable_inline_completion = false,
  disable_keymaps = false
}

local M = {}

M.setup_config = function(args)
  local config = vim.tbl_deep_extend("force", default_config, args)
  return config
end

return M
