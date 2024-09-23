local binary = require("supermaven-nvim.binary.binary_handler")
local preview = require("supermaven-nvim.completion_preview")
local config = require("supermaven-nvim.config")

local M = {
  augroup = nil,
}

M.setup = function()
  M.augroup = vim.api.nvim_create_augroup("supermaven", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = M.augroup,
    callback = function(event)
      local file_name = event["file"]
      local buffer = event["buf"]
      if not file_name or not buffer then
        return
      end
      binary:on_update(buffer, file_name, "text_changed")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    callback = function(_)
      local ok, api = pcall(require, "supermaven-nvim.api")
      if not ok then
        return
      end
      if config.condition() or vim.g.SUPERMAVEN_DISABLED == 1 then
        if api.is_running() then
          api.stop()
          return
        end
      else
        if api.is_running() then
          return
        end
        api.start()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = M.augroup,
    callback = function(event)
      local file_name = event["file"]
      local buffer = event["buf"]
      if not file_name or not buffer then
        return
      end
      binary:on_update(buffer, file_name, "cursor")
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = M.augroup,
    callback = function(event)
      preview:dispose_inlay()
    end,
  })

  if config.color and config.color.suggestion_color and config.color.cterm then
    vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
      group = M.augroup,
      pattern = "*",
      callback = function(event)
        vim.api.nvim_set_hl(0, "SupermavenSuggestion", {
          fg = config.color.suggestion_color,
          ctermfg = config.color.cterm,
        })
        preview.suggestion_group = "SupermavenSuggestion"
      end,
    })
  end
end

M.teardown = function()
  if M.augroup ~= nil then
    vim.api.nvim_del_augroup_by_id(M.augroup)
    M.augroup = nil
  end
end

return M
