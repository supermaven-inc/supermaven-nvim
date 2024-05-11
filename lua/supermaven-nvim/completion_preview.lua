local u = require("supermaven-nvim.util")

local CompletionPreview = {
  inlay_instance = nil,
  ns_id = vim.api.nvim_create_namespace('supermaven'),
  suggestion_group = "Comment",
}

CompletionPreview.__index = CompletionPreview

function CompletionPreview:render_with_inlay(buffer, prior_delete, completion_text, line_after_cursor, line_before_cursor)
  self:dispose_inlay()

  if not buffer then
    return
  end

  if vim.api.nvim_get_mode().mode ~= 'i' then
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

  if (#line_after_cursor > 0) and (not u.contains(first_line, line_after_cursor)) then
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
  }
  self.inlay_instance = new_instance
end

function CompletionPreview:render_floating(first_line, opts, buf, line_before_cursor)
  if first_line ~= "" then
    opts.virt_text = { { u.trim_start(line_before_cursor) .. first_line, self.suggestion_group } }
  end

  opts.virt_text_pos = "eol"
  local _extmark_id = vim.api.nvim_buf_set_extmark(buf, self.ns_id, vim.fn.line(".") - 1, 0, opts) -- :h api-extended-marks
end

function CompletionPreview:render_standard(first_line, other_lines, opts, buf)
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
  if buf ~= nil then
    vim.api.nvim_buf_del_extmark(buf, self.ns_id, 1)
  end
  self.inlay_instance = nil
end

function CompletionPreview:accept_completion_text()
  local current_instance = self.inlay_instance
  if current_instance == nil then
    return nil
  end
  local completion_text = current_instance.completion_text
  local prior_delete = current_instance.prior_delete
  CompletionPreview:dispose_inlay()

  if completion_text ~= nil then
    return {completion_text = completion_text, prior_delete = prior_delete, is_active = current_instance.is_active}
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

function CompletionPreview.on_accept_suggestion()
  local accept_completion = CompletionPreview:accept_completion_text()
  if accept_completion ~= nil and accept_completion.is_active then
    local completion_text = accept_completion.completion_text:gsub("\n\n*$", "") -- remove extra newlines
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
      }
    }

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space><Left><Del>", true, false, true), "n", false)
    vim.lsp.util.apply_text_edits({{ range = range, newText = completion_text }}, vim.api.nvim_get_current_buf(), "utf-16")
    local termcodes = string.rep("<Down>", u.line_count(completion_text))
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(termcodes .. "<End>", true, false, true), "n", false)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false , true), "n", true)
  end
end

function CompletionPreview.on_dispose_inlay()
  CompletionPreview:dispose_inlay()
end

return CompletionPreview
