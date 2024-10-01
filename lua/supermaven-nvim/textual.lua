local u = require("supermaven-nvim.util")
local M = {}

local function find_first_non_empty_newline(s)
  local seen_non_whitespace = false
  for i = 1, #s do
    local char = s:sub(i, i)
    if char == "\n" and seen_non_whitespace then
      return i
    elseif not u.isWhitespace(char) then
      seen_non_whitespace = true
    end
  end
  return nil
end

local function is_all_dust(line, dust_strings)
  local line_holding = line
  while #line_holding > 0 do
    local original_length = #line_holding
    line_holding = u.trim_start(line_holding)
    for _, dust_string in ipairs(dust_strings) do
      if line_holding:sub(1, #dust_string) == dust_string then
        line_holding = line_holding:sub(#dust_string + 1)
      end
    end

    if #line_holding == original_length then
      return false
    end
  end

  return true
end

local function is_all_whitespace_and_closing_paren(original_line)
  local line = original_line
  while #line > 0 do
    local start_length = #line
    line = u.trim_start(line)
    if line:sub(1, 1) == ")" then
      line = line:sub(2)
    end
    if #line == start_length then
      return false
    end
  end
  return true
end

local function has_leading_newline(s)
  for i = 1, #s do
    local char = s:sub(i, i)
    if char == "\n" then
      return true
    elseif not u.isWhitespace(char) then
      return false
    end
  end
  return false
end

local function find_last_newline(s)
  for i = #s, 1, -1 do
    local char = s:sub(i, i)
    if char == "\n" then
      return i
    end
  end

  return nil
end

local function can_delete(params)
  local trimmed = u.trim(params.line_before_cursor)
  if trimmed == "" and (not is_all_dust(params.line_after_cursor, params.dust_strings)) then
    return false
  end
  return true
end

---@param output string
---@param dedent string
---@param params CompletionParams
---@param full_completion_index integer | nil
---@return TextCompletion | nil
local function finish_completion(output, dedent, params, full_completion_index)
  if not can_delete(params) then
    return nil
  end
  local has_trailing_characters = #u.trim(params.line_after_cursor) > 0
  local output_trimmed = u.trim(output)
  if output_trimmed == "" then
    return nil
  end

  if has_leading_newline(output) then
    local first_non_empty_line = find_first_non_empty_newline(output)
    local last_new_line = find_last_newline(output)
    if first_non_empty_line ~= nil and last_new_line ~= nil then
      local text = output:sub(1, last_new_line)
      return {
        kind = "text",
        text = text,
        dedent = dedent,
        should_retry = nil,
        is_incomplete = false,
        source_state_id = params.source_state_id,
        completion_index = full_completion_index,
      }
    end
    return nil
  else
    local index = find_first_non_empty_newline(output)
    if index ~= nil then
      local text = output:sub(0, index)
      return {
        kind = "text",
        text = text,
        dedent = dedent,
        should_retry = true,
        is_incomplete = false,
        source_state_id = params.source_state_id,
        completion_index = nil,
      }
    end
    if params.can_retry then
      if has_trailing_characters then
        return {
          kind = "text",
          text = output,
          dedent = dedent,
          should_retry = true,
          is_incomplete = true,
          source_state_id = params.source_state_id,
          completion_index = nil,
        }
      end
      if u.trim(params.line_before_cursor) == "" then
        return {
          kind = "text",
          text = output,
          dedent = dedent,
          should_retry = true,
          is_incomplete = true,
          source_state_id = params.source_state_id,
          completion_index = nil,
        }
      end
      return {
        kind = "text",
        text = output,
        dedent = dedent,
        should_retry = true,
        is_incomplete = true,
        source_state_id = params.source_state_id,
        completion_index = nil,
      }
    end

    if has_trailing_characters then
      return nil
    end
    if u.trim(params.line_before_cursor) == "" then
      return nil
    end
    if params.can_show_partial_line then
      return {
        kind = "text",
        text = output,
        dedent = dedent,
        should_retry = true,
        is_incomplete = true,
        source_state_id = params.source_state_id,
        completion_index = nil,
      }
    end
    return nil
  end
end

---@param output string
---@param dedent string
---@param params CompletionParams
---@param completion_index integer
---@return TextCompletion
local function force_complete(output, dedent, params, completion_index)
  local result = finish_completion(output .. "\n", dedent, params, completion_index)
  if result == nil then
    return { kind = "text", text = "", dedent = "", is_incomplete = false }
  else
    return result
  end
end

---@param completion ResponseItem[]
---@param params CompletionParams
---@return AnyCompletion | nil
function M.derive_completion(completion, params)
  local output = ""
  local delete_lines = {}
  local dedent = ""

  for completion_index, response_item in ipairs(completion) do
    if response_item.kind == "end" then
      if string.find(output, "\n") then
        return force_complete(output, dedent, params, completion_index)
      else
        return nil
      end
    end
    if #delete_lines > 0 and response_item.kind ~= "delete" then
      return {
        type = "delete",
        lines = delete_lines,
        completion_index = completion_index,
        source_state_id = params.source_state_id,
      }
    end

    if response_item.kind == "text" then
      output = output .. response_item.text
    elseif (response_item.kind == "barrier") or (response_item.kind == "finish_edit") then
      if u.trim(output) ~= "" then
        return force_complete(output, dedent, params, completion_index)
      end
    elseif response_item.kind == "dedent" then
      dedent = dedent .. response_item.text
    elseif response_item.kind == "jump" then
      if u.trim(output) ~= "" then
        return {
          kind = "jump",
          file_name = response_item.fileName,
          line_number = response_item.lineNumber,
          verify = response_item.verify,
          precede = response_item.precede,
          follow = response_item.follow,
          completion_index = completion_index + 1,
          source_state_id = params.source_state_id,
          is_create_file = response_item.isCreateFile,
        }
      else
        break
      end
    elseif response_item.kind == "delete" then
      if u.trim(output) ~= "" then
        return force_complete(output, dedent, params, completion_index)
      end
      local following_line = params.get_following_line(#delete_lines)
      if u.trim_end(response_item.verify) == u.trim_end(following_line) then
        delete_lines[#delete_lines + 1] = following_line
      end
    elseif response_item.kind == "skip" then
      if u.trim(output) ~= "" then
        return force_complete(output, dedent, params, completion_index)
      end
      return {
        kind = "skip",
        n = response_item.n,
        completion_index = completion_index + 1,
        source_state_id = params.source_state_id,
      }
    end
  end

  output = u.trim_end(output)
  local index = find_first_non_empty_newline(output)
  if index ~= nil then
    output = output:sub(1, index)
  end

  return finish_completion(output, dedent, params, nil)
end

return M
