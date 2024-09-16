local log = require("supermaven-nvim.logger")
local u = require("supermaven-nvim.util")

local loop = u.uv

local BinaryFetcher = {
  binary_path = nil,
  binary_url = nil,
  os_uname = loop.os_uname(),
  homedir = loop.os_homedir(),
}

local function generate_temp_path(n)
  local charset = "abcdefghijklmnopqrstuvwxyz0123456789"
  local random_string = ""

  for _ = 1, n do
    local random_index = math.random(1, #charset)
    random_string = random_string .. string.sub(charset, random_index, random_index)
  end

  return random_string .. ".tmp"
end

function BinaryFetcher:platform()
  local os = self.os_uname.sysname
  if os == "Darwin" then
    return "macosx"
  elseif os == "Linux" then
    return "linux"
  elseif os == "Windows_NT" then
    return "windows"
  end
  return ""
end

function BinaryFetcher:get_arch()
  if self.os_uname.machine == "arm64" or self.os_uname.machine == "aarch64" then
    return "aarch64"
  elseif self.os_uname.machine == "x86_64" then
    return "x86_64"
  end
  return ""
end

function BinaryFetcher:discover_binary_url()
  local platform = self:platform()
  local arch = self:get_arch()
  local url = "https://supermaven.com/api/download-path?platform=" .. platform .. "&arch=" .. arch .. "&editor=neovim"
  local response = ""
  if platform == "windows" then
    response = vim.fn.system({
      "powershell",
      "-Command",
      "Invoke-WebRequest",
      "-Uri",
      "'" .. url .. "'",
      "-UseBasicParsing",
      "|",
      "Select-Object",
      "-ExpandProperty",
      "Content",
    })
    response = string.gsub(response, "[\r\n]+", "")
  else
    response = vim.fn.system({ "curl", "-s", url })
  end

  local json = vim.fn.json_decode(response)
  if json == nil then
    log:error("Unable to find download URL for Supermaven binary")
    return nil
  end

  return json.downloadUrl
end

function BinaryFetcher:fetch_binary()
  local local_binary_path = self:local_binary_path()
  local status = loop.fs_stat(local_binary_path)
  if status ~= nil then
    return local_binary_path
  else
    local success = vim.fn.mkdir(self:local_binary_parent_path(), "p")
    if not success then
      log:error("Error creating directory " .. self:local_binary_parent_path())
      return nil
    end
  end

  local url = self:discover_binary_url()
  if url == nil then
    return nil
  end

  log:info("Downloading Supermaven binary, please wait...")
  local temp_path = generate_temp_path(10)

  local platform = self:platform()
  local response = ""
  if platform == "windows" then
    response = vim.fn.system({
      "powershell",
      "-Command",
      "Invoke-WebRequest",
      "-Uri",
      "'" .. url .. "'",
      "-OutFile",
      "'" .. local_binary_path .. "'",
    })
  else
    response = vim.fn.system({ "curl", "-o", temp_path, url })
  end
  if vim.v.shell_error == 0 then
    if platform ~= "windows" then
      vim.fn.system({ "mv", temp_path, local_binary_path })
    end
    log:info("Downloaded binary sm-agent to " .. local_binary_path)
  else
    log:error("sm-agent download failed")
    return nil
  end
  loop.fs_chmod(local_binary_path, 493)
  return local_binary_path
end

function BinaryFetcher:local_binary_path()
  if self:platform() == "windows" then
    return self:local_binary_parent_path() .. "/sm-agent.exe"
  else
    return self:local_binary_parent_path() .. "/sm-agent"
  end
end

function BinaryFetcher:local_binary_parent_path()
  local home_dir = self.homedir
  return home_dir .. "/.supermaven/binary/v15/" .. self:platform() .. "-" .. self:get_arch()
end

return BinaryFetcher
