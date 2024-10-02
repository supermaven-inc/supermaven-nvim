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

local function finish_completion(output, deletion, dedent, params)
  if not can_delete(params) then
    return nil
  end
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
        text = text,
        dedent = dedent,
        is_incomplete = false,
      }
    end
    return nil
  else
    local index = find_first_non_empty_newline(output)
    if index ~= nil then
      local text = output:sub(0, index)
      return {
        text = text,
        dedent = dedent,
        is_incomplete = false,
      }
    end

    if not is_all_whitespace_and_closing_paren(params.line_after_cursor) then
      return nil
    end

    local trimmed = u.trim(params.line_before_cursor)
    if trimmed == "" then
      return nil
    end

    if params.can_show_partial_line then
      return {
        text = output,
        dedent = dedent,
        is_incomplete = true,
      }
    end
  end

  return nil
end

function M.derive_completion(completion, completion_params)
  local output = ""
  local deletion = ""
  local dedent = ""
  for _, response_item in ipairs(completion) do
    if response_item.kind == "text" then
      output = output .. response_item.text
    elseif (response_item.kind == "end") or (response_item.kind == "barrier") then
      if u.trim(output) ~= "" or response_item.kind == "end" then
        local return_output = u.trim_end(output) .. "\n"
        local finished_completion = finish_completion(return_output, deletion, dedent, completion_params)
        if finished_completion ~= nil then
          return finished_completion
        else
          return {
            text = "",
            dedent = "",
            is_incomplete = false,
          }
        end
      end
    elseif response_item.kind == "del" then
      deletion = deletion .. response_item.text
    elseif response_item.kind == "dedent" then
      dedent = dedent .. response_item.text
    end
  end

  output = u.trim_end(output)
  local index = find_first_non_empty_newline(output)
  if index ~= nil then
    output = output:sub(1, index)
  end

  return finish_completion(output, deletion, dedent, completion_params)
end

return M
