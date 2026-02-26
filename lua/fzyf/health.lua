---@class FzyfHealth
local M = {}

---Required binaries for the plugin to work
local REQUIRED_BINARIES = { "fzy", "fd" }

---Optional binaries that enhance functionality
local OPTIONAL_BINARIES = { "rg" }

---Check if a binary is executable
---@param binary string Name of the binary
---@return boolean
local function is_executable(binary)
  return vim.fn.executable(binary) == 1
end

---Run health check
function M.check()
  vim.health.start("fzyf.nvim: dependencies")

  -- Check required binaries
  for _, binary in ipairs(REQUIRED_BINARIES) do
    if is_executable(binary) then
      vim.health.ok(string.format("'%s' is installed", binary))
    else
      vim.health.error(
        string.format("'%s' is NOT installed", binary),
        string.format("Install '%s' to use fzyf.nvim", binary)
      )
    end
  end

  -- Check optional binaries
  for _, binary in ipairs(OPTIONAL_BINARIES) do
    if is_executable(binary) then
      vim.health.ok(string.format("'%s' is installed (optional)", binary))
    else
      vim.health.warn(
        string.format("'%s' is NOT installed (optional)", binary),
        string.format("Install '%s' for live grep functionality", binary)
      )
    end
  end

  -- Check Neovim version
  vim.health.start("fzyf.nvim: version")
  local version = vim.version()
  local version_str = string.format("v%d.%d.%d", version.major, version.minor, version.patch)

  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim " .. version_str .. " (supported)")
  else
    vim.health.warn(
      "Neovim " .. version_str .. " (may have issues)",
      "Neovim 0.9+ is recommended"
    )
  end

  -- Check for fzy-lua-native (optional)
  vim.health.start("fzyf.nvim: optional features")
  local has_native, _ = pcall(require, "fzy_native")
  if has_native then
    vim.health.ok("'fzy-lua-native' is available (faster native fuzzy matching)")
  else
    vim.health.info("'fzy-lua-native' not found (using external fzy binary)")
  end
end

return M
