local CompletionPreview = require("supermaven-nvim.completion_preview")
local u = require("supermaven-nvim.util")

local loop = u.uv

local source = { executions = {} }

local label_text = function(text, lines)
  if lines > 1 then
    text = text .. " ~"
  end

  local shorten = function(str)
    local short_prefix = string.sub(str, 0, 20)
    local short_suffix = string.sub(str, string.len(str) - 15, string.len(str))
    local delimiter = " ... "
    return short_prefix .. delimiter .. short_suffix
  end

  text = text:gsub("^%s*", "")
  return string.len(text) > 40 and shorten(text) or text
end

function source.get_trigger_characters()
  return { "*" }
end

function source.get_keyword_pattern()
  return "."
end

function source.is_available()
  return true
end

function source.resolve(self, completion_item, callback)
  for _, fn in ipairs(self.executions) do
    completion_item = fn(completion_item)
  end

  callback(completion_item)
end

function source.execute(self, completion_item, callback)
  CompletionPreview:dispose_inlay()

  callback(completion_item)
end

function source.complete(self, params, callback)
  local inlay_instance = CompletionPreview:get_inlay_instance()

  if inlay_instance == nil or inlay_instance.is_active == false then
    callback({
      isIncomplete = true,
      items = {},
    })
    return
  end

  -- local context         = params.context
  local cursor = vim.api.nvim_win_get_cursor(0)

  local range = {
    start = {
      line = cursor[1] - 1,
      -- character = math.max(cursor[2] - inlay_instance.prior_delete, 0),
      character = vim.fn.col("0"),
    },
    ["end"] = {
      line = cursor[1] - 1,
      character = vim.fn.col("$"),
    },
  }

  local completion_text = inlay_instance.line_before_cursor .. inlay_instance.completion_text
  local preview_text = completion_text
  local split = vim.split(completion_text, "\n", { plain = true })
  local label = label_text(split[1], #split)
  -- local label           = u.trim_start(vim.split(completion_text, "\n", { plain = true })[1])

  -- print("Completion label:", label)

  local items = {
    {
      label = label,
      kind = 1,
      score = 100,
      filterText = nil,
      cmp = {
        kind_hl_group = "CmpItemKindSupermaven",
        kind_text = "Supermaven",
      },
      textEdit = {
        newText = completion_text,
        insert = range,
        replace = range,
      },
      documentation = {
        kind = "markdown",
        value = "```" .. vim.bo.filetype .. "\n" .. preview_text .. "\n```",
      },
      dup = 0,
    },
  }

  return callback({
    isIncomplete = false,
    items = items,
  })
end

function source.new(client, opts)
  local self = setmetatable({
    timer = loop.new_timer(),
  }, { __index = source })

  self.client = client

  return self
end

return source
