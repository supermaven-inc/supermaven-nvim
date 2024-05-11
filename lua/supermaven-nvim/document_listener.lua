local u = require("supermaven-nvim.util")
local binary = require("supermaven-nvim.binary.binary_handler")
local preview = require("supermaven-nvim.completion_preview")

vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
  callback = function(event)
    local file_name = event["file"]
    local buffer = event["buf"]
    if not file_name or not buffer then
      return
    end
    if vim.api.nvim_buf_is_valid(buffer) then
      binary:on_update(buffer, file_name, "text_changed")
    end
  end
})

vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
  callback = function(event)
    local file_name = event["file"]
    local buffer = event["buf"]
    if not file_name or not buffer then
      return
    end

    if vim.api.nvim_buf_is_valid(buffer) then
      binary:on_update(buffer, file_name, "cursor")
    end
  end
})

vim.api.nvim_create_autocmd({"InsertLeave"}, {
  callback = function(event)
    preview:dispose_inlay()
  end
})
