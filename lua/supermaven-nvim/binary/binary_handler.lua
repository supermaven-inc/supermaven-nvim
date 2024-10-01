local api = vim.api
local u = require("supermaven-nvim.util")
local loop = u.uv
local textual = require("supermaven-nvim.textual")
local config = require("supermaven-nvim.config")
local preview = require("supermaven-nvim.completion_preview")
local binary_fetcher = require("supermaven-nvim.binary.binary_fetcher")
local log = require("supermaven-nvim.logger")

local binary_path = binary_fetcher:fetch_binary()

local BinaryLifecycle = {
  state_map = {},
  current_state_id = 0,
  last_provide_time = 0,
  buffer = nil,
  cursor = nil,
  max_state_id_retention = 50,
  service_message_displayed = false,
  changed_document_list = {},
  last_state = nil,
  dust_strings = {},
}

BinaryLifecycle.HARD_SIZE_LIMIT = 10e6

local timer = loop.new_timer()
timer:start(
  0,
  25,
  vim.schedule_wrap(function()
    if BinaryLifecycle.wants_polling then
      BinaryLifecycle:poll_once()
    end
  end)
)

function BinaryLifecycle:start_binary()
  self.stdin = loop.new_pipe(false)
  self.stdout = loop.new_pipe(false)
  self.stderr = loop.new_pipe(false)
  self.last_text = nil
  self.last_path = nil
  self.last_context = nil
  self.wants_polling = false
  self.handle = loop.spawn(binary_path, {
    args = {
      "stdio",
    },
    stdio = { self.stdin, self.stdout, self.stderr },
  }, function(code, signal)
    log:debug("sm-agent exited with code " .. code)
    self.handle:close()
    self.handle = nil
  end)
  if not self.handle then
    log:debug("Starting binary")
  end
  self:read_loop()
  self:greeting_message()
end

function BinaryLifecycle:is_running()
  return self.handle ~= nil and self.handle:is_active()
end

function BinaryLifecycle:stop_binary()
  if self:is_running() then
    self.handle:kill(loop.constants.SIGTERM)
    self.handle:close()
    self.handle = nil
  end
end

function BinaryLifecycle:greeting_message()
  local message = vim.json.encode({ kind = "greeting", allowGitignore = false }) .. "\n"
  loop.write(self.stdin, message) -- fails silently
end

---@param buffer integer
---@param file_name string
---@param event_type "text_changed" | "cursor"
function BinaryLifecycle:on_update(buffer, file_name, event_type)
  if config.ignore_filetypes[vim.bo.ft] or vim.tbl_contains(config.ignore_filetypes, vim.bo.filetype) then
    return
  end
  local buffer_text = u.get_text(buffer)
  local file_path = vim.api.nvim_buf_get_name(buffer)
  if #buffer_text > self.HARD_SIZE_LIMIT then
    log:warn("File is too large to send to server. Skipping...")
    return
  end

  self:document_changed(file_path, buffer_text)
  local cursor = api.nvim_win_get_cursor(0)
  local completion_is_allowed = (buffer_text ~= self.last_text) and (self.last_path == file_name)
  local context = {
    document_text = buffer_text,
    cursor = cursor,
    file_name = file_name,
  }
  if completion_is_allowed then
    self:provide_inline_completion_items(buffer, cursor, context)
  elseif not self:same_context(context) then
    preview:dispose_inlay()
  end

  self.last_path = file_name
  self.last_text = buffer_text
  self.last_context = context
end

function BinaryLifecycle:check_process()
  if self.handle ~= nil and self.handle:is_active() then
    return true
  end

  if self.handle ~= nil then
    self.handle:close()
  end

  self:start_binary()
end

function BinaryLifecycle:same_context(context)
  if self.last_context == nil then
    return false
  end
  return context.cursor[1] == self.last_context.cursor[1]
    and context.cursor[2] == self.last_context.cursor[2]
    and context.file_name == self.last_context.file_name
    and context.document_text == self.last_context.document_text
end

function BinaryLifecycle:read_loop()
  local stdout = self.stdout
  local buffer = ""
  loop.read_start(stdout, function(err, data)
    if err then
      self:on_error(err)
      return
    else
      if data == nil then
        return
      end
      buffer = buffer .. data
      while true do
        local line_end = string.find(buffer, "\n")
        if line_end then
          local line = string.sub(buffer, 1, line_end - 1)
          buffer = string.sub(buffer, line_end + 1)
          self:process_line(line)
        else
          break
        end
      end
    end
  end)
end

function BinaryLifecycle:process_line(line)
  if string.sub(line, 1, 11) == "SM-MESSAGE " then
    line = string.sub(line, 12)
    local message = vim.json.decode(line)
    self:process_message(message)
  else
    log:debug("Unknown message: " .. line)
  end
end

function BinaryLifecycle:process_message(message)
  if message.kind == "response" then
    self:update_state_id(message)
  elseif message.kind == "metadata" then
    self:update_metadata(message)
  elseif message.kind == "activation_request" then
    self.activate_url = message.activateUrl
    vim.schedule(function()
      if self.activate_url ~= nil then
        self:open_popup(self.activate_url, true)
      end
    end)
  elseif message.kind == "activation_success" then
    self.activate_url = nil
    log:trace("Supermaven was activated successfully.")
    vim.schedule(function()
      self:close_popup()
    end)
  elseif message.kind == "passthrough" then
    self:process_message(message.passthrough)
  elseif message.kind == "popup" then
    -- unused
  elseif message.kind == "task_status" then
    -- unused, no status bar is displayed
  elseif message.kind == "active_repo" then
    -- unused, no status bar is displayed
  elseif message.kind == "service_tier" then
    if not self.service_message_displayed then
      if message.display then
        log:trace("Supermaven " .. message.display .. " is running.")
      end
      self.service_message_displayed = true
    end
    vim.schedule(function()
      self:close_popup()
    end)
  elseif message.kind == "apology" then
    -- legacy
  elseif message.kind == "set" then
    -- unused, no status bar is displayed
  end
end

function BinaryLifecycle:update_state_id(message)
  -- Run on receiving binary message
  local completion_state_id = tonumber(message.stateId)
  local current_state = self.state_map[completion_state_id]
  if current_state == nil then
    -- Unknown state, could have been removed by purge_old_states
    return
  end
  local state_completion = current_state.completion
  for _, completion in ipairs(message.items) do
    table.insert(state_completion, completion)
  end
end

function BinaryLifecycle:update_metadata(metadata_message)
  if metadata_message.dustStrings ~= nil then
    self.dust_strings = metadata_message.dustStrings
  end
end

function BinaryLifecycle:on_error(err)
  require("supermaven-nvim.api").stop()
  log:error("Error reading stdout: " .. err)
end

function BinaryLifecycle:send_json(msg)
  local message = vim.json.encode(msg) .. "\n"
  loop.write(self.stdin, message) -- fails silently
end

function BinaryLifecycle:send_message(updates)
  local state_update = {
    kind = "state_update",
    newId = tostring(self.current_state_id),
    updates = updates,
  }

  self:send_json(state_update)
end

function BinaryLifecycle:purge_old_states()
  for state_id, _ in pairs(self.state_map) do
    if state_id < self.current_state_id - self.max_state_id_retention then
      self.state_map[state_id] = nil
    end
  end
end

function BinaryLifecycle:provide_inline_completion_items(buffer, cursor, context)
  self.buffer = buffer
  self.cursor = cursor
  self.last_context = context
  self.last_provide_time = loop.now()
  self:poll_once()
end

function BinaryLifecycle:poll_once()
  if config.ignore_filetypes[vim.bo.ft] or vim.tbl_contains(config.ignore_filetypes, vim.bo.filetype) then
    return
  end
  local now = loop.now()
  if now - self.last_provide_time > 5 * 1000 then
    self.wants_polling = false
    return
  end
  self.wants_polling = true
  local buffer = self.buffer
  local cursor = self.cursor
  if not vim.api.nvim_buf_is_valid(buffer) then
    self.wants_polling = false
    return
  end
  local text_split = u.get_text_before_after_cursor(cursor)
  local line_before_cursor = text_split.text_before_cursor
  local line_after_cursor = text_split.text_after_cursor
  if line_before_cursor == nil or line_after_cursor == nil then
    return
  end
  local status, prefix = pcall(u.get_cursor_prefix, buffer, cursor)
  if not status then
    return
  end
  local get_following_line = function(index)
    return u.safe_get_line(buffer, cursor[1] + index) or ""
  end
  local cached_chain_info = nil -- TODO
  local query_state_id = self:submit_query(buffer, prefix)
  if query_state_id == nil then
    return
  end
  local maybe_completion = self:check_state(
    prefix,
    line_before_cursor,
    line_after_cursor,
    false,
    get_following_line,
    query_state_id,
    cached_chain_info
  )

  if maybe_completion == nil then
    preview:dispose_inlay()
    return
  end

  if maybe_completion.kind == "jump" then
    return
  elseif maybe_completion.kind == "delete" then
    return
  elseif maybe_completion.kind == "skip" then
    return
  end

  self.wants_polling = maybe_completion.is_incomplete
  if maybe_completion.dedent == nil or
   (#maybe_completion.dedent > 0 and not u.ends_with(line_before_cursor, maybe_completion.dedent))
  then
    return
  end

  while
    #maybe_completion.dedent > 0
    and #maybe_completion.text > 0
    and maybe_completion.dedent:sub(1, 1) == maybe_completion.text:sub(1, 1)
  do
    maybe_completion.text = maybe_completion.text:sub(2)
    maybe_completion.dedent = maybe_completion.dedent:sub(2)
  end

  local prior_delete = #maybe_completion.dedent
  maybe_completion.text = u.trim_end(maybe_completion.text)
  preview:render_with_inlay(buffer, prior_delete, maybe_completion.text, line_after_cursor, line_before_cursor)
end

---@param prefix string
---@param line_before_cursor string
---@param line_after_cursor string
---@param can_retry boolean
---@param get_following_line fun(line: string): string
---@param query_state_id integer
---@param cached_chain_info ChainInfo | nil
---@return AnyCompletion | nil
function BinaryLifecycle:check_state(
  prefix,
  line_before_cursor,
  line_after_cursor,
  can_retry,
  get_following_line,
  query_state_id,
  cached_chain_info
)
  local params = {
    line_before_cursor = line_before_cursor,
    line_after_cursor = line_after_cursor,
    get_following_line = get_following_line,
    dust_strings = self.dust_strings,
    can_show_partial_line = true,
    can_retry = can_retry,
    source_state_id = query_state_id,
  }

  self:check_process()
  local best_completion = {}
  local best_length = 0
  local best_state_id = -1

  for state_id, state in pairs(self.state_map) do
    local state_prefix = state.prefix
    if state_prefix ~= nil and #prefix >= #state_prefix then
      if string.sub(prefix, 1, #state_prefix) == state_prefix then
        local user_input = prefix:sub(#state_prefix + 1)
        local remaining_completion = self:strip_prefix(state.completion, user_input)
        if remaining_completion ~= nil then
          local total_length = self:completion_text_length(remaining_completion)
          if total_length > best_length or (total_length == best_length and state_id > best_state_id) then
            best_completion = remaining_completion
            best_length = total_length
            best_state_id = state_id
          end
        end
      end
    end
  end

  return textual.derive_completion(best_completion, params)
end

function BinaryLifecycle:completion_text_length(completion)
  local length = 0
  for _, response_item in ipairs(completion) do
    if response_item.kind == "text" then
      length = length + #response_item.text
    end
  end
  return length
end

---@param bufnr integer
---@param prefix string
---@return integer | nil
function BinaryLifecycle:submit_query(bufnr, prefix)
  self:purge_old_states()
  local buffer_text = u.get_text(bufnr)
  local offset = #prefix
  local document_state = {
    kind = "file_update",
    path = vim.api.nvim_buf_get_name(bufnr),
    content = buffer_text,
  }
  local cursor_state = {
    kind = "cursor_update",
    path = vim.api.nvim_buf_get_name(bufnr),
    offset = offset,
  }
  if self.last_state ~= nil then
    if #self.changed_document_list == 0 then
      if self.last_state.cursor.path == cursor_state.path and self.last_state.cursor.offset == cursor_state.offset then
        if
          self.last_state.document.path == document_state.path
          and self.last_state.document.content == document_state.content
        then
          return self.current_state_id
        end
      end
    end
  end

  local updates = {
    cursor_state,
  }
  self:document_changed(document_state.path, buffer_text)
  for _, document_value in pairs(self.changed_document_list) do
    updates[#updates + 1] = {
      kind = "file_update",
      path = document_value.path,
      content = document_value.content,
    }
  end
  self.changed_document_list = {}
  self.current_state_id = self.current_state_id + 1
  self:send_message(updates)
  self.state_map[self.current_state_id] = {
    prefix = prefix,
    completion = {},
    has_ended = false,
  }
  self.last_state = {
    cursor = cursor_state,
    document = document_state,
  }
  return self.current_state_id
end

---@param completion ResponseItem[]
---@param original_prefix string
---@return ResponseItem[] | nil
function BinaryLifecycle:strip_prefix(completion, original_prefix)
  local prefix = original_prefix
  local remaining_response_item = {}

  for _, response_item in ipairs(completion) do
    if response_item.kind == "text" then
      local text = response_item.text
      if not self:shares_common_prefix(text, prefix) then
        return nil
      end
      local trim_length = math.min(#text, #prefix)
      text = text:sub(trim_length + 1)
      prefix = prefix:sub(trim_length + 1)
      if #text > 0 then
        table.insert(remaining_response_item, {
          kind = "text",
          text = text,
        })
      end
    elseif response_item.kind == "delete" then
      table.insert(remaining_response_item, response_item)
    elseif response_item.kind == "dedent" then
      if #prefix > 0 then
        return nil
      end
      table.insert(remaining_response_item, response_item)
    else
      if #prefix == 0 then
        table.insert(remaining_response_item, response_item)
      end
    end
  end
  return remaining_response_item
end

function BinaryLifecycle:shares_common_prefix(str1, str2)
  local min_length = math.min(#str1, #str2)
  if str1:sub(1, min_length) ~= str2:sub(1, min_length) then
    return false
  end
  return true
end

function BinaryLifecycle:show_activation_message()
  if self.activate_url ~= nil then
    log:info([[Thank you for installing Supermaven!

Use :SupermavenUsePro to set up Supermaven Pro, or use the command :SupermavenUseFree to use the Free Tier]])
  end
end

function BinaryLifecycle:use_free_version()
  local message = vim.json.encode({ kind = "use_free_version" }) .. "\n"
  loop.write(self.stdin, message) -- fails silently
end

function BinaryLifecycle:logout()
  self.service_message_displayed = false
  local message = vim.json.encode({ kind = "logout" }) .. "\n"
  loop.write(self.stdin, message) -- fails silently
end

function BinaryLifecycle:use_pro()
  if self.activate_url ~= nil then
    log:debug("Visit " .. self.activate_url .. " to set up Supermaven Pro")
    self:open_popup(self.activate_url)
  else
    log:error("Could not find an activation URL.")
  end
end

function BinaryLifecycle:close_popup()
  if self.win ~= nil and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
  self.win = nil
end

function BinaryLifecycle:open_popup(message, include_free)
  if self.win ~= nil and vim.api.nvim_win_is_valid(self.win) then
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)

  local width = 0
  local height = 0
  width = u.nvim_get_option_value("columns", { scope = "local" })
  height = u.nvim_get_option_value("lines", { scope = "local" })

  local intro_message = "Please visit the following URL to set up Supermaven Pro"
  if include_free then
    intro_message = intro_message .. " (or use :SupermavenUseFree)."
  end
  local win_height = 3
  local win_width = math.max(#message, #intro_message) + 3
  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = "rounded",
    focusable = true,
    noautocmd = true,
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { intro_message, "", message .. " " })
  u.nvim_set_option_value("winhl", "Normal:Normal", { scope = "local", win = win })
  u.nvim_set_option_value("wrap", true, { scope = "local", win = win })

  self.win = win
end

---@param full_path string
---@param buffer_text string
function BinaryLifecycle:document_changed(full_path, buffer_text)
  self.changed_document_list[full_path] = {
    path = full_path,
    content = buffer_text,
    cursor = api.nvim_win_get_cursor(0),
  }
  local outgoing_message = {
    kind = "inform_file_changed",
    path = full_path,
  }
  self:send_json(outgoing_message)
end

return BinaryLifecycle
