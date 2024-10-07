local _MODREV, _SPECREV = "scm", "-1"

rockspec_format = "3.0"
package = "supermaven-nvim"
version = _MODREV .. _SPECREV

description = {
  summary = "The official Neovim plugin for Supermaven",
  detailed = [[
    The official Neovim plugin for Supermaven.

    This plugin provides code suggestions using Supermaven's AI assistant.
  ]],
  homepage = "https://github.com/supermaven-inc/supermaven-nvim",
  license = "MIT",
}

source = {
  url = "git+https://github.com/supermaven-inc/supermaven-nvim.git",
  tag = _MODREV .. _SPECREV,
}

dependencies = {
  "lua >= 5.1 < 5.4",
}

build = {
  type = "builtin",
}
