local BinaryFetcher = {
  binary_path = nil,
  binary_url = nil,
  os_uname = vim.loop.os_uname(),
  homedir = vim.loop.os_homedir()
}

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
    response = vim.fn.system {
      'powershell',
      '-Command',
      'Invoke-WebRequest',
      '-Uri',
      "'" .. url .. "'",
      '-UseBasicParsing',
      '|',
      'Select-Object',
      '-ExpandProperty',
      'Content'
    }
    response = string.gsub(response, "[\r\n]+", "")
  else
    response = vim.fn.system({"curl", "-s", url})
  end

  local json = vim.fn.json_decode(response)
  if json == nil then
    print("Error: Unable to find download URL for Supermaven binary")
    return nil
  end

  return json.downloadUrl
end

function BinaryFetcher:fetch_binary()
  local local_binary_path = self:local_binary_path()
  local status = vim.loop.fs_stat(local_binary_path)
  if status ~= nil then
    return local_binary_path
  else
    local success = vim.fn.mkdir(self:local_binary_parent_path(), "p")
    if not success then
      print("Error creating directory " .. self:local_binary_parent_path())
      return nil
    end
  end

  local url = self:discover_binary_url()
  if url == nil then
    return nil
  end

  print("Downloading Supermaven binary, please wait...")
  local platform = self:platform()
  local response = ""
  if platform == "windows" then
    response = vim.fn.system {
      'powershell',
      '-Command',
      'Invoke-WebRequest',
      '-Uri',
      "'" .. url .. "'",
      '-OutFile',
      "'" .. local_binary_path .. "'"
    }
  else
    response = vim.fn.system({"curl", "-o", local_binary_path, url})
  end
  if vim.v.shell_error == 0 then
    print("Downloaded binary sm-agent to " .. local_binary_path)
  else
    print("Error: sm-agent download failed")
    return nil
  end
  vim.loop.fs_chmod(local_binary_path, 493)
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
