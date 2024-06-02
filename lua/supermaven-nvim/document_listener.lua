local binary = require("supermaven-nvim.binary.binary_handler")
local preview = require("supermaven-nvim.completion_preview")
local config = require("supermaven-nvim.config")

local M = {}

M.setup = function()
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    callback = function(event)
      local file_name = event["file"]
      local buffer = event["buf"]
      if not file_name or not buffer then
        return
      end
      binary:on_update(buffer, file_name, "text_changed")
    end
  })

  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    callback = function(event)
      local file_name = event["file"]
      local buffer = event["buf"]
      if not file_name or not buffer then
        return
      end
      binary:on_update(buffer, file_name, "cursor")
    end
  })

  vim.api.nvim_create_autocmd({"InsertLeave"}, {
    callback = function(event)
      preview:dispose_inlay()
    end
  })

  if config.color and config.color.suggestion_color and config.color.cterm then
    vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
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

return M
  end
})

vim.api.nvim_create_autocmd({"InsertLeave"}, {
  callback = function(event)
    preview:dispose_inlay()
  end
})