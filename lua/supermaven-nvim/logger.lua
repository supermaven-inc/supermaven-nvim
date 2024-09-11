---@diagnostic disable: missing-parameter
local c = require("supermaven-nvim.config")

---@class Log
local log = {}

---@alias LogLevel "off" | "trace" | "debug" | "info" | "warn" | "error" | "log"

local join_path = function(...)
  local is_windows = vim.loop.os_uname().version:match("Windows") -- could be "Windows" or "Windows_NT"
  local path_sep = is_windows and "\\" or "/"
  if vim.version().minor >= 10 then
    return table.concat(vim.iter({ ... }):flatten():totable(), path_sep):gsub(path_sep .. "+", path_sep)
  end
  return table.concat(vim.tbl_flatten({ ... }), path_sep):gsub(path_sep .. "+", path_sep)
end

--- Creates a log file if it doesn't exist
local create_log_file = function()
  local log_path = log:get_log_path()
  if log_path ~= nil then
    return
  end
  log_path = join_path(vim.fn.stdpath("cache"), "supermaven-nvim.log")
  local file = io.open(log_path, "w")
  if file == nil then
    error("Failed to create log file: " .. log_path)
    return
  end
  file:close()
end

--- Writes a log entry to the log file
---@param level LogLevel: The log level
---@param msg string: The log message
function log:write_log_file(level, msg)
  local log_path = log:get_log_path()
  if log_path == nil then
    create_log_file()
    return
  end
  local file = io.open(log_path, "a")
  if file == nil then
    vim.api.nvim_err_writeln("Failed to open log file: " .. log_path)
    return
  end
  file:write(string.format("[%-6s %s] %s\n", level:upper(), os.date(), msg))
  file:close()
end

--- Adds log entry to the log file
---@param level LogLevel: The log level
---@param msg string: The log message
function log:add_entry(level, msg)
  local conf = c.config

  if not self.__notify_fmt then
    self.__notify_fmt = function(message)
      return string.format(string.format("[supermaven-nvim] %s", message))
    end
  end

  if conf.log_level == "off" then
    return
  end

  if self.__log_file == nil then
    self.__log_file = create_log_file()
  end

  self:write_log_file(level, msg)
  if conf.log_level ~= "error" and conf.log_level ~= "warn" then
    if level ~= "error" and level ~= "warn" then
      print(self.__notify_fmt(msg))
    end
  end
end

--- Returns the path to the log file
---@return string|nil: The path to the log file or nil if it doesn't exist
function log:get_log_path()
  local log_path = join_path(vim.fn.stdpath("cache"), "supermaven-nvim.log")
  if vim.fn.filereadable(log_path) == 0 then
    return nil
  end
  return log_path
end

--- Logs a message to the log file
---@example log:log("Hello, world!")
---@param msg string: The log message
function log:log(msg)
  self:add_entry("log", msg)
end

--- Logs a warning message to the log file
---@example log:warn("Something went wrong!")
---@param msg string: The log message
function log:warn(msg)
  self:add_entry("warn", msg)
  vim.api.nvim_notify(self.__notify_fmt(msg), vim.log.levels.WARN, { title = "Supermaven" })
end

--- Logs an error message to the log file
---@example log:error("Something went wrong!")
---@param msg string: The log message
function log:error(msg)
  self:add_entry("error", msg)
  vim.api.nvim_notify(self.__notify_fmt(msg), vim.log.levels.ERROR, { title = "Supermaven" })
end

--- Logs an informational message to the log file
---
--- This is the level use to log information to the user as default.
---@example log:info("Something happened!")
---@param msg string: The log message
function log:info(msg)
  self:add_entry("info", msg)
end

--- Logs a debug message to the log file
---
--- Used to keep track of the execution of the plugin and extra information.
---
--- Only visible if the `debug` option is set to `true`.
---@example log:debug("Debugging...")
---@param msg string: The log message
function log:debug(msg)
  self:add_entry("debug", msg)
end

--- Logs a trace message to the log file
---
--- Used to keep track of the execution of the plugin.
---
--- Only visible if the `silence_info` option is set to `false`.
---@example log:trace("Tracing...")
---@param msg string: The log message
function log:trace(msg)
  self:add_entry("trace", msg)
end

setmetatable({}, log)
return log
