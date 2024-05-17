---@diagnostic disable: missing-parameter
local c = require("supermaven-nvim.config")

---@class Log
local log = {}

local join_path = function(...)
	local is_windows = vim.loop.os_uname().version:match("Windows") -- could be "Windows" or "Windows_NT"
	local path_sep = is_windows and "\\" or "/"
	return table.concat(vim.tbl_flatten({ ... }), path_sep):gsub(path_sep .. "+", path_sep)
end

--- Creates a log file if it doesn't exist
local create_log_file = function()
	local log_path = log:get_log_path()
	if log_path ~= nil then
		return
	end
	log_path = join_path(vim.fn.stdpath("cache"), "supermaven-nvim.log")
	local file = io.open(log_path, "a")
	if file == nil then
		vim.api.nvim_err_writeln("Failed to create log file: " .. log_path)
		return
	end
	file:close()
end

function log:write_log_file(level, msg)
	local log_path = log:get_log_path()
	if log_path == nil then
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

function log:add_entry(level, msg)
	if msg == nil then
		print("received nil message")
		return
	end
	local conf = c.get_config()
	if self.__log_file == nil then
		self.__log_file = create_log_file()
	end

	if not self.__notify_fmt then
		self.__notify_fmt = function(message)
			return string.format(message)
		end
	end

	if conf.log_level == "off" then
		return
	end

	self:write_log_file(level, msg)
	if level == "info" then
		print(self.__notify_fmt(string.format("[supermaven-nvim] INFO: %s", msg)))
	end
  if not conf.silence_info then
    if level == "trace" then
      print(self.__notify_fmt(string.format("[supermaven-nvim] TRACE: %s", msg)))
    end
  end
  if conf.debug then
    if level == "debug" then
      print(self.__notify_fmt(string.format("[supermaven-nvim] DEBUG: %s", msg)))
    end
  end
end

function log:get_log_path()
	local log_path = join_path(vim.fn.stdpath("cache"), "supermaven-nvim.log")
	if vim.fn.filereadable(log_path) == 0 then
		return nil
	end
	return log_path
end

function log:log(msg)
	self:add_entry("log", msg)
end

function log:warn(msg)
	self:add_entry("warn", msg)
	vim.api.nvim_err_writeln(self.__notify_fmt(msg))
end

function log:error(msg)
	self:add_entry("error", msg)
	vim.api.nvim_err_writeln(self.__notify_fmt(msg))
end

function log:info(msg)
	self:add_entry("info", msg)
end

function log:debug(msg)
	self:add_entry("debug", msg)
end

function log:trace(msg)
	self:add_entry("trace", msg)
end

setmetatable({}, log)
return log
