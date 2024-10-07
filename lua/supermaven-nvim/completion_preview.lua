local u = require("supermaven-nvim.util")

local CompletionPreview = {
  inlay_instance = nil,
  ns_id = vim.api.nvim_create_namespace("supermaven"),
  suggestion_group = "Comment",
  disable_inline_completion = false,
}

CompletionPreview.__index = CompletionPreview

function CompletionPreview:render_with_inlay(
  buffer,
  prior_delete,
  completion_text,
  line_after_cursor,
  line_before_cursor
)
  self:dispose_inlay()

  if not buffer then
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  if mode ~= "i" and mode ~= "ic" then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local opts = {
    id = 1,
    hl_mode = "combine",
  }

  local processed_text = u.first_line_split(completion_text, self.suggestion_group)
  local first_line = processed_text.first_line
  local other_lines = processed_text.other_lines

  local is_floating = (#line_after_cursor > 0) and (not u.contains(first_line, line_after_cursor))

  if is_floating then
    self:render_floating(first_line, opts, buf, line_before_cursor)
    completion_text = first_line
  else
    self:render_standard(first_line, other_lines, opts, buf)
  end
  local new_instance = {
    prior_delete = prior_delete,
    buffer = buffer,
    completion_text = completion_text,
    is_active = self:should_completion_be_active(completion_text, line_before_cursor, first_line),
    line_before_cursor = line_before_cursor,
    line_after_cursor = line_after_cursor,
    is_floating = is_floating,
  }
  self.inlay_instance = new_instance
end

function CompletionPreview:render_floating(first_line, opts, buf, line_before_cursor)
  if self.disable_inline_completion then
    return
  end

  if first_line ~= "" then
    opts.virt_text = { { u.trim_start(line_before_cursor) .. first_line, self.suggestion_group } }
  end

  opts.virt_text_pos = "eol"

  local _extmark_id = vim.api.nvim_buf_set_extmark(buf, self.ns_id, vim.fn.line(".") - 1, 0, opts) -- :h api-extended-marks
end

function CompletionPreview:render_standard(first_line, other_lines, opts, buf)
  if self.disable_inline_completion then
    return
  end

  if first_line ~= "" then
    opts.virt_text = { { first_line, self.suggestion_group } }
  end
  if #other_lines > 0 then
    opts.virt_lines = other_lines
  end

  opts.virt_text_win_col = vim.fn.virtcol(".") - 1

  local _extmark_id = vim.api.nvim_buf_set_extmark(buf, self.ns_id, vim.fn.line(".") - 1, vim.fn.col(".") - 1, opts) -- :h api-extended-marks
end

function CompletionPreview:dispose_inlay()
  local current_instance = self.inlay_instance
  if current_instance == nil then
    return
  end

  local buf = current_instance.buffer
  if buf ~= nil and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_del_extmark(buf, self.ns_id, 1)
  end
  self.inlay_instance = nil
end

function CompletionPreview:accept_completion_text(is_partial)
  local current_instance = self.inlay_instance
  if current_instance == nil then
    return nil
  end
  local completion_text = current_instance.completion_text
  local prior_delete = current_instance.prior_delete
  CompletionPreview:dispose_inlay()

  if completion_text ~= nil then
    if is_partial then
      completion_text = u.to_next_word(completion_text)
    end
    return { completion_text = completion_text, prior_delete = prior_delete, is_active = current_instance.is_active }
  end
end

function CompletionPreview:should_completion_be_active(completion_text, line_before_cursor, first_line)
  if (completion_text == "") or (not completion_text:sub(1, 1):match("%s")) then
    return true
  end

  if u.trim(line_before_cursor) ~= "" then
    return true
  end

  if u.trim(first_line) == "" then
    return true
  end

  return false
end

function CompletionPreview:get_inlay_instance()
  return self.inlay_instance
end

function CompletionPreview.on_accept_suggestion(is_partial)
  local accept_completion = CompletionPreview:accept_completion_text(is_partial)
  if accept_completion ~= nil and accept_completion.is_active then
    local completion_text = accept_completion.completion_text
    local prior_delete = accept_completion.prior_delete
    local cursor = vim.api.nvim_win_get_cursor(0)
    local range = {
      start = {
        line = cursor[1] - 1,
        character = math.max(cursor[2] - prior_delete, 0),
      },
      ["end"] = {
        line = cursor[1] - 1,
        character = vim.fn.col("$"),
      },
    }

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space><Left><Del>", true, false, true), "n", false)
    vim.lsp.util.apply_text_edits(
      { { range = range, newText = completion_text } },
      vim.api.nvim_get_current_buf(),
      "utf-8"
    )

    local lines = u.line_count(completion_text)
    local last_line = u.get_last_line(completion_text)
    local new_cursor_pos = { cursor[1] + lines, cursor[2] + #last_line + 1 }
    vim.api.nvim_win_set_cursor(0, new_cursor_pos)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
  end
end

function CompletionPreview.on_accept_suggestion_word()
  CompletionPreview.on_accept_suggestion(true)
end

function CompletionPreview.on_dispose_inlay()
  CompletionPreview:dispose_inlay()
end

function CompletionPreview.has_suggestion()
  local inlay_instance = CompletionPreview:get_inlay_instance()
  return inlay_instance ~= nil
    and inlay_instance.is_active
    and inlay_instance.completion_text ~= nil
    and inlay_instance.completion_text ~= ""
end

return CompletionPreview
